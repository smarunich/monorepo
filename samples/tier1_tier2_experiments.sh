#!/usr/bin/env bash

# Set the global variables

export MESH_ID="mesh1"
export CLUSTER1_CTX="eks-tidp2-eu-west-1-0-kubeconfig"
export CLUSTER2_CTX="eks-tidp2-eu-west-1-1-kubeconfig"
export CLUSTER1_ID="cluster1"
export CLUSTER2_ID="cluster2"
export NETWORK1_ID="network1"
export NETWORK2_ID="network2"

# Setup common trust very very very very... dirty :D 

curl -o ca.crt https://raw.githubusercontent.com/smarunich/monorepo/main/samples/cacerts-istiod/ca.crt
curl -o ca.key https://raw.githubusercontent.com/smarunich/monorepo/main/samples/cacerts-istiod/ca.key
curl -o istiod_cacerts.sh https://raw.githubusercontent.com/smarunich/monorepo/main/samples/cacerts-istiod/tsb_deploy_istiod_cacerts.sh
chmod a+x istiod_cacerts.sh
./istiod_cacerts.sh

# Setup cluster1 prereqs

# If the istio-system namespace is already created, we need to set the cluster’s network there:
kubectl --context="${CLUSTER1_CTX}" create ns istio-system
kubectl --context="${CLUSTER1_CTX}" get namespace istio-system
kubectl --context="${CLUSTER1_CTX}" label namespace istio-system topology.istio.io/network=$NETWORK1_ID
kubectl --context="${CLUSTER1_CTX}" create secret generic cacerts -n istio-system \
  --from-file=ca-cert.pem="istiod_intermediate_ca.crt" \
  --from-file=ca-key.pem="istiod_intermediate_ca.key" \
  --from-file=root-cert.pem="ca.crt" \
  --from-file=cert-chain.pem="istiod_intermediate_ca.crt"


cat <<EOF > $CLUSTER1_ID.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: $MESH_ID
      multiCluster:
        clusterName: $CLUSTER1_ID
      network: $NETWORK1_ID
  meshConfig:
    accessLogFile: /dev/stdout
    defaultConfig:
      proxyMetadata:
        # Enable basic DNS proxying
        ISTIO_META_DNS_CAPTURE: "true"
        # Enable automatic address allocation, optional
        ISTIO_META_DNS_AUTO_ALLOCATE: "true"
EOF

getmesh switch 1.17.2-tetrate-v0
istioctl install --context="${CLUSTER1_CTX}" -f $CLUSTER1_ID.yaml

curl https://raw.githubusercontent.com/istio/istio/release-1.17/samples/multicluster/gen-eastwest-gateway.sh -o gen-eastwest-gateway.sh
chmod a+x gen-eastwest-gateway.sh

./gen-eastwest-gateway.sh \
    --mesh $MESH_ID --cluster $CLUSTER1_ID --network $NETWORK1_ID | \
    istioctl --context="${CLUSTER1_CTX}" install -y -f -

export CLUSTER1_EWGW_ENDPOINT=`kubectl --context="${CLUSTER1_CTX}" get svc istio-eastwestgateway -n istio-system -o json | jq -r '.status.loadBalancer.ingress[0].hostname'`

cat <<EOF > ${CLUSTER1_ID}_EWGW_ISTIO_GATEWAY.yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: eastwestgateway
  namespace: istio-system
spec:
  selector:
    istio: eastwestgateway
  servers:
    - port:
        number: 15443
        name: tls
        protocol: TLS
      tls:
        mode: AUTO_PASSTHROUGH
      hosts:
        - "*.local"
EOF

kubectl --context="${CLUSTER1_CTX}" apply -n istio-system -f ${CLUSTER1_ID}_EWGW_ISTIO_GATEWAY.yaml

# Setup cluster2 prereqs

# If the istio-system namespace is already created, we need to set the cluster’s network there:
kubectl --context="${CLUSTER2_CTX}" create ns istio-system
kubectl --context="${CLUSTER2_CTX}" get namespace istio-system
kubectl --context="${CLUSTER2_CTX}" label namespace istio-system topology.istio.io/network=$NETWORK1_ID
kubectl --context="${CLUSTER2_CTX}" create secret generic cacerts -n istio-system \
  --from-file=ca-cert.pem="istiod_intermediate_ca.crt" \
  --from-file=ca-key.pem="istiod_intermediate_ca.key" \
  --from-file=root-cert.pem="ca.crt" \
  --from-file=cert-chain.pem="istiod_intermediate_ca.crt"

cat <<EOF > $CLUSTER2_ID.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: $MESH_ID
      multiCluster:
        clusterName: $CLUSTER2_ID
      network: $NETWORK2_ID
  meshConfig:
    accessLogFile: /dev/stdout
    defaultConfig:
      proxyMetadata:
        # Enable basic DNS proxying
        ISTIO_META_DNS_CAPTURE: "true"
        # Enable automatic address allocation, optional
        ISTIO_META_DNS_AUTO_ALLOCATE: "true"
EOF

getmesh switch 1.17.2-tetrate-v0
istioctl install --context="${CLUSTER2_CTX}" -f $CLUSTER2_ID.yaml

curl https://raw.githubusercontent.com/istio/istio/release-1.17/samples/multicluster/gen-eastwest-gateway.sh -o gen-eastwest-gateway.sh
chmod a+x gen-eastwest-gateway.sh

./gen-eastwest-gateway.sh \
    --mesh $MESH_ID --cluster $CLUSTER2_ID --network $NETWORK2_ID | \
    istioctl --context="${CLUSTER2_CTX}" install -y -f -

export CLUSTER2_EWGW_ENDPOINT=`kubectl --context="${CLUSTER2_CTX}" get svc istio-eastwestgateway -n istio-system -o json | jq -r '.status.loadBalancer.ingress[0].hostname'`

cat <<EOF > ${CLUSTER2_ID}_EWGW_ISTIO_GATEWAY.yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: eastwestgateway
  namespace: istio-system
spec:
  selector:
    istio: eastwestgateway
  servers:
    - port:
        number: 15443
        name: tls
        protocol: TLS
      tls:
        mode: AUTO_PASSTHROUGH
      hosts:
        - "*.local"
EOF

kubectl --context="${CLUSTER2_CTX}" apply -n istio-system -f ${CLUSTER2_ID}_EWGW_ISTIO_GATEWAY.yaml

# Enable Endpoint Discovery
istioctl x create-remote-secret \
  --context="${CLUSTER1_CTX}" \
  --name=$CLUSTER1_ID | \
  kubectl apply -f - --context="${CLUSTER2_CTX}"

istioctl x create-remote-secret \
  --context="${CLUSTER2_CTX}" \
  --name=$CLUSTER2_ID | \
  kubectl apply -f - --context="${CLUSTER1_CTX}"


# Deploy the demo application, the instructions do include:
  # Part 1 - application, CLUSTER2_CTX
  # Part 2 - application ingress (tier2), CLUSTER2_CTX
  # Part 3 - platform ingress (tier1), CLUSTER1_CTX

## Part 1 - Application
## Application is hosted at CLUSTER2 

export APP_NS="app1-bookinfo"

kubectl --context="${CLUSTER2_CTX}" create namespace $APP_NS
kubectl --context="${CLUSTER2_CTX}" label namespace $APP_NS istio-injection=enabled
kubectl --context="${CLUSTER2_CTX}" apply -n $APP_NS -f https://raw.githubusercontent.com/istio/istio/release-1.17/samples/bookinfo/platform/kube/bookinfo.yaml

## Part 2 - Application ingress (tier2), CLUSTER2_CTX
## Application is hosted at CLUSTER2 

cat <<EOF > ${CLUSTER2_ID}_${APP_NS}_TIER2_ISTIO.yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: bookinfo-gateway
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo
spec:
  hosts:
  - "*"
  gateways:
  - bookinfo-gateway
  http:
  - match:
    - uri:
        exact: /productpage
    - uri:
        prefix: /static
    - uri:
        exact: /login
    - uri:
        exact: /logout
    - uri:
        prefix: /api/v1/products
    route:
    - destination:
        host: productpage
        port:
          number: 9080
EOF

kubectl --context="${CLUSTER2_CTX}" apply -n $APP_NS -f ${CLUSTER2_ID}_${APP_NS}_TIER2_ISTIO.yaml

export CLUSTER2_APP_TIER2_ENDPOINT=`kubectl --context="${CLUSTER2_CTX}" get svc istio-ingressgateway -n istio-system -o json | jq -r '.status.loadBalancer.ingress[0].hostname'`

curl -s "http://${CLUSTER2_APP_TIER2_ENDPOINT}/productpage" | grep -o "<title>.*</title>"


## Part 3 - Application ingress (tier2), CLUSTER2_CTX
## Application is hosted at CLUSTER2 

export TIER1_NS="tier1"

kubectl --context="${CLUSTER1_CTX}" create namespace $TIER1_NS
kubectl --context="${CLUSTER1_CTX}" label namespace $TIER1_NS istio-injection=enabled

cat <<EOF > ${CLUSTER1_ID}_${APP_NS}_TIER1_ISTIO.yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: tier1-bookinfo-gateway
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo
spec:
  hosts:
  - "*"
  gateways:
  - tier1-bookinfo-gateway
  http:
  - match:
    - uri:
        exact: /productpageba
    route:
    - destination:
        host: productpage.app1-bookinfo.svc.cluster.local
        port:
          number: 9080
EOF

kubectl --context="${CLUSTER1_CTX}" apply -n $TIER1_NS -f ${CLUSTER1_ID}_${APP_NS}_TIER1_ISTIO.yaml

export CLUSTER1_TIER1_ENDPOINT=`kubectl --context="${CLUSTER1_CTX}" get svc istio-ingressgateway -n istio-system -o json | jq -r '.status.loadBalancer.ingress[0].hostname'`


curl -s "http://${CLUSTER1_TIER1_ENDPOINT}/productpage" | grep -o "<title>.*</title>"
