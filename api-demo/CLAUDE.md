# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with the TSB Gateway API Demo Suite.

## Project Overview

This is the **TSB Gateway API Demo Suite** - a comprehensive demonstration and testing framework for Tetrate Service Bridge (TSB) Gateway annotations and split gateway configurations. The suite provides multi-environment, multi-backend scenarios with extensive testing capabilities.

## Project Structure

```
api-demo/
├── Taskfile.yml                  # Task automation for demo workflows (47+ tasks)
├── enterprise-gateway-demo.sh    # Enterprise multi-tier architecture with financial service names
├── advanced-demo.sh              # Main demo deployment script
├── run-advanced-tests.sh         # Sequential test runner with auto-discovery
├── run-advanced-tests-parallel.sh # Parallel test runner for faster execution
├── test-advanced-demo-gateways.sh # Comprehensive testing script
├── test-advanced-demo.sh         # Legacy single-backend test script
├── tests/                        # Test framework directory
│   ├── test-enterprise-gateway-demo.sh  # Comprehensive test suite
│   ├── TEST_FRAMEWORK_README.md         # Testing documentation
│   └── TESTING_QUICK_REFERENCE.md       # Quick test reference
├── README.md                     # Complete documentation
└── CLAUDE.md                     # This file
```

## Key Technologies

- **Tetrate Service Bridge (TSB)** - Service mesh gateway management
- **Kubernetes** - Container orchestration platform
- **Task (go-task)** - Modern task runner and build tool
- **Bash** - Shell scripting for automation
- **curl** - HTTP client for testing
- **kubectl** - Kubernetes command-line tool
- **Docker Images**: httpbin, httpbingo, nginx, echo server

## Quick Start with Taskfile

The **Taskfile.yml** provides a modern, declarative way to run all demo workflows. Install [Task](https://taskfile.dev/) first if you haven't already.

### Installation
```bash
# macOS
brew install go-task/tap/go-task

# Linux
sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d

# Or download from: https://github.com/go-task/task/releases
```

### Quick Commands
```bash
# Show quick start guide
task

# Show all available tasks
task --list

# Bootstrap: check prerequisites and cluster
task bootstrap:all

# Deploy and test advanced demo
task demo:advanced

# Deploy and test enterprise demo
task demo:enterprise

# Full workflow with failover testing
task demo:full:enterprise:failover

# Inspect resources
task inspect:all

# Generate traffic (uses run-advanced-tests.sh)
task traffic:generate:light    # Sequential: 60 iterations
task traffic:generate:medium   # Sequential: 5 iterations
task traffic:generate:heavy    # Parallel: 3 iterations across all environments
task traffic:stress            # Parallel: 10 iterations stress test

# Cleanup
task cleanup:all
```

### Configuration
Override default values using environment-style variables:
```bash
# Use custom namespace and domain
task demo:advanced NAMESPACE=mycompany DOMAIN=api.company.com

# Deploy enterprise demo with custom settings
task demo:enterprise NAMESPACE=fintech DOMAIN=api.fintech.com CLOUD_PROVIDER=gcp
```

Default configuration:
- **NAMESPACE**: `wealth`
- **DOMAIN**: `api.wealth.com`
- **CLOUD_PROVIDER**: `aws`
- **MAX_ITERATIONS**: `10`
- **SLEEP_INTERVAL**: `5`

View current config: `task config:show`

## Development Commands (Shell Scripts)

### Demo Deployment
```bash
# Deploy advanced demo with split gateways
./advanced-demo.sh -n mycompany -d api.company.com

# Preview configurations without applying
./advanced-demo.sh -n mycompany --skip-apply

# Deploy with cloud-specific annotations
./advanced-demo.sh -n mycompany -c gcp|aws|azure

# Clean up all demo resources
./advanced-demo.sh --cleanup -n mycompany
```

### Testing
```bash
# Auto-discover gateway and run comprehensive tests
./run-advanced-tests.sh -n mycompany -d api.company.com

# Run tests continuously
./run-advanced-tests.sh -n mycompany --continuous --max 50

# Direct testing with specific gateway IP
./test-advanced-demo-gateways.sh -i 10.0.0.1 -d api.company.com -n mycompany

# Legacy single-backend testing
./test-advanced-demo.sh -i 10.0.0.1 -d api.company.com
```

## Code Architecture

### Core Components

1. **Split Gateway Configuration**
   - Each environment has dedicated gateway: `app={namespace}-{env}-gateway`
   - Gateway namespace: `tetrate-system`
   - Annotations: `gateway.tetrate.io/workload-selector` and `gateway.tetrate.io/gateway-namespace`

2. **Multi-Environment Setup**
   - **Environments**: prod, staging, dev, test
   - **Backends**: httpbin, httpbingo, nginx, echo
   - **Services**: 50+ gateway configurations per deployment

3. **Demo Scenarios**
   - Basic HTTP/HTTPS services
   - API gateway routing with versioning
   - Authentication (JWT/OIDC)
   - WAF protection
   - Cross-environment communication
   - Load balancing strategies
   - Multi-protocol services

### Script Functions

#### `advanced-demo.sh` Key Functions
- `get_gateway_annotations_for_namespace()` - Generates split gateway annotations
- `get_backend_for_namespace()` - Maps namespaces to backend types
- `demo_*()` functions - Individual demo scenario deployments
- `setup_environment()` - Creates namespaces and deploys backends
- `create_tls_secrets()` - Generates TLS certificates for HTTPS

#### Testing Scripts Key Functions
- `run_test_suite()` - Main test execution loop
- `run_http_test()` / `run_https_test()` - HTTP/HTTPS test helpers
- `discover_split_gateways()` - Auto-discovery of multiple split gateway services
- `validate_split_gateways()` - Multi-gateway accessibility validation
- `add_gateway_mapping()` / `get_gateway_ip()` - Bash 3.2 compatible gateway mapping

## Configuration Patterns

### Gateway Annotations Template
```yaml
annotations:
  gateway.tetrate.io/host: "{subdomain}.{domain}"
  gateway.tetrate.io/workload-selector: "app={namespace}-{env}-gateway"
  gateway.tetrate.io/gateway-namespace: "tetrate-system"
  gateway.tetrate.io/auto-deploy: "true"  # Required: auto-deployment is disabled by default
  gateway.tetrate.io/protocol: "HTTP|HTTPS"
  gateway.tetrate.io/port: "{port}"
  # Additional scenario-specific annotations...
```

**Important**: As of the latest TSB Gateway changes, auto-deployment is **disabled by default**. You must explicitly set `gateway.tetrate.io/auto-deploy: "true"` when using `workload-selector` to enable automatic creation of gateway.install resources. Without this annotation, the gateway will only check if a gateway.install resource exists but won't create one.

### Backend Mapping

#### Advanced Demo (advanced-demo.sh)
- **httpbin** → dynabank-prod (port 80)
- **httpbingo** → dynabank-staging (port 8080)
- **nginx** → dynabank-dev (port 80)
- **echo** → dynabank-test (port 8080)

#### Enterprise Gateway Demo (enterprise-gateway-demo.sh) - **UPDATED**
Financial service-themed backend names that align with business service layers:
- **market-data-feed** → wealth-prod (port 80) - Provides market quotes and pricing data
- **order-execution-service** → wealth-staging (port 8080) - Handles trade order execution
- **compliance-records** → wealth-dev (port 80) - Stores compliance audit logs
- **settlement-ledger** → wealth-test (port 8080) - Manages settlement transaction records

### Environment Variables
- `BASE_NAMESPACE` - Namespace prefix (default: demo)
- `DOMAIN` - Base domain (default: demo.example.com)
- `CLOUD_PROVIDER` - Cloud annotations (aws|gcp|azure)
- `SKIP_APPLY` - Preview mode flag
- `BROKEN_SERVICES` - **NEW** Inject high error rates for traffic failover testing (enterprise-gateway-demo.sh only)

## Enterprise Gateway Demo (enterprise-gateway-demo.sh)

### Overview
The enterprise-gateway-demo.sh script creates a **multi-tier architecture** with financial service-themed names:
- **Business Service Layer**: market-data-gateway, trading-engine-proxy, compliance-validator, settlement-processor
- **Core Backend Layer**: market-data-feed, order-execution-service, compliance-records, settlement-ledger

### Traffic Flow
```
Client → Gateway → Business Service (Giraffe) → Core Backend
                   ↓                           ↓
              Processing Layer              Backend Service
             (Financial Logic)          (market-data-feed, etc.)
```

### Broken Services Feature
The `--broken-services` flag enables **traffic failover testing** by injecting high error rates:

```bash
./enterprise-gateway-demo.sh -n wealth -d api.wealth.com --broken-services
```

#### Broken Service Configuration
When enabled, the following services emit high error rates (HTTP 503):
- **market-data-gateway** in **prod**: 50% error rate
- **trading-engine-proxy** in **staging**: 70% error rate
- **compliance-validator** in **dev**: 100% error rate (always fails)
- **settlement-processor** in **test**: 100% error rate (always fails)

This configuration allows testing of:
- Circuit breaker patterns
- Traffic failover scenarios
- Service mesh resilience
- Retry policies
- Fallback strategies

#### Key Functions (enterprise-gateway-demo.sh)
- `deploy_business_service()` - Deploys Giraffe microservices with configurable ERROR_RATE
- `deploy_backend()` - Deploys financial-named backend services
- `get_upstream_services_for_business_service()` - Configures multi-tier service chains
- `get_business_service_for_namespace()` - Maps namespaces to business services (array rotation)
- `get_backend_for_namespace()` - Maps namespaces to financial backend names

## Testing Architecture

### Test Categories
1. **Basic Functionality** - HTTP methods, status codes, headers
2. **Authentication** - JWT token validation, OIDC flows, API keys
3. **Content Handling** - JSON/XML/YAML payloads, file uploads
4. **Protocol Features** - Compression, caching, redirects, CORS
5. **Performance** - Concurrent requests, payload sizes, timeouts
6. **Security** - WAF testing, XSS/SQLi detection (safe)
7. **Backend-Specific** - HTTPBin/HTTPBingo endpoint testing

### Test Execution Flow
1. **Discovery Phase** - Find gateway IP and validate accessibility
2. **Resource Check** - Verify demo namespaces and deployments exist
3. **Test Suite** - Execute 100+ test cases across all environments
4. **Results** - Structured output with success/failure tracking

## Development Guidelines

### When Adding New Features
1. **New Backend Types**:
   - Update `BACKEND_NAMES` and `BACKEND_IMAGES` arrays
   - Add deployment logic in `deploy_backend()` function
   - Update helper functions for port mapping and selectors

2. **New Demo Scenarios**:
   - Create new `demo_*()` function following existing patterns
   - Use `get_gateway_annotations_for_namespace()` for split gateway config
   - Call from main demo execution flow

3. **New Test Cases**:
   - Add to appropriate test category in test scripts
   - Use `run_http_test()` and `run_https_test()` helpers
   - Follow timeout patterns: `--connect-timeout 0.5 --max-time 2`

### Code Style
- Use bash best practices with proper error handling
- Include descriptive logging with color-coded output
- Follow existing patterns for configuration generation
- Maintain backward compatibility with existing flags

### Testing Requirements
- All new features must include corresponding test cases
- Tests should cover both success and failure scenarios
- Use realistic payloads and authentication patterns
- Include timeout handling for network operations

## Security Considerations

### Authentication Integration
- **JWT Tokens**: Fetched from real Keycloak instance
- **OIDC Flows**: Use demo credentials for testing only
- **API Keys**: Use test values, never production keys
- **TLS Secrets**: Generated self-signed certificates for demo

### Safe Security Testing
- **WAF Testing**: Uses safe, known test patterns
- **XSS/SQLi Tests**: Non-destructive detection testing only
- **Rate Limiting**: Respects reasonable request limits
- **CORS Testing**: Uses valid origin patterns

## Troubleshooting Guide

### Common Issues
1. **Gateway Discovery Fails**
   - Check gateway service names and namespaces
   - Verify TSB installation and gateway deployment
   - Use manual IP with `-i` flag as fallback

2. **Image Pull Errors**
   - Ensure cluster has internet access
   - Check if private registries require authentication
   - Verify image tags are available

3. **Authentication Failures**
   - Confirm Keycloak endpoint accessibility
   - Check JWT token format and validation
   - Verify OIDC client configuration

4. **Test Timeouts**
   - Adjust timeout values in test scripts
   - Check gateway and backend responsiveness
   - Verify DNS resolution for test domains

### Debug Commands
```bash
# Check demo deployment status
kubectl get pods,services -n {namespace}-{env}
kubectl describe service {service-name} -n {namespace}-{env}

# Check gateway configuration
kubectl get gateways,virtualservices -A
kubectl describe gateway {gateway-name} -n tetrate-system

# Check TLS secrets
kubectl get secrets -n tetrate-system | grep tls
kubectl describe secret {secret-name} -n tetrate-system
```

## Taskfile Task Reference

The `Taskfile.yml` provides 47+ tasks organized into categories:

### Bootstrap Tasks
- `bootstrap:check` - Check prerequisites (kubectl, curl, jq, openssl)
- `bootstrap:cluster` - Verify Kubernetes cluster connectivity
- `bootstrap:tsb` - Verify TSB Gateway installation
- `bootstrap:all` - Run all bootstrap checks

### Advanced Demo Workflow
- `demo:advanced:preview` - Preview configurations without applying
- `demo:advanced:deploy` - Deploy advanced demo (4 environments, 4 backends, 50+ configs)
- `demo:advanced:verify` - Verify deployment
- `demo:advanced:test` - Run comprehensive tests
- `demo:advanced:test:parallel` - Run tests in parallel
- `demo:advanced:test:continuous` - Run continuous testing
- `demo:advanced` - Complete workflow: deploy → verify → test

### Enterprise Demo Workflow
- `demo:enterprise:preview` - Preview enterprise configurations
- `demo:enterprise:deploy` - Deploy enterprise multi-tier demo
- `demo:enterprise:deploy:broken` - Deploy with broken services for failover testing
- `demo:enterprise:verify` - Verify enterprise deployment
- `demo:enterprise:test` - Run comprehensive tests
- `demo:enterprise:test:continuous` - Run continuous testing
- `demo:enterprise` - Complete workflow: deploy → verify → test

### Traffic Generation
- `traffic:generate:light` - Light traffic using sequential test runner (60 iterations)
- `traffic:generate:medium` - Medium load using sequential test runner (5 iterations)
- `traffic:generate:heavy` - Heavy load using parallel test runner (3 iterations)
- `traffic:stress` - Parallel stress test across all environments (10 iterations)

### Monitoring and Inspection
- `inspect:namespaces` - List all demo namespaces
- `inspect:pods` - Show all pods across environments
- `inspect:services` - Show all services across environments
- `inspect:gateways` - Show gateway configurations
- `inspect:tls` - Show TLS secrets
- `inspect:logs` - Tail logs from specific pod (requires POD_NAME and ENV)
- `inspect:all` - Complete inspection of demo environment

### Debugging
- `debug:describe:pod` - Describe specific pod (requires POD_NAME and ENV)
- `debug:describe:service` - Describe specific service (requires SERVICE_NAME and ENV)
- `debug:events` - Show recent events in namespace (requires ENV)
- `debug:port-forward` - Port forward to service (requires SERVICE_NAME, ENV, and PORT)

### Cleanup
- `cleanup:advanced` - Clean up advanced demo resources
- `cleanup:enterprise` - Clean up enterprise demo resources
- `cleanup:namespaces` - Force delete demo namespaces (with confirmation)
- `cleanup:tls` - Clean up TLS secrets
- `cleanup:all` - Complete cleanup of all resources

### Complete Workflows
- `demo:full:advanced` - Full advanced workflow: bootstrap → deploy → test → report
- `demo:full:enterprise` - Full enterprise workflow: bootstrap → deploy → test → report
- `demo:full:enterprise:failover` - Enterprise demo with broken services for failover testing
- `demo:quick` - Quick demo with minimal testing

### Utility Tasks
- `help` - Show all available tasks with descriptions
- `version` - Show versions of key components
- `config:show` - Show current configuration variables
- `default` - Show quick start guide

### Example Workflows

#### Complete Demo Lifecycle
```bash
# 1. Bootstrap and verify prerequisites
task bootstrap:all

# 2. Deploy enterprise demo with failover testing
task demo:enterprise:deploy:broken

# 3. Verify deployment
task demo:enterprise:verify

# 4. Run comprehensive tests
task demo:enterprise:test

# 5. Generate background traffic (runs 60 test iterations)
task traffic:generate:light

# 6. Inspect resources
task inspect:all

# 7. Debug specific service
task debug:describe:service SERVICE_NAME=market-data-gateway ENV=prod

# 8. Cleanup when done
task cleanup:enterprise
```

#### Quick Testing Workflow
```bash
# Deploy, verify, and test in one command
task demo:advanced

# Or use the full workflow
task demo:full:advanced
```

#### Custom Configuration
```bash
# Deploy with custom namespace and domain
task demo:enterprise \
  NAMESPACE=fintech \
  DOMAIN=api.fintech.com \
  CLOUD_PROVIDER=gcp

# Run continuous tests with custom iterations
task demo:advanced:test:continuous \
  NAMESPACE=mycompany \
  MAX_ITERATIONS=50
```

#### Debugging and Inspection
```bash
# View all resources
task inspect:all

# View logs from specific pod
task inspect:logs POD_NAME=market-data-gateway-xxx ENV=prod

# Port forward to service
task debug:port-forward \
  SERVICE_NAME=market-data-gateway \
  ENV=prod \
  PORT=8080:80

# Check recent events
task debug:events ENV=staging
```

## Important Notes

- **Demo Purpose**: This is for demonstration and testing only
- **Resource Cleanup**: Always run cleanup after testing
- **Namespace Isolation**: Each environment uses separate namespaces
- **Split Gateway**: Each environment has dedicated gateway workload
- **Extensibility**: Designed to be easily extended with new scenarios
- **Taskfile Advantage**: Use `task` for standardized workflows and easier demo execution

## Support and Documentation

- Full documentation available in `README.md`
- Script help available with `--help` flag on all scripts
- Error messages include troubleshooting hints
- Structured logging helps identify issues during execution