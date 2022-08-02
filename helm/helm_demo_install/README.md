# Let's install TSB demo using Helm

## Deploying MP...

Please refer for more details over here: https://docs.tetrate.io/service-bridge/1.5.x/en-us/setup/requirements-and-download, https://docs.tetrate.io/service-bridge/1.5.x/en-us/setup/helm/managementplane

### Prep the certificates using OpenSSL on Linux

```sh
export FOLDER="."
export TSB_FQDN="r150helm.cx.tetrate.info"
./certs-gen/certs-gen.sh
```

The output will consist of:

- `ca.crt` - self-signed CA
- `tsb_certs.crt, tsb_certs.key` - TSB UI certificate
- `xcp-central-cert.crt, xcp-central-cert.key` - XCP Central certificate

### Prep the `managementplane_values.yaml`

```sh
./prep_managementplane_values.sh
cat managementplane_values.yaml
```

### Install MP using Helm

helm repo add tetrate-tsb-helm 'https://charts.dl.tetrate.io/public/helm/charts/'
helm repo update
helm install mp tetrate-tsb-helm/managementplane -n tsb --create-namespace -f managementplane_values.yaml

## Deploying CP...

```
export TSB_FQDN="r150helm.cx.tetrate.info"
tctl config clusters set helm --bridge-address $TSB_FQDN:8443

tctl config users set helm --username admin --password "Tetrate123" --org "tetrate"
tctl config profiles set helm --cluster helm --username helm
tctl config profiles set-current helm
```
