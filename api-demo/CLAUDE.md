# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with the TSB Gateway API Demo Suite.

## Project Overview

This is the **TSB Gateway API Demo Suite** - a comprehensive demonstration and testing framework for Tetrate Service Bridge (TSB) Gateway annotations and split gateway configurations. The suite provides multi-environment, multi-backend scenarios with extensive testing capabilities.

## Project Structure

```
api-demo/
├── advanced-demo.sh              # Main demo deployment script
├── test-advanced-demo-gateways.sh # Comprehensive testing script
├── run-advanced-tests.sh         # Auto-discovery test runner
├── test-advanced-demo.sh         # Legacy single-backend test script
├── README.md                     # Complete documentation
└── CLAUDE.md                     # This file
```

## Key Technologies

- **Tetrate Service Bridge (TSB)** - Service mesh gateway management
- **Kubernetes** - Container orchestration platform
- **Bash** - Shell scripting for automation
- **curl** - HTTP client for testing
- **kubectl** - Kubernetes command-line tool
- **Docker Images**: httpbin, httpbingo, nginx, echo server

## Development Commands

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
  gateway.tetrate.io/protocol: "HTTP|HTTPS"
  gateway.tetrate.io/port: "{port}"
  # Additional scenario-specific annotations...
```

### Backend Mapping
- **httpbin** → dynabank-prod (port 80)
- **httpbingo** → dynabank-staging (port 8080)
- **nginx** → dynabank-dev (port 80)
- **echo** → dynabank-test (port 8080)

### Environment Variables
- `BASE_NAMESPACE` - Namespace prefix (default: demo)
- `DOMAIN` - Base domain (default: demo.example.com)
- `CLOUD_PROVIDER` - Cloud annotations (aws|gcp|azure)
- `SKIP_APPLY` - Preview mode flag

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

## Important Notes

- **Demo Purpose**: This is for demonstration and testing only
- **Resource Cleanup**: Always run cleanup after testing
- **Namespace Isolation**: Each environment uses separate namespaces
- **Split Gateway**: Each environment has dedicated gateway workload
- **Extensibility**: Designed to be easily extended with new scenarios

## Support and Documentation

- Full documentation available in `README.md`
- Script help available with `--help` flag on all scripts
- Error messages include troubleshooting hints
- Structured logging helps identify issues during execution