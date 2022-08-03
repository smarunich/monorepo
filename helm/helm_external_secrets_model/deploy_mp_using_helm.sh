kubectl create ns tsb
kubectl apply -f mp-secrets.yaml
ssh-keygen -f jwt-token.key -m pem  -q -N ""
kubectl -n tsb create secret generic iam-signing-key --from-file=private.key=jwt-token.key
helm install tsb-managementplane --debug -n tsb -f mp-helm-values-no-secrets-provided.yaml tetrate-tsb-helm/managementplane --version 1.5.0-EA2 --devel