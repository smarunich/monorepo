export FOLDER="."
export REGISTRY="ea1p2demotsbacrqsnstv6qddaupjrc.azurecr.io"
export ORG="tetrate"

cat >"${FOLDER}/managementplane_values.yaml" <<EOF
image:
  registry: $REGISTRY
  tag: 1.5.0
secrets:
  tsb:
    adminPassword: Tetrate123
    cert: |
      $(cat tsb_certs.crt)
    key: |
      $(cat tsb_certs.key)
  xcp:
    autoGenerateCerts: false
    central:
      cert: |
        $(cat xcp-central.crt) 
      key: |
        $(cat xcp-central.key) 
    rootca: |
      $(cat ca.crt)
spec:
  hub: $REGISTRY
  organization: $ORG
EOF