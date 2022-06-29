export FOLDER="."

cat > "${FOLDER}/cluster1.yaml" <<EOF
---
apiVersion: api.tsb.tetrate.io/v2
kind: Cluster
metadata:
  name: ea2p3d1
  organization: tetrate
spec:
  tokenTtl: "87600h"
  tier1Cluster: false
EOF


# can be a direct api call, tctl can be avoided, please refer to https://github.com/smarunich/monorepo/blob/main/samples/curl.md
tctl apply -f "${FOLDER}/cluster1.yaml" 

# can be a direct api call, tctl can be avoided, please refer to https://github.com/smarunich/monorepo/blob/main/samples/curl.md
tctl install cluster-service-account --cluster ea1p4d2 > ea1p4d2-service-account.jwk

# shortcut, only for example purposes, please refer to cp-secrets.yaml for the template
# tctl install manifest control-plane-secrets \
#     --cluster ea1p4d2 \
#     --cluster-service-account="$(cat ea1p4d2-service-account.jwk)"
#     > ea1p4d2-service-account-secrets.yaml

kubectl create ns istio-system
kubectl apply -f cp-secrets.yaml
helm install tsb-controlplane --debug -n istio-system -f cp-helm-values-no-secrets-provided.yaml tetrate-tsb-helm/controlplane --version 1.5.0-EA2 --devel
helm install tsb-dataplane --debug --create-namespace -n istio-gateway -f dp-helm-values-no-secrets-provided.yaml tetrate-tsb-helm/dataplane --version 1.5.0-EA2 --devel