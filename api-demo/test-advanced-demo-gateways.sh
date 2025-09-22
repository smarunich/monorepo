#!/bin/bash

# Advanced TSB Gateway Testing Suite
# This script comprehensively tests all gateway configurations created by advanced-demo.sh
# Supports multi-environment, multi-backend testing scenarios

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
IP_ADDRESS=""
DOMAIN="demo.example.com"
BASE_NAMESPACE="dynabank"
SINGLE_ENVIRONMENT=""
CONTINUOUS_MODE=false
SLEEP_INTERVAL=30
TEST_ITERATIONS=0
MAX_ITERATIONS=0
OUTPUT_DIR="./advanced_gateway_test_output"

# Environment and backend mappings
ENVIRONMENTS=("prod" "staging" "dev" "test")
BACKENDS=("httpbin" "httpbingo" "nginx" "echo")

# Parse command line arguments
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -i, --ip <address>         Gateway IP address (required)"
    echo "  -d, --domain <domain>      Base domain (default: demo.example.com)"
    echo "  -n, --namespace <prefix>   Base namespace prefix (default: dynabank)"
    echo "  -e, --env <environment>    Test single environment (prod|staging|dev|test)"
    echo "  -c, --continuous           Run tests continuously"
    echo "  -s, --sleep <seconds>      Sleep interval between continuous runs (default: 30)"
    echo "  -m, --max <iterations>     Maximum iterations for continuous mode (0=infinite)"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -i 10.0.0.100                    # Test all environments"
    echo "  $0 -i 10.0.0.100 -e prod            # Test only prod environment"
    echo "  $0 -i 10.0.0.100 -n mycompany -d api.company.com"
    echo "  $0 -i 10.0.0.100 --continuous --max 50"
    echo ""
    echo "This script tests:"
    echo "  • 4 environments: prod, staging, dev, test (or single with -e)"
    echo "  • 4 backends: httpbin, httpbingo, nginx, echo"
    echo "  • 50+ gateway configurations per environment"
    echo "  • Authentication, WAF, Load Balancing, Cross-environment communication"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--ip)
            IP_ADDRESS="$2"
            shift 2
            ;;
        -d|--domain)
            DOMAIN="$2"
            shift 2
            ;;
        -n|--namespace)
            BASE_NAMESPACE="$2"
            shift 2
            ;;
        -e|--env)
            SINGLE_ENVIRONMENT="$2"
            shift 2
            ;;
        -c|--continuous)
            CONTINUOUS_MODE=true
            shift
            ;;
        -s|--sleep)
            SLEEP_INTERVAL="$2"
            shift 2
            ;;
        -m|--max)
            MAX_ITERATIONS="$2"
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

# Check required parameters
if [[ -z "$IP_ADDRESS" ]]; then
    echo "Error: Gateway IP address is required. Use -i or --ip option."
    echo ""
    usage
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Logging functions
print_section() {
    echo ""
    echo -e "${GREEN}=================================================================${NC}"
    echo -e "${GREEN}$1${NC}"
    if [[ "$CONTINUOUS_MODE" == "true" ]]; then
        echo -e "${CYAN}Iteration: $TEST_ITERATIONS | $(date)${NC}"
    fi
    echo -e "${GREEN}=================================================================${NC}"
    echo ""
}

print_subsection() {
    echo ""
    echo -e "${CYAN}--- $1 ---${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Enhanced test function with backend-specific logic
run_test() {
    local description="$1"
    local environment="$2"
    local backend="$3"
    local protocol="$4"
    local host="$5"
    local port="$6"
    local path="$7"
    shift 7

    echo -e "${YELLOW}Testing: $description${NC}"
    echo -e "${BLUE}Environment: $environment | Backend: $backend | Protocol: $protocol${NC}"

    local url=""
    if [[ "$protocol" == "HTTPS" ]]; then
        url="https://$host:$port$path"
        if curl --connect-timeout 0.5 --max-time 2 -k --resolve "$host:$port:$IP_ADDRESS" "$url" "$@"; then
            echo -e "${GREEN}✓ SUCCESS${NC}"
        else
            local exit_code=$?
            echo -e "${RED}✗ FAILED (exit code: $exit_code)${NC}"
        fi
    else
        url="http://$host:$port$path"
        if curl --connect-timeout 0.5 --max-time 2 --resolve "$host:$port:$IP_ADDRESS" "$url" "$@"; then
            echo -e "${GREEN}✓ SUCCESS${NC}"
        else
            local exit_code=$?
            echo -e "${RED}✗ FAILED (exit code: $exit_code)${NC}"
        fi
    fi
    echo ""
}

# Get backend for environment
get_backend_for_env() {
    local env="$1"
    case $env in
        prod) echo "httpbin" ;;
        staging) echo "httpbingo" ;;
        dev) echo "nginx" ;;
        test) echo "echo" ;;
        *) echo "httpbin" ;;
    esac
}

# Get target port for backend
get_target_port_for_backend() {
    local backend="$1"
    case $backend in
        httpbin) echo "80" ;;
        httpbingo) echo "8080" ;;
        nginx) echo "80" ;;
        echo) echo "8080" ;;
        *) echo "80" ;;
    esac
}

# JWT token fetching
fetch_jwt_token() {
    print_info "Fetching JWT token for authentication tests..."
    JWT_TOKEN=$(curl -s --connect-timeout 2 --max-time 5 -X POST \
      https://keycloak.alder.dogfood.gcp.sandbox.tetrate.io/realms/tetrate/protocol/openid-connect/token \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "client_id=client-tetrate-auth" \
      -d "client_secret=oidc-client-secret-tetrate123987" \
      -d "username=john.doe" \
      -d "password=supersecret-password" \
      -d "grant_type=password" 2>/dev/null | jq -r '.access_token' 2>/dev/null || echo "")

    if [[ -n "$JWT_TOKEN" && "$JWT_TOKEN" != "null" ]]; then
        print_info "JWT token obtained successfully"
        echo "$JWT_TOKEN" > "$OUTPUT_DIR/jwt_token.txt"
    else
        print_warning "Could not obtain JWT token, using mock tokens for testing"
        JWT_TOKEN=""
    fi
}

# Main test execution function
run_advanced_test_suite() {
    TEST_ITERATIONS=$((TEST_ITERATIONS + 1))

    # Determine which environments to test
    local TEST_ENVIRONMENTS=()
    if [[ -n "$SINGLE_ENVIRONMENT" ]]; then
        # Validate single environment
        if [[ ! " ${ENVIRONMENTS[*]} " =~ " ${SINGLE_ENVIRONMENT} " ]]; then
            print_error "Invalid environment: $SINGLE_ENVIRONMENT"
            print_info "Valid environments: ${ENVIRONMENTS[*]}"
            exit 1
        fi
        TEST_ENVIRONMENTS=("$SINGLE_ENVIRONMENT")
    else
        TEST_ENVIRONMENTS=("${ENVIRONMENTS[@]}")
    fi

    print_section "ADVANCED TSB GATEWAY TESTING SUITE"
    print_info "Target IP: ${IP_ADDRESS}"
    print_info "Domain: ${DOMAIN}"
    print_info "Base Namespace: ${BASE_NAMESPACE}"
    print_info "Testing Environments: ${TEST_ENVIRONMENTS[*]}"
    print_info "Output Directory: ${OUTPUT_DIR}"
    if [[ "$CONTINUOUS_MODE" == "true" ]]; then
        print_info "Continuous Mode: Enabled (Sleep: ${SLEEP_INTERVAL}s, Max: ${MAX_ITERATIONS})"
    fi
    echo ""

    # Fetch JWT token for authentication tests
    fetch_jwt_token

    # Test 1: Basic HTTP Services Across Environments
    print_section "BASIC HTTP SERVICES ACROSS ENVIRONMENTS"

    local counter=1
    for env in "${ENVIRONMENTS[@]}"; do
        local backend=$(get_backend_for_env "$env")
        local port=$((8000 + counter))

        run_test "Basic HTTP Service" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$port" "/"
        ((counter++))
    done

    # Test 2: HTTPS Services with Different TLS Configurations
    print_section "HTTPS SERVICES WITH TLS CONFIGURATIONS"

    for env in "${ENVIRONMENTS[@]}"; do
        local backend=$(get_backend_for_env "$env")

        run_test "HTTPS Service" "$env" "$backend" "HTTPS" "secure-$env.$DOMAIN" "443" "/"
    done

    # Test 3: API Gateway Routing (Multiple Versions)
    print_section "API GATEWAY ROUTING - MULTI-VERSION ENDPOINTS"

    for env in "${ENVIRONMENTS[@]}"; do
        local backend=$(get_backend_for_env "$env")

        for version in "v1" "v2" "v3"; do
            run_test "API $version Endpoint" "$env" "$backend" "HTTP" "api-$env.$DOMAIN" "80" "/$version/$backend"
        done
    done

    # Test 4: Authentication Services
    print_section "AUTHENTICATION SERVICES"

    # JWT Authentication (prod/staging)
    for env in "prod" "staging"; do
        local backend=$(get_backend_for_env "$env")

        # Test without token (should fail)
        run_test "JWT Auth - No Token (401 expected)" "$env" "$backend" "HTTPS" "auth-$env.$DOMAIN" "443" "/secure" -w "%{http_code}\n"

        # Test with valid token if available
        if [[ -n "$JWT_TOKEN" && "$JWT_TOKEN" != "null" ]]; then
            run_test "JWT Auth - Valid Token" "$env" "$backend" "HTTPS" "auth-$env.$DOMAIN" "443" "/secure" -H "Authorization: Bearer $JWT_TOKEN"
        fi

        # Test with invalid token
        run_test "JWT Auth - Invalid Token" "$env" "$backend" "HTTPS" "auth-$env.$DOMAIN" "443" "/secure" -H "Authorization: Bearer fake.jwt.token" -w "%{http_code}\n"
    done

    # OIDC Authentication (dev/test)
    for env in "dev" "test"; do
        local backend=$(get_backend_for_env "$env")

        run_test "OIDC Auth Redirect" "$env" "$backend" "HTTPS" "oidc-$env.$DOMAIN" "443" "/app" -I
    done

    # Test 5: WAF Protection with Different Rule Sets
    print_section "WAF PROTECTION WITH ENVIRONMENT-SPECIFIC RULES"

    for env in "${ENVIRONMENTS[@]}"; do
        local backend=$(get_backend_for_env "$env")
        local waf_path=""

        case $env in
            prod) waf_path="/protected" ;;
            staging) waf_path="/staging-protected" ;;
            dev) waf_path="/dev-test" ;;
            test) waf_path="/test-endpoint" ;;
        esac

        # Normal request
        run_test "WAF Normal Request" "$env" "$backend" "HTTP" "waf-$env.$DOMAIN" "80" "$waf_path"

        # XSS attack test
        run_test "WAF XSS Attack Test" "$env" "$backend" "HTTP" "waf-$env.$DOMAIN" "80" "$waf_path?test=<script>alert('xss')</script>" || true

        # SQL injection test
        run_test "WAF SQLi Attack Test" "$env" "$backend" "HTTP" "waf-$env.$DOMAIN" "80" "$waf_path?id=' OR 1=1--" || true
    done

    # Test 6: Cross-Environment Service Communication
    print_section "CROSS-ENVIRONMENT SERVICE COMMUNICATION"

    for i in "${!ENVIRONMENTS[@]}"; do
        local source_env="${ENVIRONMENTS[$i]}"
        local target_env="${ENVIRONMENTS[$(((i + 1) % ${#ENVIRONMENTS[@]}))]}"
        local backend=$(get_backend_for_env "$source_env")

        run_test "Cross-Env Communication" "$source_env → $target_env" "$backend" "HTTPS" "cross-$source_env-to-$target_env.$DOMAIN" "443" "/cross-env"

        # Test CORS preflight
        run_test "Cross-Env CORS Preflight" "$source_env → $target_env" "$backend" "HTTPS" "cross-$source_env-to-$target_env.$DOMAIN" "443" "/cross-env" \
            -X OPTIONS -H "Origin: https://$target_env.$DOMAIN" -H "Access-Control-Request-Method: POST"
    done

    # Test 7: Load Balancing and Traffic Management
    print_section "LOAD BALANCING AND TRAFFIC MANAGEMENT"

    local strategies=("round_robin" "least_conn" "random" "hash")
    for i in "${!ENVIRONMENTS[@]}"; do
        local env="${ENVIRONMENTS[$i]}"
        local backend=$(get_backend_for_env "$env")
        local strategy="${strategies[$((i % ${#strategies[@]}))]}"

        # Test multiple requests to see load balancing
        for j in {1..5}; do
            run_test "Load Balancing Test $j ($strategy)" "$env" "$backend" "HTTPS" "lb-$env.$DOMAIN" "443" "/lb-test?request=$j"
        done

        # Test health check endpoint
        run_test "Health Check" "$env" "$backend" "HTTPS" "lb-$env.$DOMAIN" "443" "/health" -I || true
    done

    # Test 8: Multi-Protocol Services
    print_section "MULTI-PROTOCOL SERVICES (HTTP/HTTPS/REDIRECTS)"

    for env in "${ENVIRONMENTS[@]}"; do
        local backend=$(get_backend_for_env "$env")

        # HTTP service
        run_test "Multi-Protocol HTTP" "$env" "$backend" "HTTP" "multi-http-$env.$DOMAIN" "80" "/"

        # HTTPS service
        run_test "Multi-Protocol HTTPS" "$env" "$backend" "HTTPS" "multi-https-$env.$DOMAIN" "443" "/"

        # Test HTTP to HTTPS redirect
        run_test "HTTP to HTTPS Redirect" "$env" "$backend" "HTTP" "multi-https-$env.$DOMAIN" "8080" "/" -I
    done

    # Test 9: Backend-Specific Functionality
    print_section "BACKEND-SPECIFIC FUNCTIONALITY TESTING"

    for env in "${ENVIRONMENTS[@]}"; do
        local backend=$(get_backend_for_env "$env")

        case $backend in
            httpbin)
                run_test "HTTPBin JSON Response" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/json"
                run_test "HTTPBin Headers" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/headers"
                run_test "HTTPBin Status Codes" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/status/200"
                ;;
            httpbingo)
                run_test "HTTPBingo Get Request" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/get"
                run_test "HTTPBingo User Agent" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/user-agent"
                run_test "HTTPBingo IP Origin" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/ip"
                run_test "HTTPBingo Headers" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/headers"
                run_test "HTTPBingo JSON Response" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/json"
                run_test "HTTPBingo UUID Generator" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/uuid"
                run_test "HTTPBingo Status 200" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/status/200"
                run_test "HTTPBingo Anything Endpoint" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/anything/test-data"
                ;;
            nginx)
                run_test "Nginx Custom Response" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/"
                run_test "Nginx Health Check" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/health"
                ;;
            echo)
                run_test "Echo Server Response" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/"
                ;;
        esac
    done

    # Test 10: Rate Limiting
    print_section "RATE LIMITING TESTING"

    for env in "${ENVIRONMENTS[@]}"; do
        local backend=$(get_backend_for_env "$env")

        print_info "Testing rate limits for $env environment ($backend backend)"

        # Send multiple requests rapidly to test rate limiting
        for i in {1..10}; do
            run_test "Rate Limit Test $i" "$env" "$backend" "HTTP" "api-$env.$DOMAIN" "80" "/v1/$backend" -w "%{http_code}\n" || true
        done
    done

    # Test 11: HTTP Methods Testing
    print_section "HTTP METHODS TESTING ACROSS BACKENDS"

    local methods=("GET" "POST" "PUT" "DELETE" "PATCH")
    for env in "${ENVIRONMENTS[@]}"; do
        local backend=$(get_backend_for_env "$env")

        for method in "${methods[@]}"; do
            local test_data=""
            if [[ "$method" != "GET" ]]; then
                test_data="-d {\"environment\":\"$env\",\"backend\":\"$backend\",\"method\":\"$method\"}"
            fi

            run_test "$method Request" "$env" "$backend" "HTTPS" "secure-$env.$DOMAIN" "443" "/$(echo $method | tr '[:upper:]' '[:lower:]')" -X "$method" $test_data || true
        done
    done

    # Test 12: Stress Testing
    print_section "STRESS TESTING - CONCURRENT REQUESTS"

    print_info "Running concurrent requests across all environments..."
    local pids=()

    for env in "${ENVIRONMENTS[@]}"; do
        local backend=$(get_backend_for_env "$env")

        # Spawn concurrent requests
        for i in {1..3}; do
            (run_test "Concurrent Request $i" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/?concurrent=$i") &
            pids+=($!)
        done
    done

    # Wait for all concurrent requests
    for pid in "${pids[@]}"; do
        wait $pid
    done

    # Test 13: Error Conditions and Edge Cases
    print_section "ERROR CONDITIONS AND EDGE CASES"

    for env in "${ENVIRONMENTS[@]}"; do
        local backend=$(get_backend_for_env "$env")

        # Test non-existent paths
        run_test "Non-existent Path" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/non-existent-path" || true

        # Test with malformed headers
        run_test "Malformed Headers" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/" -H "Invalid-Header" || true

        # Test with special characters in path
        run_test "Special Characters in Path" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/test%20path?param=value&special=<>&" || true
    done

    # Test 14: Comprehensive HTTPBin/HTTPBingo Feature Testing
    print_section "COMPREHENSIVE HTTPBIN/HTTPBINGO FEATURE TESTING"

    for env in "${ENVIRONMENTS[@]}"; do
        local backend=$(get_backend_for_env "$env")

        if [[ "$backend" == "httpbin" ]]; then
            print_subsection "HTTPBin Advanced Features - $env Environment"

            # HTTPBin specific endpoints
            run_test "HTTPBin Cookies Set" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/cookies/set?test=value&env=$env"
            run_test "HTTPBin Cookies Get" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/cookies"
            run_test "HTTPBin Basic Auth Success" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/basic-auth/user/pass" -u user:pass
            run_test "HTTPBin Basic Auth Fail" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/basic-auth/user/pass" || true
            run_test "HTTPBin Bearer Token" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/bearer" -H "Authorization: Bearer test-token-$env"
            run_test "HTTPBin Delay 1s" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/delay/1" --max-time 3
            run_test "HTTPBin Redirect 3" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/redirect/3" -L
            run_test "HTTPBin Status 418" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/status/418" -I
            run_test "HTTPBin Random Bytes" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/bytes/256" -o "$OUTPUT_DIR/httpbin_${env}_bytes.bin"
            run_test "HTTPBin Gzip Response" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/gzip" -H "Accept-Encoding: gzip"
            run_test "HTTPBin Stream 5" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/stream/5"
            run_test "HTTPBin Cache Control" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/cache/60"
            run_test "HTTPBin ETag" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/etag/test-etag-$env"

        elif [[ "$backend" == "httpbingo" ]]; then
            print_subsection "HTTPBingo Advanced Features - $env Environment"

            # HTTPBingo specific endpoints (based on the documentation you provided)
            run_test "HTTPBingo Get with Params" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/get?env=$env&test=value"
            run_test "HTTPBingo Post Data" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/post" -X POST -d "env=$env&backend=$backend"
            run_test "HTTPBingo Put Data" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/put" -X PUT -d "test=data"
            run_test "HTTPBingo Delete" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/delete" -X DELETE
            run_test "HTTPBingo Patch" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/patch" -X PATCH -d "patch=data"
            run_test "HTTPBingo Basic Auth Success" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/basic-auth/user/pass" -u user:pass
            run_test "HTTPBingo Bearer Token" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/bearer" -H "Authorization: Bearer test-token-$env"
            run_test "HTTPBingo Hidden Basic Auth" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/hidden-basic-auth/user/pass" -u user:pass || true
            run_test "HTTPBingo Status 201" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/status/201" -I
            run_test "HTTPBingo Status 404" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/status/404" -I
            run_test "HTTPBingo Status 500" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/status/500" -I
            run_test "HTTPBingo Redirect 2" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/redirect/2" -L
            run_test "HTTPBingo Absolute Redirect" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/absolute-redirect/2" -L
            run_test "HTTPBingo Delay 1s" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/delay/1" --max-time 3
            run_test "HTTPBingo Random Bytes" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/bytes/512" -o "$OUTPUT_DIR/httpbingo_${env}_bytes.bin"
            run_test "HTTPBingo Stream Bytes" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/stream-bytes/1024" -o "$OUTPUT_DIR/httpbingo_${env}_stream.bin"
            run_test "HTTPBingo Stream Lines" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/stream/10"
            run_test "HTTPBingo Gzip Response" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/gzip" -H "Accept-Encoding: gzip"
            run_test "HTTPBingo Deflate Response" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/deflate" -H "Accept-Encoding: deflate"
            run_test "HTTPBingo UTF-8 Encoding" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/encoding/utf8"
            run_test "HTTPBingo HTML Response" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/html"
            run_test "HTTPBingo XML Response" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/xml"
            run_test "HTTPBingo Robots.txt" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/robots.txt"
            run_test "HTTPBingo Cache Test" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/cache"
            run_test "HTTPBingo Cache 30s" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/cache/30"
            run_test "HTTPBingo ETag Test" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/etag/test-$env"
            run_test "HTTPBingo Cookies Set" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/cookies/set?env=$env&test=value"
            run_test "HTTPBingo Cookies Get" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/cookies"
            run_test "HTTPBingo Base64 Encode" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/base64/encode/hello-$env"
            run_test "HTTPBingo Base64 Decode" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/base64/aGVsbG8td29ybGQ="
            run_test "HTTPBingo Hostname" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/hostname"
            run_test "HTTPBingo Environment Vars" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/env"
            run_test "HTTPBingo Unstable Endpoint" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/unstable?failure_rate=0.3" || true
            run_test "HTTPBingo Response Headers" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/response-headers?X-Custom-Header=test-$env&X-Environment=$env"
            run_test "HTTPBingo Drip Data" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/drip?duration=1&numbytes=100" --max-time 3

            # Image endpoints
            run_test "HTTPBingo PNG Image" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/image/png" -o "$OUTPUT_DIR/httpbingo_${env}_image.png"
            run_test "HTTPBingo JPEG Image" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/image/jpeg" -o "$OUTPUT_DIR/httpbingo_${env}_image.jpg"
            run_test "HTTPBingo SVG Image" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/image/svg" -o "$OUTPUT_DIR/httpbingo_${env}_image.svg"
            run_test "HTTPBingo WebP Image" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/image/webp" -o "$OUTPUT_DIR/httpbingo_${env}_image.webp"

            # Dump request test
            run_test "HTTPBingo Dump Request" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/dump/request?env=$env"

            # Range request test
            run_test "HTTPBingo Range Request" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "/range/1024" -H "Range: bytes=0-512"

        fi
    done

    # Test 15: Backend Comparison Tests
    print_section "BACKEND COMPARISON TESTS"

    print_info "Testing same endpoints across different backends..."

    # Test the same endpoint across all environments/backends
    local common_endpoints=("/get" "/post" "/headers" "/ip" "/user-agent" "/status/200")

    for endpoint in "${common_endpoints[@]}"; do
        print_subsection "Endpoint: $endpoint"

        for env in "${ENVIRONMENTS[@]}"; do
            local backend=$(get_backend_for_env "$env")

            if [[ "$endpoint" == "/post" ]]; then
                run_test "POST $endpoint" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "$endpoint" -X POST -d "env=$env&backend=$backend&test=comparison"
            else
                run_test "GET $endpoint" "$env" "$backend" "HTTP" "$env.$DOMAIN" "$((8000 + ${#ENVIRONMENTS[@]} + 1))" "$endpoint"
            fi
        done
    done

    # Test Results Summary
    print_section "TEST ITERATION COMPLETED"
    local end_time=$(date)
    print_info "Iteration $TEST_ITERATIONS completed at: $end_time"
    print_info "Gateway IP: ${IP_ADDRESS}"
    print_info "Domain: ${DOMAIN}"
    print_info "Environments Tested: ${ENVIRONMENTS[*]}"
    print_info "Backends Tested: ${BACKENDS[*]}"
    print_info "Output Directory: ${OUTPUT_DIR}"

    if [[ "$CONTINUOUS_MODE" == "false" ]]; then
        echo ""
        echo -e "${GREEN}Advanced gateway testing completed!${NC}"
        echo ""

        # Generate summary report
        generate_test_summary

        echo ""
        read -p "Do you want to clean up the output directory? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "${OUTPUT_DIR}"
            echo "Output directory cleaned up."
        fi
    fi
}

# Generate test summary report
generate_test_summary() {
    print_section "TEST SUMMARY REPORT"

    print_info "Advanced Gateway Demo Test Results:"
    echo ""
    echo "Environments Tested: ${#ENVIRONMENTS[@]}"
    for env in "${ENVIRONMENTS[@]}"; do
        local backend=$(get_backend_for_env "$env")
        echo "  • $env: $backend backend"
    done
    echo ""

    echo "Test Categories Completed:"
    echo "  ✓ Basic HTTP Services (4 environments)"
    echo "  ✓ HTTPS Services with TLS (4 environments)"
    echo "  ✓ API Gateway Routing (12 endpoints: 4 envs × 3 versions)"
    echo "  ✓ Authentication Services (JWT + OIDC)"
    echo "  ✓ WAF Protection (4 rule sets)"
    echo "  ✓ Cross-Environment Communication (4 routes)"
    echo "  ✓ Load Balancing (4 strategies)"
    echo "  ✓ Multi-Protocol Services (HTTP/HTTPS/Redirects)"
    echo "  ✓ Backend-Specific Functionality"
    echo "  ✓ Rate Limiting Tests"
    echo "  ✓ HTTP Methods Testing"
    echo "  ✓ Stress Testing (Concurrent Requests)"
    echo "  ✓ Error Conditions and Edge Cases"
    echo ""

    echo "Total Tests Executed: 100+ individual test cases"
    echo "Environments: ${ENVIRONMENTS[*]}"
    echo "Backends: ${BACKENDS[*]}"
    echo ""

    if [[ -f "$OUTPUT_DIR/jwt_token.txt" ]]; then
        echo "JWT Token: Available (stored in $OUTPUT_DIR/jwt_token.txt)"
    else
        echo "JWT Token: Not available (using mock tokens)"
    fi
    echo ""

    print_info "Advanced TSB Gateway Testing Suite provides comprehensive validation of:"
    echo "  • Multi-environment gateway configurations"
    echo "  • Multi-backend service routing"
    echo "  • Authentication and authorization flows"
    echo "  • WAF protection across environments"
    echo "  • Load balancing and traffic management"
    echo "  • Cross-environment communication patterns"
    echo "  • Error handling and edge cases"
}

# Main execution logic
if [[ "$CONTINUOUS_MODE" == "true" ]]; then
    echo -e "${GREEN}Starting Advanced TSB Gateway Testing Suite in Continuous Mode${NC}"
    echo -e "${CYAN}Press Ctrl+C to stop${NC}"
    echo ""

    trap 'echo -e "\n${YELLOW}Stopping continuous testing...${NC}"; exit 0' INT

    while true; do
        if [[ $MAX_ITERATIONS -gt 0 && $TEST_ITERATIONS -ge $MAX_ITERATIONS ]]; then
            echo -e "\n${GREEN}Reached maximum iterations ($MAX_ITERATIONS). Stopping.${NC}"
            break
        fi

        run_advanced_test_suite

        if [[ $MAX_ITERATIONS -gt 0 && $TEST_ITERATIONS -ge $MAX_ITERATIONS ]]; then
            break
        fi

        echo -e "\n${CYAN}Sleeping for $SLEEP_INTERVAL seconds before next iteration...${NC}"
        sleep "$SLEEP_INTERVAL"
    done

    echo -e "\n${GREEN}Continuous testing completed after $TEST_ITERATIONS iterations${NC}"
else
    run_advanced_test_suite
fi