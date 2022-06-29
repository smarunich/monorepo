kubectl create ns tsb
kubectl apply -f mp-secrets.yaml
helm install tsb-managementplane --debug -n tsb -f mp-helm-values-no-secrets-provided.yaml tetrate-tsb-helm/managementplane --version 1.5.0-EA2 --devel