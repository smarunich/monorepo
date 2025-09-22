#!/bin/bash

# Helper script to automatically find gateway IP and run advanced tests
# This script auto-discovers the gateway IP and runs comprehensive tests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DOMAIN="demo.example.com"
BASE_NAMESPACE="dynabank"
GATEWAY_IPS=""
CONTINUOUS_MODE=false
ITERATIONS=""

# Gateway mappings (bash 3.2 compatible)
GATEWAY_ENVIRONMENTS=()
GATEWAY_IPS_ARRAY=()

# Helper function to add gateway mapping
add_gateway_mapping() {
    local env="$1"
    local ip="$2"
    GATEWAY_ENVIRONMENTS+=("$env")
    GATEWAY_IPS_ARRAY+=("$ip")
}

# Helper function to get gateway IP for environment
get_gateway_ip() {
    local env="$1"
    for i in "${!GATEWAY_ENVIRONMENTS[@]}"; do
        if [[ "${GATEWAY_ENVIRONMENTS[$i]}" == "$env" ]]; then
            echo "${GATEWAY_IPS_ARRAY[$i]}"
            return 0
        fi
    done
    return 1
}

# Helper function to get all environments with gateways
get_gateway_environments() {
    printf '%s\n' "${GATEWAY_ENVIRONMENTS[@]}"
}

# Print usage
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -d, --domain <domain>      Base domain (default: demo.example.com)"
    echo "  -n, --namespace <prefix>   Base namespace prefix (default: dynabank)"
    echo "  -c, --continuous           Run tests continuously"
    echo "  -m, --max <iterations>     Maximum iterations for continuous mode"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                         # Auto-detect gateway and run tests"
    echo "  $0 -n mycompany -d api.company.com"
    echo "  $0 --continuous --max 10   # Run 10 continuous iterations"
    echo ""
    echo "This helper script:"
    echo "  • Auto-discovers gateway IP address"
    echo "  • Validates gateway accessibility"
    echo "  • Runs comprehensive tests on all demo configurations"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--domain)
            DOMAIN="$2"
            shift 2
            ;;
        -n|--namespace)
            BASE_NAMESPACE="$2"
            shift 2
            ;;
        -c|--continuous)
            CONTINUOUS_MODE=true
            shift
            ;;
        -m|--max)
            ITERATIONS="--max $2"
            shift 2
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

# Auto-discover multiple split gateway IPs
discover_split_gateways() {
    log_header "Auto-Discovering Split Gateway IP Addresses"

    # Split gateway service patterns for the demo
    local environments=("prod" "staging" "dev" "test")
    local gateway_namespaces=("tetrate-system" "istio-system" "gateway-system")
    local found_gateways=0

    log_info "Searching for split gateway services for namespace: ${BASE_NAMESPACE}..."

    for ns in "${gateway_namespaces[@]}"; do
        log_info "Checking namespace: $ns"

        for env in "${environments[@]}"; do
            local gateway_name="${BASE_NAMESPACE}-${env}-gateway"

            if kubectl get service "$gateway_name" -n "$ns" &>/dev/null; then
                log_info "Found split gateway service: $gateway_name in namespace $ns"

                # Try to get external IP
                local external_ip=$(kubectl get service "$gateway_name" -n "$ns" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
                if [[ -n "$external_ip" && "$external_ip" != "null" ]]; then
                    add_gateway_mapping "$env" "$external_ip"
                    log_success "External IP found for $env: $external_ip"
                    ((found_gateways++))
                    continue
                fi

                # Try to get external hostname
                local external_hostname=$(kubectl get service "$gateway_name" -n "$ns" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
                if [[ -n "$external_hostname" && "$external_hostname" != "null" ]]; then
                    add_gateway_mapping "$env" "$external_hostname"
                    log_success "External hostname found for $env: $external_hostname"
                    ((found_gateways++))
                    continue
                fi

                # Fallback to cluster IP
                local cluster_ip=$(kubectl get service "$gateway_name" -n "$ns" -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
                if [[ -n "$cluster_ip" && "$cluster_ip" != "null" ]]; then
                    add_gateway_mapping "$env" "$cluster_ip"
                    log_warning "Using cluster IP for $env (internal access only): $cluster_ip"
                    ((found_gateways++))
                fi
            fi
        done
    done

    if [[ $found_gateways -eq 0 ]]; then
        return 1
    fi

    log_success "Found $found_gateways split gateway(s)"
    return 0
}

# Validate multiple gateway accessibility
validate_split_gateways() {
    log_header "Validating Split Gateway Accessibility"

    local total_gateways=0
    local accessible_gateways=0

    # Test basic connectivity on common ports
    local ports=(80 443)

    for i in "${!GATEWAY_ENVIRONMENTS[@]}"; do
        local env="${GATEWAY_ENVIRONMENTS[$i]}"
        local gateway_ip="${GATEWAY_IPS_ARRAY[$i]}"
        ((total_gateways++))

        log_info "Testing connectivity to $env gateway: $gateway_ip..."

        local accessible_ports=()
        for port in "${ports[@]}"; do
            if timeout 3 bash -c "</dev/tcp/$gateway_ip/$port" &>/dev/null; then
                accessible_ports+=($port)
            fi
        done

        if [[ ${#accessible_ports[@]} -gt 0 ]]; then
            log_success "$env gateway ($gateway_ip) - accessible ports: ${accessible_ports[*]}"
            ((accessible_gateways++))
        else
            log_warning "$env gateway ($gateway_ip) - no accessible ports"
        fi
    done

    if [[ $accessible_gateways -eq 0 ]]; then
        log_error "No gateways are accessible"
        return 1
    fi

    log_success "Gateway validation completed. $accessible_gateways/$total_gateways gateways accessible"
    return 0
}

# Check if demo resources exist
check_demo_resources() {
    log_header "Checking Demo Resources"

    local namespaces=("${BASE_NAMESPACE}-prod" "${BASE_NAMESPACE}-staging" "${BASE_NAMESPACE}-dev" "${BASE_NAMESPACE}-test")
    local missing_namespaces=()

    for ns in "${namespaces[@]}"; do
        if kubectl get namespace "$ns" &>/dev/null; then
            log_success "Namespace $ns exists"

            # Check if there are services in the namespace
            local service_count=$(kubectl get services -n "$ns" --no-headers 2>/dev/null | wc -l)
            log_info "Services in $ns: $service_count"
        else
            missing_namespaces+=("$ns")
            log_warning "Namespace $ns does not exist"
        fi
    done

    if [[ ${#missing_namespaces[@]} -gt 0 ]]; then
        log_warning "Missing namespaces: ${missing_namespaces[*]}"
        log_info "Run the advanced-demo.sh script first to create the demo environment"
        return 1
    fi

    log_success "All demo namespaces exist and contain resources"
    return 0
}

# Run the comprehensive tests
run_tests() {
    log_header "Running Comprehensive Gateway Tests"

    local test_script="./test-advanced-demo-gateways.sh"

    if [[ ! -f "$test_script" ]]; then
        log_error "Test script not found: $test_script"
        log_info "Make sure the test-advanced-demo-gateways.sh script is in the current directory"
        exit 1
    fi

    if [[ ! -x "$test_script" ]]; then
        log_info "Making test script executable..."
        chmod +x "$test_script"
    fi

    # Test each environment with its specific gateway
    for i in "${!GATEWAY_ENVIRONMENTS[@]}"; do
        local env="${GATEWAY_ENVIRONMENTS[$i]}"
        local gateway_ip="${GATEWAY_IPS_ARRAY[$i]}"

        log_header "Testing Environment: $env (Gateway: $gateway_ip)"

        # Build command arguments for this environment
        local cmd_args="-i $gateway_ip -d $DOMAIN -n $BASE_NAMESPACE -e $env"

        if [[ "$CONTINUOUS_MODE" == "true" ]]; then
            cmd_args="$cmd_args --continuous"
        fi

        if [[ -n "$ITERATIONS" ]]; then
            cmd_args="$cmd_args $ITERATIONS"
        fi

        log_info "Running: $test_script $cmd_args"
        echo ""

        # Execute the test script for this environment
        $test_script $cmd_args

        echo ""
        log_info "Completed testing for environment: $env"
        echo ""
    done
}

# Show summary information
show_summary() {
    log_header "Advanced Gateway Testing Summary"

    echo "Configuration:"
    echo "  • Split Gateways:"
    for i in "${!GATEWAY_ENVIRONMENTS[@]}"; do
        local env="${GATEWAY_ENVIRONMENTS[$i]}"
        local gateway_ip="${GATEWAY_IPS_ARRAY[$i]}"
        echo "    - $env: $gateway_ip"
    done
    echo "  • Domain: $DOMAIN"
    echo "  • Base Namespace: $BASE_NAMESPACE"
    echo "  • Continuous Mode: $CONTINUOUS_MODE"
    echo ""

    echo "What was tested:"
    echo "  • 4 Environments: ${BASE_NAMESPACE}-prod, ${BASE_NAMESPACE}-staging, ${BASE_NAMESPACE}-dev, ${BASE_NAMESPACE}-test"
    echo "  • 4 Split Gateways: One dedicated gateway per environment"
    echo "  • 4 Backend Types: httpbin, httpbingo, nginx, echo"
    echo "  • 100+ Test Cases per environment covering:"
    echo "    - Basic HTTP/HTTPS services"
    echo "    - API gateway routing (multi-version)"
    echo "    - Authentication (JWT/OIDC)"
    echo "    - WAF protection with environment-specific rules"
    echo "    - Cross-environment communication"
    echo "    - Load balancing strategies"
    echo "    - Multi-protocol services"
    echo "    - Backend-specific functionality"
    echo "    - Rate limiting"
    echo "    - HTTP methods testing"
    echo "    - Stress testing"
    echo "    - Error conditions and edge cases"
    echo ""

    echo "Next steps:"
    echo "  • Review test results above for each environment"
    echo "  • Check individual gateway logs for any errors:"
    for i in "${!GATEWAY_ENVIRONMENTS[@]}"; do
        local env="${GATEWAY_ENVIRONMENTS[$i]}"
        echo "    kubectl logs -n tetrate-system -l app=${BASE_NAMESPACE}-${env}-gateway"
    done
    echo "  • Monitor gateway metrics and performance"
    echo "  • Run continuous tests for ongoing validation"
}

# Main execution
main() {
    log_header "Advanced Gateway Test Runner"

    # Check prerequisites
    log_info "Checking prerequisites..."

    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed or not in PATH"
        exit 1
    fi

    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi

    # Auto-discover split gateway IPs
    if ! discover_split_gateways; then
        log_error "Could not auto-discover split gateway IP addresses"
        log_info "Please check that split gateway services are running in your cluster"
        log_info "Expected gateway services: ${BASE_NAMESPACE}-prod-gateway, ${BASE_NAMESPACE}-staging-gateway, etc."
        log_info "You can also run the test script manually with: ./test-advanced-demo-gateways.sh -i <gateway-ip> -e <env>"
        exit 1
    fi

    # Validate split gateway accessibility
    if ! validate_split_gateways; then
        log_error "Split gateway validation failed"
        log_info "Some gateways may not be accessible or properly configured"
        log_info "Proceeding with tests anyway..."
    fi

    # Check if demo resources exist
    if ! check_demo_resources; then
        log_error "Demo resources are missing"
        echo ""
        log_info "To create demo resources, run:"
        log_info "  ./advanced-demo.sh -n $BASE_NAMESPACE -d $DOMAIN"
        echo ""
        read -p "Do you want to continue with tests anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Exiting. Create demo resources first."
            exit 1
        fi
    fi

    # Run the tests
    run_tests

    # Show summary
    show_summary
}

# Run main function
main "$@"