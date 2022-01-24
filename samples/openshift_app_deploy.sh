export FOLDER='.'
export APP_NS='bookinfo'

cat >"${FOLDER}/oc_networkattach.yaml" <<EOF
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: istio-cni
EOF


oc create namespace $APP_NS
oc label namespace $APP_NS istio-injection=enabled

oc -n $APP_NS create -f $FOLDER/oc_networkattach.yaml
oc adm policy add-scc-to-group anyuid system:serviceaccounts:$APP_NS

oc rollout restart deployment -n $APP_NS
