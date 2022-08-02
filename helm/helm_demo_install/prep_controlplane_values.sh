tctl config clusters set helm --tls-insecure --bridge-address $TSB_FQDN:8443
tctl config users set helm --username admin --password "Tetrate123" --org "tetrate"
tctl config profiles set helm --cluster helm --username helm
tctl config profiles set-current helm

cat > "${FOLDER}/$CLUSTER_NAME.yaml" <<EOF
---
apiVersion: api.tsb.tetrate.io/v2
kind: Cluster
metadata:
  name: $CLUSTER_NAME
  organization: $ORG
spec:
  tokenTtl: "87600h"
  tier1Cluster: false
EOF

tctl apply -f "${FOLDER}/$CLUSTER_NAME.yaml" 

tctl install cluster-service-account --cluster $CLUSTER_NAME > $CLUSTER_NAME-service-account.jwk

export CA_CRT=$(cat ca.crt)
export TSB_CRT=$(cat tsb_certs.crt)
export TSB_KEY=$(cat tsb_certs.key)
export XCP_CENTRAL_CERT=$(cat xcp-central-cert.crt)
export XCP_CENTRAL_KEY=$(cat xcp-central-cert.key)

cat >"${FOLDER}/controlplane_values.yaml" <<EOF
image:
  registry: $REGISTRY
  tag: 1.5.0
secrets:
secrets:
  clusterServiceAccount:
    JWK: '\$(cat $CLUSTER_NAME-service-account.jwk)'
    clusterFQN: organizations/$ORG/clusters/$CLUSTER_NAME
  elasticsearch:
    cacert: |
  tsb:
    cacert: |  
  xcp: 
    rootca: |
spec:
  hub: $REGISTRY
  managementPlane:
    clusterName: $CLUSTER_NAME
    host: $TSB_FQDN
    port: 8443
    selfSigned: true
  meshExpansion: {}
  telemetryStore:
    elastic:
      host: $TSB_FQDN
      port: 8443
      protocol: https
      selfSigned: true
      version: 7
EOF

yq -i '.secrets.elasticsearch.cacert = strenv(CA_CRT) |
       .secrets.tsb.cacert = strenv(CA_CRT) |
       .secrets.xcp.rootca = strenv(CA_CRT)' controlplane_values.yaml

cat >"${FOLDER}/dataplane_values.yaml" <<EOF
image:
  registry: $REGISTRY
  tag: 1.5.0
EOF