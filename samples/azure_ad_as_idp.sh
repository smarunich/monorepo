export FOLDER='.'
export TSB_FQDN="ms-station.cx.tetrate.info"
export AZURE_TENANT_ID="1076231c-4971-42f2-8c33-aa8680e81ea8"                 

cat >"${FOLDER}/requireResourceManifest.json" <<EOF
[
  {
    "resourceAppId": "00000003-0000-0000-c000-000000000000",
    "resourceAccess": [
      {
        "id": "7ab1d382-f21e-4acd-a863-ba3e13f7da61",
        "type": "Role"
      }
    ]
  }
]
EOF

az ad app create \
  --display-name TSB-${TSB_FQDN} \
  --reply-urls "https://${TSB_FQDN}:8443/iam/v2/oidc/callback" \
  --oauth2-allow-implicit-flow true \
  --required-resource-accesses @requireResourceManifest.json
  
export TSB_APP_ID=`az ad app list --display-name=TSB-${TSB_FQDN} | jq -r '.[].appId'`
  
az ad app  credential reset  --id $TSB_APP_ID  --append

az ad sp create --id  $TSB_APP_ID

az ad app permission admin-consent --id  $TSB_APP_ID

az ad app permission grant --id $TSB_APP_ID --api 00000003-0000-0000-c000-000000000000

# In order to use the TSB token, a user record must be created in TSB with a user ID matching the subject claim from the AzureAD Service Principal, which is also the same as the Client ID from the AzureAD App Registration screen. In addition, the AzureAD App Registration must also set accessTokenAcceptedVersion=2 in the App Manifest. This enables TSB to perform token checks required for the token exchange grant.

#tctl install manifest management-plane-secrets --allow-defaults --tsb-admin-password <TSB_Admin_Pass>   \
    --oidc-client-secret=<Client_Secret> \
    --teamsync-azure-client-secret=<Client_Secret> > secret.yaml


kubectl -n tsb create secret generic iam-oidc-client-secret --from-literal=client-secret=''
kubectl -n tsb create secret generic azure-credentials --from-literal=client-secret=''

#kubectl apply -f secret.yaml

kubectl edit managementplane managementplane -n tsb


cat >"${FOLDER}/managementplane_oidc_patch.yaml" <<EOF
spec:
  identityProvider:
    oidc:
      clientId: ${TSB_APP_ID}
      providerConfig:
        dynamic:
          configurationUri: https://login.microsoftonline.com/$AZURE_TENANT_ID/v2.0/.well-known/openid-configuration
      redirectUri: https://$TSB_FQDN:8443/iam/v2/oidc/callback
      scopes:
      - email
      - profile
      - offline_access
      offlineAccessConfig:
        deviceCodeAuth:
          clientId: ${TSB_APP_ID}
        tokenExchange:
          clientId: ${TSB_APP_ID}
    sync:
      azure:
        clientId: ${TSB_APP_ID}
        tenantId: ${AZURE_TENANT_ID}
EOF
  
kubectl -n tsb patch managementplane/managementplane --patch "$(cat "$FOLDER"/managementplane_oidc_patch.yaml)" --type=merge
        
# curl -X POST  \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=client_credentials&client_id=<clientID>&resource=<clientID>&client_secret=<clientSecret>' \
  https://login.microsoftonline.com/<directoryID>/oauth2/token \
  | jq -r '.access_token'
# tctl login --use-token-exchange --access-token <azure service principal token>
