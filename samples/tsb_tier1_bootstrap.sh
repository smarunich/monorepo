export REGISTRY="mstsbacrx9pslvvlqec0jpg3.azurecr.io"
export FOLDER="."
export TSB_FQDN="ms-station.cx.tetrate.info"
   
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
