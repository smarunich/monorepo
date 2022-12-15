export FOLDER='.' 
export WASM_EXAMPLE="http_request_headers"
export WASM_EXAMPLE_VERSION="0.2"
export CR="docker.io/smarunich"


make build.example name=$WASM_EXAMPLE
docker build . -t $CR/$WASM_EXAMPLE:$WASM_EXAMPLE_VERSION -f examples/wasm-image.Dockerfile --build-arg WASM_BINARY_PATH=examples/$WASM_EXAMPLE/main.wasm

docker pull $CR/$WASM_EXAMPLE:$WASM_EXAMPLE_VERSION

cat >"${FOLDER}/wasm_extension.yaml" <<EOF
---
apiVersion: extension.tsb.tetrate.io/v2
kind: WasmExtension
metadata:
  displayName: $WASM_EXAMPLE
  name: $WASM_EXAMPLE
  organization: tetrate
spec:
  allowedIn:
  - organizations/tetrate/tenants/dev
  image: oci://$CR/$WASM_EXAMPLE:$WASM_EXAMPLE_VERSION
  imagePullPolicy: Always
  priority: 1
  source: https://github.com/tetratelabs/proxy-wasm-go-sdk/tree/main/examples/http-headers
  vmConfig: {}
EOF

cat >"${FOLDER}/wasm_extension_t1_attachment_example.yaml" <<EOF
```
apiVersion: gateway.tsb.tetrate.io/v2
kind: Tier1Gateway
metadata:
  displayName: lob-app02-int-t1
  group: lob-app02-consumer-gg
  name: lob-app02-int-t1
  organization: tetrate
  tenant: dev
  workspace: lob-app02-consumer-ws
spec:
  displayName: lob-app02-int-t1
  extension:
  - config:
      header: x-wasm-header-response-t1-consumer
      value: "true"
    fqn: organizations/tetrate/extensions/http-response-headers-wasm
  - config:
      header: x-wasm-header-request-t1-consumer
      value: "true"
    fqn: organizations/tetrate/extensions/http-request-headers-wasm
  fqn: organizations/tetrate/tenants/dev/workspaces/lob-app02-consumer-ws/gatewaygroups/lob-app02-consumer-gg/tier1gateways/lob-app02-int-t1
  internalServers:
  - clusters:
    - name: gke-r160rc6p1-us-west1-0
      weight: 100
    hostname: internal-api-httpbin.gcp.cx.tetrate.info
    name: lob-app02-consumer
  workloadSelector:
    labels:
      app: lob-app02-consumer-t1
    namespace: lob-app02
```
EOF