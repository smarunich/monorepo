export TSB_IP="52.191.20.15"

curl -X POST -ku admin:Tetrate123 https://$TSB_IP:8443/v2/organizations/tetrate/clusters/cluster1:generateTokens > cluster1-generateTokens.json

cat >"${FOLDER}/cluster1-manual-controlplane-secrets.yaml" <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: oap-token
  namespace: istio-system
type: Opaque
data:
  token: "$(cat cluster1-generateTokens.json | jq -r '.tokens."oap-agent-cluster1"' | base64)"
---
apiVersion: v1
kind: Secret
metadata:
  name: otel-token
  namespace: istio-system
type: Opaque
data:
  token: "$(cat cluster1-generateTokens.json | jq -r '.tokens."otel-collector-cluster1"'| base64)"
---
apiVersion: v1
kind: Secret
metadata:
  name: zipkin-token
  namespace: istio-system
type: Opaque
data:
  token: "$(cat cluster1-generateTokens.json | jq -r '.tokens."zipkin-agent-cluster1"'| base64)"
---
apiVersion: v1
kind: Secret
metadata:
  name: elastic-credentials
  namespace: istio-system
type: Opaque
data:
  username: "dHNi"
  password: "dHNiLWVsYXN0aWMtcGFzc3dvcmQ="
---
apiVersion: v1
kind: Secret
metadata:
  name: es-certs
  namespace: istio-system
type: Opaque
data:
  ca.crt: "$(cat ca.crt | base64)"
---
apiVersion: v1
kind: Secret
metadata:
  name: xcp-edge-central-auth-token
  namespace: istio-system
type: Opaque
data:
  jwt: "$(cat cluster1-generateTokens.json | jq -r '.tokens."xcp-edge-cluster1"'| base64)""
---
apiVersion: v1
kind: Secret
metadata:
  name: xcp-central-ca-bundle
  namespace: istio-system
type: Opaque
data:
  ca.crt: "$(cat xcp_central.crt | base64)"
EOF
