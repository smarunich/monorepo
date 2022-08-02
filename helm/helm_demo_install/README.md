# Let's install TSB demo using Helm

## Deploying MP...

Please refer for more details over here: https://docs.tetrate.io/service-bridge/1.5.x/en-us/setup/requirements-and-download, https://docs.tetrate.io/service-bridge/1.5.x/en-us/setup/helm/managementplane

### Prep the certificates using OpenSSL on Linux

```sh
export FOLDER="."
export TSB_FQDN="r150helm.cx.tetrate.info"
./certs-gen.sh
```

The output will consist of:

- `ca.crt` - self-signed CA
- `tsb_certs.crt, tsb_certs.key` - TSB UI certificate
- `xcp-central-cert.crt, xcp-central-cert.key` - XCP Central certificate

### Prep the `managementplane_values.yaml`

```sh
./prep_managementplane_values.sh
```
