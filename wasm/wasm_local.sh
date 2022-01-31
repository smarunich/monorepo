export NAMESPACE="bookinfo"
export FOLDER="."

wasm_image=1.9.0.wasm
kubectl -n $NAMESPACE create configmap wasm_header --from-file=$wasm_image




cat >"${FOLDER}/wasm-patch-annotations.yaml" <<EOF
```
spec:
  template:
    metadata:
      annotations:
        sidecar.istio.io/userVolume: '[{"name":"wasmfilters-dir","configMap": {"name":"wasm_header"}}]'
        sidecar.istio.io/userVolumeMount: '[{"mountPath":"/var/local/lib/wasm-filters","name":"wasmfilters-dir"}]'
```

patch_annotations=$(cat patch-annotations.yaml)

kubectl -n $NAMESPACE patch deployment ratings-v1 -p "$patch_annotations"

