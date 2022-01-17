az ad app create 
  --display-name TSB \
  --reply-urls "https://<TSB_IP>:8443/iam/v2/oidc/callback" \
  --oauth2-allow-implicit-flow true \
  --required-resource-accesses @requireResourceManifest.json
  
az ad app  credential reset  --id <appID>  --append

az ad sp create --id <appID>

az ad app permission admin-consent --id  <appID>

az ad app permission grant --id <appID> --api 00000002-0000-0000-c000-000000000000

# In order to use the TSB token, a user record must be created in TSB with a user ID matching the subject claim from the AzureAD Service Principal, which is also the same as the Client ID from the AzureAD App Registration screen. In addition, the AzureAD App Registration must also set accessTokenAcceptedVersion=2 in the App Manifest. This enables TSB to perform token checks required for the token exchange grant.

#tctl install manifest management-plane-secrets --allow-defaults --tsb-admin-password <TSB_Admin_Pass>   \
    --oidc-client-secret=<Client_Secret> \
    --teamsync-azure-client-secret=<Client_Secret> > secret.yaml
 
#kubectl apply -f secret.yaml

tctl edit managementplane managementplane -n tsb

apiVersion: install.tetrate.io/v1alpha1
kind: ManagementPlane
metadata:
  name: managementplane
  namespace: tsb
spec:
  ( … )
  identityProvider:
    oidc:
      clientId: <the application client id>
      providerConfig:
        dynamic:
          configurationUri: <the application configuration uri>
      redirectUri: https://<tsb-address>:8443/iam/v2/oidc/callback
      scopes:
      - email
      - profile
      - offline_access
      offlineAccessConfig:
        deviceCodeAuth:
          clientId: <the application client id>
            offlineAccessConfig:
        tokenExchange:
          clientId: <the application client id>
    sync:
      azure:
        clientId: <the application client id>
        tenantId: <the application tenant id>
        
# curl -X POST  \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=client_credentials&client_id=<clientID>&resource=<clientID>&client_secret=<clientSecret>' \
  https://login.microsoftonline.com/<directoryID>/oauth2/token \
  | jq -r '.access_token'
# tctl login --use-token-exchange --access-token <azure service principal token>
