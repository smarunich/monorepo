#!/bin/bash

# TSB Gateway HTTPBin Advanced Test Suite
# Configure these variables for your environment
IP_ADDRESS="20.237.73.201"
DOMAIN="api.company.com"
CONTINUOUS_MODE=false
SLEEP_INTERVAL=30
TEST_ITERATIONS=0
MAX_ITERATIONS=0

# Optional: Output directory for downloaded files
OUTPUT_DIR="./httpbin_test_output"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parse command line arguments
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -i, --ip <address>         Gateway IP address (default: 4.255.92.108)"
    echo "  -d, --domain <domain>      Base domain (default: demo.example.com)"
    echo "  -c, --continuous           Run tests continuously"
    echo "  -s, --sleep <seconds>      Sleep interval between continuous runs (default: 30)"
    echo "  -m, --max <iterations>     Maximum iterations for continuous mode (0=infinite)"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                         # Run once with defaults"
    echo "  $0 -i 10.0.0.1 -d api.company.com"
    echo "  $0 --continuous --sleep 60 --max 100"
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

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Function to print section headers
print_section() {
    echo -e "\n${GREEN}===================================================${NC}"
    echo -e "${GREEN}$1${NC}"
    if [[ "$CONTINUOUS_MODE" == "true" ]]; then
        echo -e "${CYAN}Iteration: $TEST_ITERATIONS | $(date)${NC}"
    fi
    echo -e "${GREEN}===================================================${NC}\n"
}

# Function to print test info
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Function to print warnings
print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to print errors
print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to run curl command with description
run_test() {
    local description="$1"
    shift
    echo -e "${YELLOW}Running: $description${NC}"
    if "$@"; then
        echo -e "${GREEN}✓ SUCCESS${NC}"
    else
        echo -e "${RED}✗ FAILED (exit code: $?)${NC}"
    fi
    echo ""
}

# Function to run curl with resolve for HTTPS endpoints
run_https_test() {
    local description="$1"
    local host="$2"
    local port="$3"
    local path="$4"
    shift 4

    echo -e "${YELLOW}Running HTTPS: $description${NC}"
    if curl --connect-timeout 0.5 --max-time 2 -k --resolve "$host:$port:$IP_ADDRESS" "https://$host:$port$path" "$@"; then
        echo -e "${GREEN}✓ HTTPS SUCCESS${NC}"
    else
        echo -e "${RED}✗ HTTPS FAILED (exit code: $?)${NC}"
    fi
    echo ""
}

# Function to run curl with resolve for HTTP endpoints
run_http_test() {
    local description="$1"
    local host="$2"
    local port="$3"
    local path="$4"
    shift 4

    echo -e "${YELLOW}Running HTTP: $description${NC}"
    if curl --connect-timeout 0.5 --max-time 2 --resolve "$host:$port:$IP_ADDRESS" "http://$host:$port$path" "$@"; then
        echo -e "${GREEN}✓ HTTP SUCCESS${NC}"
    else
        echo -e "${RED}✗ HTTP FAILED (exit code: $?)${NC}"
    fi
    echo ""
}

# Main test execution function
run_test_suite() {
    TEST_ITERATIONS=$((TEST_ITERATIONS + 1))

    print_section "TSB GATEWAY HTTPBIN ADVANCED TEST SUITE"
    print_info "Target IP: ${IP_ADDRESS}"
    print_info "Domain: ${DOMAIN}"
    print_info "Output Directory: ${OUTPUT_DIR}"
    if [[ "$CONTINUOUS_MODE" == "true" ]]; then
        print_info "Continuous Mode: Enabled (Sleep: ${SLEEP_INTERVAL}s, Max: ${MAX_ITERATIONS})"
    fi
    echo ""

    # ===== TSB GATEWAY ENDPOINTS TESTING =====
    print_section "TSB GATEWAY ENDPOINTS - BASIC HTTP"

    # Basic HTTP endpoint
    run_http_test "Basic HTTP service" "basic.$DOMAIN" "80" "/get"
    run_http_test "Basic HTTP POST" "basic.$DOMAIN" "80" "/post" -X POST -d "test=data"
    run_http_test "Basic HTTP headers" "basic.$DOMAIN" "80" "/headers"

    print_section "TSB GATEWAY ENDPOINTS - HTTPS WITH TLS"

    # HTTPS endpoints with TLS
    run_https_test "Secure HTTPS service" "secure.$DOMAIN" "443" "/get"
    run_https_test "Secure HTTPS POST" "secure.$DOMAIN" "443" "/post" -X POST -d "secure=data"
    run_https_test "Secure HTTPS JSON" "secure.$DOMAIN" "443" "/json"
    run_https_test "Secure HTTPS headers" "secure.$DOMAIN" "443" "/headers"

    print_section "TSB GATEWAY ENDPOINTS - HTTPS REDIRECT"

    # HTTPS redirect testing
    run_http_test "HTTP to HTTPS redirect test" "redirect.$DOMAIN" "8080" "/get" -I
    run_https_test "HTTPS after redirect" "redirect.$DOMAIN" "8443" "/get"
    run_https_test "HTTPS redirect POST" "redirect.$DOMAIN" "8443" "/post" -X POST -d "redirect=data"

    print_section "TSB GATEWAY ENDPOINTS - CUSTOM GATEWAY"

    # Custom gateway endpoints
    run_https_test "Custom gateway service" "custom.$DOMAIN" "8443" "/get"
    run_https_test "Custom gateway status codes" "custom.$DOMAIN" "8443" "/status/200"
    run_https_test "Custom gateway UUID" "custom.$DOMAIN" "8443" "/uuid"

    print_section "TSB GATEWAY ENDPOINTS - COMPREHENSIVE AUTHENTICATION"

    # Get real JWT token from demo provider
    print_info "Fetching JWT token from demo provider..."
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

        # Test with valid JWT token on various endpoints
        run_https_test "JWT auth valid token - secure endpoint" "secure.$DOMAIN" "443" "/get" -H "Authorization: Bearer $JWT_TOKEN"
        run_http_test "JWT auth valid token - basic endpoint" "basic.$DOMAIN" "80" "/get" -H "Authorization: Bearer $JWT_TOKEN"
        run_https_test "JWT auth valid token - auth endpoint" "auth.$DOMAIN" "443" "/secure" -H "Authorization: Bearer $JWT_TOKEN"

        # Test JWT with different HTTP methods
        local jwt_methods=("GET" "POST" "PUT" "DELETE" "PATCH")
        for method in "${jwt_methods[@]}"; do
            run_https_test "JWT $method request" "secure.$DOMAIN" "443" "/$(echo $method | tr '[:upper:]' '[:lower:]')" -X "$method" -H "Authorization: Bearer $JWT_TOKEN" -d "jwt=test"
        done

        # Test JWT with different paths
        local jwt_paths=("/api/v1/users" "/api/v2/data" "/secure/admin" "/protected/resource")
        for path in "${jwt_paths[@]}"; do
            run_https_test "JWT protected path: $path" "secure.$DOMAIN" "443" "$path" -H "Authorization: Bearer $JWT_TOKEN"
        done
    else
        print_warning "Could not obtain JWT token, using mock tokens for testing"
    fi

    # JWT Authentication without token (should fail)
    run_https_test "JWT auth without token (401 expected)" "auth.$DOMAIN" "443" "/secure" -w "%{http_code}\n"
    run_https_test "JWT auth without token - secure endpoint" "secure.$DOMAIN" "443" "/get"

    # JWT with various invalid tokens
    local invalid_tokens=(
        "fake.jwt.token"
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalid.signature"
        "expired.token.here"
        "malformed-token"
        ""
        "Bearer-without-space"
    )

    for token in "${invalid_tokens[@]}"; do
        run_https_test "JWT invalid token: ${token:0:20}..." "auth.$DOMAIN" "443" "/secure" -H "Authorization: Bearer $token" -w "%{http_code}\n"
    done

    # Different Authorization header formats
    if [[ -n "$JWT_TOKEN" && "$JWT_TOKEN" != "null" ]]; then
        run_https_test "JWT with Bearer prefix" "secure.$DOMAIN" "443" "/get" -H "Authorization: Bearer $JWT_TOKEN"
        run_https_test "JWT without Bearer prefix" "secure.$DOMAIN" "443" "/get" -H "Authorization: $JWT_TOKEN"
        run_https_test "JWT with lowercase bearer" "secure.$DOMAIN" "443" "/get" -H "Authorization: bearer $JWT_TOKEN"
    fi

    # API Key authentication patterns
    local api_keys=("api-key-12345" "test-key-67890" "demo-key-abcdef")
    for key in "${api_keys[@]}"; do
        run_https_test "API Key in header: $key" "api.$DOMAIN" "443" "/protected" -H "X-API-Key: $key"
        run_http_test "API Key in header: $key" "api.$DOMAIN" "80" "/protected" -H "X-API-Key: $key"
        run_https_test "API Key in query: $key" "api.$DOMAIN" "443" "/protected?api_key=$key"
    done

    # Custom auth headers
    local custom_auth_headers=(
        "X-Auth-Token: custom-token-123"
        "X-Access-Token: access-456"
        "X-Session-Token: session-789"
        "Authorization: Token abc123def456"
        "Authorization: ApiKey xyz789"
    )

    for header in "${custom_auth_headers[@]}"; do
        run_https_test "Custom auth: $header" "auth.$DOMAIN" "443" "/custom-auth" -H "$header"
    done

    # OIDC Authentication (will redirect)
    run_https_test "OIDC auth endpoint" "oidc.$DOMAIN" "443" "/app" -I
    run_https_test "OIDC callback endpoint" "oidc.$DOMAIN" "443" "/callback" -I
    run_https_test "OIDC logout endpoint" "oidc.$DOMAIN" "443" "/logout" -I

    print_section "TSB GATEWAY ENDPOINTS - COMPREHENSIVE MULTI HOST"

    # Environment variants
    local environments=("dev" "staging" "qa" "test" "prod" "canary" "beta" "alpha")
    for env in "${environments[@]}"; do
        run_https_test "Environment: $env" "$env.$DOMAIN" "443" "/health"
        run_http_test "Environment: $env" "$env.$DOMAIN" "80" "/health"
        run_https_test "Environment API: $env" "$env-api.$DOMAIN" "443" "/api/health"
        run_http_test "Environment API: $env" "$env-api.$DOMAIN" "80" "/api/health"
    done

    # Service types
    local services=("api" "cdn" "static" "media" "files" "docs" "admin" "portal" "dashboard" "metrics")
    for service in "${services[@]}"; do
        run_https_test "Service: $service" "$service.$DOMAIN" "443" "/status"
        run_http_test "Service: $service" "$service.$DOMAIN" "80" "/status"
    done

    # Geographic regions
    local regions=("us-east" "us-west" "eu-west" "eu-central" "asia-pacific" "ap-southeast" "ap-northeast")
    for region in "${regions[@]}"; do
        run_https_test "Region: $region" "$region.$DOMAIN" "443" "/region-info"
        run_http_test "Region: $region" "$region.$DOMAIN" "80" "/region-info"
    done

    # Brand/tenant variations
    local brands=("brand1" "brand2" "tenant-a" "tenant-b" "client-x" "client-y" "partner-1" "partner-2")
    for brand in "${brands[@]}"; do
        run_https_test "Brand: $brand" "$brand.$DOMAIN" "443" "/brand-info"
        run_http_test "Brand: $brand" "$brand.$DOMAIN" "80" "/brand-info"
    done

    # Complex subdomain patterns
    local complex_hosts=(
        "api-v2.us-east.prod.$DOMAIN"
        "cdn.static.assets.$DOMAIN"
        "admin.dashboard.internal.$DOMAIN"
        "metrics.monitoring.ops.$DOMAIN"
        "files.storage.backup.$DOMAIN"
        "auth.security.iam.$DOMAIN"
        "logs.analytics.data.$DOMAIN"
        "cache.redis.cluster.$DOMAIN"
    )

    for host in "${complex_hosts[@]}"; do
        # Remove the $DOMAIN part for the variable since it's already included
        clean_host=$(echo "$host" | sed "s/\.$DOMAIN//")
        run_https_test "Complex host: $clean_host" "$host" "443" "/complex-endpoint"
        run_http_test "Complex host: $clean_host" "$host" "80" "/complex-endpoint"
    done

    print_section "TSB GATEWAY ENDPOINTS - CUSTOM PORTS"

    # Custom port configurations
    run_https_test "Custom port service" "custom-port.$DOMAIN" "443" "/custom-port"
    run_http_test "Port mapping service" "port-map.$DOMAIN" "8090" "/port-test"

    print_section "HTTPBIN COMPREHENSIVE TESTING"

    # Test various HTTP methods on different endpoints
    local endpoints=("basic.$DOMAIN:80" "secure.$DOMAIN:443")
    local methods=("GET" "POST" "PUT" "DELETE" "PATCH")

    for endpoint in "${endpoints[@]}"; do
        IFS=':' read -r host port <<< "$endpoint"
        print_info "Testing HTTP methods on $host:$port"

        for method in "${methods[@]}"; do
            if [[ "$port" == "443" ]]; then
                run_https_test "$method request" "$host" "$port" "/$(echo $method | tr '[:upper:]' '[:lower:]')" -X "$method" -d "test=data"
            else
                run_http_test "$method request" "$host" "$port" "/$(echo $method | tr '[:upper:]' '[:lower:]')" -X "$method" -d "test=data"
            fi
        done
    done

    print_section "COMPREHENSIVE STATUS CODES TESTING"

    # 1xx Informational responses
    local status_1xx=(100 101 102 103)
    for code in "${status_1xx[@]}"; do
        run_https_test "1xx Status code ${code}" "secure.$DOMAIN" "443" "/status/${code}" -I
        run_http_test "1xx Status code ${code}" "basic.$DOMAIN" "80" "/status/${code}" -I
    done

    # 2xx Success responses
    local status_2xx=(200 201 202 203 204 205 206 207 208 226)
    for code in "${status_2xx[@]}"; do
        run_https_test "2xx Status code ${code}" "secure.$DOMAIN" "443" "/status/${code}" -I
        run_http_test "2xx Status code ${code}" "basic.$DOMAIN" "80" "/status/${code}" -I
    done

    # 3xx Redirection responses
    local status_3xx=(300 301 302 303 304 305 307 308)
    for code in "${status_3xx[@]}"; do
        run_https_test "3xx Status code ${code}" "secure.$DOMAIN" "443" "/status/${code}" -I
        run_http_test "3xx Status code ${code}" "basic.$DOMAIN" "80" "/status/${code}" -I
    done

    # 4xx Client error responses
    local status_4xx=(400 401 402 403 404 405 406 407 408 409 410 411 412 413 414 415 416 417 418 421 422 423 424 425 426 428 429 431 451)
    for code in "${status_4xx[@]}"; do
        run_https_test "4xx Status code ${code}" "secure.$DOMAIN" "443" "/status/${code}" -I
        run_http_test "4xx Status code ${code}" "basic.$DOMAIN" "80" "/status/${code}" -I
    done

    # 5xx Server error responses
    local status_5xx=(500 501 502 503 504 505 506 507 508 510 511)
    for code in "${status_5xx[@]}"; do
        run_https_test "5xx Status code ${code}" "secure.$DOMAIN" "443" "/status/${code}" -I
        run_http_test "5xx Status code ${code}" "basic.$DOMAIN" "80" "/status/${code}" -I
    done

    print_section "ADVANCED PATH PATTERNS & API VERSIONING"

    # API versioning patterns
    local api_versions=("v1" "v2" "v3" "v4" "v5")
    local api_resources=("users" "posts" "comments" "products" "orders" "files" "settings" "analytics")

    for version in "${api_versions[@]}"; do
        for resource in "${api_resources[@]}"; do
            run_http_test "API $version $resource list" "api.$DOMAIN" "80" "/$version/$resource"
            run_https_test "API $version $resource list" "api.$DOMAIN" "443" "/$version/$resource"

            # Resource with ID patterns
            local id=$((RANDOM % 1000 + 1))
            run_http_test "API $version $resource by ID" "api.$DOMAIN" "80" "/$version/$resource/$id"
            run_https_test "API $version $resource by ID" "api.$DOMAIN" "443" "/$version/$resource/$id"
        done
    done

    # Nested API paths
    local nested_paths=(
        "api/v1/users/123/posts"
        "api/v2/posts/456/comments"
        "api/v1/organizations/789/teams/members"
        "api/v3/projects/101/files/documents"
        "api/v2/users/202/settings/preferences"
        "api/v1/analytics/reports/daily"
        "rest/v1/data/metrics/performance"
        "graphql/v1/schema/introspection"
    )

    for path in "${nested_paths[@]}"; do
        run_http_test "Nested path: $path" "api.$DOMAIN" "80" "/$path"
        run_https_test "Nested path: $path" "api.$DOMAIN" "443" "/$path"
    done

    # File extension patterns
    local file_extensions=("json" "xml" "html" "txt" "csv" "pdf" "yaml" "yml")
    local base_paths=("data" "export" "report" "config" "schema")

    for ext in "${file_extensions[@]}"; do
        for base in "${base_paths[@]}"; do
            run_http_test "File: $base.$ext" "files.$DOMAIN" "80" "/$base.$ext"
            run_https_test "File: $base.$ext" "files.$DOMAIN" "443" "/$base.$ext"
        done
    done

    # Query parameter patterns
    local query_tests=(
        "search?q=test&limit=10&offset=0"
        "filter?status=active&category=tech&sort=date"
        "paginate?page=1&size=20&order=asc"
        "export?format=csv&fields=name,email&date=2024-01-01"
        "analytics?start=2024-01-01&end=2024-12-31&metrics=views,clicks"
        "search?q=special%20chars%20%26%20unicode%20%C3%A9"
        "complex?arr[]=1&arr[]=2&obj[key]=value&nested[deep][val]=test"
    )

    for query in "${query_tests[@]}"; do
        run_http_test "Query params: $query" "api.$DOMAIN" "80" "/$query"
        run_https_test "Query params: $query" "api.$DOMAIN" "443" "/$query"
    done

    print_section "REQUEST INSPECTION"

    # Test request inspection on both HTTP and HTTPS
    run_http_test "HTTP Headers inspection" "basic.$DOMAIN" "80" "/headers"
    run_https_test "HTTPS Headers inspection" "secure.$DOMAIN" "443" "/headers"

    run_http_test "HTTP IP address" "basic.$DOMAIN" "80" "/ip"
    run_https_test "HTTPS IP address" "secure.$DOMAIN" "443" "/ip"

    run_http_test "HTTP User agent" "basic.$DOMAIN" "80" "/user-agent"
    run_https_test "HTTPS User agent" "secure.$DOMAIN" "443" "/user-agent"

    print_section "CONTENT TYPE VARIETY & FILE UPLOADS"

    # Different content types for POST requests
    local content_types=(
        "application/json"
        "application/xml"
        "application/x-www-form-urlencoded"
        "text/plain"
        "text/xml"
        "text/csv"
        "application/yaml"
        "application/octet-stream"
    )

    # JSON payloads with different structures
    local json_payloads=(
        '{"simple": "test"}'
        '{"nested": {"key": "value", "number": 42}}'
        '{"array": [1, 2, 3, "string", {"obj": true}]}'
        '{"unicode": "Hello 世界 🌍", "special": "chars@#$%"}'
        '{"large_text": "'$(printf 'A%.0s' {1..100})'"}'
    )

    for content_type in "${content_types[@]}"; do
        if [[ "$content_type" == "application/json" ]]; then
            for payload in "${json_payloads[@]}"; do
                run_https_test "JSON POST: ${payload:0:30}..." "secure.$DOMAIN" "443" "/post" -H "Content-Type: $content_type" -d "$payload"
                run_http_test "JSON POST: ${payload:0:30}..." "basic.$DOMAIN" "80" "/post" -H "Content-Type: $content_type" -d "$payload"
            done
        else
            local test_data="test=data&type=$content_type&timestamp=$(date +%s)"
            run_https_test "Content-Type: $content_type" "secure.$DOMAIN" "443" "/post" -H "Content-Type: $content_type" -d "$test_data"
            run_http_test "Content-Type: $content_type" "basic.$DOMAIN" "80" "/post" -H "Content-Type: $content_type" -d "$test_data"
        fi
    done

    # XML payloads
    local xml_payload='<?xml version="1.0"?><root><item>test</item><number>123</number></root>'
    run_https_test "XML POST payload" "secure.$DOMAIN" "443" "/post" -H "Content-Type: application/xml" -d "$xml_payload"
    run_http_test "XML POST payload" "basic.$DOMAIN" "80" "/post" -H "Content-Type: application/xml" -d "$xml_payload"

    # YAML payload
    local yaml_payload=$'name: test\nversion: 1.0\nconfig:\n  enabled: true\n  timeout: 30'
    run_https_test "YAML POST payload" "secure.$DOMAIN" "443" "/post" -H "Content-Type: application/yaml" -d "$yaml_payload"

    # File upload simulations (multipart/form-data)
    local upload_dir="${OUTPUT_DIR}/uploads"
    mkdir -p "$upload_dir"

    # Create test files with different content
    echo "This is a test text file" > "$upload_dir/test.txt"
    echo '{"test": "json file"}' > "$upload_dir/data.json"
    printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01' > "$upload_dir/tiny.png"

    # Test file uploads
    local upload_files=("test.txt" "data.json" "tiny.png")
    for file in "${upload_files[@]}"; do
        if [[ -f "$upload_dir/$file" ]]; then
            run_https_test "File upload: $file" "files.$DOMAIN" "443" "/upload" -F "file=@$upload_dir/$file" -F "description=Test upload of $file"
            run_http_test "File upload: $file" "files.$DOMAIN" "80" "/upload" -F "file=@$upload_dir/$file" -F "description=Test upload of $file"
        fi
    done

    # Large payload tests
    local large_data=$(printf 'X%.0s' {1..1000})
    run_https_test "Large payload (1KB)" "secure.$DOMAIN" "443" "/post" -d "large_data=$large_data"

    # Accept header variations
    local accept_types=(
        "application/json"
        "application/xml"
        "text/html"
        "text/plain"
        "application/*"
        "*/*"
        "application/json, application/xml"
        "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
    )

    for accept in "${accept_types[@]}"; do
        run_https_test "Accept: $accept" "secure.$DOMAIN" "443" "/headers" -H "Accept: $accept"
        run_http_test "Accept: $accept" "basic.$DOMAIN" "80" "/headers" -H "Accept: $accept"
    done

    print_section "RESPONSE FORMATS"

    local formats=("json" "xml" "html" "uuid")
    for format in "${formats[@]}"; do
        run_http_test "HTTP $format response" "basic.$DOMAIN" "80" "/$format"
        run_https_test "HTTPS $format response" "secure.$DOMAIN" "443" "/$format"
    done

    print_section "AUTHENTICATION TESTING"

    # Basic auth testing on multiple endpoints
    run_http_test "HTTP Basic auth (should fail)" "basic.$DOMAIN" "80" "/basic-auth/user/passwd"
    run_http_test "HTTP Basic auth with credentials" "basic.$DOMAIN" "80" "/basic-auth/user/passwd" -u user:passwd

    run_https_test "HTTPS Basic auth (should fail)" "secure.$DOMAIN" "443" "/basic-auth/user/passwd"
    run_https_test "HTTPS Basic auth with credentials" "secure.$DOMAIN" "443" "/basic-auth/user/passwd" -u user:passwd

    # Bearer token testing
    run_http_test "HTTP Bearer token" "basic.$DOMAIN" "80" "/bearer" -H "Authorization: Bearer test-token-$(date +%s)"
    run_https_test "HTTPS Bearer token" "secure.$DOMAIN" "443" "/bearer" -H "Authorization: Bearer test-token-$(date +%s)"

    print_section "ADVANCED HTTP FEATURES & HEADERS"

    # Custom headers testing
    local custom_headers=(
        "X-Forwarded-For: 192.168.1.100"
        "X-Real-IP: 10.0.0.50"
        "X-Request-ID: req-$(uuidgen 2>/dev/null || echo $(date +%s)-$RANDOM)"
        "X-Correlation-ID: corr-$(date +%s)"
        "X-Custom-Header: CustomValue123"
        "X-Client-Version: v2.1.0"
        "X-API-Version: 2024-01-15"
        "X-Trace-ID: trace-$(date +%s)"
    )

    for header in "${custom_headers[@]}"; do
        run_https_test "Custom header: ${header%%:*}" "secure.$DOMAIN" "443" "/headers" -H "$header"
        run_http_test "Custom header: ${header%%:*}" "basic.$DOMAIN" "80" "/headers" -H "$header"
    done

    # User-Agent variations
    local user_agents=(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
        "curl/8.0.0"
        "PostmanRuntime/7.32.0"
        "python-requests/2.28.0"
        "Go-http-client/1.1"
        "CustomBot/1.0"
    )

    for ua in "${user_agents[@]}"; do
        run_https_test "User-Agent: ${ua:0:20}..." "secure.$DOMAIN" "443" "/user-agent" -H "User-Agent: $ua"
        run_http_test "User-Agent: ${ua:0:20}..." "basic.$DOMAIN" "80" "/user-agent" -H "User-Agent: $ua"
    done

    # CORS preflight requests (OPTIONS)
    local cors_origins=(
        "https://example.com"
        "https://app.example.com"
        "http://localhost:3000"
        "https://admin.example.com"
    )

    for origin in "${cors_origins[@]}"; do
        run_https_test "CORS preflight: $origin" "api.$DOMAIN" "443" "/cors-test" -X OPTIONS -H "Origin: $origin" -H "Access-Control-Request-Method: POST" -H "Access-Control-Request-Headers: Content-Type,Authorization"
        run_http_test "CORS preflight: $origin" "api.$DOMAIN" "80" "/cors-test" -X OPTIONS -H "Origin: $origin" -H "Access-Control-Request-Method: POST"
    done

    # Range requests for partial content
    local range_headers=(
        "bytes=0-499"
        "bytes=500-999"
        "bytes=-500"
        "bytes=1000-"
        "bytes=0-0"
    )

    for range in "${range_headers[@]}"; do
        run_https_test "Range request: $range" "files.$DOMAIN" "443" "/bytes/2000" -H "Range: $range" -I
        run_http_test "Range request: $range" "files.$DOMAIN" "80" "/bytes/2000" -H "Range: $range" -I
    done

    # Conditional requests
    local etag_value="test-etag-$(date +%s)"
    local if_headers=(
        "If-Match: \"$etag_value\""
        "If-None-Match: \"$etag_value\""
        "If-Modified-Since: $(date -u '+%a, %d %b %Y %H:%M:%S GMT')"
        "If-Unmodified-Since: $(date -u '+%a, %d %b %Y %H:%M:%S GMT')"
    )

    for if_header in "${if_headers[@]}"; do
        run_https_test "Conditional: ${if_header%%:*}" "secure.$DOMAIN" "443" "/etag/$etag_value" -H "$if_header" -I
        run_http_test "Conditional: ${if_header%%:*}" "basic.$DOMAIN" "80" "/etag/$etag_value" -H "$if_header" -I
    done

    # Cache control variations
    local cache_headers=(
        "Cache-Control: no-cache"
        "Cache-Control: no-store"
        "Cache-Control: max-age=3600"
        "Cache-Control: must-revalidate"
        "Pragma: no-cache"
    )

    for cache_header in "${cache_headers[@]}"; do
        run_https_test "Cache header: ${cache_header%%:*}" "secure.$DOMAIN" "443" "/cache" -H "$cache_header"
        run_http_test "Cache header: ${cache_header%%:*}" "basic.$DOMAIN" "80" "/cache" -H "$cache_header"
    done

    # Multiple headers combination
    run_https_test "Multiple custom headers" "secure.$DOMAIN" "443" "/headers" \
        -H "X-Custom-1: Value1" \
        -H "X-Custom-2: Value2" \
        -H "X-Timestamp: $(date +%s)" \
        -H "X-Client: TestSuite"

    # HTTP/2 specific testing (if supported)
    run_https_test "HTTP/2 request" "secure.$DOMAIN" "443" "/get" --http2

    print_section "REDIRECTION TESTING"

    # Test redirects on different endpoints
    local redirect_counts=(1 2 3)
    for count in "${redirect_counts[@]}"; do
        run_http_test "HTTP redirect ($count)" "basic.$DOMAIN" "80" "/redirect/$count" -L
        run_https_test "HTTPS redirect ($count)" "secure.$DOMAIN" "443" "/redirect/$count" -L
    done

    # Test different redirect types
    run_http_test "HTTP absolute redirect" "basic.$DOMAIN" "80" "/absolute-redirect/2" -L
    run_http_test "HTTP relative redirect" "basic.$DOMAIN" "80" "/relative-redirect/2" -L

    run_https_test "HTTPS absolute redirect" "secure.$DOMAIN" "443" "/absolute-redirect/2" -L
    run_https_test "HTTPS relative redirect" "secure.$DOMAIN" "443" "/relative-redirect/2" -L

    print_section "RESPONSE MANIPULATION"

    # Test delays and streaming
    local delay_times=(1 2)
    for delay in "${delay_times[@]}"; do
        run_http_test "HTTP delay ($delay seconds)" "basic.$DOMAIN" "80" "/delay/$delay" --max-time 4
        run_https_test "HTTPS delay ($delay seconds)" "secure.$DOMAIN" "443" "/delay/$delay" --max-time 4
    done

    # Test streaming
    run_http_test "HTTP stream data" "basic.$DOMAIN" "80" "/stream/3"
    run_https_test "HTTPS stream data" "secure.$DOMAIN" "443" "/stream/3"

    # Test random bytes
    run_http_test "HTTP random bytes" "basic.$DOMAIN" "80" "/bytes/512" -o "${OUTPUT_DIR}/http_random_bytes_$(date +%s).bin"
    run_https_test "HTTPS random bytes" "secure.$DOMAIN" "443" "/bytes/512" -o "${OUTPUT_DIR}/https_random_bytes_$(date +%s).bin"

    # Test drip
    run_http_test "HTTP drip data" "basic.$DOMAIN" "80" "/drip?duration=1&numbytes=50"
    run_https_test "HTTPS drip data" "secure.$DOMAIN" "443" "/drip?duration=1&numbytes=50"

    print_section "COOKIES TESTING"

    local cookie_file_http="${OUTPUT_DIR}/cookies_http_$(date +%s).txt"
    local cookie_file_https="${OUTPUT_DIR}/cookies_https_$(date +%s).txt"

    # HTTP cookies
    run_http_test "HTTP set cookies" "basic.$DOMAIN" "80" "/cookies/set?test=http_value&iteration=$TEST_ITERATIONS" -c "$cookie_file_http"
    run_http_test "HTTP get cookies" "basic.$DOMAIN" "80" "/cookies" -b "$cookie_file_http"

    # HTTPS cookies
    run_https_test "HTTPS set cookies" "secure.$DOMAIN" "443" "/cookies/set?test=https_value&iteration=$TEST_ITERATIONS" -c "$cookie_file_https"
    run_https_test "HTTPS get cookies" "secure.$DOMAIN" "443" "/cookies" -b "$cookie_file_https"

    print_section "COMPRESSION TESTING"

    local compressions=("gzip" "deflate" "brotli")
    local encodings=("gzip" "deflate" "br")

    for i in "${!compressions[@]}"; do
        local comp="${compressions[$i]}"
        local enc="${encodings[$i]}"

        run_http_test "HTTP $comp compression" "basic.$DOMAIN" "80" "/$comp" -H "Accept-Encoding: $enc"
        run_https_test "HTTPS $comp compression" "secure.$DOMAIN" "443" "/$comp" -H "Accept-Encoding: $enc"
    done

    print_section "CACHE TESTING"

    local cache_times=(30 60)
    for time in "${cache_times[@]}"; do
        run_http_test "HTTP cache ($time seconds)" "basic.$DOMAIN" "80" "/cache/$time"
        run_https_test "HTTPS cache ($time seconds)" "secure.$DOMAIN" "443" "/cache/$time"
    done

    # ETag testing with unique values
    local etag_value="test_$(date +%s)_$TEST_ITERATIONS"
    run_http_test "HTTP ETag testing" "basic.$DOMAIN" "80" "/etag/$etag_value"
    run_https_test "HTTPS ETag testing" "secure.$DOMAIN" "443" "/etag/$etag_value"

    print_section "IMAGES TESTING"

    local image_types=("png" "jpeg" "svg" "webp")
    for img_type in "${image_types[@]}"; do
        local timestamp=$(date +%s)
        run_http_test "HTTP $img_type image" "basic.$DOMAIN" "80" "/image/$img_type" -o "${OUTPUT_DIR}/http_${img_type}_${timestamp}.${img_type}"
        run_https_test "HTTPS $img_type image" "secure.$DOMAIN" "443" "/image/$img_type" -o "${OUTPUT_DIR}/https_${img_type}_${timestamp}.${img_type}"
    done

    # Generic image test
    run_http_test "HTTP generic image" "basic.$DOMAIN" "80" "/image" -o "${OUTPUT_DIR}/http_generic_$(date +%s).file"
    run_https_test "HTTPS generic image" "secure.$DOMAIN" "443" "/image" -o "${OUTPUT_DIR}/https_generic_$(date +%s).file"

    print_section "ADDITIONAL UTILITY ENDPOINTS"

    # Base64 decoding with different strings
    local base64_strings=("SFRUUEJJTiBpcyBhd2Vzb21l" "VGVzdGluZyBUU0IgR2F0ZXdheQ==")
    for b64 in "${base64_strings[@]}"; do
        run_http_test "HTTP Base64 decode" "basic.$DOMAIN" "80" "/base64/$b64"
        run_https_test "HTTPS Base64 decode" "secure.$DOMAIN" "443" "/base64/$b64"
    done

    # Robots.txt
    run_http_test "HTTP robots.txt" "basic.$DOMAIN" "80" "/robots.txt"
    run_https_test "HTTPS robots.txt" "secure.$DOMAIN" "443" "/robots.txt"

    # Response headers customization
    local custom_headers="Content-Type=application/json&X-Test-Run=$TEST_ITERATIONS&X-Timestamp=$(date +%s)"
    run_http_test "HTTP custom response headers" "basic.$DOMAIN" "80" "/response-headers?$custom_headers"
    run_https_test "HTTPS custom response headers" "secure.$DOMAIN" "443" "/response-headers?$custom_headers"

    # Anything endpoint
    run_http_test "HTTP anything endpoint" "basic.$DOMAIN" "80" "/anything" -X CUSTOM -d "test=data&iteration=$TEST_ITERATIONS"
    run_https_test "HTTPS anything endpoint" "secure.$DOMAIN" "443" "/anything" -X CUSTOM -d "test=data&iteration=$TEST_ITERATIONS"

    print_section "VERBOSE & PERFORMANCE TESTING"

    # Verbose testing
    run_http_test "HTTP verbose headers" "basic.$DOMAIN" "80" "/get" -v
    run_https_test "HTTPS verbose headers" "secure.$DOMAIN" "443" "/get" -v

    # Timing information
    run_http_test "HTTP timing info" "basic.$DOMAIN" "80" "/delay/1" -w "\nTime_total: %{time_total}s\nTime_connect: %{time_connect}s\nTime_starttransfer: %{time_starttransfer}s\n" --max-time 3
    run_https_test "HTTPS timing info" "secure.$DOMAIN" "443" "/delay/1" -w "\nTime_total: %{time_total}s\nTime_connect: %{time_connect}s\nTime_starttransfer: %{time_starttransfer}s\n" --max-time 3

    # Redirects with verbose
    run_http_test "HTTP verbose redirects" "basic.$DOMAIN" "80" "/redirect/2" -vL
    run_https_test "HTTPS verbose redirects" "secure.$DOMAIN" "443" "/redirect/2" -vL

    print_section "PERFORMANCE & LOAD TESTING PATTERNS"

    # Concurrent requests simulation
    print_info "Running concurrent request tests..."
    local concurrent_pids=()

    # Spawn multiple background requests
    for i in {1..5}; do
        (run_https_test "Concurrent request $i" "secure.$DOMAIN" "443" "/get?concurrent=$i") &
        concurrent_pids+=($!)
        (run_http_test "Concurrent request $i" "basic.$DOMAIN" "80" "/get?concurrent=$i") &
        concurrent_pids+=($!)
    done

    # Wait for all concurrent requests to complete
    for pid in "${concurrent_pids[@]}"; do
        wait $pid
    done

    # Variable payload sizes
    local payload_sizes=(100 1000 5000 10000)
    for size in "${payload_sizes[@]}"; do
        local payload_data=$(printf 'X%.0s' $(seq 1 $size))
        run_https_test "Payload size ${size}B" "secure.$DOMAIN" "443" "/post" -d "data=$payload_data"
        run_http_test "Payload size ${size}B" "basic.$DOMAIN" "80" "/post" -d "data=$payload_data"
    done

    # Stress testing with rapid requests
    print_info "Rapid fire requests test..."
    for i in {1..10}; do
        run_https_test "Rapid request $i" "secure.$DOMAIN" "443" "/status/200" -I &
    done
    wait

    # Long-running operations simulation
    local delay_values=(0.5 1 2 3)
    for delay in "${delay_values[@]}"; do
        run_https_test "Delay ${delay}s operation" "secure.$DOMAIN" "443" "/delay/$delay" --max-time $((delay + 2))
        run_http_test "Delay ${delay}s operation" "basic.$DOMAIN" "80" "/delay/$delay" --max-time $((delay + 2))
    done

    # Memory stress tests
    local byte_sizes=(1024 10240 51200 102400)
    for bytes in "${byte_sizes[@]}"; do
        run_https_test "Download ${bytes} bytes" "secure.$DOMAIN" "443" "/bytes/$bytes" -o "${OUTPUT_DIR}/perf_test_${bytes}_$(date +%s).bin"
        run_http_test "Download ${bytes} bytes" "basic.$DOMAIN" "80" "/bytes/$bytes" -o "${OUTPUT_DIR}/perf_test_${bytes}_$(date +%s).bin"
    done

    # Connection reuse testing
    print_info "Testing connection reuse..."
    for i in {1..5}; do
        run_https_test "Reuse connection $i" "secure.$DOMAIN" "443" "/get?reuse=$i" --keepalive
        run_http_test "Reuse connection $i" "basic.$DOMAIN" "80" "/get?reuse=$i" --keepalive
    done

    # Different timeout scenarios
    local timeout_tests=(
        "fast:0.1"
        "normal:1"
        "slow:3"
        "very-slow:5"
    )

    for test in "${timeout_tests[@]}"; do
        local name="${test%%:*}"
        local timeout="${test##*:}"
        run_https_test "Timeout test $name (${timeout}s)" "secure.$DOMAIN" "443" "/delay/1" --max-time "$timeout" || true
    done

    print_section "ERROR SIMULATION & EDGE CASES"

    # Malformed requests
    local malformed_tests=(
        "Invalid header" "--header 'Invalid Header Without Colon'"
        "Empty content-type" "--header 'Content-Type:'"
        "Special chars in path" "/path/with spaces/and%special&chars"
        "Unicode in path" "/path/with/üñïcödé/characters"
        "Very long path" "/$(printf 'long%.0s' {1..100})/path"
    )

    local i=0
    while [ $i -lt ${#malformed_tests[@]} ]; do
        local desc="${malformed_tests[$i]}"
        local test_param="${malformed_tests[$i+1]}"

        if [[ "$test_param" == --* ]]; then
            # It's a curl option
            run_https_test "Malformed: $desc" "secure.$DOMAIN" "443" "/anything" $test_param || true
        else
            # It's a path
            run_https_test "Edge case path: $desc" "secure.$DOMAIN" "443" "$test_param" || true
            run_http_test "Edge case path: $desc" "basic.$DOMAIN" "80" "$test_param" || true
        fi

        i=$((i + 2))
    done

    # Resource exhaustion simulation
    run_https_test "Large file download" "files.$DOMAIN" "443" "/bytes/1048576" -o "${OUTPUT_DIR}/large_file_$(date +%s).bin" --max-time 10 || true

    # Security test patterns (safe testing)
    local security_paths=(
        "/admin"
        "/.env"
        "/.git/config"
        "/config.json"
        "/backup"
        "/test"
        "/debug"
        "/healthz"
        "/metrics"
        "/actuator/health"
    )

    for path in "${security_paths[@]}"; do
        run_https_test "Security scan: $path" "secure.$DOMAIN" "443" "$path" -I || true
        run_http_test "Security scan: $path" "basic.$DOMAIN" "80" "$path" -I || true
    done

    # SQL injection attempts (safe - just testing WAF)
    local sqli_payloads=(
        "' OR 1=1--"
        "'; DROP TABLE users;--"
        "1' UNION SELECT * FROM users--"
    )

    for payload in "${sqli_payloads[@]}"; do
        local encoded_payload=$(printf '%s' "$payload" | jq -sRr @uri)
        run_https_test "SQLi test (safe): ${payload:0:15}..." "waf.$DOMAIN" "443" "/search?q=$encoded_payload" || true
    done

    # XSS attempts (safe - just testing WAF)
    local xss_payloads=(
        "<script>alert('xss')</script>"
        "javascript:alert('xss')"
        "<img src=x onerror=alert('xss')>"
    )

    for payload in "${xss_payloads[@]}"; do
        local encoded_payload=$(printf '%s' "$payload" | jq -sRr @uri)
        run_https_test "XSS test (safe): ${payload:0:15}..." "waf.$DOMAIN" "443" "/comment?text=$encoded_payload" || true
    done

    print_section "RANDOM ENDPOINT TESTING"

    # Random selection of endpoints for variety
    local random_endpoints=(
        "basic.$DOMAIN:80:/status/$(shuf -i 200-500 -n 1)"
        "secure.$DOMAIN:443:/delay/$(shuf -i 1-3 -n 1)"
        "basic.$DOMAIN:80:/bytes/$(shuf -i 100-1000 -n 1)"
        "secure.$DOMAIN:443:/stream/$(shuf -i 1-5 -n 1)"
    )

    for endpoint in "${random_endpoints[@]}"; do
        IFS=':' read -r host port path <<< "$endpoint"
        if [[ "$port" == "443" ]]; then
            run_https_test "Random HTTPS test" "$host" "$port" "$path"
        else
            run_http_test "Random HTTP test" "$host" "$port" "$path"
        fi
    done

    print_section "RATE LIMITING & WAF TESTING"

    # Test rate limiting endpoint if available
    run_http_test "Rate limited endpoint" "api.$DOMAIN" "80" "/rate-limited"

    # Test WAF endpoints
    run_http_test "WAF protected endpoint" "waf.$DOMAIN" "80" "/protected"
    run_http_test "WAF XSS test (should be blocked)" "waf.$DOMAIN" "80" "/protected?test=<script>alert(1)</script>"

    print_section "PATH ROUTING TESTING"

    # Test path-based routing
    run_http_test "API v1 path routing" "api.$DOMAIN" "80" "/v1/httpbin"
    run_http_test "API v2 path routing" "api.$DOMAIN" "80" "/v2/httpbin"

    print_section "TEST ITERATION COMPLETED"
    local end_time=$(date)
    print_info "Iteration $TEST_ITERATIONS completed at: $end_time"
    print_info "IP Address: ${IP_ADDRESS}"
    print_info "Domain: ${DOMAIN}"
    print_info "Output Directory: ${OUTPUT_DIR}"

    if [[ "$CONTINUOUS_MODE" == "false" ]]; then
        echo -e "\n${GREEN}Single test run completed!${NC}"

        # Optional cleanup for single run
        echo ""
        read -p "Do you want to clean up the output directory? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "${OUTPUT_DIR}"
            echo "Output directory cleaned up."
        fi
    fi
}

# Main execution logic
if [[ "$CONTINUOUS_MODE" == "true" ]]; then
    echo -e "${GREEN}Starting TSB Gateway HTTPBin Test Suite in Continuous Mode${NC}"
    echo -e "${CYAN}Press Ctrl+C to stop${NC}\n"

    trap 'echo -e "\n${YELLOW}Stopping continuous testing...${NC}"; exit 0' INT

    while true; do
        if [[ $MAX_ITERATIONS -gt 0 && $TEST_ITERATIONS -ge $MAX_ITERATIONS ]]; then
            echo -e "\n${GREEN}Reached maximum iterations ($MAX_ITERATIONS). Stopping.${NC}"
            break
        fi

        run_test_suite

        if [[ $MAX_ITERATIONS -gt 0 && $TEST_ITERATIONS -ge $MAX_ITERATIONS ]]; then
            break
        fi

        echo -e "\n${CYAN}Sleeping for $SLEEP_INTERVAL seconds before next iteration...${NC}"
        sleep "$SLEEP_INTERVAL"
    done

    echo -e "\n${GREEN}Continuous testing completed after $TEST_ITERATIONS iterations${NC}"
else
    run_test_suite
fi
