cat >"${FOLDER}/gateway-sample.yaml" <<EOF
---
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  annotations:
    external-dns.alpha.kubernetes.io/hostname: {{FQDN}}
    tsb.tetrate.io/organization: {{ORGANIZATION}}
    tsb.tetrate.io/tenant: {{TENANT}}
    tsb.tetrate.io/workspace: {{WORK_SPACE}}
    tsb.tetrate.io/gatewayGroup: {{GATEWAY_GROUP}}
  name: gwy-{{NAME_SPACE}}
  namespace: {{NAME_SPACE}}
spec:
  selector:
    app: igwy-{{NAME_SPACE}}
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - {{FQDN}}
EOF

cat >"${FOLDER}/dr-sample.yaml" <<EOF
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  annotations:
    tsb.tetrate.io/organization: {{ORGANIZATION}}
    tsb.tetrate.io/tenant: {{TENANT}}
    tsb.tetrate.io/workspace: {{WORK_SPACE}}
    tsb.tetrate.io/trafficGroup: {{GATEWAY_GROUP}}
  name: dr-{{APP_NAME}}
spec:
  host: {{APP_NAME}}
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
EOF

cat >"${FOLDER}/vs-sample.yaml" <<EOF
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  annotations:
    tsb.tetrate.io/organization: {{ORGANIZATION}}
    tsb.tetrate.io/tenant: {{TENANT}}
    tsb.tetrate.io/workspace: {{WORK_SPACE}}
    tsb.tetrate.io/gatewayGroup: {{TRAFFIC_GROUP}}
  name: vs-{{APP_NAME}}
spec:
  hosts: 
  - {{APP_FQDN}}
  gateways:
  - {{GATEWAY}}
  http:
  - route:
    - destination:
        host: {{APP_NAME}}
        subset: v1
  - match:
    - headers:
        version:
          exact: v2
    route:
    - destination:
        host: {{APP_NAME}}
        subset: v2
EOF


