export FOLDER='.'

cat >"${FOLDER}/tctl-tier1-mp.yaml" <<EOF
---
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  annotations:
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: dev
    tsb.tetrate.io/workspace: proxy-workspace
    tsb.tetrate.io/gatewayGroup: proxy-gatewaygroup
  name: tier1-mp
  namespace: tier1
spec:
  selector:
    app: tier1
  servers:
  - port:
      number: 8443
      name: tls-8443
      protocol: TLS
    tls:
      mode: PASSTHROUGH
    hosts:
    - dmz-ms-station.cx.tetrate.info
  - port:
      number: 9443
      name: tls-9443
      protocol: TLS
    tls:
      mode: PASSTHROUGH
    hosts:
    - dmz-ms-station.cx.tetrate.info
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  annotations:
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: dev
    tsb.tetrate.io/workspace: proxy-workspace
    tsb.tetrate.io/gatewayGroup: proxy-gatewaygroup
  name: vs-tier1-mp
  namespace: tier1
spec:
  hosts: 
  - ms-station.cx.tetrate.info
  gateways:
  - tier1/tier1-mp
  tls:
    - match:
        - sniHosts:
            - dmz-ms-station.cx.tetrate.info
          port: 8443
      route:
        - destination:
            host: "ms-station.cx.tetrate.info"
            port:
              number: 8443
    - match:
        - sniHosts:
            - dmz-ms-station.cx.tetrate.info
          port: 9443
      route:
        - destination:
            host: "ms-station.cx.tetrate.info"
            port:
              number: 9443
EOF



cat >"${FOLDER}/kubectl-tier1-mp.yaml" <<EOF
---
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: mp-serviceentry
  namespace: istio-system
spec:
  endpoints:
  - address: 52.188.177.111
    ports:
      tls-8443: 8443
  - address: 52.188.177.111
    ports:
      tls-9443: 9443
  exportTo:
  - '*'
  hosts:
  - ms-station.cx.tetrate.info
  location: MESH_EXTERNAL
  ports:
  - name: tls-8443
    number: 8443
    protocol: TLS
  - name: tls-9443
    number: 9443
    protocol: TLS
  resolution: STATIC
EOF
