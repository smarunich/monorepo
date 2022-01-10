#https://docs.tetrate.io/service-bridge/1.4.x/en-us/operations/oidc_azure

tctl edit managementplane managementplane -n tsb

---
apiVersion: install.tetrate.io/v1alpha1
kind: ManagementPlane
metadata:
  name: managementplane
  namespace: tsb
spec:
  ( … )
  identityProvider:
    sync:
      azure:
        clientId: <the application client id>
        tenantId: <the application tenant id>
