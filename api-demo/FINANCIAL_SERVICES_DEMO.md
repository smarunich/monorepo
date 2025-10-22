# Financial Services Multi-Tier Architecture Demo

A demonstration of enterprise-grade microservices architecture with business service layers and core backends, designed to showcase service mesh capabilities in financial services scenarios.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Client Traffic                              │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Service Mesh Gateway                            │
│                    (Istio/TSB Ingress Gateway)                       │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    BUSINESS SERVICE LAYER                            │
│                      (Giraffe Services)                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────────┐      ┌──────────────────────┐            │
│  │ Trading Engine Proxy │      │ Compliance Validator │            │
│  ├──────────────────────┤      ├──────────────────────┤            │
│  │ • Smart routing      │      │ • MIFID-II/GDPR      │            │
│  │ • Order processing   │      │ • Strict validation  │            │
│  │ • Execution venue    │      │ • Audit trail        │            │
│  │ • 100ms latency      │      │ • 200ms latency      │            │
│  │ • 2% error rate      │      │ • 0.5% error rate    │            │
│  └──────────┬───────────┘      └──────────┬───────────┘            │
│             │                               │                        │
└─────────────┼───────────────────────────────┼────────────────────────┘
              │                               │
              ▼                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      CORE BACKEND LAYER                              │
│                   (Financial Service Backends)                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌────────────────────────┐    ┌───────────────────────┐           │
│  │ Order Execution Service│    │  Compliance Records   │           │
│  ├────────────────────────┤    ├───────────────────────┤           │
│  │ • go-httpbin:v2.15.0   │    │  • nginx:alpine       │           │
│  │ • Port 8080            │    │  • Port 80            │           │
│  │ • Trade execution      │    │  • Audit storage      │           │
│  │ • Order management     │    │  • Compliance logs    │           │
│  └────────────────────────┘    └───────────────────────┘           │
│                                                                       │
│  ┌────────────────────────┐    ┌───────────────────────┐           │
│  │  Market Data Feed      │    │  Settlement Ledger    │           │
│  ├────────────────────────┤    ├───────────────────────┤           │
│  │ • httpbin:latest       │    │  • echoserver:1.10    │           │
│  │ • Port 80              │    │  • Port 8080          │           │
│  │ • Real-time quotes     │    │  • T+2 settlement     │           │
│  │ • Market data          │    │  • Transaction ledger │           │
│  └────────────────────────┘    └───────────────────────┘           │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

## Traffic Flow

```
Client Request
    ↓
Gateway (Istio/TSB)
    ↓
Business Service Layer (Giraffe microservices)
    ├─ Add business logic
    ├─ Add processing delay
    ├─ Add custom headers/metadata
    ├─ Simulate error rates
    └─ Call upstream services
         ↓
Core Backend Layer (Financial services)
    ├─ Market Data Feed
    ├─ Order Execution Service
    ├─ Compliance Records
    └─ Settlement Ledger
         ↓
Response with aggregated data
```

## Components

### Business Service Layer (Giraffe)

#### 1. Trading Engine Proxy
- **Purpose**: Smart order routing and execution management
- **Image**: `us-east1-docker.pkg.dev/dogfood-cx/registryrepository/giraffe:v1.0.1`
- **Port**: 9080
- **Characteristics**:
  - 100ms processing delay
  - 2% error rate (503 errors)
  - Routes to: order-execution-service, market-data-feed, settlement-ledger
- **Metadata**:
  - Engine version: v2.1.5
  - Order routing: smart-order-router
  - Execution venue: primary-exchange

#### 2. Compliance Validator
- **Purpose**: Regulatory compliance validation (MIFID-II, GDPR)
- **Image**: `us-east1-docker.pkg.dev/dogfood-cx/registryrepository/giraffe:v1.0.1`
- **Port**: 9080
- **Characteristics**:
  - 200ms processing delay
  - 0.5% error rate (503 errors)
  - Routes to: compliance-records, market-data-feed, order-execution-service
- **Metadata**:
  - Regulation set: MIFID-II, GDPR
  - Validation level: strict
  - Audit trail: enabled

### Core Backend Layer

#### 3. Order Execution Service
- **Purpose**: Trade order execution and management
- **Image**: `docker.io/mccutchen/go-httpbin:v2.15.0`
- **Port**: 8080
- **Type**: Core backend (httpbin-based service)

#### 4. Compliance Records
- **Purpose**: Compliance audit log storage
- **Image**: `nginx:alpine`
- **Port**: 80
- **Type**: Core backend (nginx with custom config)
- **Endpoints**:
  - `/` - Returns service metadata as JSON
  - `/health` - Health check endpoint

#### 5. Market Data Feed (Referenced)
- **Purpose**: Real-time market data and quotes
- **Image**: `docker.io/kennethreitz/httpbin:latest`
- **Port**: 80

#### 6. Settlement Ledger (Referenced)
- **Purpose**: T+2 settlement transaction ledger
- **Image**: `k8s.gcr.io/echoserver:1.10`
- **Port**: 8080

## Quick Start

### Prerequisites
- Kubernetes cluster (1.24+)
- kubectl configured
- Namespace created (e.g., `demo-prod`)
- Optional: Istio or Tetrate Service Bridge for service mesh features

### Deploy All Components

```bash
# Create namespace
kubectl create namespace demo-prod

# Label for service mesh injection (if using Istio/TSB)
kubectl label namespace demo-prod istio-injection=enabled

# Deploy core backends
kubectl apply -f order-execution-service-deployment.yaml -n demo-prod
kubectl apply -f compliance-records-deployment.yaml -n demo-prod

# Deploy business services
kubectl apply -f trading-engine-proxy-deployment.yaml -n demo-prod
kubectl apply -f compliance-validator-deployment.yaml -n demo-prod

# Verify deployment
kubectl get pods,services -n demo-prod
```

### Deploy Individual Components

```bash
# Deploy only trading engine proxy and its backend
kubectl apply -f order-execution-service-deployment.yaml -n demo-prod
kubectl apply -f trading-engine-proxy-deployment.yaml -n demo-prod

# Deploy only compliance validator and its backend
kubectl apply -f compliance-records-deployment.yaml -n demo-prod
kubectl apply -f compliance-validator-deployment.yaml -n demo-prod
```

## Testing the Deployment

### 1. Port Forward to Business Services

```bash
# Trading Engine Proxy
kubectl port-forward -n demo-prod svc/trading-engine-proxy 9080:9080

# Compliance Validator
kubectl port-forward -n demo-prod svc/compliance-validator 9081:9080
```

### 2. Test Trading Engine Proxy

```bash
# Basic request
curl http://localhost:9080/

# Response includes:
# - Business tier metadata
# - Upstream service responses (order-execution-service, market-data-feed, settlement-ledger)
# - Processing time and error simulation
```

### 3. Test Compliance Validator

```bash
# Basic request
curl http://localhost:9081/

# Response includes:
# - Compliance validation metadata
# - Regulation set (MIFID-II, GDPR)
# - Audit trail information
# - Upstream service responses
```

### 4. Test Core Backends Directly

```bash
# Order Execution Service
kubectl port-forward -n demo-prod svc/order-execution-service 8080:8080
curl http://localhost:8080/get

# Compliance Records
kubectl port-forward -n demo-prod svc/compliance-records 8081:80
curl http://localhost:8081/
curl http://localhost:8081/health
```

## Observability

### Check Pod Status
```bash
kubectl get pods -n demo-prod -l tier=business-service
kubectl get pods -n demo-prod -l tier=core-backend
```

### View Logs
```bash
# Trading Engine Proxy logs
kubectl logs -n demo-prod -l app=trading-engine-proxy -f

# Compliance Validator logs
kubectl logs -n demo-prod -l app=compliance-validator -f

# Order Execution Service logs
kubectl logs -n demo-prod -l app=order-execution-service -f

# Compliance Records logs
kubectl logs -n demo-prod -l app=compliance-records -f
```

### Describe Services
```bash
kubectl describe service trading-engine-proxy -n demo-prod
kubectl describe service compliance-validator -n demo-prod
kubectl describe service order-execution-service -n demo-prod
kubectl describe service compliance-records -n demo-prod
```

## Service Mesh Integration

### Gateway Configuration Example

```yaml
apiVersion: v1
kind: Service
metadata:
  name: trading-gateway
  namespace: demo-prod
  annotations:
    gateway.tetrate.io/host: "trading.api.company.com"
    gateway.tetrate.io/protocol: "HTTPS"
    gateway.tetrate.io/port: "443"
    gateway.tetrate.io/tls-secret: "trading-tls"
    gateway.tetrate.io/service-tier: "business-layer"
spec:
  selector:
    business-service: trading-engine-proxy
  ports:
  - port: 9080
    targetPort: 9080
    name: http
```

### Virtual Service Example

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: trading-routes
  namespace: demo-prod
spec:
  hosts:
  - "trading.api.company.com"
  gateways:
  - demo-gateway
  http:
  - match:
    - uri:
        prefix: /orders
    route:
    - destination:
        host: trading-engine-proxy
        port:
          number: 9080
  - match:
    - uri:
        prefix: /compliance
    route:
    - destination:
        host: compliance-validator
        port:
          number: 9080
```

## Error Simulation and Resilience Testing

The business service layer includes built-in error simulation:

### Trading Engine Proxy
- **Error Rate**: 2% (1 in 50 requests fail)
- **Error Code**: 503 Service Unavailable
- **Use Case**: Test circuit breakers and retry policies

### Compliance Validator
- **Error Rate**: 0.5% (1 in 200 requests fail)
- **Error Code**: 503 Service Unavailable
- **Use Case**: Test resilience in critical compliance workflows

### Generate Load for Testing

```bash
# Generate 100 requests to see error distribution
for i in {1..100}; do
  curl -s -o /dev/null -w "%{http_code}\n" http://localhost:9080/
done | sort | uniq -c

# Expected output:
#  98 200  (successful requests)
#   2 503  (simulated errors)
```

## Latency Testing

Business services add realistic processing delays:

```bash
# Measure latency
time curl http://localhost:9080/

# Trading Engine Proxy: ~100ms base latency
# Compliance Validator: ~200ms base latency
```

## Key Features Demonstrated

1. **Multi-Tier Architecture**
   - Clear separation between business logic and core backends
   - Service orchestration and aggregation

2. **Financial Services Patterns**
   - Order routing and execution
   - Compliance validation
   - Regulatory metadata (MIFID-II, GDPR)
   - Audit trail logging

3. **Service Mesh Capabilities**
   - Service-to-service communication
   - Distributed tracing
   - Error injection and resilience
   - Traffic management

4. **Observability**
   - Structured logging
   - Custom response metadata
   - Health check endpoints
   - Request tracing headers

## Cleanup

```bash
# Delete all components
kubectl delete -f trading-engine-proxy-deployment.yaml -n demo-prod
kubectl delete -f compliance-validator-deployment.yaml -n demo-prod
kubectl delete -f order-execution-service-deployment.yaml -n demo-prod
kubectl delete -f compliance-records-deployment.yaml -n demo-prod

# Delete namespace
kubectl delete namespace demo-prod
```

## Customization

### Adjust Error Rates

Edit the deployment YAML and modify the `ERROR_RATE` environment variable:

```yaml
- name: ERROR_RATE
  value: "0.05"  # 5% error rate
```

### Adjust Processing Delays

Edit the deployment YAML and modify the `RESPONSE_DELAY_MS` environment variable:

```yaml
- name: RESPONSE_DELAY_MS
  value: "500"  # 500ms delay
```

### Change Upstream Services

Edit the `UPSTREAM_URLS` environment variable to point to different services:

```yaml
- name: UPSTREAM_URLS
  value: "http://service-a:8080,http://service-b:9090"
```

## Advanced Scenarios

### Multi-Environment Deployment

Deploy to multiple environments with different error rates:

```bash
# Production (low error rate)
kubectl apply -f trading-engine-proxy-deployment.yaml -n prod
# Edit ERROR_RATE to 0.001 before applying

# Staging (medium error rate)
kubectl apply -f trading-engine-proxy-deployment.yaml -n staging
# Edit ERROR_RATE to 0.05 before applying

# Development (high error rate for testing)
kubectl apply -f trading-engine-proxy-deployment.yaml -n dev
# Edit ERROR_RATE to 0.20 before applying
```

### Cross-Namespace Communication

```bash
# Deploy backends in one namespace
kubectl apply -f order-execution-service-deployment.yaml -n backends

# Deploy business services in another, referencing backends
# Edit UPSTREAM_URLS to use FQDN:
# http://order-execution-service.backends.svc.cluster.local:8080
kubectl apply -f trading-engine-proxy-deployment.yaml -n business-services
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n demo-prod

# Describe pod for events
kubectl describe pod <pod-name> -n demo-prod

# Check logs
kubectl logs <pod-name> -n demo-prod
```

### Service Not Accessible

```bash
# Check service endpoints
kubectl get endpoints -n demo-prod

# Verify service selector matches pod labels
kubectl get pods -n demo-prod --show-labels
```

### Image Pull Errors

```bash
# For Giraffe image, ensure cluster has access to:
# us-east1-docker.pkg.dev/dogfood-cx/registryrepository/giraffe:v1.0.1

# May require authentication:
# kubectl create secret docker-registry giraffe-registry \
#   --docker-server=us-east1-docker.pkg.dev \
#   --docker-username=_json_key \
#   --docker-password="$(cat key.json)" \
#   -n demo-prod

# Then add imagePullSecrets to deployment
```

## Support and Documentation

- **Full Enterprise Demo**: See `enterprise-gateway-demo.sh` for complete multi-environment setup
- **Testing Framework**: See `tests/` directory for comprehensive test suites
- **Task Automation**: See `Taskfile.yml` for automated workflows
- **Main Documentation**: See `README.md` for complete project documentation

## License

This is a demonstration project for Tetrate Service Bridge capabilities.
