export REGISTRY="mstsbacrx9pslvvlqec0jpg3.azurecr.io"
export FOLDER="."
export BASE_FQDN="example.com"
export TSB_FQDN_PREFIX="tsb"
export TSB_FQDN="ms-station.cx.tetrate.info"
export TSB_GATEWAY="tsb-gateway"
export APP_NAME="bookinfo"
export APP_NAMESPACE="bookinfo"

./tctl140 config clusters set default --tls-insecure --bridge-address $(kubectl get svc -n tsb envoy --output jsonpath='{.status.loadBalancer.ingress[0].ip}'):8443
./tctl140 config profiles set-current default
./tctl140 login --org tetrate --username admin --password Tetrate123 --tenant tetrate

cat >"${FOLDER}/install-ingress-gateway.yaml" <<EOF
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: ${TSB_GATEWAY}
  namespace: ${APP_NAMESPACE}
spec:
  kubeSpec:
    service:
      type: LoadBalancer
      annotations:
        service.beta.kubernetes.io/azure-load-balancer-internal: "false"
EOF

k apply -f ${FOLDER}/install-ingress-gateway.yaml

cat >"${FOLDER}/bookinfo-ingress-gateway.yaml" <<EOF
apiVersion: gateway.tsb.tetrate.io/v2
kind: IngressGateway
Metadata:
  organization: tetrate
  tenant: tetrate
  name: bookinfo-gw-ingress
  group: bookinfo-gw
  workspace: bookinfo-ws
spec:
  workloadSelector:
    namespace: ${APP_NAMESPACE}
    labels:
      app: ${TSB_GATEWAY}
  http:
    - name: ${APP_NAME}
      hostname: "bookinfo.tetrate.com"
      routing:
        rules:
          - route:
              host: "${APP_NAMESPACE}/productpage.bookinfo.svc.cluster.local"
EOF

tctl apply -f "${FOLDER}/bookinfo-ingress-gateway.yaml"
