cat >"${FOLDER}/managementplane_values.yaml" <<EOF
image:
  registry: $REGISTRY
  tag: 1.5.0
secrets:
  tsb:
    adminPassword: Tetrate123
    cert: | 
      
    key: |
      
  xcp:
    autoGenerateCerts: false
    central:
      cert: |
        
      key: | 
        
    rootca: |
      
spec:
  hub: $REGISTRY
  organization: $ORG
EOF

export CA_CRT=$(cat ./certs-gen/ca.crt)
export TSB_CRT=$(cat ./certs-gen/tsb_certs.crt)
export TSB_KEY=$(cat ./certs-gen/tsb_certs.key)
export XCP_CENTRAL_CERT=$(cat ./certs-gen/xcp-central-cert.crt)
export XCP_CENTRAL_KEY=$(cat ./certs-gen/xcp-central-cert.key)

yq -i '.secrets.xcp.rootca = strenv(CA_CRT) |
       .secrets.xcp.central.cert = strenv(XCP_CENTRAL_CERT) |
       .secrets.xcp.central.key = strenv(XCP_CENTRAL_KEY) |
       .secrets.tsb.cert = strenv(TSB_CRT) |
       .secrets.tsb.key = strenv(TSB_KEY)'  managementplane_values.yaml