export REGISTRY="mstsbacrx9pslvvlqec0jpg3.azurecr.io"
export FOLDER="."
export TSB_FQDN="ms-station.cx.tetrate.info"

tctl config clusters set default --tls-insecure --bridge-address $(kubectl get svc -n tsb envoy --output jsonpath='{.status.loadBalancer.ingress[0].ip}'):8443
tctl config profiles set-current default
tctl login --org tetrate --username admin --password Tetrate123 --tenant tetrate

cat >"${FOLDER}/install-tier1-gateway.yaml" <<EOF
apiVersion: install.tetrate.io/v1alpha1
kind: Tier1Gateway
metadata:
  name: tier1-vm
  namespace: tier1
spec:
  kubeSpec:
    service:
      type: LoadBalancer
      annotations:
        service.beta.kubernetes.io/azure-load-balancer-internal: "false"
EOF

kubectl apply -f "${FOLDER}/install-tier1-gateway.yaml"

cat >"${FOLDER}/tier1gateway.yaml" <<EOF
---
apiVersion: gateway.tsb.tetrate.io/v2
kind: Tier1Gateway
metadata:
  name: bookinfo-tier1
  group: bookinfo-gatewaygroup 
  organization: tetrate
  tenant: dev
  workspace: bookinfo-workspace
spec:
  workloadSelector:
    namespace: tier1
    labels:
      app: tier1-vm
EOF

tctl apply -f "${FOLDER}/tier1gateway.yaml" 
