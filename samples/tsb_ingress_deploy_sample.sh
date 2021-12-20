

cat >"${FOLDER}/ingress-gateway.yaml" <<EOF
apiVersion: install.tetrate.io/v1alpha1
kind: IngressGateway
metadata:
  name: tsb-gateway-bookinfo
  namespace: bookinfo
spec:
  kubeSpec:
    service:
      type: LoadBalancer
      annotations:
        service.beta.kubernetes.io/azure-load-balancer-internal: "false"
EOF


