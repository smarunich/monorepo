export FOLDER='.'

cat >"${FOLDER}/dr-reviews.yaml" <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
  namespace: bookinfo-bridged
  annotations:
    tsb.tetrate.io/trafficGroup: bookinfo-direct-traffic-group
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: dev
    tsb.tetrate.io/workspace: proxy-direct-workspace
spec:
  host: reviews
  trafficPolicy:
    loadBalancer:
      simple: RANDOM
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
  - name: v3
    labels:
      version: v3
EOF 


cat >"${FOLDER}/vs-reviews.yaml" <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
  namespace: bookinfo-bridged
  annotations:
    tsb.tetrate.io/trafficGroup: bookinfo-direct-traffic-group
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: dev
    tsb.tetrate.io/workspace: proxy-direct-workspace
spec:
  hosts:
    - reviews
  http:
  - match:
    - headers:
        reviews:
          exact: v2
    route:
    - destination:
        host: reviews
        subset: v2
  - route:
    - destination:
        host: reviews
        subset: v1
EOF 

