helm get values dataplane -n istio-gateway  -o yaml > ${CLUSTER}-dataplane.yaml
helm get values controlplane -n istio-system -o yaml >  ${CLUSTER}-controlplane.yaml
sed 's/-rc9/-rc12/g'  ${CLUSTER}-controlplane.yaml >  ${CLUSTER}-controlplane-rc12.yaml 
sed 's/-rc9/-rc12/g'  ${CLUSTER}-dataplane.yaml >  ${CLUSTER}-dataplane-rc12.yaml 
helm upgrade controlplane --debug tetrate-tsb-helm/controlplane  -f ${CLUSTER}-controlplane-rc12.yaml --version 1.6.0-internal-rc12 -n istio-system
helm upgrade dataplane --debug tetrate-tsb-helm/dataplane  -f ${CLUSTER}-dataplane-rc12.yaml --version 1.6.0-internal-rc12 -n istio-gateway
