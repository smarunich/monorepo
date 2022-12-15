export NAMESPACE="bookinfo"
export FOLDER="."

wasm_image=wasm_header.wasm
kubectl -n $NAMESPACE create configmap wasm_header --from-file=$wasm_image


cat >"${FOLDER}/wasm-patch-annotations.yaml" <<EOF
spec:
  template:
    metadata:
      annotations:
        sidecar.istio.io/userVolume: '[{"name":"wasmfilters-dir","configMap": {"name":"wasm_header"}}]'
        sidecar.istio.io/userVolumeMount: '[{"mountPath":"/var/local/lib/wasm-filters","name":"wasmfilters-dir"}]'
EOF

patch_annotations=$(cat patch-annotations.yaml)
kubectl -n $NAMESPACE patch deployment ratings-v1 -p "$patch_annotations"

#kubectl -n $NAMESPACE patch deployment  frontpage-v1 -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/userVolume":"[{\"name\":\"wasmfilters-dir\",\"configMap\": {\"name\": \"wasm_header\"}}]","sidecar.istio.io/userVolumeMount":"[{\"mountPath\":\"/var/local/lib/wasm-filters\",\"name\":\"wasmfilters-dir\"}]"}}}}}'


# multiple filters using common configmap

k -n $NAMESPACE create configmap wasm-plugins --from-file  http_routing.wasm --from-file http_headers.wasm --from-file wasm_header.wasm
k -n $NAMESPACE apply -f http_routing.yaml
k -n $NAMESPACE apply -f http_headers.yaml
k -n $NAMESPACE apply -f envoy-filter-local.yaml

cat >"${FOLDER}/wasm-plugins-patch-annotations.yaml" <<EOF
spec:
  template:
    metadata:
      annotations:
        sidecar.istio.io/userVolume: '[{"name":"wasmfilters-dir","configMap": {"name":"wasm-plugins"}}]'
        sidecar.istio.io/userVolumeMount: '[{"mountPath":"/var/local/lib/wasm-filters","name":"wasmfilters-dir"}]'
        sidecar.istio.io/logLevel: info
EOF

patch_annotations=$(cat ${FOLDER}/wasm-plugins-patch-annotations.yaml)
kubectl -n $NAMESPACE patch deployment productpage-v1 -p "$patch_annotations"
kubectl -n $NAMESPACE patch deployment reviews-v1 -p "$patch_annotations"
kubectl -n $NAMESPACE patch deployment reviews-v2 -p "$patch_annotations"
kubectl -n $NAMESPACE patch deployment reviews-v3 -p "$patch_annotations"

