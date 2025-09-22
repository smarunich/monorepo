#!/bin/bash

# TSB Gateway Advanced Annotations Demo Script
# This script demonstrates various gateway annotation configurations using multiple backends
# across different namespaces for comprehensive testing scenarios
#
# PROTOCOL SUPPORT: HTTP and HTTPS protocols are supported.
# TCP and TLS protocols are currently disabled.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
BASE_NAMESPACE="demo"
DOMAIN="demo.example.com"
CLOUD_PROVIDER="aws"
CLEANUP_ONLY=false
SKIP_APPLY=false

# Multiple namespaces for different environments
NAMESPACES=("${BASE_NAMESPACE}-prod" "${BASE_NAMESPACE}-staging" "${BASE_NAMESPACE}-dev" "${BASE_NAMESPACE}-test")

# Multiple backend services for diverse testing
BACKEND_NAMES=("httpbin" "httpbingo" "nginx" "echo")
BACKEND_IMAGES=("docker.io/kennethreitz/httpbin:latest" "docker.io/mccutchen/go-httpbin:v2.15.0" "nginx:alpine" "k8s.gcr.io/echoserver:1.10")

# Helper function to get backend image
get_backend_image() {
    local backend="$1"
    for i in "${!BACKEND_NAMES[@]}"; do
        if [[ "${BACKEND_NAMES[$i]}" == "$backend" ]]; then
            echo "${BACKEND_IMAGES[$i]}"
            return
        fi
    done
    echo "docker.io/kennethreitz/httpbin:latest"  # fallback
}

# Print usage
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -n, --namespace <name>     Base namespace prefix (default: demo)"
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
    echo ""
    echo "This advanced demo creates:"
    echo "  • 4 namespaces: ${NAMESPACES[*]}"
    echo "  • 4 different backends: ${BACKEND_NAMES[*]}"
    echo "  • 50+ gateway configurations across environments"
    echo "  • Multi-tenant, multi-environment scenarios"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            BASE_NAMESPACE="$2"
            # Update namespaces array with new base
            NAMESPACES=("${BASE_NAMESPACE}-prod" "${BASE_NAMESPACE}-staging" "${BASE_NAMESPACE}-dev" "${BASE_NAMESPACE}-test")
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

log_subheader() {
    echo ""
    echo -e "${CYAN}--- $1 ---${NC}"
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
    log_header "Cleaning Up Advanced Demo Resources"

    for namespace in "${NAMESPACES[@]}"; do
        log_info "Removing services in namespace $namespace..."
        kubectl delete services --all -n "$namespace" --ignore-not-found=true

        log_info "Removing deployments in namespace $namespace..."
        kubectl delete deployments --all -n "$namespace" --ignore-not-found=true

        log_info "Removing namespace $namespace..."
        kubectl delete namespace "$namespace" --ignore-not-found=true
    done

    log_info "Removing TLS secrets..."
    kubectl delete secret httpbin-tls nginx-tls echo-tls bingo-tls -n tetrate-system --ignore-not-found=true

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

# Create TLS secrets for different backends
create_tls_secrets() {
    log_info "Creating TLS secrets for different backends"

    local backends=("httpbin" "nginx" "echo" "bingo")

    for backend in "${backends[@]}"; do
        # Check if secret already exists
        if kubectl get secret "${backend}-tls" -n tetrate-system &> /dev/null; then
            log_info "TLS secret ${backend}-tls already exists, skipping creation"
            continue
        fi

        # Create temporary directory for certificates
        local temp_dir=$(mktemp -d)
        local cert_file="$temp_dir/tls.crt"
        local key_file="$temp_dir/tls.key"

        # Generate self-signed certificate for demo purposes
        log_info "Generating self-signed certificate for ${backend}.*.$DOMAIN"
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$key_file" \
            -out "$cert_file" \
            -subj "/C=US/ST=Demo/L=Demo/O=Demo/OU=Demo/CN=${backend}.$DOMAIN" \
            -addext "subjectAltName=DNS:${backend}.*.$DOMAIN,DNS:${backend}.$DOMAIN,DNS:${backend}-prod.$DOMAIN,DNS:${backend}-staging.$DOMAIN,DNS:${backend}-dev.$DOMAIN" \
            2>/dev/null

        if [[ $? -eq 0 ]]; then
            # Create Kubernetes TLS secret
            kubectl create secret tls "${backend}-tls" \
                --cert="$cert_file" \
                --key="$key_file" \
                -n tetrate-system
            log_success "Created TLS secret ${backend}-tls"
        else
            log_error "Failed to generate TLS certificate for $backend"
            log_warning "HTTPS demos for $backend will fail without TLS secret"
        fi

        # Cleanup temporary files
        rm -rf "$temp_dir"
    done
}

# Deploy backend applications
deploy_backend() {
    local backend="$1"
    local namespace="$2"
    local image=$(get_backend_image "$backend")

    log_info "Deploying $backend in namespace $namespace"

    case $backend in
        httpbin)
            kubectl apply -n "$namespace" -f - << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
spec:
  replicas: 2
  selector:
    matchLabels:
      app: httpbin
      version: v1
  template:
    metadata:
      labels:
        app: httpbin
        version: v1
        backend: httpbin
    spec:
      containers:
      - image: $image
        name: httpbin
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
EOF
            ;;
        httpbingo)
            kubectl apply -n "$namespace" -f - << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbingo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: httpbingo
      version: v1
  template:
    metadata:
      labels:
        app: httpbingo
        version: v1
        backend: httpbingo
    spec:
      containers:
      - image: $image
        name: httpbingo
        ports:
        - containerPort: 8080
        env:
        - name: PORT
          value: "8080"
        resources:
          requests:
            memory: "32Mi"
            cpu: "25m"
          limits:
            memory: "64Mi"
            cpu: "50m"
EOF
            ;;
        nginx)
            kubectl apply -n "$namespace" -f - << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  default.conf: |
    server {
        listen 80;
        server_name localhost;
        location / {
            return 200 '{"service": "nginx", "namespace": "$namespace", "path": "\$uri", "method": "\$request_method", "headers": \$http_host}';
            add_header Content-Type application/json;
        }
        location /health {
            return 200 'healthy';
            add_header Content-Type text/plain;
        }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
      version: v1
  template:
    metadata:
      labels:
        app: nginx
        version: v1
        backend: nginx
    spec:
      containers:
      - image: $image
        name: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d
        resources:
          requests:
            memory: "32Mi"
            cpu: "25m"
          limits:
            memory: "64Mi"
            cpu: "50m"
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-config
EOF
            ;;
        echo)
            kubectl apply -n "$namespace" -f - << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echoserver
spec:
  replicas: 2
  selector:
    matchLabels:
      app: echoserver
      version: v1
  template:
    metadata:
      labels:
        app: echoserver
        version: v1
        backend: echo
    spec:
      containers:
      - image: $image
        name: echoserver
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "32Mi"
            cpu: "25m"
          limits:
            memory: "64Mi"
            cpu: "50m"
EOF
            ;;
    esac
}

# Setup demo environment
setup_environment() {
    log_header "Setting Up Advanced Demo Environment"

    # Create namespaces
    for namespace in "${NAMESPACES[@]}"; do
        log_info "Creating namespace: $namespace"
        kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -

        # Label namespace for service mesh injection
        log_info "Labeling namespace $namespace for service mesh injection"
        kubectl label namespace "$namespace" istio-injection=enabled --overwrite

        # Add environment label
        local env_type=$(echo "$namespace" | cut -d'-' -f2)
        kubectl label namespace "$namespace" environment="$env_type" --overwrite
    done

    # Deploy different backends to different namespaces
    local backend_list=("${BACKEND_NAMES[@]}")

    for i in "${!NAMESPACES[@]}"; do
        local namespace="${NAMESPACES[$i]}"
        local backend="${backend_list[$((i % ${#backend_list[@]}))]}"

        log_subheader "Deploying $backend to $namespace"
        deploy_backend "$backend" "$namespace"

        # Wait for deployment to be ready
        log_info "Waiting for $backend deployment to be ready in $namespace..."
        case $backend in
            httpbin) kubectl wait --for=condition=available --timeout=300s deployment/httpbin -n "$namespace" ;;
            httpbingo) kubectl wait --for=condition=available --timeout=300s deployment/httpbingo -n "$namespace" ;;
            nginx) kubectl wait --for=condition=available --timeout=300s deployment/nginx -n "$namespace" ;;
            echo) kubectl wait --for=condition=available --timeout=300s deployment/echoserver -n "$namespace" ;;
        esac
    done

    # Create TLS secrets for HTTPS demos
    create_tls_secrets

    log_success "Environment setup completed"
}

# Demo 1: Basic HTTP services across namespaces
demo_basic_http_services() {
    log_header "Demo 1: Basic HTTP Services Across Namespaces"

    local counter=1
    for namespace in "${NAMESPACES[@]}"; do
        local env_type=$(echo "$namespace" | cut -d'-' -f2)
        local port=$((8000 + counter))

        local config=$(cat << EOF
apiVersion: v1
kind: Service
metadata:
  name: basic-http-service
  namespace: $namespace
  annotations:
    gateway.tetrate.io/host: "$env_type.$DOMAIN"
    gateway.tetrate.io/port: "$port"
$(get_gateway_annotations_for_namespace "$namespace")
    # Environment-specific basic HTTP exposure
spec:
  selector:
    backend: $(get_backend_for_namespace "$namespace")
  ports:
  - port: 8000
    targetPort: $(get_target_port_for_namespace "$namespace")
    name: http
EOF
)

        apply_or_show "Basic HTTP Service - $namespace" "$config"
        ((counter++))
    done
}

# Get backend type for namespace
get_backend_for_namespace() {
    local namespace="$1"
    local backend_list=("${BACKEND_NAMES[@]}")

    for i in "${!NAMESPACES[@]}"; do
        if [[ "${NAMESPACES[$i]}" == "$namespace" ]]; then
            echo "${backend_list[$((i % ${#backend_list[@]}))]}"
            return
        fi
    done
    echo "httpbin"  # fallback
}

# Get target port for namespace based on backend
get_target_port_for_namespace() {
    local namespace="$1"
    local backend=$(get_backend_for_namespace "$namespace")

    case $backend in
        httpbin) echo "80" ;;
        httpbingo) echo "8080" ;;
        nginx) echo "80" ;;
        echo) echo "8080" ;;
        *) echo "80" ;;
    esac
}

# Get app selector for namespace
get_app_selector_for_namespace() {
    local namespace="$1"
    local backend=$(get_backend_for_namespace "$namespace")

    case $backend in
        httpbin) echo "httpbin" ;;
        httpbingo) echo "httpbingo" ;;
        nginx) echo "nginx" ;;
        echo) echo "echoserver" ;;
        *) echo "httpbin" ;;
    esac
}

# Get gateway annotations for namespace (split gateway configuration)
get_gateway_annotations_for_namespace() {
    local namespace="$1"
    local env_type=$(echo "$namespace" | cut -d'-' -f2)

    cat << EOF
    gateway.tetrate.io/workload-selector: "app=${BASE_NAMESPACE}-${env_type}-gateway"
    gateway.tetrate.io/gateway-namespace: "tetrate-system"
EOF
}

# Demo 2: HTTPS services with different TLS configurations
demo_https_services() {
    log_header "Demo 2: HTTPS Services with Different TLS Configurations"

    local counter=1
    for namespace in "${NAMESPACES[@]}"; do
        local env_type=$(echo "$namespace" | cut -d'-' -f2)
        local backend=$(get_backend_for_namespace "$namespace")
        local cloud_annotations=$(get_cloud_annotations "$CLOUD_PROVIDER")

        local config=$(cat << EOF
apiVersion: v1
kind: Service
metadata:
  name: https-service
  namespace: $namespace
  annotations:
    gateway.tetrate.io/host: "secure-$env_type.$DOMAIN"
    gateway.tetrate.io/protocol: "HTTPS"
    gateway.tetrate.io/port: "443"
    gateway.tetrate.io/tls-secret: "${backend}-tls"
$(get_gateway_annotations_for_namespace "$namespace")
    gateway.tetrate.io/cloud-annotations: |
$(echo "$cloud_annotations" | sed 's/^/      /')
spec:
  selector:
    app: $(get_app_selector_for_namespace "$namespace")
  ports:
  - port: 8000
    targetPort: $(get_target_port_for_namespace "$namespace")
    name: http
EOF
)

        apply_or_show "HTTPS Service - $namespace ($backend)" "$config"
        ((counter++))
    done
}

# Demo 3: Multi-backend API gateway with path routing
demo_api_gateway_routing() {
    log_header "Demo 3: Multi-Backend API Gateway with Path Routing"

    local api_counter=1
    for namespace in "${NAMESPACES[@]}"; do
        local env_type=$(echo "$namespace" | cut -d'-' -f2)
        local backend=$(get_backend_for_namespace "$namespace")

        # Create multiple API versions per backend
        for version in "v1" "v2" "v3"; do
            local config=$(cat << EOF
apiVersion: v1
kind: Service
metadata:
  name: api-$version-service
  namespace: $namespace
  annotations:
    gateway.tetrate.io/host: "api-$env_type.$DOMAIN"
    gateway.tetrate.io/path: "/$version/$backend"
    gateway.tetrate.io/local-path: "$(get_local_path_for_backend_version "$backend" "$version")"
$(get_gateway_annotations_for_namespace "$namespace")
    gateway.tetrate.io/rate-limits: |
      - dimensions:
          - remoteAddress:
              value: "*"
        limit:
          requestsPerUnit: $((50 * api_counter))
          unit: MINUTE
spec:
  selector:
    app: $(get_app_selector_for_namespace "$namespace")
  ports:
  - port: $((8000 + api_counter))
    targetPort: $(get_target_port_for_namespace "$namespace")
    name: http
EOF
)

            apply_or_show "API $version Service - $namespace ($backend)" "$config"
            ((api_counter++))
        done
    done
}

# Get local path for backend and version
get_local_path_for_backend_version() {
    local backend="$1"
    local version="$2"

    case $backend in
        httpbin)
            case $version in
                v1) echo "/get" ;;
                v2) echo "/post" ;;
                v3) echo "/json" ;;
            esac
            ;;
        httpbingo)
            case $version in
                v1) echo "/headers" ;;
                v2) echo "/ip" ;;
                v3) echo "/user-agent" ;;
            esac
            ;;
        nginx)
            case $version in
                v1) echo "/" ;;
                v2) echo "/health" ;;
                v3) echo "/" ;;
            esac
            ;;
        echo)
            case $version in
                v1) echo "/" ;;
                v2) echo "/" ;;
                v3) echo "/" ;;
            esac
            ;;
    esac
}

# Demo 4: Authentication services across environments
demo_authentication_services() {
    log_header "Demo 4: Authentication Services Across Environments"

    # JWT Authentication for production environments
    for namespace in "${NAMESPACES[@]}"; do
        local env_type=$(echo "$namespace" | cut -d'-' -f2)
        local backend=$(get_backend_for_namespace "$namespace")

        if [[ "$env_type" == "prod" || "$env_type" == "staging" ]]; then
            local config=$(cat << EOF
apiVersion: v1
kind: Service
metadata:
  name: jwt-auth-service
  namespace: $namespace
  annotations:
    gateway.tetrate.io/host: "auth-$env_type.$DOMAIN"
    gateway.tetrate.io/protocol: "HTTPS"
    gateway.tetrate.io/tls-secret: "${backend}-tls"
    gateway.tetrate.io/path: "/secure"
$(get_gateway_annotations_for_namespace "$namespace")
    gateway.tetrate.io/jwt-issuers: |
      - issuer: "https://accounts.google.com"
        jwksUri: "https://www.googleapis.com/oauth2/v3/certs"
      - issuer: "https://keycloak.alder.dogfood.gcp.sandbox.tetrate.io/realms/tetrate"
        jwksUri: "https://keycloak.alder.dogfood.gcp.sandbox.tetrate.io/realms/tetrate/protocol/openid-connect/certs"
spec:
  selector:
    app: $(get_app_selector_for_namespace "$namespace")
  ports:
  - port: 8000
    targetPort: $(get_target_port_for_namespace "$namespace")
    name: http
EOF
)

            apply_or_show "JWT Auth Service - $namespace ($backend)" "$config"
        fi

        # OIDC Authentication for development environments
        if [[ "$env_type" == "dev" || "$env_type" == "test" ]]; then
            # Create OIDC secret
            kubectl create secret generic oauth-client-secret-$env_type \
                --from-literal=istio_generic_secret=oidc-client-secret-tetrate123987 \
                -n tetrate-system \
                --dry-run=client \
                -o yaml | kubectl apply -f -

            local config=$(cat << EOF
apiVersion: v1
kind: Service
metadata:
  name: oidc-auth-service
  namespace: $namespace
  annotations:
    gateway.tetrate.io/host: "oidc-$env_type.$DOMAIN"
    gateway.tetrate.io/protocol: "HTTPS"
    gateway.tetrate.io/tls-secret: "${backend}-tls"
    gateway.tetrate.io/path: "/app"
$(get_gateway_annotations_for_namespace "$namespace")
    gateway.tetrate.io/oidc-enabled: "true"
    gateway.tetrate.io/oidc-config: |
      grantType: "AUTHORIZATION_CODE"
      clientId: "client-tetrate-auth"
      clientTokenSecret: "oauth-client-secret-$env_type"
      redirectUri: "https://oidc-$env_type.$DOMAIN/callback"
      provider:
        issuer: "https://keycloak.alder.dogfood.gcp.sandbox.tetrate.io/realms/tetrate"
        authorizationEndpoint: "https://keycloak.alder.dogfood.gcp.sandbox.tetrate.io/realms/tetrate/protocol/openid-connect/auth"
        tokenEndpoint: "https://keycloak.alder.dogfood.gcp.sandbox.tetrate.io/realms/tetrate/protocol/openid-connect/token"
        jwksUri: "https://keycloak.alder.dogfood.gcp.sandbox.tetrate.io/realms/tetrate/protocol/openid-connect/certs"
spec:
  selector:
    app: $(get_app_selector_for_namespace "$namespace")
  ports:
  - port: 8000
    targetPort: $(get_target_port_for_namespace "$namespace")
    name: http
EOF
)

            apply_or_show "OIDC Auth Service - $namespace ($backend)" "$config"
        fi
    done
}

# Demo 5: WAF protection with different rule sets
demo_waf_protection() {
    log_header "Demo 5: WAF Protection with Different Rule Sets"

    local waf_counter=1
    for namespace in "${NAMESPACES[@]}"; do
        local env_type=$(echo "$namespace" | cut -d'-' -f2)
        local backend=$(get_backend_for_namespace "$namespace")

        # Different WAF configurations based on environment
        case $env_type in
            prod)
                local waf_config="SecRuleEngine On"
                local path="/protected"
                ;;
            staging)
                local waf_config="SecRuleEngine DetectionOnly"
                local path="/staging-protected"
                ;;
            dev)
                local waf_config="SecRuleEngine DetectionOnly\nSecDebugLogLevel 5"
                local path="/dev-test"
                ;;
            test)
                local waf_config="SecRuleEngine Off"
                local path="/test-endpoint"
                ;;
        esac

        local config=$(cat << EOF
apiVersion: v1
kind: Service
metadata:
  name: waf-service
  namespace: $namespace
  annotations:
    gateway.tetrate.io/host: "waf-$env_type.$DOMAIN"
    gateway.tetrate.io/path: "$path"
$(get_gateway_annotations_for_namespace "$namespace")
    gateway.tetrate.io/waf-enabled: "true"
    gateway.tetrate.io/custom-config: |
      waf:
        rules:
          - "$waf_config"
spec:
  selector:
    app: $(get_app_selector_for_namespace "$namespace")
  ports:
  - port: $((9000 + waf_counter))
    targetPort: $(get_target_port_for_namespace "$namespace")
    name: http
EOF
)

        apply_or_show "WAF Protection Service - $namespace ($backend, $env_type rules)" "$config"
        ((waf_counter++))
    done
}

# Demo 6: Cross-environment service communication
demo_cross_environment_services() {
    log_header "Demo 6: Cross-Environment Service Communication"

    # Create inter-environment communication patterns
    for i in "${!NAMESPACES[@]}"; do
        local source_namespace="${NAMESPACES[$i]}"
        local source_env=$(echo "$source_namespace" | cut -d'-' -f2)
        local target_namespace="${NAMESPACES[$(((i + 1) % ${#NAMESPACES[@]}))]}"
        local target_env=$(echo "$target_namespace" | cut -d'-' -f2)
        local backend=$(get_backend_for_namespace "$source_namespace")

        local config=$(cat << EOF
apiVersion: v1
kind: Service
metadata:
  name: cross-env-service
  namespace: $source_namespace
  annotations:
    gateway.tetrate.io/host: "cross-$source_env-to-$target_env.$DOMAIN"
    gateway.tetrate.io/protocol: "HTTPS"
    gateway.tetrate.io/tls-secret: "${backend}-tls"
    gateway.tetrate.io/path: "/cross-env"
$(get_gateway_annotations_for_namespace "$source_namespace")
    gateway.tetrate.io/cors-policy: |
      allowOrigin:
        - "https://*.$DOMAIN"
        - "https://$target_env.$DOMAIN"
      allowMethods:
        - "GET"
        - "POST"
        - "PUT"
        - "DELETE"
      allowHeaders:
        - "authorization"
        - "content-type"
        - "x-env-source"
        - "x-env-target"
      maxAge: "86400s"
      allowCredentials: true
spec:
  selector:
    app: $(get_app_selector_for_namespace "$source_namespace")
  ports:
  - port: 8000
    targetPort: $(get_target_port_for_namespace "$source_namespace")
    name: http
EOF
)

        apply_or_show "Cross-Environment Service - $source_env to $target_env ($backend)" "$config"
    done
}

# Demo 7: Load balancing and traffic management
demo_load_balancing() {
    log_header "Demo 7: Load Balancing and Traffic Management"

    # Create services with different load balancing strategies
    local strategies=("round_robin" "least_conn" "random" "hash")

    for i in "${!NAMESPACES[@]}"; do
        local namespace="${NAMESPACES[$i]}"
        local env_type=$(echo "$namespace" | cut -d'-' -f2)
        local backend=$(get_backend_for_namespace "$namespace")
        local strategy="${strategies[$((i % ${#strategies[@]}))]}"

        local config=$(cat << EOF
apiVersion: v1
kind: Service
metadata:
  name: lb-service
  namespace: $namespace
  annotations:
    gateway.tetrate.io/host: "lb-$env_type.$DOMAIN"
    gateway.tetrate.io/protocol: "HTTPS"
    gateway.tetrate.io/tls-secret: "${backend}-tls"
    gateway.tetrate.io/path: "/lb-test"
$(get_gateway_annotations_for_namespace "$namespace")
    gateway.tetrate.io/load-balancer: "$strategy"
    gateway.tetrate.io/health-check: |
      path: "/health"
      interval: "30s"
      timeout: "5s"
      healthyThreshold: 2
      unhealthyThreshold: 3
spec:
  selector:
    app: $(get_app_selector_for_namespace "$namespace")
  ports:
  - port: 8000
    targetPort: $(get_target_port_for_namespace "$namespace")
    name: http
EOF
)

        apply_or_show "Load Balancing Service - $namespace ($strategy, $backend)" "$config"
    done
}

# Demo 8: Multi-protocol services
demo_multi_protocol() {
    log_header "Demo 8: Multi-Protocol Services (HTTP/HTTPS/Redirects)"

    for namespace in "${NAMESPACES[@]}"; do
        local env_type=$(echo "$namespace" | cut -d'-' -f2)
        local backend=$(get_backend_for_namespace "$namespace")

        # HTTP service
        local http_config=$(cat << EOF
apiVersion: v1
kind: Service
metadata:
  name: multi-http-service
  namespace: $namespace
  annotations:
    gateway.tetrate.io/host: "multi-http-$env_type.$DOMAIN"
    gateway.tetrate.io/protocol: "HTTP"
    gateway.tetrate.io/port: "80"
$(get_gateway_annotations_for_namespace "$namespace")
spec:
  selector:
    app: $(get_app_selector_for_namespace "$namespace")
  ports:
  - port: 8000
    targetPort: $(get_target_port_for_namespace "$namespace")
    name: http
EOF
)

        # HTTPS service with redirect
        local https_config=$(cat << EOF
---
apiVersion: v1
kind: Service
metadata:
  name: multi-https-service
  namespace: $namespace
  annotations:
    gateway.tetrate.io/host: "multi-https-$env_type.$DOMAIN"
    gateway.tetrate.io/protocol: "HTTPS"
    gateway.tetrate.io/tls-secret: "${backend}-tls"
    gateway.tetrate.io/https-redirect: "true"
    gateway.tetrate.io/http-port: "8080"
    gateway.tetrate.io/https-redirect-port: "8443"
$(get_gateway_annotations_for_namespace "$namespace")
spec:
  selector:
    app: $(get_app_selector_for_namespace "$namespace")
  ports:
  - port: 8000
    targetPort: $(get_target_port_for_namespace "$namespace")
    name: http
EOF
)

        apply_or_show "Multi-Protocol HTTP Service - $namespace ($backend)" "$http_config"
        apply_or_show "Multi-Protocol HTTPS Service - $namespace ($backend)" "$https_config"
    done
}

# Show demo status
show_status() {
    log_header "Advanced Demo Status Check"

    for namespace in "${NAMESPACES[@]}"; do
        local env_type=$(echo "$namespace" | cut -d'-' -f2)
        local backend=$(get_backend_for_namespace "$namespace")

        log_subheader "Namespace: $namespace (Backend: $backend)"

        log_info "Services:"
        kubectl get services -n "$namespace" -o wide

        echo ""
        log_info "Gateway-enabled services:"
        kubectl get services -n "$namespace" -o jsonpath='{range .items[*]}{@.metadata.name}{"\t"}{@.metadata.annotations.gateway\.tetrate\.io/host}{"\t"}{@.metadata.annotations.gateway\.tetrate\.io/protocol}{"\n"}{end}' | column -t

        echo ""
        log_info "Pods status:"
        kubectl get pods -n "$namespace"
        echo ""
    done
}

# Generate comprehensive test commands
generate_test_commands() {
    log_header "Comprehensive Test Commands"

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

    # Generate test commands for each environment and backend
    for namespace in "${NAMESPACES[@]}"; do
        local env_type=$(echo "$namespace" | cut -d'-' -f2)
        local backend=$(get_backend_for_namespace "$namespace")

        log_subheader "Test Commands for $env_type Environment ($backend backend)"

        echo "# Basic HTTP Service"
        echo "curl -H \"Host: $env_type.$DOMAIN\" http://$gateway_ip/"
        echo ""

        echo "# HTTPS Service"
        echo "curl -k -H \"Host: secure-$env_type.$DOMAIN\" https://$gateway_ip/"
        echo ""

        echo "# API Gateway (multiple versions)"
        echo "curl -H \"Host: api-$env_type.$DOMAIN\" http://$gateway_ip/v1/$backend"
        echo "curl -H \"Host: api-$env_type.$DOMAIN\" http://$gateway_ip/v2/$backend"
        echo "curl -H \"Host: api-$env_type.$DOMAIN\" http://$gateway_ip/v3/$backend"
        echo ""

        if [[ "$env_type" == "prod" || "$env_type" == "staging" ]]; then
            echo "# JWT Authentication (will return 401 without token)"
            echo "curl -k -H \"Host: auth-$env_type.$DOMAIN\" https://$gateway_ip/secure"
            echo "# With token: curl -k -H \"Host: auth-$env_type.$DOMAIN\" -H \"Authorization: Bearer TOKEN\" https://$gateway_ip/secure"
            echo ""
        fi

        if [[ "$env_type" == "dev" || "$env_type" == "test" ]]; then
            echo "# OIDC Authentication"
            echo "curl -k -H \"Host: oidc-$env_type.$DOMAIN\" https://$gateway_ip/app"
            echo ""
        fi

        echo "# WAF Protection"
        echo "curl -H \"Host: waf-$env_type.$DOMAIN\" http://$gateway_ip/$(get_waf_path_for_env "$env_type")"
        echo "# Test attack: curl -H \"Host: waf-$env_type.$DOMAIN\" \"http://$gateway_ip/$(get_waf_path_for_env "$env_type")?test=<script>alert('xss')</script>\""
        echo ""

        echo "# Cross-Environment Communication"
        local next_env=$(get_next_env "$env_type")
        echo "curl -k -H \"Host: cross-$env_type-to-$next_env.$DOMAIN\" https://$gateway_ip/cross-env"
        echo ""

        echo "# Load Balancing"
        echo "curl -k -H \"Host: lb-$env_type.$DOMAIN\" https://$gateway_ip/lb-test"
        echo ""

        echo "# Multi-Protocol Services"
        echo "curl -H \"Host: multi-http-$env_type.$DOMAIN\" http://$gateway_ip/"
        echo "curl -k -H \"Host: multi-https-$env_type.$DOMAIN\" https://$gateway_ip/"
        echo ""

        echo "---"
        echo ""
    done

    log_info "Advanced Testing Scenarios:"
    echo ""

    echo "# Cross-environment rate limiting test"
    echo "for env in prod staging dev test; do"
    echo "  for i in {1..10}; do"
    echo "    curl -s -o /dev/null -w \"%{http_code}\\n\" -H \"Host: api-\$env.$DOMAIN\" http://$gateway_ip/v1/httpbin"
    echo "  done"
    echo "done"
    echo ""

    echo "# Backend comparison test"
    echo "for env in prod staging dev test; do"
    echo "  echo \"Testing \$env environment:\""
    echo "  curl -s -H \"Host: \$env.$DOMAIN\" http://$gateway_ip/ | jq ."
    echo "done"
    echo ""

    echo "# Load balancer strategy test"
    echo "for i in {1..20}; do"
    echo "  curl -s -k -H \"Host: lb-prod.$DOMAIN\" https://$gateway_ip/lb-test"
    echo "done"
    echo ""

    if [[ "$gateway_ip" == "GATEWAY_IP" ]]; then
        log_warning "Replace 'GATEWAY_IP' with your actual gateway IP address."
        log_info "Find gateway IP with: kubectl get svc -A | grep -i gateway"
    fi
}

# Helper functions
get_waf_path_for_env() {
    case $1 in
        prod) echo "/protected" ;;
        staging) echo "/staging-protected" ;;
        dev) echo "/dev-test" ;;
        test) echo "/test-endpoint" ;;
    esac
}

get_next_env() {
    case $1 in
        prod) echo "staging" ;;
        staging) echo "dev" ;;
        dev) echo "test" ;;
        test) echo "prod" ;;
    esac
}

# Main execution
main() {
    log_header "TSB Gateway Advanced Annotations Demo"
    log_info "Base Namespace: $BASE_NAMESPACE"
    log_info "Namespaces: ${NAMESPACES[*]}"
    log_info "Domain: $DOMAIN"
    log_info "Cloud Provider: $CLOUD_PROVIDER"
    log_info "Backends: ${BACKEND_NAMES[*]}"
    log_info "Skip Apply: $SKIP_APPLY"

    # Handle cleanup-only mode
    if [[ "$CLEANUP_ONLY" == "true" ]]; then
        cleanup_resources
        exit 0
    fi

    # Run demos
    check_prerequisites
    if [[ "$SKIP_APPLY" == "false" ]]; then
        setup_environment
    else
        log_info "Skipping environment setup in preview mode"
    fi

    # Run all demo scenarios
    demo_basic_http_services
    demo_https_services
    demo_api_gateway_routing
    demo_authentication_services
    demo_waf_protection
    demo_cross_environment_services
    demo_load_balancing
    demo_multi_protocol

    # Show final status
    if [[ "$SKIP_APPLY" == "false" ]]; then
        show_status
        generate_test_commands

        log_header "Advanced Demo Completed Successfully!"
        log_success "All configurations have been applied across ${#NAMESPACES[@]} namespaces with ${#BACKEND_NAMES[@]} different backends"
        echo ""
        log_info "Demo Summary:"
        echo "  • ${#NAMESPACES[@]} Namespaces: ${NAMESPACES[*]}"
        echo "  • ${#BACKEND_NAMES[@]} Backend Types: ${BACKEND_NAMES[*]}"
        echo "  • 50+ Gateway Configurations"
        echo "  • Multi-environment, multi-backend scenarios"
        echo "  • Authentication, WAF, Load Balancing, Cross-environment communication"
        echo ""
        log_info "To clean up all demo resources, run:"
        log_info "$0 --cleanup -n $BASE_NAMESPACE"
    else
        log_header "Configuration Preview Completed"
        log_info "All configurations were displayed. Run without --skip-apply to apply them."
    fi
}

# Run main function
main "$@"