# Custom Envoyfilter to modify tcp.connectTimeout for the defined service

1(a). Identify the cluster you want to modify the ```tcp.connectTimeout``

```sh
~/workspace/smarunich/sandbox-r172d1/outputs main !1 ?6 ❯ istioctl pc endpoint tier1-gw-6dcc96f4d9-nckx6 -n tier1                                   ✘ INT ⎈ azure-r172d1-eastus-0
ENDPOINT                                                STATUS      OUTLIER CHECK     CLUSTER
10.0.104.234:11800                                      HEALTHY     OK                envoy_accesslog_service
10.0.104.234:11800                                      HEALTHY     OK                envoy_metrics_service
10.0.128.209:9411                                       HEALTHY     OK                zipkin
10.0.160.133:15443                                      HEALTHY     OK                outbound|80|tier1-bookinfo-gw-productpage-external-port-80|internal-bookinfo.tetrate.io
10.0.160.133:15443                                      HEALTHY     OK                outbound|80||internal-bookinfo.tetrate.io
127.0.0.1:15000                                         HEALTHY     OK                prometheus_stats
127.0.0.1:15020                                         HEALTHY     OK                agent
unix://./etc/istio/proxy/XDS                            HEALTHY     OK                xds-grpc
unix://./var/run/secrets/workload-spiffe-uds/socket     HEALTHY     OK                sds-grpc
```

1(b). Identify the cluster you want to modify the ```tcp.connectTimeout``
 without istioctl

```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  annotations:
    owner: bookinfo-ws-team
    tsb.tetrate.io/config-mode: bridged
    tsb.tetrate.io/etag: '"9Te/clKUQeI="'
    tsb.tetrate.io/fqn: organizations/tetrate/tenants/dev/workspaces/bookinfo-ws/gatewaygroups/bookinfo-gg/unifiedgateways/tier1-bookinfo-gw
    tsb.tetrate.io/runtime-etag: '"ymN00DtTJ68="'
    xcp.tetrate.io/contentHash: f97a524b87d4f797a190aef6d6949609
  creationTimestamp: "2023-10-23T15:58:59Z"
  generation: 1
  labels:
    app: bookinfo
    app.kubernetes.io/managed-by: tsb
    argocd.argoproj.io/instance: bookinfo
    domain: dev
    istio.io/rev: default
    xcp.tetrate.io/gatewayGroup: bookinfo-gg
    xcp.tetrate.io/workspace: bookinfo-ws-3f33545c770e7109
  name: tier1-tier1-bookinfo-gwinternal-bookinfo-tetrate-io
  namespace: tier1
  resourceVersion: "27349"
  uid: 8e32cb02-6b53-4292-a048-cf1be0eca1c5
spec:
  exportTo:
  - .
  host: internal-bookinfo.tetrate.io
  subsets:
  - labels:
      xcp.tetrate.io/svc-port-80: "true"
    name: tier1-bookinfo-gw-productpage-external-port-80
    trafficPolicy:
      portLevelSettings:
      - connectionPool:
          http:
            useClientProtocol: true
        outlierDetection:
          consecutiveGatewayErrors: 10
          maxEjectionPercent: 100
        port:
          number: 80
        tls:
          mode: ISTIO_MUTUAL
          sni: internal-bookinfo.tetrate.io
  workloadSelector:
    matchLabels:
      app: tier1-gw
```

Look for subset name as `.spec.subsets[].name`

```
~/workspace/smarunich/sandbox-r172d1/outputs main !1 ?6 ❯ k get dr -n tier1 tier1-tier1-bookinfo-gwinternal-bookinfo-tetrate-io -o yaml  | yq '.spec.subsets[].name'
tier1-bookinfo-gw-productpage-external-port-80
```

where `internal-bookinfo.tetrate.io` is your service name

The cluster will be: ```outbound|80|tier1-bookinfo-gw-productpage-external-port-80|internal-bookinfo.tetrate.io```


2. Apply envoyfilter for a specific Tier1 catered service...

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: modify-connect-timeout
  namespace: tier1
spec:
  workloadSelector:
    labels:
      app: tier1-gw # Update this with the appropriate label of your gateway
  configPatches:
    - applyTo: CLUSTER
      match:
        context: GATEWAY
        cluster:
          name: "outbound|80|tier1-bookinfo-gw-productpage-external-port-80|internal-bookinfo.tetrate.io"
      patch:
        operation: MERGE
        value:
          connect_timeout: "0.5s"
```
