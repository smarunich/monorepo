export CA_CRT=$(cat ca.crt)
export TSB_CRT=$(cat tsb_certs.crt)
export TSB_KEY=$(cat tsb_certs.key)
export XCP_CENTRAL_CERT=$(cat xcp-central-cert.crt)
export XCP_CENTRAL_KEY=$(cat xcp-central-cert.key)

cat >"${FOLDER}/managementplane_values.yaml" <<EOF
image:
  registry: $REGISTRY
  tag: 1.5.0
secrets:
  ldap:
    binddn: cn=admin,dc=tetrate,dc=io
    bindpassword: admin
  postgres:
    password: tsb-postgres-password
    username: tsb
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

yq -i '.secrets.xcp.rootca = strenv(CA_CRT) |
       .secrets.xcp.central.cert = strenv(XCP_CENTRAL_CERT) |
       .secrets.xcp.central.key = strenv(XCP_CENTRAL_KEY) |
       .secrets.tsb.cert = strenv(TSB_CRT) |
       .secrets.tsb.key = strenv(TSB_KEY)'  managementplane_values.yaml