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
export FOLDER="."
export REGISTRY="r150helm1tsbacrqasvohujrqvnjp0u.azurecr.io"
export ORG="tetrate"
./prep_managementplane_values.sh
cat managementplane_values.yaml
```

### Install MP using Helm

```sh
helm repo add tetrate-tsb-helm 'https://charts.dl.tetrate.io/public/helm/charts/'
helm repo update
helm install mp tetrate-tsb-helm/managementplane -n tsb --create-namespace -f managementplane_values.yaml
```

## Deploying CP...

Please refer for more details over here: https://docs.tetrate.io/service-bridge/1.5.x/en-us/setup/requirements-and-download, https://docs.tetrate.io/service-bridge/1.5.x/en-us/setup/helm/controlplane

### Connect to MP

```sh
export TSB_FQDN="r150helm.cx.tetrate.info"
tctl config clusters set helm --tls-insecure --bridge-address $TSB_FQDN:8443
tctl config users set helm --username admin --password "Tetrate123" --org "tetrate"
tctl config profiles set helm --cluster helm --username helm
tctl config profiles set-current helm
```

### Validate the connection

```
❯ tctl get org
NAME       DISPLAY NAME    DESCRIPTION
tetrate    tetrate
```

### Prep the `controlplane_values.yaml` and `dataplane_values.yaml`

```sh
export FOLDER="."
export TSB_FQDN="r150helm.cx.tetrate.info"
export REGISTRY="r150helm1tsbacrqasvohujrqvnjp0u.azurecr.io"
export ORG="tetrate"
export CLUSTER_NAME="app-cluster1"
./prep_controlplane_values.sh
cat controlplane_values.yaml
```

### Install CP using Helm

```sh
helm repo add tetrate-tsb-helm 'https://charts.dl.tetrate.io/public/helm/charts/'
helm repo update
helm install cp tetrate-tsb-helm/controlplane -n istio-system --create-namespace -f controlplane_values.yaml
helm install dp tetrate-tsb-helm/dataplane -n istio-gateway --create-namespace -f dataplane_values.yaml
```
