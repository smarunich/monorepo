# AUTO_RELOAD_PLUGIN_CERTS with certmanager

Istio to be made aware of Intermediate CA Cert rotation being handled by cert-manager

## ControlPlane values.yaml
Components peiced together - more details below
```yaml
spec:
  components:
    istio:
      kubeSpec:
        deployment:
          env:
          - name: AUTO_RELOAD_PLUGIN_CERTS
            value: "true"
        overlays:
        - apiVersion: install.istio.io/v1alpha1
          kind: IstioOperator
          name: tsb-istiocontrolplane
          patches:
          - path: spec.components.pilot.k8s.overlays
            value:
            - apiVersion: apps/v1
              kind: Deployment
              name: istiod
              patches:
              - path: spec.template.spec.volumes[2]
                value:
                  name: cacerts
                  secret:
                    defaultMode: 420
                    items:
                    - key: tls.crt
                      path: cert-chain.pem
                    - key: tls.crt
                      path: ca-cert.pem
                    - key: tls.key
                      path: ca-key.pem
                    - key: ca.crt
                      path: root-cert.pem
                    optional: true
                    secretName: cacerts
```

## Enable Istio to detect when cacerts secret changes 
To enable Istio to detect cacerts secret updates
```yaml
env:
- name: AUTO_RELOAD_PLUGIN_CERTS
  value: "true"
```

## Secret cacerts path mapping
cert-manager writes kubernetes/tls secret, but Istio will expect the secret ```cacerts``` in a specific format, but we can map those paths in the overlays.
```yaml
patches:
- path: spec.template.spec.volumes[2]
  value:
    name: cacerts
    secret:
      defaultMode: 420
      items:
      - key: tls.crt
        path: cert-chain.pem
      - key: tls.crt
        path: ca-cert.pem
      - key: tls.key
        path: ca-key.pem
      - key: ca.crt
        path: root-cert.pem
      optional: true
      secretName: cacerts
```

## Sample Certificate to build istiod CA

```yaml
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: cacerts
  namespace: istio-system
spec:
  secretName: cacerts
  duration: 1440h
  renewBefore: 360h
  commonName: istiod.istio-system.svc
  isCA: true
  usages:
    - digital signature
    - key encipherment
    - cert sign
  dnsNames:
    - istiod.istio-system.svc
  issuerRef:
    name: selfsigned-ca
    kind: ClusterIssuer
    group: cert-manager.io
```
