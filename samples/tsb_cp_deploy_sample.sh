export REGISTRY="mstsbacrx9pslvvlqec0jpg3.azurecr.io"
export FOLDER="."
export BASE_FQDN="example.com"
export TSB_FQDN_PREFIX="tsb"
export TSB_FQDN="ms-station.cx.tetrate.info"

./tctl140 config clusters set default --tls-insecure --bridge-address $(kubectl get svc -n tsb envoy --output jsonpath='{.status.loadBalancer.ingress[0].ip}'):8443
./tctl140 config profiles set-current default
./tctl140 login --org tetrate --username admin --password Tetrate123 --tenant tetrate

cat >"${FOLDER}/tctl-cluster1.yaml" <<EOF
apiVersion: api.tsb.tetrate.io/v2
kind: Cluster
metadata:
  name: cluster1
  organization: tetrate
spec:
  tokenTtl: "8760h"
  tier1Cluster: false
EOF

./tctl140 apply -f "${FOLDER}/tctl-cluster1.yaml"

./tctl140 install manifest cluster-operators \
    --registry ${REGISTRY} > ${FOLDER}/clusteroperators.yaml
    
kubectl apply -f clusteroperators.yaml
 
tctl install manifest control-plane-secrets \
    --elastic-password tsb-elastic-password \
    --elastic-username tsb \
    --cluster cluster1 \
    --xcp-central-ca-bundle "$(cat xcp_central.crt)" \
    --elastic-ca-certificate "$(cat ca.crt)" \
    > ${FOLDER}/cluster1-controlplane-secrets.yaml
    
    
k apply -f ${FOLDER}/cluster1-controlplane-secrets.yaml

kubectl -n istio-system create secret generic xcp-edge-ca-bundle --from-literal="ca.crt=$(kubectl get secret -n tsb xcp-central-cert -o jsonpath='{.data.ca\.crt}' | base64 -d)"

cat >"${FOLDER}/cluster1-controlplane.yaml" <<EOF
apiVersion: install.tetrate.io/v1alpha1
kind: ControlPlane
metadata:
  name: controlplane
  namespace: istio-system
spec:
  hub: ${REGISTRY}
  telemetryStore:
    elastic:
      host: ${TSB_FQDN}
      port: 8443
      protocol: https
      selfSigned: true
      version: 7
  managementPlane:
    host: ${TSB_FQDN}
    port: 8443
    clusterName: cluster1
  components:
    istio:
      kubeSpec:
        overlays:
          - apiVersion: install.istio.io/v1alpha1
            kind: IstioOperator
            name: tsb-istiocontrolplane
            patches:
            - path: spec.meshConfig.defaultConfig.proxyMetadata
              value:
              - name: ISTIO_META_DNS_CAPTURE
                value: "true"
            - path: spec.meshConfig.defaultConfig.proxyMetadata
              value:
              - name: ISTIO_META_DNS_AUTO_ALLOCATE
                value: "true"           
    xcp:
      centralAuthMode: JWT
      kubeSpec:
        overlays:
        - apiVersion: install.xcp.tetrate.io/v1alpha1
          kind: EdgeXcp
          name: edge-xcp
          # These patches enable edges to be able to verify Central's server cert. The host is
          # changed from a bare IP address as it's difficult to generate a cert with the IP
          # address in the SANs as the IP isn't known until after the service is deployed.
          patches:
          - path: spec.components.edgeServer.kubeSpec.deployment.env
            value:
            - name: ENABLE_RESTORE_ORIGINAL_NAMES
              value: "false"
          - path: "spec.centralAuthJwt.centralCaSecret"
            value: "xcp-central-ca-bundle"
          - path: spec.components.edgeServer.kubeSpec.service.annotations
            value:
              service.beta.kubernetes.io/azure-load-balancer-internal: "false"
          - path: spec.components.edgeServer.kubeSpec.overlays
            value:
            - apiVersion: v1
              kind: Service
              name: xcp-edge
              patches:
              - path: spec.type
                value: LoadBalancer
  meshExpansion: {}
EOF
 
kubectl apply -f "${FOLDER}/cluster1-controlplane.yaml" 
