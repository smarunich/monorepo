cat >"${FOLDER}/gateway-sample.yaml" <<EOF
---
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  annotations:
    external-dns.alpha.kubernetes.io/hostname: {{DNS}}
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
  - hosts:
    - {{DNS}}
    port:
      name: http
      number: 80
      protocol: HTTP
EOF
