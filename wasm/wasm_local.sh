export NAMESPACE="bookinfo"
export FOLDER="."

wasm_image=wasm_header.wasm
kubectl -n $NAMESPACE create configmap wasm_header --from-file=$wasm_image

kubectl -n $NAMESPACE patch deployment  frontpage-v1 -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/userVolume":"[{\"name\":\"wasmfilters-dir\",\"configMap\": {\"name\": \"wasm_header\"}}]","sidecar.istio.io/userVolumeMount":"[{\"mountPath\":\"/var/local/lib/wasm-filters\",\"name\":\"wasmfilters-dir\"}]"}}}}}'

kubectl -n $NAMESPACE exec -it deployment/frontpage-v1 -c istio-proxy -- ls /var/local/lib/wasm-filters/


