
https://gateway.envoyproxy.io/latest/tasks/operations/customize-envoyproxy/

```sh
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: eg
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
  parametersRef:
    group: gateway.envoyproxy.io
    kind: EnvoyProxy
    name: custom-proxy-config
    namespace: envoy-gateway-system
EOF

cat <<EOF | kubectl apply -f -
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: EnvoyProxy
metadata:
  name: custom-proxy-config
  namespace: envoy-gateway-system
spec:
  provider:
    type: Kubernetes
    kubernetes:
      envoyDeployment:
        container:
          resources:
            requests:
              cpu: 150m
              memory: 640Mi
            limits:
              cpu: 500m
              memory: 1Gi
EOF

cat <<EOF | kubectl apply -f -
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: EnvoyProxy
metadata:
  name: custom-proxy-config
  namespace: envoy-gateway-system
spec:
  provider:
    type: Kubernetes
    kubernetes:
      envoyHpa:
        minReplicas: 2
        maxReplicas: 10
        metrics:
          - resource:
              name: cpu
              target:
                averageUtilization: 60
                type: Utilization
            type: Resource
EOF

```

https://gateway.envoyproxy.io/latest/tasks/operations/deployment-mode/

```
Kubernetes

    The default deployment model is - Envoy Gateway watches for resources such a Service & HTTPRoute in all namespaces and creates managed data plane resources such as EnvoyProxy Deployment in the namespace where Envoy Gateway is running.
    Envoy Gateway also supports Namespaced deployment mode, you can watch resources in the specific namespaces by assigning EnvoyGateway.provider.kubernetes.watch.namespaces or EnvoyGateway.provider.kubernetes.watch.namespaceSelector and creates managed data plane resources in the namespace where Envoy Gateway is running.
    Support for alternate deployment modes is being tracked here.

Multi-tenancy
Kubernetes

    A tenant is a group within an organization (e.g. a team or department) who shares organizational resources. We recommend each tenant deploy their own Envoy Gateway controller in their respective namespace. Below is an example of deploying Envoy Gateway by the marketing and product teams in separate namespaces.

    Lets deploy Envoy Gateway in the marketing namespace and also watch resources only in this namespace. We are also setting the controller name to a unique string here gateway.envoyproxy.io/marketing-gatewayclass-controller.
```


```apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: basic-gateway
spec:
  gatewayClassName: envoy-gateway
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
      hostname: "first.example.com"
      tls:
        mode: Terminate
        certificateRefs:
          kind: Secret
          name: example-cert
    - name: https
      protocol: HTTPS
      port: 443
      hostname: "*.example.com"
      tls:
        mode: Terminate
        certificateRefs:
          kind: Secret
          name: wildcard-cert
    - name: http
      protocol: HTTP
      port: 80
```


Namespace is the namespace of the referenced object. When unspecified, the local namespace is inferred.

Note that when a namespace different than the local namespace is specified, a ReferenceGrant object is required in the referent namespace to allow that namespace’s owner to accept the reference. See the ReferenceGrant documentation for details.

Support: Core
