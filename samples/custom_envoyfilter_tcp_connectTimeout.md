# Custom Envoyfilter to modify tcp.connectTimeout for the defined service

1(a). Identify the cluster you want to modify the ```tcp.connectTimeout```

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

1(b) Identify the cluster you want to modify the ```tcp.connectTimeout``` by checking GatewayLogs
If you send connection to the service your hitting for northsouth traffic the gateway should present logs which includes the cluster name we need for the envoyfilter
```sh
kubectl logs deploy/tier1-gw
[2023-10-24T14:37:51.491Z] "HEAD /productpage HTTP/1.1" 200 - via_upstream - "-" 0 0 31 31 "172.20.0.5" "curl/8.1.2" "ecb8976d-cabf-43f9-80c1-d4f7ad1148c4" "bookinfo.tetrate.io" "10.0.80.75:15443" outbound|80|tier1-igw-bookinfo-external-port-80|bookinfo.tetrate.io 10.244.1.14:48680 10.244.1.14:8080 172.20.0.5:7826 - tier1-igw-bookinfo-external
[2023-10-24T14:37:55.697Z] "HEAD /productpage HTTP/1.1" 200 - via_upstream - "-" 0 0 40 40 "10.244.1.1" "curl/8.1.2" "0a477562-60c3-4b29-b54d-2ca0b3acba26" "bookinfo.tetrate.io" "10.0.80.75:15443" outbound|80|tier1-igw-bookinfo-external-port-80|bookinfo.tetrate.io 10.244.1.14:48672 10.244.1.14:8080 10.244.1.1:59617 - tier1-igw-bookinfo-external
[2023-10-24T14:37:59.937Z] "HEAD /productpage HTTP/1.1" 200 - via_upstream - "-" 0 0 31 31 "172.20.0.7" "curl/8.1.2" "030cb32d-4800-44f0-b2a5-4c37a9511567" "bookinfo.tetrate.io" "10.0.80.75:15443" outbound|80|tier1-igw-bookinfo-external-port-80|bookinfo.tetrate.io 10.244.1.14:48672 10.244.1.14:8080 172.20.0.7:40175 - tier1-igw-bookinfo-external
```
Look for the cluster from the logs, in this example is: ```outbound|80|tier1-igw-bookinfo-external-port-80|bookinfo.tetrate.io```

1(c). Identify the cluster you want to modify the ```tcp.connectTimeout```
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
