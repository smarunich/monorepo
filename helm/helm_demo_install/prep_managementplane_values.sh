export FOLDER="."
export REGISTRY="r150helm0tsbacrahbiwkvvrb9u6wii.azurecr.io"
export ORG="tetrate"

cat >"${FOLDER}/managementplane_values.yaml" <<EOF
image:
  registry: $REGISTRY
  tag: 1.5.0
secrets:
  tsb:
    adminPassword: Tetrate123
    cert: | 
      $(for line in $(cat tsb_certs.crt); do echo "   $line"; done;)
    key: 
      $(for line in $(cat tsb_certs.key); do echo "   $line"; done;)
  xcp:
    autoGenerateCerts: false
    central:
      cert: |
        $(for line in $(cat xcp-central-cert.crt); do echo "   $line"; done;)
      key: | 
        $(for line in $(cat xcp-central-cert.key); do echo "   $line"; done;)
    rootca: |
      $(for line in $(cat ca.crt); do echo "   $line"; done;)
spec:
  hub: $REGISTRY
  organization: $ORG
EOF