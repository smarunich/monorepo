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
    
oc adm policy add-scc-to-user privileged \
    system:serviceaccount:istio-system:tsb-operator-control-plane
oc adm policy add-scc-to-user privileged \
    system:serviceaccount:istio-gateway:tsb-operator-data-plane

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
    oap:
      kubeSpec:
        overlays:
          - apiVersion: extensions/v1beta1
            kind: Deployment
            name: oap-deployment
            patches:
              - path: spec.template.spec.containers.[name:oap].env.[name:SW_RECEIVER_GRPC_SSL_CERT_CHAIN_PATH].value
                value: /skywalking/pkin/tls.crt
              - path: spec.template.spec.containers.[name:oap].env.[name:SW_CORE_GRPC_SSL_TRUSTED_CA_PATH].value
                value: /skywalking/pkin/tls.crt
        service:
          annotations:
            service.beta.openshift.io/serving-cert-secret-name: dns.oap-service-account
    istio:
      traceSamplingRate: 100
      kubeSpec:
        CNI:
          binaryDirectory: /var/lib/cni/bin
          chained: false
          configurationDirectory: /etc/cni/multus/net.d
          configurationFileName: istio-cni.conf
        overlays:
          - apiVersion: install.istio.io/v1alpha1
            kind: IstioOperator
            name: tsb-istiocontrolplane
            patches:
              - path: spec.meshConfig.defaultConfig.envoyAccessLogService.address
                value: oap.istio-system.svc:11800
              - path: spec.meshConfig.defaultConfig.envoyAccessLogService.tlsSettings.caCertificates
                value: /var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt
              - path: spec.values.cni.chained
                value: false
              - path: spec.values.sidecarInjectorWebhook
                value:
                  injectedAnnotations:
                    k8s.v1.cni.cncf.io/networks: istio-cni
              - path: spec.meshConfig.defaultConfig.proxyMetadata.ISTIO_META_DNS_CAPTURE
                value: "true"
              - path: spec.meshConfig.defaultConfig.proxyMetadata.ISTIO_META_DNS_AUTO_ALLOCATE
                value: "true"      
              - path: spec.meshConfig.defaultConfig.proxyMetadata.ISTIO_META_PROXY_XDS_VIA_AGENT
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
 
oc adm policy add-scc-to-user anyuid -n istio-system -z istiod-service-account # SA for istiod
oc adm policy add-scc-to-user anyuid -n istio-system -z vmgateway-service-account # SA for vmgateway
oc adm policy add-scc-to-user anyuid -n istio-system -z istio-system-oap # SA for OAP
oc adm policy add-scc-to-user privileged -n istio-system -z xcp-edge # SA for XCP-Edge

kubectl apply -f "${FOLDER}/cluster1-controlplane.yaml" 

#  k edit clusterrole istio-system-onboarding-operator
# - apiGroups:
#  - ""
#  resources:
#  - secrets
#  verbs: ["get"]

