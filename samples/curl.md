# cp onboarding prereqs using curl

## basic auth examples https://docs.tetrate.io/service-bridge/1.5.0.dev/en-us/reference/rest-api/guide

```
curl -k -X GET -H"x-tetrate-token: eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NTY0MzU5NzMsImlhdCI6MTY1NjQzMjM3MywiaXNzIjoiaHR0cHM6Ly9kZW1vLnRldHJhdGUuaW8iLCJqdGkiOiI2ZmIwNDFiZC1mYmY5LTQ5NTktODJkOC0xMzdmNTI3ZGE2NjAiLCJzdWIiOiJhZG1pbiIsInRva2VudHlwZSI6ImJlYXJlciJ9.nj2zPAYdhkZYr0q4mZpr2zXmkY_axI30yvhzwhQyeEwE4_jUMJDp8e1Xp8LAbzAyIYB8NBXWL9qBLQbCJyxvyeaXJdzWgB7WH0wZKnCqljxAq0AKZFwb5AdIOzcBjXWa3sC7apeXMyotRclJGc_IBXZTWfLplkYgA6GPsJqhCDQyRQ5Rb8LbZTLyIxaRUWueffNpt-8xEULpxoP4h8P7Jo5siS2jMLNBXCvx-SFqkXbOjbLUoKVP1Kt8lo73x15xRZZ9qEZsoOnqY72qjHezy0M4eFAu2W1d7kId_5npgJOtauS4dzRXSi203ceOmoqJDczvlI2CtMtjQTVK0vV6499yqUF99IBH04Spq8d7aNjSV6DfE7zv3ops2bGJn5fIErjvDdYbvAT26lUwPBk5SN4Dvfga6ivKsjPRF8sruoCvAyPo4Fe0kDBaSRDUYOKff7gvQedN1p0boIZrolPjIn2hfHWhgl7yGfZBryAQdEAih6Y2nwzWjngbEVOZMYQfaPNIXVtRh4q_r-4Zpcfe8UyP_HGH0a_I-wX-J1SOZKZzBd_JA-UXp4LMoXwP-LLtkaZrvll8G4mIPSnQ56kHYkpVf1to0a6CBu2BYzVxwSdrRNamkhFkHEo9QdRksl42swFjZgRQrRQnjc8kjWH-qjSpH_fncrnXJiMYT8CmefE" https://104.199.122.83:8443/v2/organizations/tetrate/tenants | jq -r .
```

```
curl -k -X GET -u admin:Tetrate123 https://104.199.122.83:8443/v2/organizations/tetrate/clusters | jq -r '.clusters[].fqn'
```

## Step 1 creating cluster, i.e. `tctl apply -f "${FOLDER}/$CLUSTER.yaml"`

```
export FOLDER='.'
export ORG="tetrate"
export CLUSTER="testcluster3"

# https://docs.tetrate.io/service-bridge/1.5.0.dev/rest/#operation/ClustersCreateCluster
cat > "${FOLDER}/cluster-$CLUSTER.json" <<EOF
{
  "name": "$CLUSTER",
  "tokenTtl": "87600h",
  "tier1Cluster": false,
  "cluster": {}
}
EOF

# can be a direct api call, tctl can be avoided
# tctl apply -f "${FOLDER}/$CLUSTER.yaml"

curl -k -u admin:Tetrate123 https://104.199.122.83:8443/v2/organizations/$ORG/clusters -X POST -d @cluster-$CLUSTER.json

```

## Step 2 creating service account, i.e. `tctl install cluster-service-account --cluster $CLUSTER > $CLUSTER-service-account.jwk`

```
export FOLDER='.'
export ORG="tetrate"
export CLUSTER="testcluster3"

# can be a direct api call, tctl can be avoided
# tctl install cluster-service-account --cluster $CLUSTER > $CLUSTER-service-account.jwk

#https://docs.tetrate.io/service-bridge/1.5.0.dev/rest/#operation/TeamsCreateServiceAccount
cat > "${FOLDER}/sa-$CLUSTER.json" <<EOF
{
  "name": "cluster-$CLUSTER",
  "serviceAccount": {}
}
EOF

curl -k -u admin:Tetrate123 https://104.199.122.83:8443/v2/organizations/$ORG/serviceaccounts -X POST -d @sa-$CLUSTER.json > sa-$CLUSTER-keys.json
#cat sa-$CLUSTER-keys.json
#curl -k -u admin:Tetrate123 https://104.199.122.83:8443/v2/organizations/$ORG/clusters/$CLUSTER/policy -X GET

cat > "${FOLDER}/sa-$CLUSTER-policy.json" <<EOF
{
    "allow": [
        {
            "role": "rbac/admin",
            "subjects": [
                {
                    "serviceAccount": "admin"
                }
            ]
        },
        {
            "role": "rbac/writer",
            "subjects": [
                {
                    "serviceAccount": "organizations/$ORG/serviceaccounts/cluster-$CLUSTER"
                }
            ]
        }
    ]
}
EOF

curl -k -u admin:Tetrate123 https://104.199.122.83:8443/v2/organizations/$ORG/clusters/$CLUSTER/policy -X PUT -d @sa-$CLUSTER-policy.json
# required jwk for cluster-service-account secret as part of control plane onboarding
curl -k -u admin:Tetrate123 https://104.199.122.83:8443/v2/organizations/$ORG/serviceaccounts/cluster-$CLUSTER/jwks > sa-$CLUSTER-jwk.json
```

## delete examples

```
export ORG="tetrate"
export CLUSTER="testcluster3"

curl -k -u admin:Tetrate123 https://104.199.122.83:8443/v2/organizations/$ORG/clusters/$CLUSTER -X DELETE
curl -k -u admin:Tetrate123 https://104.199.122.83:8443/v2/organizations/$ORG/serviceaccounts/cluster-$CLUSTER -X DELETE
```
