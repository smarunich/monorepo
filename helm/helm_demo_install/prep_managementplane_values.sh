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
    cert: $(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' tsb_certs.crt)
    key: $(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' tsb_certs.key)
  xcp:
    autoGenerateCerts: false
    central:
      cert: $(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' xcp-central-cert.crt) 
      key: $(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' xcp-central-cert.key) 
    rootca: $(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' ca.crt)
spec:
  hub: $REGISTRY
  organization: $ORG
EOF