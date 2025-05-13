# Autherservice Setup

## Setup Authservice
```sh
NAMESPACE=authservice
kubectl create namespace ${NAMESPACE}
```

### Create Authservice Configuration

```sh
OIDC_CLIENT_ID="oidc-client-tetrate"
OIDC_CLIENT_SECRET="oidc-client-secret-tetrate"
OIDC_CONFIGURATION_URI="http://keycloak-demo.example.com:8080/realms/tetrate/.well-known/openid-configuration"
NAMESPACE=authservice
HOSTNAME=bookinfo-oidc.sandbox.tetrate.io

cat <<EOF | kubectl apply -n ${NAMESPACE} -f -
apiVersion: v1
kind: Secret
metadata:
  name: client-secret-oidc
type: Opaque
stringData:
  client-secret: "${OIDC_CLIENT_SECRET}"
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: authservice-config
data:
  config.json: |
    {
      "listen_address": "0.0.0.0",
      "listen_port": "10003",
      "log_level": "debug",
      "allow_unmatched_requests": false,
      "chains": [
        {
          "name": "oidc",
          "filters": [
            {
              "oidc":
              {
                "configuration_uri": "${OIDC_CONFIGURATION_URI}",
                "callback_uri": "https://${HOSTNAME}/callback",
                "client_id": "${OIDC_CLIENT_ID}",
                "client_secret_ref": {
                  "namespace": "authservice",
                  "name": "client-secret-oidc"
                },
                "id_token": {
                  "preamble": "Bearer",
                  "header": "authorization"
                },
                "access_token": {
                  "header": "x-access-token"
                }
              }
            }
          ]
        }
      ]
    }
EOF
```

### Deploy Authservice

```sh
NAMESPACE=authservice
cat <<EOF | kubectl apply -n ${NAMESPACE} -f -
apiVersion: v1
kind: Service
metadata:
  name: authservice
  labels:
    app: authservice
spec:
  ports:
    - port: 10003
      targetPort: 10003
      name: grpc-authservice
      protocol: TCP
    - port: 10004
      targetPort: 10004
      name: grpc-health
      protocol: TCP
  selector:
    app: authservice
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: authservice
  labels:
    app: authservice
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: authservice-secrets
rules:
  # Allow authservice to read the secrets in its namespace so it can read
  # the OIDC client-secret from a Kubernetes secret instead of having it in clear text
  # in the ConfigMap
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: authservice-secrets
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: authservice-secrets
subjects:
  - kind: ServiceAccount
    name: authservice
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: authservice
spec:
  replicas: 1
  selector:
    matchLabels:
      app: authservice
      version: v1
  template:
    metadata:
      labels:
        app: authservice
        version: v1
    spec:
      serviceAccountName: authservice
      containers:
        - name: authservice
          image: ghcr.io/istio-ecosystem/authservice/authservice:1.0.4
          imagePullPolicy: IfNotPresent
          ports:
            - name: authz
              containerPort: 10003
              protocol: TCP
            - name: health
              containerPort: 10004
              protocol: TCP
          volumeMounts:
            - name: config
              mountPath: /etc/authservice
          livenessProbe:
            initialDelaySeconds: 1
            periodSeconds: 5
            tcpSocket:
              port: 10003
          readinessProbe:
            initialDelaySeconds: 5
            periodSeconds: 5
            httpGet:
              port: 10004
              path: /healthz
      volumes:
        - name: config
          configMap:
            name: authservice-config
EOF
```

## TSB Setup with no external auth
Sample Gateway setup with certificate without enforcing external auth

### Sample Certificate Setup
```sh
cat <<EOF | kubectl apply -n bookinfo -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: bookinfo-oidc-certificate
  namespace: bookinfo
spec:
  secretName: bookinfo-oidc-certificate
  duration: 21600h # 900d
  issuerRef:
    name: selfsigned-ca
    kind: ClusterIssuer
    group: cert-manager.io
  dnsNames:
    - "bookinfo-oidc.sandbox.tetrate.io"
EOF
```

### Gateway Setup

```sh
HOSTNAME=bookinfo-oidc.sandbox.tetrate.io
NAMESPACE=bookinfo
cat <<EOF | kubectl apply -n ${NAMESPACE} -f -
apiVersion: gateway.tsb.tetrate.io/v2
kind: Gateway
metadata:
  annotations:
    tsb.tetrate.io/gatewayGroup: bookinfo-gg
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: dev
    tsb.tetrate.io/workspace: bookinfo-ws
  name: app-bookinfo-oidc
spec:
  http:
  - hostname: ${HOSTNAME}
    name: productpage
    port: 443
    tls:
      mode: SIMPLE
      secretName: bookinfo-oidc-certificate
    routing:
      rules:
      - route:
          serviceDestination:
            host: bookinfo/productpage.bookinfo.svc.cluster.local
            port: 9080
  workloadSelector:
    labels:
      app: app-gw
    namespace: bookinfo
EOF
```

### Test
```sh
HOSTNAME=bookinfo-oidc.sandbox.tetrate.io
INGRESS_GATEWAY=$(kubectl get svc -n edge edge-gw -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -vIX GET -H"Host: ${HOSTNAME}" --resolve ${HOSTNAME}:443:${INGRESS_GATEWAY} https://${HOSTNAME}/productpage
```

## TSB Setup with external auth

Now to add external auth

### Gateway Update
```sh
HOSTNAME=bookinfo-oidc.sandbox.tetrate.io
NAMESPACE=bookinfo
cat <<EOF | kubectl apply -n ${NAMESPACE} -f -
apiVersion: gateway.tsb.tetrate.io/v2
kind: Gateway
metadata:
  annotations:
    tsb.tetrate.io/gatewayGroup: bookinfo-gg
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: dev
    tsb.tetrate.io/workspace: bookinfo-ws
  name: app-bookinfo-oidc
  namespace: bookinfo
spec:
  http:
  - hostname: ${HOSTNAME}
    name: productpage
    port: 443
    tls:
      mode: SIMPLE
      secretName: bookinfo-oidc-certificate
    authorization:
      external:
        includeRequestHeaders: []
        uri: grpc://authservice.authservice.svc.cluster.local:10003
    routing:
      rules:
      - route:
          serviceDestination:
            host: bookinfo/productpage.bookinfo.svc.cluster.local
            port: 9080
  workloadSelector:
    labels:
      app: app-gw
    namespace: bookinfo
EOF
```

### JWT Validation
Create configuration profile to enforce jwt validation for a given workspace

```sh
NAMESPACE=bookinfo
cat <<EOF | kubectl apply -n ${NAMESPACE} -f -
apiVersion: profile.tsb.tetrate.io/v2
kind: Profile
metadata:
  name: jwt-required-defaults
  annotations:
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: dev
    tsb.tetrate.io/workspace: bookinfo-ws
spec:
  displayName: jwt-validation
  defaults:
    authenticationSettings:
      trafficMode: REQUIRED
      http:
        rules:
          jwt:
            - issuer: "http://keycloak-auth.sandbox.tetrate.io:8080/realms/tetrate"
              jwksUri: "http://keycloak-auth.sandbox.tetrate.io:8080/realms/tetrate/protocol/openid-connect/certs"
---
apiVersion: tsb.tetrate.io/v2
kind: Workspace
metadata:
  annotations:
    owner: bookinfo-ws-team
    tsb.tetrate.io/organization: tetrate
    tsb.tetrate.io/tenant: dev
  labels:
    app: bookinfo
  name: bookinfo-ws
spec:
  profiles:
    - organizations/tetrate/tenants/dev/workspaces/bookinfo-ws/profiles/jwt-required-defaults
  namespaceSelector:
    names:
    - '*/bookinfo'
    - '*/edge'
    - '*/egress'
EOF
```