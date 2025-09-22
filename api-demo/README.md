# TSB Gateway API Demo Suite

A comprehensive demonstration suite for Tetrate Service Bridge (TSB) Gateway annotations and split gateway configurations, featuring multi-environment, multi-backend scenarios with extensive testing capabilities.

## 📁 Contents

- **`advanced-demo.sh`** - Main demo deployment script with split gateway configurations
- **`enterprise-gateway-demo.sh`** - **NEW** Enterprise multi-tier architecture demo with Giraffe business services
- **`test-advanced-demo-gateways.sh`** - Comprehensive testing script for all demo configurations
- **`run-advanced-tests.sh`** - Helper script for auto-discovery and test execution
- **`run-advanced-tests-parallel.sh`** - Parallel testing version for faster execution
- **`test-advanced-demo.sh`** - Legacy single-backend test script with 100+ test cases

## 🚀 Quick Start

### Prerequisites
- Kubernetes cluster with TSB Gateway installed
- `kubectl` configured and connected to your cluster
- `curl`, `jq`, and `openssl` available in your PATH

### Basic Usage

1. **Deploy the advanced demo:**
   ```bash
   ./advanced-demo.sh -n mycompany -d api.company.com
   ```

2. **Deploy the enterprise multi-tier demo:**
   ```bash
   ./enterprise-gateway-demo.sh -n fintech -d api.enterprise.com
   ```

3. **Run comprehensive tests:**
   ```bash
   ./run-advanced-tests.sh -n mycompany -d api.company.com
   # Or run tests in parallel for faster execution:
   ./run-advanced-tests-parallel.sh -n mycompany -d api.company.com
   ```

4. **Clean up:**
   ```bash
   ./advanced-demo.sh --cleanup -n mycompany
   # Or for enterprise demo:
   ./enterprise-gateway-demo.sh --cleanup -n fintech
   ```

## 📋 Demo Overview

### Advanced Demo (`advanced-demo.sh`)

Creates a comprehensive multi-environment setup with:

- **4 Environments**: `{namespace}-prod`, `{namespace}-staging`, `{namespace}-dev`, `{namespace}-test`
- **4 Backend Types**: httpbin, httpbingo, nginx, echo
- **Split Gateway Architecture**: Each environment has its own gateway (`app={namespace}-{env}-gateway`)
- **50+ Gateway Configurations** across all scenarios

#### Demo Scenarios

1. **Basic HTTP Services** - Simple HTTP exposure across environments
2. **HTTPS Services** - TLS termination with environment-specific certificates
3. **API Gateway Routing** - Multi-version API paths with rate limiting
4. **Authentication Services** - JWT and OIDC authentication flows
5. **WAF Protection** - Environment-specific Web Application Firewall rules
6. **Cross-Environment Communication** - CORS-enabled inter-environment services
7. **Load Balancing** - Different load balancing strategies per environment
8. **Multi-Protocol Services** - HTTP/HTTPS with redirects

### Enterprise Gateway Demo (`enterprise-gateway-demo.sh`) 🆕

**NEW**: Advanced enterprise multi-tier architecture demo featuring business service layers using Giraffe microservices as intermediate processing hops before reaching core backends.

#### Architecture Overview
```
Gateway → Business Service (Giraffe) → Core Backend
         ↓                          ↓
    Processing Layer            Original Service
   (Financial Services)        (httpbin/nginx/etc)
```

#### Key Features:
- **4 Business Service Layers**: Market Data Gateway, Trading Engine Proxy, Compliance Validator, Settlement Processor
- **Professional Financial Terminology**: Enterprise-grade service naming and business logic
- **Multi-Tier Request Flow**: Every request passes through business service before reaching backend
- **Enhanced Observability**: Complete distributed tracing through business service hops
- **Configurable Processing**: Business services add delays, error simulation, and custom metadata
- **60+ Gateway Configurations**: Extended scenarios with business service intelligence

#### Business Services:

| Service | Function | Features |
|---------|----------|----------|
| **Market Data Gateway** | Financial data routing | Sub-100ms SLA, Bloomberg API integration simulation |
| **Trading Engine Proxy** | Order routing and execution | Smart order routing, execution venue selection |
| **Compliance Validator** | Regulatory compliance | MIFID-II/GDPR validation, audit trail generation |
| **Settlement Processor** | Transaction settlement | T+2 settlement cycle, DTCC clearing house simulation |

#### Request Flow Examples:
1. **Direct Path**: `client → market-data-gateway → httpbin`
2. **API Path**: `client → api-prod.domain.com/v1/market-data-gateway → httpbin`
3. **Secure Path**: `client → auth-prod.domain.com → compliance-validator → nginx`

#### Enterprise Benefits:
- **Real-world simulation** of financial services architecture
- **Business logic processing** before backend calls
- **Professional service naming** for enterprise demos
- **Complete trace visibility** through business service hops
- **Configurable error rates** and processing delays per service tier

### Testing Suite

#### Comprehensive Tests (`test-advanced-demo-gateways.sh`)
- **100+ Test Cases** covering all demo configurations
- **Backend-Specific Testing** for httpbin, httpbingo, nginx, and echo
- **Environment Validation** across prod, staging, dev, and test
- **Authentication Testing** with real JWT token integration
- **Performance and Error Condition Testing**

#### Auto-Discovery Helper (`run-advanced-tests.sh`)
- **Automatic Split Gateway Discovery** for all environment-specific gateways
- **Multi-Gateway Accessibility Validation** with port testing per environment
- **Resource Verification** before running tests
- **Continuous Testing Mode** with configurable iterations
- **Bash 3.2 Compatible** for older systems

## 🔧 Configuration Options

### Advanced Demo Script

```bash
./advanced-demo.sh [options]

Options:
  -n, --namespace <name>     Base namespace prefix (default: demo)
  -d, --domain <domain>      Base domain for demos (default: demo.example.com)
  -c, --cloud <provider>     Cloud provider annotations (aws|gcp|azure)
  --cleanup                  Only perform cleanup
  --skip-apply              Show configurations without applying
  -h, --help                Show help message
```

### Test Runner Script

```bash
./run-advanced-tests.sh [options]

Options:
  -n, --namespace <prefix>   Base namespace prefix (default: demo)
  -d, --domain <domain>      Base domain (default: demo.example.com)
  -c, --continuous           Run tests continuously
  -m, --max <iterations>     Maximum iterations for continuous mode
  -h, --help                Show help message
```

### Comprehensive Test Script

```bash
./test-advanced-demo-gateways.sh [options]

Options:
  -i, --ip <address>         Gateway IP address
  -d, --domain <domain>      Base domain
  -n, --namespace <prefix>   Base namespace prefix
  -c, --continuous           Run continuously
  -s, --sleep <seconds>      Sleep interval between runs
  -m, --max <iterations>     Maximum iterations
```

## 🏗️ Split Gateway Architecture

Each service includes split gateway annotations for dedicated traffic management:

```yaml
annotations:
  gateway.tetrate.io/workload-selector: "app={namespace}-{env}-gateway"
  gateway.tetrate.io/gateway-namespace: "tetrate-system"
```

### Environment Gateway Mapping
- **Production**: `app=mycompany-prod-gateway`
- **Staging**: `app=mycompany-staging-gateway`
- **Development**: `app=mycompany-dev-gateway`
- **Test**: `app=mycompany-test-gateway`

## 📊 What Gets Created

### Namespaces and Backends
- **dynabank-prod**: httpbin backend
- **dynabank-staging**: httpbingo backend
- **dynabank-dev**: nginx backend
- **dynabank-test**: echo backend

### Service Types Per Environment
- Basic HTTP service (port 8001-8004)
- HTTPS service with TLS (port 443)
- API v1/v2/v3 services with path routing
- JWT authentication service (prod/staging)
- OIDC authentication service (dev/test)
- WAF protection service
- Cross-environment communication service
- Load balancing service
- Multi-protocol HTTP/HTTPS services

## 🧪 Testing Features

### Backend-Specific Tests
- **HTTPBin**: Standard HTTP testing service endpoints
- **HTTPBingo**: Go-based HTTP testing with additional features
- **Nginx**: Web server with custom configuration
- **Echo**: Simple echo server for request inspection

### Test Categories
- ✅ HTTP Methods (GET, POST, PUT, DELETE, PATCH)
- ✅ Status Codes (1xx, 2xx, 3xx, 4xx, 5xx)
- ✅ Authentication (JWT, OIDC, API Keys)
- ✅ Content Types (JSON, XML, YAML, form data)
- ✅ File Uploads and Downloads
- ✅ Compression (gzip, deflate, brotli)
- ✅ Caching and ETags
- ✅ CORS and Cross-Origin Requests
- ✅ Rate Limiting and WAF Testing
- ✅ Performance and Stress Testing
- ✅ Error Conditions and Edge Cases

## 🔐 Authentication Integration

### JWT Authentication
- **Real Token Fetching** from Keycloak provider
- **Multiple Issuers** support (Google, Keycloak)
- **Token Validation** across different endpoints
- **Authorization Header** format testing

### OIDC Authentication
- **Authorization Code Flow** configuration
- **Redirect URI** handling
- **Provider Configuration** for Keycloak
- **Client Secret** management

## 📈 Monitoring and Observability

### Test Output
- **Structured Logging** with color-coded output
- **Test Result Tracking** with success/failure counts
- **Performance Metrics** with timing information
- **Output Files** for downloaded content and artifacts

### Continuous Testing
- **Configurable Intervals** between test runs
- **Maximum Iteration** limits
- **Progress Tracking** across test cycles
- **Graceful Shutdown** with Ctrl+C handling

## 🛠️ Advanced Usage

### Preview Mode
Preview configurations without applying:
```bash
./advanced-demo.sh -n mycompany -d api.company.com --skip-apply
```

### Continuous Testing
Run tests continuously with custom intervals:
```bash
./run-advanced-tests.sh -n mycompany --continuous --max 50
```

### Environment-Specific Testing
Test specific environments:
```bash
./test-advanced-demo-gateways.sh -i 10.0.0.1 -d api.company.com -n mycompany
```

### Cloud Provider Annotations
Deploy with cloud-specific annotations:
```bash
./advanced-demo.sh -n mycompany -c gcp  # For Google Cloud
./advanced-demo.sh -n mycompany -c azure  # For Azure
```

## 🔍 Troubleshooting

### Common Issues

1. **Gateway Not Found**
   - Ensure TSB Gateway is installed and running
   - Check gateway service names in your cluster
   - Verify the run-advanced-tests.sh script discovers the correct gateway

2. **Image Pull Errors**
   - The demo uses public images (httpbin, nginx, echo)
   - Ensure your cluster has internet access
   - Check if images are accessible from your cluster

3. **Authentication Failures**
   - JWT tokens are fetched from a demo Keycloak instance
   - OIDC configuration uses demo credentials
   - Ensure outbound HTTPS connectivity for token validation

4. **DNS Resolution Issues**
   - The demo uses `demo.example.com` by default
   - Configure DNS or use custom domain with `-d` flag
   - For testing, you can use IP-based access

### Debug Commands

Check deployment status:
```bash
kubectl get pods,services -n {namespace}-prod
kubectl get pods,services -n {namespace}-staging
kubectl get pods,services -n {namespace}-dev
kubectl get pods,services -n {namespace}-test
```

Check gateway services:
```bash
kubectl get services -n istio-system | grep gateway
kubectl get services -n tetrate-system | grep gateway
```

Check TLS secrets:
```bash
kubectl get secrets -n tetrate-system | grep tls
```

## 📝 Examples

### Complete Demo Deployment
```bash
# Deploy with custom namespace and domain
./advanced-demo.sh -n fintech -d api.fintech.com -c aws

# Verify deployment
kubectl get namespaces | grep fintech
kubectl get pods -n fintech-prod
kubectl get services -n fintech-prod

# Run comprehensive tests
./run-advanced-tests.sh -n fintech -d api.fintech.com

# Run continuous testing
./run-advanced-tests.sh -n fintech -d api.fintech.com --continuous --max 10

# Clean up
./advanced-demo.sh --cleanup -n fintech
```

### Testing Specific Scenarios
```bash
# Test with specific gateway IP
./test-advanced-demo-gateways.sh -i 192.168.1.100 -d api.company.com -n mycompany

# Continuous testing with custom sleep interval
./test-advanced-demo-gateways.sh -i 192.168.1.100 -d api.company.com -n mycompany \
  --continuous --sleep 60 --max 100
```

## 🤝 Contributing

This demo suite is designed to be extensible. To add new test scenarios:

1. **Add Backend Types**: Extend `BACKEND_NAMES` and `BACKEND_IMAGES` arrays
2. **Add Test Cases**: Extend the test scripts with new endpoint patterns
3. **Add Environments**: Modify the `NAMESPACES` array for additional environments
4. **Add Authentication**: Extend JWT/OIDC configurations for new providers

## 📄 License

This demo suite is provided as-is for demonstration and testing purposes with Tetrate Service Bridge.

---

**Note**: This demo creates multiple namespaces and services in your cluster. Always run cleanup after testing to remove demo resources.