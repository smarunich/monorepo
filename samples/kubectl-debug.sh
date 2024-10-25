POD=`kubectl get pod -l app=edge -n istio-system | grep -v NAME | cut -d' ' -f1`
CONTAINER=`kubectl get pod $POD -n istio-system -o json | jq -r .spec.containers[].name`

cat <<EOF > /tmp/custom.yaml
securityContext:
  runAsUser: 0
EOF

kubectl debug -it $POD \
  --image alpine:latest \
  --target $CONTAINER \
  --namespace istio-system \
  --profile sysadmin \
  --custom /tmp/custom.yaml
