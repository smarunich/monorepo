#!/bin/bash

# TSB Gateway Annotations Demo Script
# This script demonstrates various gateway annotation configurations using httpbin
# 
# PROTOCOL SUPPORT: HTTP and HTTPS protocols are supported.
# TCP and TLS protocols are currently disabled.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
NAMESPACE="httpbin"
DOMAIN="demo.example.com"
CLOUD_PROVIDER="aws"
CLEANUP_ONLY=false
SKIP_APPLY=false

# Print usage
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -n, --namespace <name>     Namespace to use (default: httpbin)"
    echo "  -d, --domain <domain>      Base domain for demos (default: demo.example.com)"
    echo "  -c, --cloud <provider>     Cloud provider annotations (aws|gcp|azure) (default: aws)"
    echo "  --cleanup                  Only perform cleanup"
    echo "  --skip-apply              Skip kubectl apply, only show configs"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                         # Run demo with defaults"
    echo "  $0 -n my-demo -d api.company.com -c gcp"
    echo "  $0 --cleanup               # Clean up demo resources"
    echo "  $0 --skip-apply            # Show configurations without applying"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -d|--domain)
            DOMAIN="$2"
            shift 2
            ;;
        -c|--cloud)
            CLOUD_PROVIDER="$2"
            shift 2
            ;;
        --cleanup)
            CLEANUP_ONLY=true
            shift
            ;;
        --skip-apply)
            SKIP_APPLY=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}================================${NC}"
}

# Get cloud provider specific annotations
get_cloud_annotations() {
    case $1 in
        aws)
            cat << EOF
service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: "preserve_client_ip.enabled=true"
EOF
            ;;
        gcp)
            cat << EOF
cloud.google.com/neg: '{"ingress":true}'
cloud.google.com/load-balancer-type: "External"
networking.gke.io/load-balancer-type: "External"
EOF
            ;;
        azure)
            cat << EOF
service.beta.kubernetes.io/azure-load-balancer-internal: "false"
service.beta.kubernetes.io/azure-load-balancer-mode: "auto"
service.beta.kubernetes.io/azure-dns-label-name: "httpbin-demo"
EOF
            ;;
        *)
            log_error "Unknown cloud provider: $1"
            exit 1
            ;;
    esac
}

# Apply configuration or just print it
apply_or_show() {
    local config_name="$1"
    local config_content="$2"
    
    log_info "Configuration: $config_name"
    echo "$config_content"
    echo ""
    
    if [[ "$SKIP_APPLY" == "false" ]]; then
        echo "$config_content" | kubectl apply -f -
        log_success "Applied $config_name"
    else
        log_info "Skipped applying $config_name (--skip-apply mode)"
    fi
    echo ""
}

# Cleanup function
cleanup_resources() {
    log_header "Cleaning Up Demo Resources"
    
    log_info "Removing services with gateway annotations..."
    kubectl delete service httpbin-basic httpbin-https httpbin-redirect httpbin-custom-gateway httpbin-auth httpbin-oidc httpbin-rate-limited httpbin-waf httpbin-waf-custom httpbin-multi-path httpbin-multi-path-2 httpbin-multi-hosts httpbin-alias-domains httpbin-custom-port httpbin-port-mapping -n "$NAMESPACE" --ignore-not-found=true
    
    log_info "Removing TLS secret..."
    kubectl delete secret httpbin-tls -n "$NAMESPACE" --ignore-not-found=true
    
    log_info "Removing namespace $NAMESPACE..."
    kubectl delete namespace "$NAMESPACE" --ignore-not-found=true
    
    log_success "Cleanup completed"
}

# Check prerequisites
check_prerequisites() {
    log_header "Checking Prerequisites"
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check openssl for TLS certificate generation
    if ! command -v openssl &> /dev/null; then
        log_error "openssl is not installed or not in PATH"
        log_info "openssl is required for generating TLS certificates for HTTPS demos"
        exit 1
    fi
    
    # Check cluster connection
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Create TLS secret for HTTPS demos
create_tls_secret() {
    log_info "Creating TLS secret for HTTPS demos"
    
    # Check if secret already exists
    if kubectl get secret httpbin-tls -n tetrate-system &> /dev/null; then
        log_info "TLS secret already exists, skipping creation"
        return
    fi
    
    # Create temporary directory for certificates
    local temp_dir=$(mktemp -d)
    local cert_file="$temp_dir/tls.crt"
    local key_file="$temp_dir/tls.key"
    
    # Generate self-signed certificate for demo purposes
    log_info "Generating self-signed certificate for *.$DOMAIN"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$key_file" \
        -out "$cert_file" \
        -subj "/C=US/ST=Demo/L=Demo/O=Demo/OU=Demo/CN=*.$DOMAIN" \
        -addext "subjectAltName=DNS:*.$DOMAIN,DNS:$DOMAIN,DNS:secure.$DOMAIN,DNS:custom.$DOMAIN,DNS:auth.$DOMAIN" \
        2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        # Create Kubernetes TLS secret
        kubectl create secret tls httpbin-tls \
            --cert="$cert_file" \
            --key="$key_file" \
            -n tetrate-system
        log_success "Created TLS secret httpbin-tls"
    else
        log_error "Failed to generate TLS certificate"
        log_warning "HTTPS demos will fail without TLS secret"
    fi
    
    # Cleanup temporary files
    rm -rf "$temp_dir"
}

# Setup demo environment
setup_environment() {
    log_header "Setting Up Demo Environment"
    
    # Create namespace
    log_info "Creating namespace: $NAMESPACE"
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Label namespace for TSB management (assuming ARCA or similar is used)
    log_info "Labeling namespace for service mesh injection"
    kubectl label namespace "$NAMESPACE" istio-injection=enabled --overwrite
    
    # Deploy httpbin application
    log_info "Deploying httpbin application"
    kubectl apply -n "$NAMESPACE" -f https://raw.githubusercontent.com/istio/istio/master/samples/httpbin/httpbin.yaml
    
    # Wait for deployment to be ready
    log_info "Waiting for httpbin deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/httpbin -n "$NAMESPACE"
    
    # Create TLS secret for HTTPS demos
    create_tls_secret
    
    log_success "Environment setup completed"
}

# Demo 1: Basic HTTP exposure
demo_basic_http() {
    log_header "Demo 1: Basic HTTP Service Exposure"
    
    local config=$(cat << EOF
apiVersion: v1
kind: Service
metadata:
  name: httpbin-basic
  namespace: $NAMESPACE
  annotations:
    gateway.tetrate.io/host: "basic.$DOMAIN"
    # Uses defaults: HTTP protocol, port 80, path /
spec:
  selector:
    app: httpbin
    version: v1
  ports:
  - port: 8000
    targetPort: 8080
    name: http
EOF
)
    
    apply_or_show "Basic HTTP Service" "$config"
}

# Demo 2: HTTPS with TLS and cloud annotations
demo_https_with_tls() {
    log_header "Demo 2: HTTPS Service with TLS and Cloud Annotations"
    
    local cloud_annotations=$(get_cloud_annotations "$CLOUD_PROVIDER")
    
    local config=$(cat << EOF
apiVersion: v1
kind: Service
metadata:
  name: httpbin-https
  namespace: $NAMESPACE
  annotations:
    gateway.tetrate.io/host: "secure.$DOMAIN"
    gateway.tetrate.io/protocol: "HTTPS"
    gateway.tetrate.io/port: "443"
    gateway.tetrate.io/tls-secret: "httpbin-tls"
    gateway.tetrate.io/cloud-annotations: |
$(echo "$cloud_annotations" | sed 's/^/      /')
spec:
  selector:
    app: httpbin
    version: v1
  ports:
  - port: 8000
    targetPort: 8080
    name: http
EOF
)
    
    apply_or_show "HTTPS Service with TLS and Cloud Annotations" "$config"
}

# Demo 3: HTTPS with HTTP to HTTPS redirect
demo_https_redirect() {
    log_header "Demo 3: HTTPS Service with HTTP to HTTPS Redirect"
    
    local config=$(cat << EOF
apiVersion: v1
kind: Service
metadata:
  name: httpbin-redirect
  namespace: $NAMESPACE
  annotations:
    gateway.tetrate.io/host: "redirect.$DOMAIN"
    gateway.tetrate.io/protocol: "HTTPS"
    gateway.tetrate.io/tls-secret: "httpbin-tls"
    gateway.tetrate.io/https-redirect: "true"     # Default: true for HTTPS
    gateway.tetrate.io/http-port: "8080"          # HTTP redirect server port
    gateway.tetrate.io/https-redirect-port: "8443" # HTTPS destination port
    # Creates both HTTP (redirect) and HTTPS servers automatically
spec:
  selector:
    app: httpbin
    version: v1
  ports:
  - port: 8000
    targetPort: 8080
    name: http
EOF
)
    
    apply_or_show "HTTPS Service with HTTP to HTTPS Redirect" "$config"
}

# Demo 4: Custom gateway with auto-deploy
demo_custom_gateway() {
    log_header "Demo 4: Custom Gateway with Auto-Deploy"
    
    local config=$(cat << EOF
apiVersion: v1
kind: Service
metadata:
  name: httpbin-custom-gateway
  namespace: $NAMESPACE
  annotations:
    gateway.tetrate.io/host: "custom.$DOMAIN"
    gateway.tetrate.io/workload-selector: "app=custom-httpbin-gateway"
    gateway.tetrate.io/gateway-namespace: "tetrate-system"
    gateway.tetrate.io/auto-deploy: "true"
    gateway.tetrate.io/protocol: "HTTPS"
    gateway.tetrate.io/tls-secret: "httpbin-tls"
    gateway.tetrate.io/port: "8443"
spec:
  selector:
    app: httpbin
    version: v1
  ports:
  - port: 8000
    targetPort: 8080
    name: http
EOF
)
    
    apply_or_show "Custom Gateway with Auto-Deploy" "$config"
}

# Demo 5: JWT Authentication
demo_jwt_auth() {
    log_header "Demo 5: Service with JWT Authentication"
    
    local config=$(cat << EOF
apiVersion: v1
kind: Service
metadata:
  name: httpbin-auth
  namespace: $NAMESPACE
  annotations:
    gateway.tetrate.io/host: "auth.$DOMAIN"
    gateway.tetrate.io/protocol: "HTTPS"
    gateway.tetrate.io/tls-secret: "httpbin-tls"
    gateway.tetrate.io/path: "/secure"
    gateway.tetrate.io/jwt-issuers: |
      - issuer: "https://accounts.google.com"
        jwksUri: "https://www.googleapis.com/oauth2/v3/certs"
      - issuer: "https://keycloak.alder.dogfood.gcp.sandbox.tetrate.io/realms/tetrate"
        jwksUri: "https://keycloak.alder.dogfood.gcp.sandbox.tetrate.io/realms/tetrate/protocol/openid-connect/certs"
spec:
  selector:
    app: httpbin
    version: v1
  ports:
  - port: 8000
    targetPort: 8080
    name: http
EOF
)
    
    apply_or_show "Service with JWT Authentication" "$config"
}

# Demo 6: OIDC Authentication
demo_oidc_auth() {
    log_header "Demo 6: Service with OIDC Authentication"
    kubectl create secret generic oauth-client-secret \
        --from-literal=istio_generic_secret=oidc-client-secret-tetrate123987 \
        -n tetrate-system \
        --dry-run=client \
        -o yaml | kubectl apply -f -

    local config=$(cat << EOF
apiVersion: v1
kind: Service
metadata:
  name: httpbin-oidc
  namespace: $NAMESPACE
  annotations:
    gateway.tetrate.io/host: "oidc.$DOMAIN"
    gateway.tetrate.io/protocol: "HTTPS"
    gateway.tetrate.io/tls-secret: "httpbin-tls"
    gateway.tetrate.io/path: "/app"
    gateway.tetrate.io/oidc-enabled: "true"
    gateway.tetrate.io/oidc-config: |
      grantType: "AUTHORIZATION_CODE"
      clientId: "client-tetrate-auth"
      clientTokenSecret: "oauth-client-secret"
      redirectUri: "https://oidc.$DOMAIN/callback"
      provider:
        issuer: "https://keycloak.alder.dogfood.gcp.sandbox.tetrate.io/realms/tetrate"
        authorizationEndpoint: "https://keycloak.alder.dogfood.gcp.sandbox.tetrate.io/realms/tetrate/protocol/openid-connect/auth"
        tokenEndpoint: "https://keycloak.alder.dogfood.gcp.sandbox.tetrate.io/realms/tetrate/protocol/openid-connect/token"
        jwksUri: "https://keycloak.alder.dogfood.gcp.sandbox.tetrate.io/realms/tetrate/protocol/openid-connect/certs"
spec:
  selector:
    app: httpbin
    version: v1
  ports:
  - port: 8000
    targetPort: 8080
    name: http
EOF
)
    
    apply_or_show "Service with OIDC Authentication" "$config"
}

# Demo 7: Rate limiting and CORS
demo_rate_limiting() {
    log_header "Demo 7: Service with Rate Limiting and CORS"
    
    local config=$(cat << EOF
apiVersion: v1
kind: Service
metadata:
  name: httpbin-rate-limited
  namespace: $NAMESPACE
  annotations:
    gateway.tetrate.io/host: "api.$DOMAIN"
    gateway.tetrate.io/path: "/rate-limited"
    gateway.tetrate.io/rate-limits: |
      - dimensions:
          - remoteAddress:
              value: "*"
        limit:
          requestsPerUnit: 10
          unit: MINUTE
      - dimensions:
          - header:
              name: "x-api-key"
        limit:
          requestsPerUnit: 100
          unit: HOUR
    gateway.tetrate.io/cors-policy: |
      allowOrigin:
        - "https://*.example.com"
        - "https://demo.company.com"
      allowMethods:
        - "GET"
        - "POST"
        - "PUT"
      allowHeaders:
        - "authorization"
        - "content-type"
        - "x-api-key"
      maxAge: "86400s"
      allowCredentials: true
spec:
  selector:
    app: httpbin
    version: v1
  ports:
  - port: 8000
    targetPort: 8080
    name: http
EOF
)
    
    apply_or_show "Service with Rate Limiting and CORS" "$config"
}

# Demo 8: WAF Protection
demo_waf_protection() {
    log_header "Demo 8: WAF Protection with OWASP ModSecurity Rules"
    
    local config=$(cat << EOF
apiVersion: v1
kind: Service
metadata:
  name: httpbin-waf
  namespace: $NAMESPACE
  annotations:
    gateway.tetrate.io/host: "waf.$DOMAIN"
    gateway.tetrate.io/path: "/protected"
    gateway.tetrate.io/waf-enabled: "true"
    # Automatically configures OWASP ModSecurity rules:
    # - Include @recommended-conf
    # - SecRuleEngine On
    # - SecResponseBodyAccess Off
    # - Include @crs-setup-conf
    # - Include @owasp_crs/*.conf
spec:
  selector:
    app: httpbin
    version: v1
  ports:
  - port: 8000
    targetPort: 8080
    name: http
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin-waf-custom
  namespace: $NAMESPACE
  annotations:
    gateway.tetrate.io/host: "waf-custom.$DOMAIN"
    gateway.tetrate.io/path: "/xss-test"
    gateway.tetrate.io/waf-enabled: "true"
    gateway.tetrate.io/custom-config: |
      waf:
        rules:
          - "SecRuleEngine DetectionOnly"
          - "SecDebugLogLevel 5"
spec:
  selector:
    app: httpbin
    version: v1
  ports:
  - port: 8000
    targetPort: 8080
    name: http
EOF
)
    
    apply_or_show "WAF Protection Services" "$config"
}

# Demo 8: Path-based routing (collision scenario)
demo_path_routing() {
    log_header "Demo 8: Path-Based Routing and Collision Handling"
    
    # Service 1: API v1
    local config1=$(cat << EOF
apiVersion: v1
kind: Service
metadata:
  name: httpbin-multi-path
  namespace: $NAMESPACE
  annotations:
    gateway.tetrate.io/host: "api.$DOMAIN"
    gateway.tetrate.io/path: "/v1/httpbin"
    gateway.tetrate.io/local-path: "/get"  # Path rewriting
spec:
  selector:
    app: httpbin
    version: v1
  ports:
  - port: 8001
    targetPort: 8080
    name: http
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin-multi-path-2
  namespace: $NAMESPACE
  annotations:
    gateway.tetrate.io/host: "api.$DOMAIN"
    gateway.tetrate.io/path: "/v2/httpbin"
    gateway.tetrate.io/local-path: "/status/200"  # Different internal path
spec:
  selector:
    app: httpbin
    version: v1
  ports:
  - port: 8002
    targetPort: 8080
    name: http
EOF
)
    
    apply_or_show "Path-Based Routing Services" "$config1"
}

# Demo 9: Multiple Hosts Support
demo_multiple_hosts() {
    log_header "Demo 9: Multiple Hosts Support"
    
    local config=$(cat << EOF
apiVersion: v1
kind: Service
metadata:
  name: httpbin-multi-hosts
  namespace: $NAMESPACE
  annotations:
    gateway.tetrate.io/host: "multi.$DOMAIN, staging-multi.$DOMAIN, dev-multi.$DOMAIN"
    gateway.tetrate.io/protocol: "HTTPS"
    gateway.tetrate.io/tls-secret: "httpbin-tls"
    gateway.tetrate.io/path: "/multi"
    # Creates 3 separate TSB Gateway objects, all routing to the same backend
spec:
  selector:
    app: httpbin
    version: v1
  ports:
  - port: 8000
    targetPort: 8080
    name: http
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin-alias-domains
  namespace: $NAMESPACE
  annotations:
    gateway.tetrate.io/host: "brand1.$DOMAIN, brand2.$DOMAIN"
    gateway.tetrate.io/protocol: "HTTP"
    gateway.tetrate.io/path: "/brands"
    # Example: Same service accessible under multiple brand domains
spec:
  selector:
    app: httpbin
    version: v1
  ports:
  - port: 8000
    targetPort: 8080
    name: http
EOF
)
    
    apply_or_show "Multiple Hosts Support Services" "$config"
}

# Demo 10: Custom Local Port Configuration
demo_local_port() {
    log_header "Demo 10: Custom Local Port Configuration"
    
    local config=$(cat << EOF
apiVersion: v1
kind: Service
metadata:
  name: httpbin-custom-port
  namespace: $NAMESPACE
  annotations:
    gateway.tetrate.io/host: "custom-port.$DOMAIN"
    gateway.tetrate.io/protocol: "HTTPS"
    gateway.tetrate.io/port: "443"                   # External HTTPS port
    gateway.tetrate.io/local-port: "9999"            # Custom internal service port
    gateway.tetrate.io/tls-secret: "httpbin-tls"
    gateway.tetrate.io/path: "/custom-port"
    # Routes external port 443 to internal service port 9999
spec:
  selector:
    app: httpbin
    version: v1
  ports:
  - port: 9999      # Must match local-port annotation
    targetPort: 8080 # Actual container port
    name: http
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin-port-mapping
  namespace: $NAMESPACE
  annotations:
    gateway.tetrate.io/host: "port-map.$DOMAIN"
    gateway.tetrate.io/protocol: "HTTP"
    gateway.tetrate.io/port: "8090"                  # Custom external HTTP port
    gateway.tetrate.io/local-port: "7777"            # Custom internal port
    gateway.tetrate.io/path: "/port-test"
    # External port 8090 -> internal port 7777 -> container port 8080
spec:
  selector:
    app: httpbin
    version: v1
  ports:
  - port: 7777      # Must match local-port annotation  
    targetPort: 8080 # Container port
    name: http
EOF
)
    
    apply_or_show "Custom Local Port Configuration Services" "$config"
}

# Demo 11: TCP service (DISABLED)
demo_tcp_service() {
    log_header "Demo 11: TCP Service Configuration (DISABLED)"
    log_warning "TCP protocol is currently disabled in this version of the agent."
    log_info "Only HTTP and HTTPS protocols are supported."
    log_info "Skipping TCP service configuration demo."
    
    # Commented out - TCP protocol disabled
    # local config=$(cat << EOF
    # apiVersion: v1
    # kind: Service
    # metadata:
    #   name: httpbin-tcp
    #   namespace: $NAMESPACE
    #   annotations:
    #     gateway.tetrate.io/host: "tcp.$DOMAIN"
    #     gateway.tetrate.io/protocol: "TCP"
    #     gateway.tetrate.io/port: "9080"
    #     gateway.tetrate.io/workload-selector: "app=tcp-gateway"
    # spec:
    #   selector:
    #     app: httpbin
    #     version: v1
    #   ports:
    #   - port: 9080
    #     targetPort: 8080
    #     name: tcp
    #     protocol: TCP
    # EOF
    # )
    # 
    # apply_or_show "TCP Service Configuration" "$config"
}

# Show demo status
show_status() {
    log_header "Demo Status Check"
    
    log_info "Services in namespace $NAMESPACE:"
    kubectl get services -n "$NAMESPACE" -o wide
    
    echo ""
    log_info "Gateway-enabled services:"
    kubectl get services -n "$NAMESPACE" -o jsonpath='{range .items[*]}{@.metadata.name}{"\t"}{@.metadata.annotations.gateway\.tetrate\.io/expose}{"\t"}{@.metadata.annotations.gateway\.tetrate\.io/host}{"\n"}{end}' | column -t
    
    echo ""
    log_info "Pods status:"
    kubectl get pods -n "$NAMESPACE"
}

# Generate curl test commands
generate_test_commands() {
    log_header "Curl Test Commands"
    
    # Try to find gateway service IP
    local gateway_ip=""
    local gateway_service=""
    
    # Common gateway service names to check
    local gateway_services=("istio-ingressgateway" "gateway" "tetrate-gateway" "ingress-gateway")
    local gateway_namespaces=("istio-system" "tetrate-system" "gateway-system" "default")
    
    for ns in "${gateway_namespaces[@]}"; do
        for svc in "${gateway_services[@]}"; do
            if kubectl get service "$svc" -n "$ns" &>/dev/null; then
                gateway_service="$svc"
                gateway_ip=$(kubectl get service "$svc" -n "$ns" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
                if [[ -z "$gateway_ip" ]]; then
                    gateway_ip=$(kubectl get service "$svc" -n "$ns" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
                fi
                if [[ -z "$gateway_ip" ]]; then
                    gateway_ip=$(kubectl get service "$svc" -n "$ns" -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
                fi
                if [[ -n "$gateway_ip" ]]; then
                    log_info "Found gateway service: $svc in namespace $ns (IP: $gateway_ip)"
                    break 2
                fi
            fi
        done
    done
    
    if [[ -z "$gateway_ip" ]]; then
        log_warning "Could not find gateway service IP. Using 'GATEWAY_IP' placeholder."
        log_info "To find your gateway IP, run: kubectl get svc -A | grep -i gateway"
        gateway_ip="GATEWAY_IP"
    fi
    
    log_info "Test the following endpoints using curl with IP resolution:"
    echo ""
    
    # HTTP endpoints
    log_info "1. Basic HTTP Service:"
    echo "curl -H \"Host: basic.$DOMAIN\" http://$gateway_ip/"
    echo "# Or with --resolve flag:"
    echo "curl --resolve \"basic.$DOMAIN:80:$gateway_ip\" http://basic.$DOMAIN/"
    echo ""
    
    # HTTPS endpoints
    log_info "2. Secure HTTPS Service (with self-signed cert):"
    echo "curl -k -H \"Host: secure.$DOMAIN\" https://$gateway_ip/"
    echo "# Or with --resolve flag:"
    echo "curl -k --resolve \"secure.$DOMAIN:443:$gateway_ip\" https://secure.$DOMAIN/"
    echo ""
    
    log_info "3. HTTPS with HTTP Redirect (demonstrates automatic redirect):"
    echo "# Test HTTP -> HTTPS redirect (should return 301):"
    echo "curl -v -H \"Host: redirect.$DOMAIN\" http://$gateway_ip:8080/"
    echo "# Test HTTPS endpoint:"
    echo "curl -k -H \"Host: redirect.$DOMAIN\" https://$gateway_ip:8443/"
    echo "# Or with --resolve flag:"
    echo "curl -k --resolve \"redirect.$DOMAIN:8443:$gateway_ip\" https://redirect.$DOMAIN:8443/"
    echo ""
    
    log_info "4. Custom Gateway HTTPS (port 8443):"
    echo "curl -k -H \"Host: custom.$DOMAIN\" https://$gateway_ip:8443/"
    echo "# Or with --resolve flag:"
    echo "curl -k --resolve \"custom.$DOMAIN:8443:$gateway_ip\" https://custom.$DOMAIN:8443/"
    echo ""
    
    log_info "5. JWT Protected Service (will return 401 without valid token):"
    echo "curl -k -H \"Host: auth.$DOMAIN\" https://$gateway_ip/secure"
    echo "# With Authorization header (replace TOKEN with valid JWT):"
    echo "curl -k -H \"Host: auth.$DOMAIN\" -H \"Authorization: Bearer TOKEN\" https://$gateway_ip/secure"
    echo ""
    
    log_info "6. OIDC Protected Service (requires authentication flow):"
    echo "curl -k -H \"Host: oidc.$DOMAIN\" https://$gateway_ip/app"
    echo "# This will redirect to OIDC provider for authentication"
    echo ""
    
    log_info "7. Rate Limited API Service:"
    echo "curl -H \"Host: api.$DOMAIN\" http://$gateway_ip/rate-limited"
    echo "# Test CORS preflight:"
    echo "curl -H \"Host: api.$DOMAIN\" -H \"Origin: https://demo.company.com\" -X OPTIONS http://$gateway_ip/rate-limited"
    echo ""
    
    log_info "8. WAF Protection Services:"
    echo "curl -H \"Host: waf.$DOMAIN\" http://$gateway_ip/protected  # Protected by OWASP rules"
    echo "# Test XSS attack (should be blocked or logged):"
    echo "curl -H \"Host: waf.$DOMAIN\" \"http://$gateway_ip/protected?test=<script>alert('xss')</script>\""
    echo "# Custom WAF rules (XSS detection only):"
    echo "curl -H \"Host: waf-custom.$DOMAIN\" http://$gateway_ip/xss-test"
    echo "curl -H \"Host: waf-custom.$DOMAIN\" \"http://$gateway_ip/xss-test?param=<script>alert(1)</script>\""
    echo ""
    
    log_info "9. Path-based Routing:"
    echo "curl -H \"Host: api.$DOMAIN\" http://$gateway_ip/v1/httpbin  # Routes to /get"
    echo "curl -H \"Host: api.$DOMAIN\" http://$gateway_ip/v2/httpbin  # Routes to /status/200"
    echo ""
    
    log_info "10. Multiple Hosts Support:"
    echo "# Same service accessible via multiple hostnames"
    echo "curl -k -H \"Host: multi.$DOMAIN\" https://$gateway_ip/multi"
    echo "curl -k -H \"Host: staging-multi.$DOMAIN\" https://$gateway_ip/multi"
    echo "curl -k -H \"Host: dev-multi.$DOMAIN\" https://$gateway_ip/multi"
    echo "# Different brand domains"
    echo "curl -H \"Host: brand1.$DOMAIN\" http://$gateway_ip/brands"
    echo "curl -H \"Host: brand2.$DOMAIN\" http://$gateway_ip/brands"
    echo ""
    
    log_info "11. Custom Local Port Configuration:"
    echo "# External HTTPS port 443 -> internal port 9999"
    echo "curl -k -H \"Host: custom-port.$DOMAIN\" https://$gateway_ip/custom-port"
    echo "# External HTTP port 8090 -> internal port 7777"
    echo "curl -H \"Host: port-map.$DOMAIN\" http://$gateway_ip:8090/port-test"
    echo ""
    
    log_info "12. TCP Service (DISABLED):"
    log_warning "TCP protocol is currently disabled."
    echo ""
    
    # Advanced testing scenarios
    log_info "Advanced Testing Scenarios:"
    echo ""
    log_info "• Rate Limiting Test (run multiple times quickly):"
    echo "for i in {1..15}; do curl -s -o /dev/null -w \"%{http_code}\\n\" -H \"Host: api.$DOMAIN\" http://$gateway_ip/rate-limited; done"
    echo ""
    
    log_info "• JWT Authentication Test:"
    echo "# This should return 401 Unauthorized"
    echo "curl -s -o /dev/null -w \"%{http_code}\\n\" -k -H \"Host: auth.$DOMAIN\" https://$gateway_ip/secure"
    echo ""
    
    log_info "• WAF Attack Testing:"
    echo "# Test various attack patterns against WAF"
    echo "curl -s -o /dev/null -w \"%{http_code}\\n\" -H \"Host: waf.$DOMAIN\" \"http://$gateway_ip/protected?test=<script>alert('xss')</script>\""
    echo "curl -s -o /dev/null -w \"%{http_code}\\n\" -H \"Host: waf.$DOMAIN\" \"http://$gateway_ip/protected?test=' OR 1=1--\""
    echo "curl -s -o /dev/null -w \"%{http_code}\\n\" -H \"Host: waf.$DOMAIN\" \"http://$gateway_ip/protected\" -d \"data=../../../etc/passwd\""
    echo ""
    
    log_info "• TLS Certificate Inspection:"
    echo "echo | openssl s_client -servername secure.$DOMAIN -connect $gateway_ip:443 2>/dev/null | openssl x509 -noout -text"
    echo ""
    
    if [[ "$gateway_ip" == "GATEWAY_IP" ]]; then
        log_warning "Replace 'GATEWAY_IP' with your actual gateway IP address."
        log_info "Find gateway IP with: kubectl get svc -A | grep -i gateway"
    fi
}

# Main execution
main() {
    log_header "TSB Gateway Annotations Demo"
    log_info "Namespace: $NAMESPACE"
    log_info "Domain: $DOMAIN"
    log_info "Cloud Provider: $CLOUD_PROVIDER"
    log_info "Skip Apply: $SKIP_APPLY"
    
    # Handle cleanup-only mode
    if [[ "$CLEANUP_ONLY" == "true" ]]; then
        cleanup_resources
        exit 0
    fi
    
    # Run demos
    check_prerequisites
    setup_environment
    
    # Run all demo scenarios
    demo_basic_http
    demo_https_with_tls
    demo_https_redirect
    demo_custom_gateway
    demo_jwt_auth
    demo_oidc_auth
    demo_rate_limiting
    demo_waf_protection
    demo_path_routing
    demo_multiple_hosts
    demo_local_port
    demo_tcp_service
    
    # Show final status
    if [[ "$SKIP_APPLY" == "false" ]]; then
        show_status
        generate_test_commands
        
        log_header "Demo Completed Successfully!"
        log_success "All demo configurations have been applied to namespace: $NAMESPACE"
        echo ""
        log_info "Demo endpoints summary (if DNS is configured):"
        echo "  • http://basic.$DOMAIN - Basic HTTP service"
        echo "  • https://secure.$DOMAIN - HTTPS with TLS"
        echo "  • http://redirect.$DOMAIN:8080 -> https://redirect.$DOMAIN:8443 - HTTP to HTTPS redirect"
        echo "  • https://custom.$DOMAIN:8443 - Custom gateway"
        echo "  • https://auth.$DOMAIN/secure - JWT authenticated service"
        echo "  • https://oidc.$DOMAIN/app - OIDC authenticated service"
        echo "  • http://api.$DOMAIN/rate-limited - Rate limited service"
        echo "  • http://waf.$DOMAIN/protected - WAF protected service (OWASP rules)"
        echo "  • http://waf-custom.$DOMAIN/xss-test - Custom WAF rules (XSS detection)"
        echo "  • http://api.$DOMAIN/v1/httpbin - Path routing v1"
        echo "  • http://api.$DOMAIN/v2/httpbin - Path routing v2"
        echo "  • https://multi.$DOMAIN/multi - Multi-host service (+ staging-multi, dev-multi)"
        echo "  • http://brand1.$DOMAIN/brands - Brand alias domains (+ brand2)"
        echo "  • https://custom-port.$DOMAIN/custom-port - Custom local port (9999)"
        echo "  • http://port-map.$DOMAIN:8090/port-test - Custom external port mapping"
        echo "  • tcp://tcp.$DOMAIN:9080 - TCP service (DISABLED)"
        echo ""
        log_info "To clean up demo resources, run:"
        log_info "$0 --cleanup -n $NAMESPACE"
    else
        log_header "Configuration Preview Completed"
        log_info "All configurations were displayed. Run without --skip-apply to apply them."
    fi
}

# Run main function
main "$@"
