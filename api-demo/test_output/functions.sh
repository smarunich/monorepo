#!/bin/bash

# TSB Enterprise Gateway Demo Script with Multi-Tier Service Architecture
# This script demonstrates enterprise-grade service architectures with business service layers
# using Giraffe microservices as intermediate processing tiers before reaching core backend systems
#
# PROTOCOL SUPPORT: HTTP and HTTPS protocols are supported.
# TCP and TLS protocols are currently disabled.


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
BROKEN_SERVICES=false

# Multiple namespaces for different business environments
NAMESPACES=("${BASE_NAMESPACE}-prod" "${BASE_NAMESPACE}-staging" "${BASE_NAMESPACE}-dev" "${BASE_NAMESPACE}-test")

# Business service layer names (using financial/enterprise terminology)
BUSINESS_SERVICES=("market-data-gateway" "trading-engine-proxy" "compliance-validator" "settlement-processor")

# Core backend services for ultimate destinations
BACKEND_NAMES=("httpbin" "httpbingo" "nginx" "echo")
BACKEND_IMAGES=("docker.io/kennethreitz/httpbin:latest" "docker.io/mccutchen/go-httpbin:v2.15.0" "nginx:alpine" "k8s.gcr.io/echoserver:1.10")

# Giraffe image for business service layers
GIRAFFE_IMAGE="us-east1-docker.pkg.dev/dogfood-cx/registryrepository/giraffe:v1.0.1"

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
    echo "  --broken-services         Inject high error rates (50-80%) in some services for failover testing"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                         # Run demo with defaults"
    echo "  $0 -n fintech -d api.company.com -c gcp"
    echo "  $0 --cleanup               # Clean up demo resources"
    echo "  $0 --skip-apply            # Show configurations without applying"
    echo "  $0 -n wealth -d api.wealth.com --broken-services  # Deploy with broken services for failover testing"
    echo ""
    echo "This enterprise demo creates:"
    echo "  • 4 namespaces: ${NAMESPACES[*]}"
    echo "  • 4 business service layers: ${BUSINESS_SERVICES[*]}"
    echo "  • 4 core backends: ${BACKEND_NAMES[*]}"
    echo "  • Multi-tier service architecture with intermediate processing layers"
    echo "  • 60+ gateway configurations across environments"
    echo "  • Enterprise-grade multi-tenant, multi-environment scenarios"
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
        --broken-services)
            BROKEN_SERVICES=true
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
service.beta.kubernetes.io/azure-dns-label-name: "enterprise-gateway-demo"
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
    log_header "Cleaning Up Enterprise Gateway Demo Resources"

    for namespace in "${NAMESPACES[@]}"; do
        log_info "Removing services in namespace $namespace..."
        kubectl delete services --all -n "$namespace" --ignore-not-found=true

        log_info "Removing deployments in namespace $namespace..."
        kubectl delete deployments --all -n "$namespace" --ignore-not-found=true

        log_info "Removing namespace $namespace..."
        kubectl delete namespace "$namespace" --ignore-not-found=true
    done

    log_info "Removing TLS secrets..."
    kubectl delete secret market-data-tls trading-engine-tls compliance-tls settlement-tls -n tetrate-system --ignore-not-found=true
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

# Create TLS secrets for business services and backends
create_tls_secrets() {
    log_info "Creating TLS secrets for business services and backends"

    local all_services=("${BUSINESS_SERVICES[@]}" "${BACKEND_NAMES[@]}")

    for service in "${all_services[@]}"; do
        # Create service-specific secret name
        local secret_name="${service}-tls"
        if [[ "$service" == "httpbingo" ]]; then
            secret_name="bingo-tls"
        fi

        # Check if secret already exists
        if kubectl get secret "$secret_name" -n tetrate-system &> /dev/null; then
            log_info "TLS secret $secret_name already exists, skipping creation"
            continue
        fi

        # Create temporary directory for certificates
        local temp_dir=$(mktemp -d)
        local cert_file="$temp_dir/tls.crt"
        local key_file="$temp_dir/tls.key"

        # Generate self-signed certificate for demo purposes
        log_info "Generating self-signed certificate for ${service}.*.$DOMAIN"
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$key_file" \
            -out "$cert_file" \
            -subj "/C=US/ST=Demo/L=Demo/O=Enterprise/OU=Gateway/CN=${service}.$DOMAIN" \
            -addext "subjectAltName=DNS:${service}.*.$DOMAIN,DNS:${service}.$DOMAIN,DNS:${service}-prod.$DOMAIN,DNS:${service}-staging.$DOMAIN,DNS:${service}-dev.$DOMAIN" \
            2>/dev/null

        if [[ $? -eq 0 ]]; then
            # Create Kubernetes TLS secret
            kubectl create secret tls "$secret_name" \
                --cert="$cert_file" \
                --key="$key_file" \
                -n tetrate-system
            log_success "Created TLS secret $secret_name"
        else
            log_error "Failed to generate TLS certificate for $service"
            log_warning "HTTPS demos for $service will fail without TLS secret"
        fi

        # Cleanup temporary files
        rm -rf "$temp_dir"
    done
}

# Get multiple upstream services for business service
get_upstream_services_for_business_service() {
    local business_service="$1"
    local namespace="$2"

    # Get the core backend for this namespace
    local backend=$(get_backend_for_namespace "$namespace")
    local backend_service=$(get_app_selector_for_namespace "$namespace")
    local backend_port=$(get_target_port_for_namespace "$namespace")

    case $business_service in
        market-data-gateway)
            # Call local backend + cross-namespace services
            echo "http://$backend_service:$backend_port,http://httpbingo.${BASE_NAMESPACE}-staging:8080,http://nginx.${BASE_NAMESPACE}-dev:80"
            ;;
        trading-engine-proxy)
            echo "http://$backend_service:$backend_port,http://httpbin.${BASE_NAMESPACE}-prod:80,http://echoserver.${BASE_NAMESPACE}-test:8080"
            ;;
        compliance-validator)
            echo "http://$backend_service:$backend_port,http://httpbin.${BASE_NAMESPACE}-prod:80,http://httpbingo.${BASE_NAMESPACE}-staging:8080"
            ;;
        settlement-processor)
            echo "http://$backend_service:$backend_port,http://nginx.${BASE_NAMESPACE}-dev:80,http://httpbin.${BASE_NAMESPACE}-prod:80"
            ;;
        *)
            echo "http://$backend_service:$backend_port"  # fallback
            ;;
    esac
}

# Deploy Giraffe business service
deploy_business_service() {
    local service_name="$1"
    local namespace="$2"

    log_info "Deploying business service $service_name in namespace $namespace"

    # Get multiple upstream services for this business service
    local upstream_urls=$(get_upstream_services_for_business_service "$service_name" "$namespace")

    # Get environment-specific configuration
    local env_type=$(echo "$namespace" | cut -d'-' -f2)
    local delay_ms=0
    local error_rate="0.0"
    local custom_fields=""

    # Business logic configuration based on service type
    case $service_name in
        market-data-gateway)
            delay_ms=50
            error_rate="0.01"
            custom_fields='
        - name: RESPONSE_FIELD_MARKET_SESSION
          value: "OPEN"
        - name: RESPONSE_FIELD_DATA_PROVIDER
          value: "bloomberg-api"
        - name: RESPONSE_FIELD_LATENCY_SLA
          value: "sub-100ms"'
            ;;
        trading-engine-proxy)
            delay_ms=100
            error_rate="0.02"
            custom_fields='
        - name: RESPONSE_FIELD_ENGINE_VERSION
          value: "v2.1.5"
        - name: RESPONSE_FIELD_ORDER_ROUTING
          value: "smart-order-router"
        - name: RESPONSE_FIELD_EXECUTION_VENUE
          value: "primary-exchange"'
            ;;
        compliance-validator)
            delay_ms=200
            error_rate="0.005"
            custom_fields='
        - name: RESPONSE_FIELD_REGULATION_SET
          value: "MIFID-II,GDPR"
        - name: RESPONSE_FIELD_VALIDATION_LEVEL
          value: "strict"
        - name: RESPONSE_FIELD_AUDIT_TRAIL
          value: "enabled"'
            ;;
        settlement-processor)
            delay_ms=300
            error_rate="0.001"
            custom_fields='
        - name: RESPONSE_FIELD_SETTLEMENT_CYCLE
          value: "T+2"
        - name: RESPONSE_FIELD_CLEARING_HOUSE
          value: "DTCC"
        - name: RESPONSE_FIELD_CURRENCY_PAIR
          value: "USD-EUR"'
            ;;
    esac

    # Increase delay and error rates for non-production environments
    case $env_type in
        staging)
            delay_ms=$((delay_ms + 50))
            error_rate=$(echo "$error_rate * 2" | bc -l)
            ;;
        dev)
            delay_ms=$((delay_ms + 100))
            error_rate=$(echo "$error_rate * 3" | bc -l)
            ;;
        test)
            delay_ms=$((delay_ms + 150))
            error_rate=$(echo "$error_rate * 5" | bc -l)
            ;;
    esac

    # Inject high error rates for broken services mode (traffic failover testing)
    if [[ "$BROKEN_SERVICES" == "true" ]]; then
        # Break specific services in specific environments for realistic failover scenarios
        # NOTE: Services are deployed according to array rotation:
        #   prod→market-data-gateway, staging→trading-engine-proxy, dev→compliance-validator, test→settlement-processor
        case $service_name in
            market-data-gateway)
                # Break market-data-gateway in prod environment (50% error rate)
                if [[ "$env_type" == "prod" ]]; then
                    error_rate="0.50"
                    log_warning "BROKEN SERVICE: $service_name in $namespace set to ${error_rate} error rate (50%)"
                fi
                ;;
            trading-engine-proxy)
                # Break trading-engine-proxy in staging environment (70% error rate)
                if [[ "$env_type" == "staging" ]]; then
                    error_rate="0.70"
                    log_warning "BROKEN SERVICE: $service_name in $namespace set to ${error_rate} error rate (70%)"
                fi
                ;;
            compliance-validator)
                # Break compliance-validator in dev environment (60% error rate)
                if [[ "$env_type" == "dev" ]]; then
                    error_rate="1"
                    log_warning "BROKEN SERVICE: $service_name in $namespace set to ${error_rate} error rate (60%)"
                fi
                ;;
            settlement-processor)
                # Break settlement-processor in test environment (80% error rate)
                if [[ "$env_type" == "test" ]]; then
                    error_rate="1"
                    log_warning "BROKEN SERVICE: $service_name in $namespace set to ${error_rate} error rate (80%)"
                fi
                ;;
        esac
    fi

    kubectl apply -n "$namespace" -f - << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $service_name
  labels:
    app: $service_name
    version: v1
    tier: business-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: $service_name
      version: v1
  template:
    metadata:
      labels:
        app: $service_name
        version: v1
        tier: business-service
        business-service: $service_name
    spec:
      containers:
      - name: giraffe
        image: $GIRAFFE_IMAGE
        ports:
        - containerPort: 9080
        env:
        - name: SERVICE_NAME
          value: "$service_name"
        - name: SERVICE_VERSION
          value: "v1"
        - name: SERVICE_PORT
          value: "9080"
        - name: HOMEPAGE_NAME
          value: "$service_name"
        - name: UPSTREAM_URLS
          value: "$upstream_urls"
        - name: CALL_UPSTREAMS
          value: "true"
        - name: INCLUDE_HEADERS
          value: "true"
        - name: INCLUDE_QUERY
          value: "true"
        - name: RESPONSE_DELAY_MS
          value: "$delay_ms"
        - name: ERROR_RATE
          value: "$error_rate"
        - name: ERROR_STATUS_CODE
          value: "503"
        - name: ERROR_MESSAGE
          value: "$service_name service temporarily unavailable"
        - name: RESPONSE_FIELD_BUSINESS_TIER
          value: "$service_name"
        - name: RESPONSE_FIELD_ENVIRONMENT
          value: "$env_type"
        - name: RESPONSE_FIELD_PROCESSING_TIME_MS
          value: "$delay_ms"$custom_fields
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
EOF
}

# Deploy backend applications
deploy_backend() {
    local backend="$1"
    local namespace="$2"
    local image=$(get_backend_image "$backend")

    log_info "Deploying core backend $backend in namespace $namespace"

    case $backend in
        httpbin)
            kubectl apply -n "$namespace" -f - << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
  labels:
    app: httpbin
    version: v1
    tier: core-backend
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
        tier: core-backend
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
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
    tier: core-backend
spec:
  selector:
    app: httpbin
  ports:
  - port: 80
    targetPort: 80
    name: http
EOF
            ;;
        httpbingo)
            kubectl apply -n "$namespace" -f - << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbingo
  labels:
    app: httpbingo
    version: v1
    tier: core-backend
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
        tier: core-backend
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
---
apiVersion: v1
kind: Service
metadata:
  name: httpbingo
  labels:
    app: httpbingo
    tier: core-backend
spec:
  selector:
    app: httpbingo
  ports:
  - port: 8080
    targetPort: 8080
    name: http
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
            return 200 '{"service": "nginx", "namespace": "$namespace", "path": "\$uri", "method": "\$request_method", "headers": \$http_host, "backend_tier": "core"}';
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
  labels:
    app: nginx
    version: v1
    tier: core-backend
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
        tier: core-backend
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
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
    tier: core-backend
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    name: http
EOF
            ;;
        echo)
            kubectl apply -n "$namespace" -f - << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echoserver
  labels:
    app: echoserver
    version: v1
    tier: core-backend
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
        tier: core-backend
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
---
apiVersion: v1
kind: Service
metadata:
  name: echoserver
  labels:
    app: echoserver
    tier: core-backend
spec:
  selector:
    app: echoserver
  ports:
  - port: 8080
    targetPort: 8080
    name: http
EOF
            ;;
    esac
}

# Setup enterprise demo environment
setup_environment() {
    log_header "Setting Up Enterprise Gateway Demo Environment"

    # Create namespaces
    for namespace in "${NAMESPACES[@]}"; do
        log_info "Creating namespace: $namespace"
        kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -

        # Label namespace for service mesh injection
        log_info "Labeling namespace $namespace for service mesh injection"
        kubectl label namespace "$namespace" istio-injection=enabled --overwrite
        kubectl label namespace "$namespace" tetrate.io/rev=default --overwrite

        kubectl annotate namespace "$namespace" traffic.tetrate.io/global="true" --overwrite

        # Add environment and tier labels
        local env_type=$(echo "$namespace" | cut -d'-' -f2)
        kubectl label namespace "$namespace" environment="$env_type" --overwrite
        kubectl label namespace "$namespace" architecture="multi-tier" --overwrite
        kubectl label namespace "$namespace" demo-type="enterprise-gateway" --overwrite
    done

    # Deploy core backends and business services to different namespaces
    local backend_list=("${BACKEND_NAMES[@]}")
    local business_service_list=("${BUSINESS_SERVICES[@]}")

    for i in "${!NAMESPACES[@]}"; do
        local namespace="${NAMESPACES[$i]}"
        local backend="${backend_list[$((i % ${#backend_list[@]}))]}"
        local business_service="${business_service_list[$((i % ${#business_service_list[@]}))]}"

        log_subheader "Deploying core backend $backend to $namespace"
        deploy_backend "$backend" "$namespace"

        # Wait for backend deployment to be ready
        log_info "Waiting for $backend deployment to be ready in $namespace..."
        case $backend in
            httpbin) kubectl wait --for=condition=available --timeout=300s deployment/httpbin -n "$namespace" ;;
            httpbingo) kubectl wait --for=condition=available --timeout=300s deployment/httpbingo -n "$namespace" ;;
            nginx) kubectl wait --for=condition=available --timeout=300s deployment/nginx -n "$namespace" ;;
            echo) kubectl wait --for=condition=available --timeout=300s deployment/echoserver -n "$namespace" ;;
        esac

        # Note: Business service layer will be deployed after gateway services are created
    done

    # Create TLS secrets for HTTPS demos
    create_tls_secrets

    log_success "Enterprise environment setup completed"
}

# Demo 1: Basic HTTP services through business layer
demo_basic_http_services() {
    log_header "Demo 1: Basic HTTP Services Through Business Service Layer"

    local counter=1
    for namespace in "${NAMESPACES[@]}"; do
        local env_type=$(echo "$namespace" | cut -d'-' -f2)
        local port=$((8000 + counter))
        local business_service=$(get_business_service_for_namespace "$namespace")

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
    # Enterprise HTTP exposure through business service layer
    gateway.tetrate.io/service-tier: "business-layer"
    gateway.tetrate.io/upstream-backend: "$(get_backend_for_namespace "$namespace")"
spec:
  selector:
    business-service: $business_service
  ports:
  - port: 8000
    targetPort: 9080
    name: http
EOF
)

        apply_or_show "Basic HTTP Service - $namespace (via $business_service)" "$config"
        ((counter++))
    done
}

# Get business service for namespace
get_business_service_for_namespace() {
    local namespace="$1"
    local business_service_list=("${BUSINESS_SERVICES[@]}")

    for i in "${!NAMESPACES[@]}"; do
        if [[ "${NAMESPACES[$i]}" == "$namespace" ]]; then
            echo "${business_service_list[$((i % ${#business_service_list[@]}))]}"
            return
        fi
    done
    echo "market-data-gateway"  # fallback
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

# Demo 2: HTTPS services through business layer with enhanced security
demo_https_services() {
    log_header "Demo 2: HTTPS Services Through Business Layer with Enhanced Security"

    local counter=1
    for namespace in "${NAMESPACES[@]}"; do
        local env_type=$(echo "$namespace" | cut -d'-' -f2)
        local business_service=$(get_business_service_for_namespace "$namespace")
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
    gateway.tetrate.io/tls-secret: "${business_service}-tls"
$(get_gateway_annotations_for_namespace "$namespace")
    gateway.tetrate.io/service-tier: "secure-business-layer"
    gateway.tetrate.io/upstream-backend: "$(get_backend_for_namespace "$namespace")"
    gateway.tetrate.io/cloud-annotations: |
$(echo "$cloud_annotations" | sed 's/^/      /')
spec:
  selector:
    business-service: $business_service
  ports:
  - port: 8000
    targetPort: 9080
    name: http
EOF
)

        apply_or_show "HTTPS Service - $namespace (via $business_service)" "$config"
        ((counter++))
    done
}

# Demo 3: Multi-tier API gateway with business logic routing
demo_api_gateway_routing() {
    log_header "Demo 3: Multi-Tier API Gateway with Business Logic Routing"

    local api_counter=1
    for namespace in "${NAMESPACES[@]}"; do
        local env_type=$(echo "$namespace" | cut -d'-' -f2)
        local business_service=$(get_business_service_for_namespace "$namespace")
        local backend=$(get_backend_for_namespace "$namespace")

        # Create multiple API versions per business service
        for version in "v1" "v2" "v3"; do
            local config=$(cat << EOF
apiVersion: v1
kind: Service
metadata:
  name: api-$version-service
  namespace: $namespace
  annotations:
    gateway.tetrate.io/host: "api-$env_type.$DOMAIN"
    gateway.tetrate.io/path: "/$version/$business_service"
    gateway.tetrate.io/local-path: "$(get_local_path_for_business_service_version "$business_service" "$version")"
$(get_gateway_annotations_for_namespace "$namespace")
    gateway.tetrate.io/service-tier: "api-business-layer"
    gateway.tetrate.io/business-service: "$business_service"
    gateway.tetrate.io/core-backend: "$backend"
    gateway.tetrate.io/rate-limits: |
      - dimensions:
          - remoteAddress:
              value: "*"
        limit:
          requestsPerUnit: $((100 * api_counter))
          unit: MINUTE
spec:
  selector:
    business-service: $business_service
  ports:
  - port: $((8000 + api_counter))
    targetPort: 9080
    name: http
EOF
)

            apply_or_show "API $version Service - $namespace (via $business_service → $backend)" "$config"
            ((api_counter++))
        done
    done
}

# Get local path for business service and version
get_local_path_for_business_service_version() {
    local business_service="$1"
    local version="$2"

    case $business_service in
        market-data-gateway)
            case $version in
                v1) echo "/market/quotes" ;;
                v2) echo "/market/realtime" ;;
                v3) echo "/market/analytics" ;;
            esac
            ;;
        trading-engine-proxy)
            case $version in
                v1) echo "/orders/submit" ;;
                v2) echo "/orders/status" ;;
                v3) echo "/orders/modify" ;;
            esac
            ;;
        compliance-validator)
            case $version in
                v1) echo "/compliance/check" ;;
                v2) echo "/compliance/validate" ;;
                v3) echo "/compliance/audit" ;;
            esac
            ;;
        settlement-processor)
            case $version in
                v1) echo "/settlement/initiate" ;;
                v2) echo "/settlement/status" ;;
                v3) echo "/settlement/confirm" ;;
            esac
            ;;
    esac
}

# Demo 4: Enterprise authentication services
demo_authentication_services() {
    log_header "Demo 4: Enterprise Authentication Services Through Business Layer"

    # JWT Authentication for production environments
    for namespace in "${NAMESPACES[@]}"; do
        local env_type=$(echo "$namespace" | cut -d'-' -f2)
        local business_service=$(get_business_service_for_namespace "$namespace")

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
    gateway.tetrate.io/tls-secret: "${business_service}-tls"
    gateway.tetrate.io/path: "/secure"
$(get_gateway_annotations_for_namespace "$namespace")
    gateway.tetrate.io/service-tier: "authenticated-business-layer"
    gateway.tetrate.io/business-service: "$business_service"
    gateway.tetrate.io/jwt-issuers: |
      - issuer: "https://accounts.google.com"
        jwksUri: "https://www.googleapis.com/oauth2/v3/certs"
      - issuer: "https://keycloak.alder.dogfood.gcp.sandbox.tetrate.io/realms/tetrate"
        jwksUri: "https://keycloak.alder.dogfood.gcp.sandbox.tetrate.io/realms/tetrate/protocol/openid-connect/certs"
spec:
  selector:
    business-service: $business_service
  ports:
  - port: 8000
    targetPort: 9080
    name: http
EOF
)

            apply_or_show "JWT Auth Service - $namespace (via $business_service)" "$config"
        fi

        # OIDC Authentication for development environments
        if [[ "$env_type" == "dev" || "$env_type" == "test" ]]; then
            # Create OIDC secret
            kubectl create secret generic oauth-client-secret-$env_type \
                --from-literal=istio_generic_secret=oidc-client-secret-enterprise123 \
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
    gateway.tetrate.io/tls-secret: "${business_service}-tls"
    gateway.tetrate.io/path: "/app"
$(get_gateway_annotations_for_namespace "$namespace")
    gateway.tetrate.io/service-tier: "oidc-business-layer"
    gateway.tetrate.io/business-service: "$business_service"
    gateway.tetrate.io/oidc-enabled: "true"
    gateway.tetrate.io/oidc-config: |
      grantType: "AUTHORIZATION_CODE"
      clientId: "client-enterprise-auth"
      clientTokenSecret: "oauth-client-secret-$env_type"
      redirectUri: "https://oidc-$env_type.$DOMAIN/callback"
      provider:
        issuer: "https://keycloak.alder.dogfood.gcp.sandbox.tetrate.io/realms/tetrate"
        authorizationEndpoint: "https://keycloak.alder.dogfood.gcp.sandbox.tetrate.io/realms/tetrate/protocol/openid-connect/auth"
        tokenEndpoint: "https://keycloak.alder.dogfood.gcp.sandbox.tetrate.io/realms/tetrate/protocol/openid-connect/token"
        jwksUri: "https://keycloak.alder.dogfood.gcp.sandbox.tetrate.io/realms/tetrate/protocol/openid-connect/certs"
spec:
  selector:
    business-service: $business_service
  ports:
  - port: 8000
    targetPort: 9080
    name: http
EOF
)

            apply_or_show "OIDC Auth Service - $namespace (via $business_service)" "$config"
        fi
    done
}

# Demo 5: WAF protection with business logic validation
demo_waf_protection() {
    log_header "Demo 5: WAF Protection with Business Logic Validation"

    local waf_counter=1
    for namespace in "${NAMESPACES[@]}"; do
        local env_type=$(echo "$namespace" | cut -d'-' -f2)
        local business_service=$(get_business_service_for_namespace "$namespace")

        # Different WAF configurations based on environment and business service
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
                local waf_config="SecRuleEngine DetectionOnly\\nSecDebugLogLevel 5"
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
    gateway.tetrate.io/service-tier: "waf-business-layer"
    gateway.tetrate.io/business-service: "$business_service"
    gateway.tetrate.io/waf-enabled: "true"
    gateway.tetrate.io/custom-config: |
      waf:
        rules:
          - "$waf_config"
        businessLogicValidation: true
        upstreamValidation: "$business_service"
spec:
  selector:
    business-service: $business_service
  ports:
  - port: $((9000 + waf_counter))
    targetPort: 9080
    name: http
EOF
)

        apply_or_show "WAF Protection Service - $namespace (via $business_service, $env_type rules)" "$config"
        ((waf_counter++))
    done
}

# Demo 6: Cross-environment business service communication
demo_cross_environment_services() {
    log_header "Demo 6: Cross-Environment Business Service Communication"

    # Create inter-environment communication patterns through business services
    for i in "${!NAMESPACES[@]}"; do
        local source_namespace="${NAMESPACES[$i]}"
        local source_env=$(echo "$source_namespace" | cut -d'-' -f2)
        local target_namespace="${NAMESPACES[$(((i + 1) % ${#NAMESPACES[@]}))]}"
        local target_env=$(echo "$target_namespace" | cut -d'-' -f2)
        local business_service=$(get_business_service_for_namespace "$source_namespace")

        local config=$(cat << EOF
apiVersion: v1
kind: Service
metadata:
  name: cross-env-service
  namespace: $source_namespace
  annotations:
    gateway.tetrate.io/host: "cross-$source_env-to-$target_env.$DOMAIN"
    gateway.tetrate.io/protocol: "HTTPS"
    gateway.tetrate.io/tls-secret: "${business_service}-tls"
    gateway.tetrate.io/path: "/cross-env"
$(get_gateway_annotations_for_namespace "$source_namespace")
    gateway.tetrate.io/service-tier: "cross-env-business-layer"
    gateway.tetrate.io/source-business-service: "$business_service"
    gateway.tetrate.io/target-environment: "$target_env"
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
        - "x-business-service"
        - "x-env-source"
        - "x-env-target"
        - "x-trace-id"
      maxAge: "86400s"
      allowCredentials: true
spec:
  selector:
    business-service: $business_service
  ports:
  - port: 8000
    targetPort: 9080
    name: http
EOF
)

        apply_or_show "Cross-Environment Service - $source_env to $target_env (via $business_service)" "$config"
    done
}

# Demo 7: Load balancing with business service intelligence
demo_load_balancing() {
    log_header "Demo 7: Load Balancing with Business Service Intelligence"

    # Create services with different load balancing strategies
    local strategies=("round_robin" "least_conn" "random" "hash")

    for i in "${!NAMESPACES[@]}"; do
        local namespace="${NAMESPACES[$i]}"
        local env_type=$(echo "$namespace" | cut -d'-' -f2)
        local business_service=$(get_business_service_for_namespace "$namespace")
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
    gateway.tetrate.io/tls-secret: "${business_service}-tls"
    gateway.tetrate.io/path: "/lb-test"
$(get_gateway_annotations_for_namespace "$namespace")
    gateway.tetrate.io/service-tier: "lb-business-layer"
    gateway.tetrate.io/business-service: "$business_service"
    gateway.tetrate.io/load-balancer: "$strategy"
    gateway.tetrate.io/business-logic-lb: "true"
    gateway.tetrate.io/health-check: |
      path: "/health"
      interval: "30s"
      timeout: "5s"
      healthyThreshold: 2
      unhealthyThreshold: 3
      businessServiceHealth: true
spec:
  selector:
    business-service: $business_service
  ports:
  - port: 8000
    targetPort: 9080
    name: http
EOF
)

        apply_or_show "Load Balancing Service - $namespace ($strategy via $business_service)" "$config"
    done
}

# Deploy business services after all gateway services are created
deploy_all_business_services() {
    log_header "Deploying Business Service Layer (Giraffe Services)"

    for i in "${!NAMESPACES[@]}"; do
        local namespace="${NAMESPACES[$i]}"
        local business_service="${BUSINESS_SERVICES[$((i % ${#BUSINESS_SERVICES[@]}))]}"

        log_subheader "Deploying business service $business_service to $namespace"
        deploy_business_service "$business_service" "$namespace"

        # Wait for business service deployment to be ready
        log_info "Waiting for $business_service deployment to be ready in $namespace..."
        kubectl wait --for=condition=available --timeout=300s deployment/"$business_service" -n "$namespace"
    done

    log_success "All business services deployed successfully"
}

# Demo 8: Multi-protocol services with business layer
demo_multi_protocol() {
    log_header "Demo 8: Multi-Protocol Services Through Business Layer (HTTP/HTTPS/Redirects)"

    for namespace in "${NAMESPACES[@]}"; do
        local env_type=$(echo "$namespace" | cut -d'-' -f2)
        local business_service=$(get_business_service_for_namespace "$namespace")

        # HTTP service through business layer
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
    gateway.tetrate.io/service-tier: "multi-protocol-business-layer"
    gateway.tetrate.io/business-service: "$business_service"
spec:
  selector:
    business-service: $business_service
  ports:
  - port: 8000
    targetPort: 9080
    name: http
EOF
)

        # HTTPS service with redirect through business layer
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
    gateway.tetrate.io/tls-secret: "${business_service}-tls"
    gateway.tetrate.io/https-redirect: "true"
    gateway.tetrate.io/http-port: "8080"
    gateway.tetrate.io/https-redirect-port: "8443"
$(get_gateway_annotations_for_namespace "$namespace")
    gateway.tetrate.io/service-tier: "secure-multi-protocol-business-layer"
    gateway.tetrate.io/business-service: "$business_service"
spec:
  selector:
    business-service: $business_service
  ports:
  - port: 8000
    targetPort: 9080
    name: http
EOF
)

        apply_or_show "Multi-Protocol HTTP Service - $namespace (via $business_service)" "$http_config"
        apply_or_show "Multi-Protocol HTTPS Service - $namespace (via $business_service)" "$https_config"
    done
}

# Show demo status with business service details
show_status() {
    log_header "Enterprise Gateway Demo Status Check"

    for namespace in "${NAMESPACES[@]}"; do
        local env_type=$(echo "$namespace" | cut -d'-' -f2)
        local backend=$(get_backend_for_namespace "$namespace")
        local business_service=$(get_business_service_for_namespace "$namespace")

        log_subheader "Namespace: $namespace"
        echo "  Business Service: $business_service"
        echo "  Core Backend: $backend"
        echo "  Architecture: Business Layer → Core Backend"

        log_info "All Services:"
        kubectl get services -n "$namespace" -o wide

        echo ""
        log_info "Business Layer Services (Giraffe):"
        kubectl get deployments -n "$namespace" -l tier=business-service -o wide

        echo ""
        log_info "Core Backend Services:"
        kubectl get deployments -n "$namespace" -l tier=core-backend -o wide

        echo ""
        log_info "Gateway-enabled services:"
        kubectl get services -n "$namespace" -o jsonpath='{range .items[*]}{@.metadata.name}{"\t"}{@.metadata.annotations.gateway\.tetrate\.io/host}{"\t"}{@.metadata.annotations.gateway\.tetrate\.io/protocol}{"\t"}{@.metadata.annotations.gateway\.tetrate\.io/service-tier}{"\n"}{end}' | column -t

        echo ""
        log_info "Pods status:"
        kubectl get pods -n "$namespace"
        echo ""
    done
}

# Generate comprehensive test commands for multi-tier architecture
generate_test_commands() {
    log_header "Enterprise Multi-Tier Architecture Test Commands"

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

    # Generate test commands for each environment and business service
    for namespace in "${NAMESPACES[@]}"; do
        local env_type=$(echo "$namespace" | cut -d'-' -f2)
        local business_service=$(get_business_service_for_namespace "$namespace")
        local backend=$(get_backend_for_namespace "$namespace")

        log_subheader "Test Commands for $env_type Environment"
        echo "Business Service: $business_service → Core Backend: $backend"
        echo ""

        echo "# Basic HTTP Service (through business layer)"
        echo "curl -H \"Host: $env_type.$DOMAIN\" http://$gateway_ip/"
        echo "# Response includes business service metadata and backend data"
        echo ""

        echo "# HTTPS Service (through business layer)"
        echo "curl -k -H \"Host: secure-$env_type.$DOMAIN\" https://$gateway_ip/"
        echo ""

        echo "# API Gateway (business service routing)"
        echo "curl -H \"Host: api-$env_type.$DOMAIN\" http://$gateway_ip/v1/$business_service"
        echo "curl -H \"Host: api-$env_type.$DOMAIN\" http://$gateway_ip/v2/$business_service"
        echo "curl -H \"Host: api-$env_type.$DOMAIN\" http://$gateway_ip/v3/$business_service"
        echo ""

        if [[ "$env_type" == "prod" || "$env_type" == "staging" ]]; then
            echo "# JWT Authentication (through business layer)"
            echo "curl -k -H \"Host: auth-$env_type.$DOMAIN\" https://$gateway_ip/secure"
            echo "# With token: curl -k -H \"Host: auth-$env_type.$DOMAIN\" -H \"Authorization: Bearer TOKEN\" https://$gateway_ip/secure"
            echo ""
        fi

        if [[ "$env_type" == "dev" || "$env_type" == "test" ]]; then
            echo "# OIDC Authentication (through business layer)"
            echo "curl -k -H \"Host: oidc-$env_type.$DOMAIN\" https://$gateway_ip/app"
            echo ""
        fi

        echo "# WAF Protection (business logic validation)"
        echo "curl -H \"Host: waf-$env_type.$DOMAIN\" http://$gateway_ip/$(get_waf_path_for_env "$env_type")"
        echo "# Test attack: curl -H \"Host: waf-$env_type.$DOMAIN\" \"http://$gateway_ip/$(get_waf_path_for_env "$env_type")?test=<script>alert('xss')</script>\""
        echo ""

        echo "# Cross-Environment Communication (business service to business service)"
        local next_env=$(get_next_env "$env_type")
        echo "curl -k -H \"Host: cross-$env_type-to-$next_env.$DOMAIN\" https://$gateway_ip/cross-env"
        echo ""

        echo "# Load Balancing (with business service intelligence)"
        echo "curl -k -H \"Host: lb-$env_type.$DOMAIN\" https://$gateway_ip/lb-test"
        echo ""

        echo "# Multi-Protocol Services (through business layer)"
        echo "curl -H \"Host: multi-http-$env_type.$DOMAIN\" http://$gateway_ip/"
        echo "curl -k -H \"Host: multi-https-$env_type.$DOMAIN\" https://$gateway_ip/"
        echo ""

        echo "---"
        echo ""
    done

    log_info "Enterprise Testing Scenarios:"
    echo ""

    echo "# Business Service Performance Test (multi-tier latency)"
    echo "for env in prod staging dev test; do"
    echo "  echo \"Testing \$env business service performance:\""
    echo "  time curl -s -H \"Host: \$env.$DOMAIN\" http://$gateway_ip/ | jq ."
    echo "done"
    echo ""

    echo "# Business Service → Backend Chain Test"
    echo "for env in prod staging dev test; do"
    echo "  echo \"Testing \$env full chain (Business Service → Backend):\""
    echo "  curl -s -H \"Host: \$env.$DOMAIN\" -H \"X-Debug-Chain: true\" http://$gateway_ip/ | jq ."
    echo "done"
    echo ""

    echo "# Multi-tier Rate Limiting Test"
    echo "for env in prod staging dev test; do"
    echo "  for i in {1..20}; do"
    echo "    curl -s -o /dev/null -w \"%{http_code}\\n\" -H \"Host: api-\\$env.$DOMAIN\" http://$gateway_ip/v1/$(get_business_service_for_namespace "${BASE_NAMESPACE}-prod")"
    echo "  done"
    echo "done"
    echo ""

    echo "# Business Service Error Simulation Test"
    echo "for i in {1..50}; do"
    echo "  curl -s -o /dev/null -w \"%{http_code}\\n\" -H \"Host: dev.$DOMAIN\" http://$gateway_ip/"
    echo "done | sort | uniq -c"
    echo ""

    if [[ "$gateway_ip" == "GATEWAY_IP" ]]; then
        log_warning "Replace 'GATEWAY_IP' with your actual gateway IP address."
        log_info "Find gateway IP with: kubectl get svc -A | grep -i gateway"
    fi

    log_info "Architecture Notes:"
    echo "• Traffic flows: Gateway → Business Service (Giraffe) → Core Backend"
    echo "• Business Services add processing delays, error simulation, and custom metadata"
    echo "• Core Backends provide final responses (httpbin, httpbingo, nginx, echo)"
    echo "• All trace headers are propagated through the entire chain"
    echo "• Business service responses include upstream backend data"
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
