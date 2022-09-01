# Configure JWT Issuer 

### KB
https://docs.tetrate.io/service-bridge/latest/en-us/setup/self_managed/management-plane-installation#iam-signing-key

Recomendedation: in production deployment to supply a dedicated signing key for signing JWT tokens

### Example generation of Private Key

```bash
ssh-keygen -f jwt-token.key -m pem

# Create Kubernetes Secret using generated key
kubectl -n default create secret generic iam-signing-key --from-file=private.key=jwt-token.key
```
### Supply following to Management Plane Config
Private Key secret name and `key` name of `private.key` used by iam secret volumeMount

```yaml
spec:
  tokenIssuer:
    jwt:
      expiration: 3600s
      refreshExpiration: 2592000s
      tokenPruneInterval: 3600s
      issuers:
        - name: https://jwt.tetrate.io
          signingKey: private.key
      signingKeysSecret: iam-signing-key
```
