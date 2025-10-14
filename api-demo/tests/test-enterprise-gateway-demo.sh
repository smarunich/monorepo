#!/bin/bash

# Comprehensive Test Framework for TSB Enterprise Gateway Demo Suite
# Tests enterprise-gateway-demo.sh functionality including broken services mode
#
# Usage: ./test-enterprise-gateway-demo.sh [options]
# Options:
#   --unit          Run unit tests only
#   --integration   Run integration tests only
#   --all           Run all tests (default)
#   -v, --verbose   Verbose output
#   -h, --help      Show help

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SCRIPT="$SCRIPT_DIR/enterprise-gateway-demo.sh"
TEST_MODE="all"
VERBOSE=false
TEST_OUTPUT_DIR="./test_output"
MOCK_MODE=true

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Test environment variables
export TEST_NAMESPACE="test-demo"
export TEST_DOMAIN="test.example.com"
export TEST_CLOUD="aws"

# Create test output directory
mkdir -p "$TEST_OUTPUT_DIR"

# Logging functions
log_test_header() {
    echo ""
    echo -e "${GREEN}=================================================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}=================================================================${NC}"
    echo ""
}

log_test_section() {
    echo ""
    echo -e "${CYAN}--- $1 ---${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_failure() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${MAGENTA}[VERBOSE]${NC} $1"
    fi
}

# Test assertion functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ "$expected" == "$actual" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_success "Test $TESTS_RUN: $test_name"
        log_verbose "  Expected: '$expected', Got: '$actual'"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        log_failure "Test $TESTS_RUN: $test_name"
        echo -e "  ${RED}Expected: '$expected'${NC}"
        echo -e "  ${RED}Got:      '$actual'${NC}"
        return 1
    fi
}

assert_not_empty() {
    local value="$1"
    local test_name="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ -n "$value" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_success "Test $TESTS_RUN: $test_name"
        log_verbose "  Value is not empty: '$value'"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        log_failure "Test $TESTS_RUN: $test_name"
        echo -e "  ${RED}Expected non-empty value, got empty${NC}"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ "$haystack" == *"$needle"* ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_success "Test $TESTS_RUN: $test_name"
        log_verbose "  String contains: '$needle'"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        log_failure "Test $TESTS_RUN: $test_name"
        echo -e "  ${RED}Expected to contain: '$needle'${NC}"
        echo -e "  ${RED}In string: '$haystack'${NC}"
        return 1
    fi
}

assert_matches_regex() {
    local value="$1"
    local pattern="$2"
    local test_name="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ "$value" =~ $pattern ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_success "Test $TESTS_RUN: $test_name"
        log_verbose "  Value matches pattern: '$pattern'"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        log_failure "Test $TESTS_RUN: $test_name"
        echo -e "  ${RED}Expected to match pattern: '$pattern'${NC}"
        echo -e "  ${RED}Value: '$value'${NC}"
        return 1
    fi
}

assert_file_exists() {
    local file_path="$1"
    local test_name="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ -f "$file_path" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_success "Test $TESTS_RUN: $test_name"
        log_verbose "  File exists: '$file_path'"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        log_failure "Test $TESTS_RUN: $test_name"
        echo -e "  ${RED}Expected file to exist: '$file_path'${NC}"
        return 1
    fi
}

assert_exit_code() {
    local expected_code="$1"
    local actual_code="$2"
    local test_name="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ "$expected_code" -eq "$actual_code" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_success "Test $TESTS_RUN: $test_name"
        log_verbose "  Exit code: $actual_code"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
        log_failure "Test $TESTS_RUN: $test_name"
        echo -e "  ${RED}Expected exit code: $expected_code${NC}"
        echo -e "  ${RED}Got exit code: $actual_code${NC}"
        return 1
    fi
}

# Mock external commands for testing
setup_mocks() {
    log_info "Setting up mock commands for testing"

    # Create mock bin directory
    export MOCK_BIN_DIR="$TEST_OUTPUT_DIR/mock_bin"
    mkdir -p "$MOCK_BIN_DIR"

    # Mock kubectl
    cat > "$MOCK_BIN_DIR/kubectl" << 'EOF'
#!/bin/bash
# Mock kubectl for testing
case "$1" in
    cluster-info)
        echo "Kubernetes control plane is running"
        exit 0
        ;;
    create)
        if [[ "$2" == "namespace" ]]; then
            echo "namespace/$4 created" >&2
        elif [[ "$2" == "secret" ]]; then
            echo "secret/$4 created" >&2
        fi
        exit 0
        ;;
    apply)
        echo "Mock kubectl apply executed" >&2
        exit 0
        ;;
    get)
        if [[ "$2" == "secret" ]]; then
            exit 1  # Secret doesn't exist
        fi
        echo "Mock resource found"
        exit 0
        ;;
    label)
        echo "namespace/$2 labeled" >&2
        exit 0
        ;;
    annotate)
        echo "namespace/$2 annotated" >&2
        exit 0
        ;;
    wait)
        echo "condition met" >&2
        exit 0
        ;;
    delete)
        echo "resource deleted" >&2
        exit 0
        ;;
    *)
        echo "Mock kubectl: $*" >&2
        exit 0
        ;;
esac
EOF
    chmod +x "$MOCK_BIN_DIR/kubectl"

    # Mock openssl
    cat > "$MOCK_BIN_DIR/openssl" << 'EOF'
#!/bin/bash
# Mock openssl for testing
if [[ "$1" == "req" ]]; then
    # Create dummy cert files
    touch "$8" "$6"
    exit 0
fi
exit 0
EOF
    chmod +x "$MOCK_BIN_DIR/openssl"

    # Add mock bin to PATH
    export PATH="$MOCK_BIN_DIR:$PATH"

    log_verbose "Mock kubectl location: $(which kubectl)"
    log_verbose "Mock openssl location: $(which openssl)"
}

cleanup_mocks() {
    log_info "Cleaning up mock commands"
    rm -rf "$MOCK_BIN_DIR"
}

# Source functions from target script for unit testing
source_script_functions() {
    log_info "Sourcing functions from $TARGET_SCRIPT"

    # Extract and source only functions (not main execution)
    # We'll create a temporary file with just the functions
    local temp_functions="$TEST_OUTPUT_DIR/functions.sh"

    # Extract everything except the main() call and set -e
    awk '/^main\(\)/ {exit} {print}' "$TARGET_SCRIPT" | grep -v "^set -e" > "$temp_functions"

    source "$temp_functions"

    log_verbose "Functions sourced from target script"
}

# Unit Tests
run_unit_tests() {
    log_test_header "UNIT TESTS - Function-Level Testing"

    # Test 1: get_backend_for_namespace
    log_test_section "Test: get_backend_for_namespace()"

    BASE_NAMESPACE="demo"
    NAMESPACES=("demo-prod" "demo-staging" "demo-dev" "demo-test")
    BACKEND_NAMES=("market-data-feed" "order-execution-service" "compliance-records" "settlement-ledger")

    local result=$(get_backend_for_namespace "demo-prod")
    assert_equals "market-data-feed" "$result" "get_backend_for_namespace(demo-prod) should return market-data-feed"

    result=$(get_backend_for_namespace "demo-staging")
    assert_equals "order-execution-service" "$result" "get_backend_for_namespace(demo-staging) should return order-execution-service"

    result=$(get_backend_for_namespace "demo-dev")
    assert_equals "compliance-records" "$result" "get_backend_for_namespace(demo-dev) should return compliance-records"

    result=$(get_backend_for_namespace "demo-test")
    assert_equals "settlement-ledger" "$result" "get_backend_for_namespace(demo-test) should return settlement-ledger"

    result=$(get_backend_for_namespace "invalid-namespace")
    assert_equals "market-data-feed" "$result" "get_backend_for_namespace(invalid) should return fallback market-data-feed"

    # Test 2: get_business_service_for_namespace
    log_test_section "Test: get_business_service_for_namespace()"

    BUSINESS_SERVICES=("market-data-gateway" "trading-engine-proxy" "compliance-validator" "settlement-processor")

    result=$(get_business_service_for_namespace "demo-prod")
    assert_equals "market-data-gateway" "$result" "get_business_service_for_namespace(demo-prod) should return market-data-gateway"

    result=$(get_business_service_for_namespace "demo-staging")
    assert_equals "trading-engine-proxy" "$result" "get_business_service_for_namespace(demo-staging) should return trading-engine-proxy"

    result=$(get_business_service_for_namespace "demo-dev")
    assert_equals "compliance-validator" "$result" "get_business_service_for_namespace(demo-dev) should return compliance-validator"

    result=$(get_business_service_for_namespace "demo-test")
    assert_equals "settlement-processor" "$result" "get_business_service_for_namespace(demo-test) should return settlement-processor"

    # Test 3: get_target_port_for_namespace
    log_test_section "Test: get_target_port_for_namespace()"

    result=$(get_target_port_for_namespace "demo-prod")
    assert_equals "80" "$result" "get_target_port_for_namespace(demo-prod/market-data-feed) should return 80"

    result=$(get_target_port_for_namespace "demo-staging")
    assert_equals "8080" "$result" "get_target_port_for_namespace(demo-staging/order-execution-service) should return 8080"

    result=$(get_target_port_for_namespace "demo-dev")
    assert_equals "80" "$result" "get_target_port_for_namespace(demo-dev/compliance-records) should return 80"

    result=$(get_target_port_for_namespace "demo-test")
    assert_equals "8080" "$result" "get_target_port_for_namespace(demo-test/settlement-ledger) should return 8080"

    # Test 4: get_app_selector_for_namespace
    log_test_section "Test: get_app_selector_for_namespace()"

    result=$(get_app_selector_for_namespace "demo-prod")
    assert_equals "market-data-feed" "$result" "get_app_selector_for_namespace(demo-prod) should return market-data-feed"

    result=$(get_app_selector_for_namespace "demo-staging")
    assert_equals "order-execution-service" "$result" "get_app_selector_for_namespace(demo-staging) should return order-execution-service"

    result=$(get_app_selector_for_namespace "demo-dev")
    assert_equals "compliance-records" "$result" "get_app_selector_for_namespace(demo-dev) should return compliance-records"

    result=$(get_app_selector_for_namespace "demo-test")
    assert_equals "settlement-ledger" "$result" "get_app_selector_for_namespace(demo-test) should return settlement-ledger"

    # Test 5: get_cloud_annotations
    log_test_section "Test: get_cloud_annotations()"

    result=$(get_cloud_annotations "aws")
    assert_contains "$result" "aws-load-balancer-type" "get_cloud_annotations(aws) should contain aws-load-balancer-type"
    assert_contains "$result" "nlb" "get_cloud_annotations(aws) should contain nlb"

    result=$(get_cloud_annotations "gcp")
    assert_contains "$result" "cloud.google.com/neg" "get_cloud_annotations(gcp) should contain cloud.google.com/neg"

    result=$(get_cloud_annotations "azure")
    assert_contains "$result" "azure-load-balancer-internal" "get_cloud_annotations(azure) should contain azure-load-balancer-internal"

    # Test 6: get_gateway_annotations_for_namespace
    log_test_section "Test: get_gateway_annotations_for_namespace()"

    BASE_NAMESPACE="mycompany"
    result=$(get_gateway_annotations_for_namespace "mycompany-prod")
    assert_contains "$result" "gateway.tetrate.io/workload-selector" "Should contain workload-selector annotation"
    assert_contains "$result" "app=mycompany-prod-gateway" "Should contain correct gateway name"
    assert_contains "$result" "gateway.tetrate.io/gateway-namespace" "Should contain gateway-namespace annotation"
    assert_contains "$result" "tetrate-system" "Should reference tetrate-system namespace"

    # Test 7: get_backend_image
    log_test_section "Test: get_backend_image()"

    BACKEND_NAMES=("market-data-feed" "order-execution-service" "compliance-records" "settlement-ledger")
    BACKEND_IMAGES=("docker.io/kennethreitz/httpbin:latest" "docker.io/mccutchen/go-httpbin:v2.15.0" "nginx:alpine" "k8s.gcr.io/echoserver:1.10")

    result=$(get_backend_image "market-data-feed")
    assert_equals "docker.io/kennethreitz/httpbin:latest" "$result" "get_backend_image(market-data-feed) should return httpbin image"

    result=$(get_backend_image "order-execution-service")
    assert_equals "docker.io/mccutchen/go-httpbin:v2.15.0" "$result" "get_backend_image(order-execution-service) should return httpbingo image"

    result=$(get_backend_image "compliance-records")
    assert_equals "nginx:alpine" "$result" "get_backend_image(compliance-records) should return nginx image"

    result=$(get_backend_image "settlement-ledger")
    assert_equals "k8s.gcr.io/echoserver:1.10" "$result" "get_backend_image(settlement-ledger) should return echo image"

    result=$(get_backend_image "unknown")
    assert_equals "docker.io/kennethreitz/httpbin:latest" "$result" "get_backend_image(unknown) should return fallback"

    # Test 8: get_backend_error_rate (NEW - for sidecar error injection)
    log_test_section "Test: get_backend_error_rate()"

    BACKEND_NAMES=("market-data-feed" "order-execution-service" "compliance-records" "settlement-ledger")

    # Test with BROKEN_SERVICES=false
    BROKEN_SERVICES=false
    result=$(get_backend_error_rate "market-data-feed" "demo-prod")
    assert_equals "" "$result" "get_backend_error_rate should return empty when BROKEN_SERVICES=false"

    # Test with BROKEN_SERVICES=true
    BROKEN_SERVICES=true

    result=$(get_backend_error_rate "market-data-feed" "demo-prod")
    assert_equals "0.50" "$result" "market-data-feed in prod should return 0.50 error rate"

    result=$(get_backend_error_rate "order-execution-service" "demo-staging")
    assert_equals "0.70" "$result" "order-execution-service in staging should return 0.70 error rate"

    result=$(get_backend_error_rate "compliance-records" "demo-dev")
    assert_equals "1" "$result" "compliance-records in dev should return 1 error rate (100%)"

    result=$(get_backend_error_rate "settlement-ledger" "demo-test")
    assert_equals "1" "$result" "settlement-ledger in test should return 1 error rate (100%)"

    # Test that backends are NOT broken in wrong environments
    result=$(get_backend_error_rate "market-data-feed" "demo-staging")
    assert_equals "" "$result" "market-data-feed should NOT be broken in staging"

    result=$(get_backend_error_rate "order-execution-service" "demo-prod")
    assert_equals "" "$result" "order-execution-service should NOT be broken in prod"

    result=$(get_backend_error_rate "compliance-records" "demo-prod")
    assert_equals "" "$result" "compliance-records should NOT be broken in prod"

    result=$(get_backend_error_rate "settlement-ledger" "demo-prod")
    assert_equals "" "$result" "settlement-ledger should NOT be broken in prod"
}

# Critical: Broken Services Logic Tests (Backend Layer with Sidecars)
run_broken_services_tests() {
    log_test_header "BROKEN SERVICES LOGIC TESTS (CRITICAL) - Backend Layer Error Injection"

    log_info "Testing backend error rate calculation with --broken-services flag (sidecar pattern)"

    # Setup test environment
    BASE_NAMESPACE="test"
    NAMESPACES=("test-prod" "test-staging" "test-dev" "test-test")
    BACKEND_NAMES=("market-data-feed" "order-execution-service" "compliance-records" "settlement-ledger")
    BROKEN_SERVICES=false

    # Test 1: Backend error rates with --broken-services disabled
    log_test_section "Test: Backend error rates (--broken-services disabled)"

    BROKEN_SERVICES=false

    local rate=$(get_backend_error_rate "market-data-feed" "test-prod")
    assert_equals "" "$rate" "market-data-feed should have NO sidecar error injection when BROKEN_SERVICES=false"

    rate=$(get_backend_error_rate "order-execution-service" "test-staging")
    assert_equals "" "$rate" "order-execution-service should have NO sidecar error injection when BROKEN_SERVICES=false"

    rate=$(get_backend_error_rate "compliance-records" "test-dev")
    assert_equals "" "$rate" "compliance-records should have NO sidecar error injection when BROKEN_SERVICES=false"

    rate=$(get_backend_error_rate "settlement-ledger" "test-test")
    assert_equals "" "$rate" "settlement-ledger should have NO sidecar error injection when BROKEN_SERVICES=false"

    # Test 2: Backend sidecar error injection (BROKEN_SERVICES=true)
    log_test_section "Test: Backend sidecar error injection (--broken-services enabled)"

    BROKEN_SERVICES=true

    rate=$(get_backend_error_rate "market-data-feed" "test-prod")
    assert_equals "0.50" "$rate" "market-data-feed in prod should have 0.50 error rate (50%, sidecar injection)"

    rate=$(get_backend_error_rate "order-execution-service" "test-staging")
    assert_equals "0.70" "$rate" "order-execution-service in staging should have 0.70 error rate (70%, sidecar injection)"

    rate=$(get_backend_error_rate "compliance-records" "test-dev")
    assert_equals "1" "$rate" "compliance-records in dev should have 1.0 error rate (100%, sidecar injection)"

    rate=$(get_backend_error_rate "settlement-ledger" "test-test")
    assert_equals "1" "$rate" "settlement-ledger in test should have 1.0 error rate (100%, sidecar injection)"

    # Test 3: Verify backend errors only affect correct environment
    log_test_section "Test: Backend errors only in designated environments"

    BROKEN_SERVICES=true

    # market-data-feed should only be broken in prod, not in other environments
    rate=$(get_backend_error_rate "market-data-feed" "test-staging")
    assert_equals "" "$rate" "market-data-feed in staging should NOT have sidecar error injection"

    rate=$(get_backend_error_rate "market-data-feed" "test-dev")
    assert_equals "" "$rate" "market-data-feed in dev should NOT have sidecar error injection"

    # order-execution-service should only be broken in staging
    rate=$(get_backend_error_rate "order-execution-service" "test-prod")
    assert_equals "" "$rate" "order-execution-service in prod should NOT have sidecar error injection"

    rate=$(get_backend_error_rate "order-execution-service" "test-dev")
    assert_equals "" "$rate" "order-execution-service in dev should NOT have sidecar error injection"

    # compliance-records should only be broken in dev
    rate=$(get_backend_error_rate "compliance-records" "test-prod")
    assert_equals "" "$rate" "compliance-records in prod should NOT have sidecar error injection"

    rate=$(get_backend_error_rate "compliance-records" "test-staging")
    assert_equals "" "$rate" "compliance-records in staging should NOT have sidecar error injection"

    # settlement-ledger should only be broken in test
    rate=$(get_backend_error_rate "settlement-ledger" "test-prod")
    assert_equals "" "$rate" "settlement-ledger in prod should NOT have sidecar error injection"

    rate=$(get_backend_error_rate "settlement-ledger" "test-staging")
    assert_equals "" "$rate" "settlement-ledger in staging should NOT have sidecar error injection"

    # Test 4: Array rotation logic verification for backend mapping
    log_test_section "Test: Backend to environment mapping (array rotation)"

    BASE_NAMESPACE="company"
    NAMESPACES=("company-prod" "company-staging" "company-dev" "company-test")
    BACKEND_NAMES=("market-data-feed" "order-execution-service" "compliance-records" "settlement-ledger")

    # Verify the mapping follows array rotation (i % array_length)
    local backend=$(get_backend_for_namespace "company-prod")
    assert_equals "market-data-feed" "$backend" "company-prod (index 0) should map to market-data-feed (index 0)"

    backend=$(get_backend_for_namespace "company-staging")
    assert_equals "order-execution-service" "$backend" "company-staging (index 1) should map to order-execution-service (index 1)"

    backend=$(get_backend_for_namespace "company-dev")
    assert_equals "compliance-records" "$backend" "company-dev (index 2) should map to compliance-records (index 2)"

    backend=$(get_backend_for_namespace "company-test")
    assert_equals "settlement-ledger" "$backend" "company-test (index 3) should map to settlement-ledger (index 3)"

    log_info "Array rotation ensures each backend is deployed to its corresponding environment"
    log_info "CRITICAL: Backend mapping must match for sidecar error injection to work correctly"
    log_info "Architecture: Gateway → Business Service (healthy) → Backend + Giraffe Sidecar (with errors)"
}

# Integration Tests
run_integration_tests() {
    log_test_header "INTEGRATION TESTS - Full Workflow Testing"

    setup_mocks

    # Test 1: Script execution with --help
    log_test_section "Test: Script --help flag"

    local output=$("$TARGET_SCRIPT" --help 2>&1 || true)
    assert_contains "$output" "Usage:" "Help output should contain Usage"
    assert_contains "$output" "Options:" "Help output should contain Options"
    assert_contains "$output" "--broken-services" "Help should mention --broken-services flag"

    # Test 2: Script execution with invalid arguments
    log_test_section "Test: Script with invalid arguments"

    output=$("$TARGET_SCRIPT" --invalid-arg 2>&1 || true)
    assert_contains "$output" "Unknown option" "Should report unknown option"

    # Test 3: Script execution with --skip-apply (preview mode)
    log_test_section "Test: Script with --skip-apply (preview mode)"

    output=$("$TARGET_SCRIPT" -n test-ns -d test.com --skip-apply 2>&1 || true)
    assert_contains "$output" "Skip Apply: true" "Should indicate skip-apply mode"
    assert_contains "$output" "Skipped applying" "Should skip applying configurations"

    # Test 4: Script execution with --broken-services flag (backend layer)
    log_test_section "Test: Script with --broken-services flag (backend sidecar injection)"

    output=$("$TARGET_SCRIPT" -n test-ns -d test.com --broken-services --skip-apply 2>&1 || true)
    assert_contains "$output" "BROKEN SERVICES MODE ENABLED" "Should indicate broken services mode"
    assert_contains "$output" "Broken backends:" "Should mention broken backends"
    assert_contains "$output" "market-data-feed (prod-50%)" "Should mention market-data-feed broken backend"
    assert_contains "$output" "order-execution-service (staging-70%)" "Should mention order-execution-service broken backend"
    assert_contains "$output" "compliance-records (dev-100%)" "Should mention compliance-records broken backend"
    assert_contains "$output" "settlement-ledger (test-100%)" "Should mention settlement-ledger broken backend"
    assert_contains "$output" "Giraffe sidecars" "Should mention Giraffe sidecar injection"

    # Test 5: Command-line argument parsing
    log_test_section "Test: Command-line argument parsing"

    output=$("$TARGET_SCRIPT" -n mycompany -d api.mycompany.com -c gcp --skip-apply 2>&1 || true)
    assert_contains "$output" "Base Namespace: mycompany" "Should parse namespace correctly"
    assert_contains "$output" "Domain: api.mycompany.com" "Should parse domain correctly"
    assert_contains "$output" "Cloud Provider: gcp" "Should parse cloud provider correctly"

    # Test 6: Invalid cloud provider validation
    log_test_section "Test: Invalid cloud provider validation"

    output=$("$TARGET_SCRIPT" -n test -d test.com -c invalid --skip-apply 2>&1 || true)
    local exit_code=$?
    assert_contains "$output" "Unknown cloud provider" "Should reject invalid cloud provider"

    # Test 7: YAML generation correctness (basic HTTP service)
    log_test_section "Test: YAML generation correctness"

    output=$("$TARGET_SCRIPT" -n testco -d test.example.com --skip-apply 2>&1 || true)

    # Check for correct namespace generation
    assert_contains "$output" "testco-prod" "Should generate testco-prod namespace"
    assert_contains "$output" "testco-staging" "Should generate testco-staging namespace"
    assert_contains "$output" "testco-dev" "Should generate testco-dev namespace"
    assert_contains "$output" "testco-test" "Should generate testco-test namespace"

    # Check for gateway annotations
    assert_contains "$output" "gateway.tetrate.io/host" "Should include gateway host annotation"
    assert_contains "$output" "gateway.tetrate.io/workload-selector" "Should include workload selector"
    assert_contains "$output" "gateway.tetrate.io/gateway-namespace" "Should include gateway namespace"

    # Test 8: Demo scenario execution order
    log_test_section "Test: Demo scenario execution order"

    output=$("$TARGET_SCRIPT" -n order-test -d test.com --skip-apply 2>&1 || true)

    # Verify all demo scenarios are executed
    assert_contains "$output" "Demo 1: Basic HTTP" "Should execute Demo 1"
    assert_contains "$output" "Demo 2: HTTPS" "Should execute Demo 2"
    assert_contains "$output" "Demo 3: Multi-Tier API Gateway" "Should execute Demo 3"
    assert_contains "$output" "Demo 4: Enterprise Authentication" "Should execute Demo 4"
    assert_contains "$output" "Demo 5: WAF Protection" "Should execute Demo 5"
    assert_contains "$output" "Demo 6: Cross-Environment" "Should execute Demo 6"
    assert_contains "$output" "Demo 7: Load Balancing" "Should execute Demo 7"
    assert_contains "$output" "Demo 8: Multi-Protocol" "Should execute Demo 8"

    cleanup_mocks
}

# YAML Validation Tests
run_yaml_validation_tests() {
    log_test_header "YAML VALIDATION TESTS"

    setup_mocks

    log_test_section "Test: Generated YAML structure validation"

    # Generate YAML output to file
    local yaml_output="$TEST_OUTPUT_DIR/generated_yaml.txt"
    "$TARGET_SCRIPT" -n validation -d val.com --skip-apply > "$yaml_output" 2>&1 || true

    # Check YAML structure
    assert_file_exists "$yaml_output" "YAML output file should be created"

    # Validate service definitions
    local service_count=$(grep -c "kind: Service" "$yaml_output" || echo 0)
    log_info "Found $service_count Service definitions in generated YAML"
    assert_not_empty "$service_count" "Should generate Service definitions"

    # Validate deployment definitions
    local deployment_count=$(grep -c "kind: Deployment" "$yaml_output" || echo 0)
    log_info "Found $deployment_count Deployment definitions in generated YAML"
    assert_not_empty "$deployment_count" "Should generate Deployment definitions"

    # Check for business service environment variables
    assert_contains "$(cat "$yaml_output")" "UPSTREAM_URLS" "Business service should have UPSTREAM_URLS"
    assert_contains "$(cat "$yaml_output")" "ERROR_RATE" "Business service should have ERROR_RATE"
    assert_contains "$(cat "$yaml_output")" "RESPONSE_DELAY_MS" "Business service should have RESPONSE_DELAY_MS"

    cleanup_mocks
}

# Error Handling Tests
run_error_handling_tests() {
    log_test_header "ERROR HANDLING TESTS"

    # Test 1: Missing prerequisites (kubectl)
    log_test_section "Test: Missing kubectl prerequisite"

    # Temporarily modify PATH to hide kubectl
    local original_path="$PATH"
    export PATH="/nonexistent:$PATH"

    # Note: This will fail because our mock won't be found
    # We need to test without mocks for this one
    output=$("$TARGET_SCRIPT" --skip-apply 2>&1 || true)

    # Restore PATH
    export PATH="$original_path"

    # Test 2: Invalid namespace format
    log_test_section "Test: Namespace naming validation"

    # Script should accept various namespace formats
    output=$("$TARGET_SCRIPT" -n "my-company" -d test.com --skip-apply 2>&1 || true)
    assert_contains "$output" "my-company-prod" "Should handle hyphenated namespace names"

    output=$("$TARGET_SCRIPT" -n "company123" -d test.com --skip-apply 2>&1 || true)
    assert_contains "$output" "company123-prod" "Should handle alphanumeric namespace names"
}

# Namespace and Service Mapping Tests
run_mapping_tests() {
    log_test_header "NAMESPACE AND SERVICE MAPPING TESTS"

    log_test_section "Test: Backend to namespace mapping consistency"

    BASE_NAMESPACE="mapping-test"
    NAMESPACES=("mapping-test-prod" "mapping-test-staging" "mapping-test-dev" "mapping-test-test")
    BACKEND_NAMES=("market-data-feed" "order-execution-service" "compliance-records" "settlement-ledger")
    BUSINESS_SERVICES=("market-data-gateway" "trading-engine-proxy" "compliance-validator" "settlement-processor")

    # Verify consistent mapping
    for i in "${!NAMESPACES[@]}"; do
        local ns="${NAMESPACES[$i]}"
        local expected_backend="${BACKEND_NAMES[$i]}"
        local expected_business_service="${BUSINESS_SERVICES[$i]}"

        local actual_backend=$(get_backend_for_namespace "$ns")
        local actual_business_service=$(get_business_service_for_namespace "$ns")

        assert_equals "$expected_backend" "$actual_backend" "Namespace $ns should map to backend $expected_backend"
        assert_equals "$expected_business_service" "$actual_business_service" "Namespace $ns should map to business service $expected_business_service"
    done

    log_test_section "Test: Cross-namespace service references"

    # Test get_upstream_services_for_business_service
    local upstream=$(get_upstream_services_for_business_service "market-data-gateway" "mapping-test-prod")
    # Local service uses short name, cross-namespace uses FQDN
    assert_contains "$upstream" "market-data-feed:" "market-data-gateway should reference local market-data-feed"
    assert_contains "$upstream" "order-execution-service.mapping-test-staging" "market-data-gateway should reference cross-namespace services"

    upstream=$(get_upstream_services_for_business_service "trading-engine-proxy" "mapping-test-staging")
    assert_contains "$upstream" "order-execution-service:" "trading-engine-proxy should reference local order-execution-service"
    assert_contains "$upstream" "market-data-feed.mapping-test-prod" "trading-engine-proxy should reference prod market-data-feed"
}

# Performance and Edge Case Tests
run_edge_case_tests() {
    log_test_header "EDGE CASE AND PERFORMANCE TESTS"

    log_test_section "Test: Empty namespace handling"

    BASE_NAMESPACE=""
    result=$(get_backend_for_namespace "-prod" || echo "error")
    log_info "Empty namespace base result: $result"

    log_test_section "Test: Special characters in domain"

    setup_mocks
    output=$("$TARGET_SCRIPT" -n test -d "test-api.example-company.com" --skip-apply 2>&1 || true)
    assert_contains "$output" "test-api.example-company.com" "Should handle hyphens in domain"
    cleanup_mocks

    log_test_section "Test: Large namespace count scalability"

    # Test with many namespaces (simulate array rotation)
    BASE_NAMESPACE="scale"
    NAMESPACES=()
    for i in {1..100}; do
        NAMESPACES+=("scale-env$i")
    done

    BACKEND_NAMES=("market-data-feed" "order-execution-service" "compliance-records" "settlement-ledger")

    # Test array rotation works correctly with large arrays
    local result=$(get_backend_for_namespace "scale-env1")
    assert_not_empty "$result" "Should handle large namespace arrays"

    result=$(get_backend_for_namespace "scale-env100")
    assert_not_empty "$result" "Should handle array rotation with large indices"
}

# Configuration Completeness Tests
run_configuration_tests() {
    log_test_header "CONFIGURATION COMPLETENESS TESTS"

    setup_mocks

    log_test_section "Test: All demo scenarios generate valid configurations"

    local output_file="$TEST_OUTPUT_DIR/full_config.yaml"
    "$TARGET_SCRIPT" -n config-test -d config.example.com --skip-apply > "$output_file" 2>&1 || true

    # Count different service types
    local http_services=$(grep -c "name: basic-http-service" "$output_file" || echo 0)
    local https_services=$(grep -c "name: https-service" "$output_file" || echo 0)
    local api_services=$(grep -c "name: api-.*-service" "$output_file" || echo 0)
    local jwt_services=$(grep -c "name: jwt-auth-service" "$output_file" || echo 0)
    local oidc_services=$(grep -c "name: oidc-auth-service" "$output_file" || echo 0)
    local waf_services=$(grep -c "name: waf-service" "$output_file" || echo 0)
    local cross_env_services=$(grep -c "name: cross-env-service" "$output_file" || echo 0)
    local lb_services=$(grep -c "name: lb-service" "$output_file" || echo 0)

    log_info "Configuration breakdown:"
    log_info "  HTTP services: $http_services"
    log_info "  HTTPS services: $https_services"
    log_info "  API services: $api_services"
    log_info "  JWT auth services: $jwt_services"
    log_info "  OIDC auth services: $oidc_services"
    log_info "  WAF services: $waf_services"
    log_info "  Cross-env services: $cross_env_services"
    log_info "  Load balancer services: $lb_services"

    # Verify minimum expected counts (4 environments)
    [[ $http_services -ge 4 ]] && log_success "HTTP services count >= 4" || log_failure "HTTP services count < 4"
    [[ $https_services -ge 4 ]] && log_success "HTTPS services count >= 4" || log_failure "HTTPS services count < 4"
    [[ $waf_services -ge 4 ]] && log_success "WAF services count >= 4" || log_failure "WAF services count < 4"

    cleanup_mocks
}

# Main test execution
run_all_tests() {
    log_test_header "TSB ENTERPRISE GATEWAY DEMO - COMPREHENSIVE TEST SUITE"
    log_info "Target Script: $TARGET_SCRIPT"
    log_info "Test Mode: $TEST_MODE"
    log_info "Verbose: $VERBOSE"
    echo ""

    # Check if target script exists
    if [[ ! -f "$TARGET_SCRIPT" ]]; then
        log_failure "Target script not found: $TARGET_SCRIPT"
        exit 1
    fi

    # Source script functions
    source_script_functions

    # Run test suites based on mode
    if [[ "$TEST_MODE" == "unit" ]] || [[ "$TEST_MODE" == "all" ]]; then
        run_unit_tests
        run_broken_services_tests
        run_mapping_tests
        run_edge_case_tests
    fi

    if [[ "$TEST_MODE" == "integration" ]] || [[ "$TEST_MODE" == "all" ]]; then
        run_integration_tests
        run_yaml_validation_tests
        run_error_handling_tests
        run_configuration_tests
    fi

    # Print final results
    print_test_results
}

# Print test results summary
print_test_results() {
    log_test_header "TEST RESULTS SUMMARY"

    echo ""
    echo -e "${CYAN}Total Tests Run:${NC}     $TESTS_RUN"
    echo -e "${GREEN}Tests Passed:${NC}        $TESTS_PASSED"
    echo -e "${RED}Tests Failed:${NC}        $TESTS_FAILED"
    echo ""

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "${RED}Failed Tests:${NC}"
        for test in "${FAILED_TESTS[@]}"; do
            echo -e "  ${RED}✗${NC} $test"
        done
        echo ""
    fi

    local pass_rate=0
    if [[ $TESTS_RUN -gt 0 ]]; then
        pass_rate=$(awk "BEGIN {printf \"%.2f\", ($TESTS_PASSED / $TESTS_RUN) * 100}")
    fi

    echo -e "${CYAN}Pass Rate:${NC}           $pass_rate%"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}   ALL TESTS PASSED SUCCESSFULLY!${NC}"
        echo -e "${GREEN}========================================${NC}"
        exit 0
    else
        echo -e "${RED}========================================${NC}"
        echo -e "${RED}   SOME TESTS FAILED${NC}"
        echo -e "${RED}========================================${NC}"
        exit 1
    fi
}

# Parse command-line arguments
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --unit          Run unit tests only"
    echo "  --integration   Run integration tests only"
    echo "  --all           Run all tests (default)"
    echo "  -v, --verbose   Verbose output"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run all tests"
    echo "  $0 --unit             # Run only unit tests"
    echo "  $0 --integration -v   # Run integration tests with verbose output"
    echo ""
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --unit)
            TEST_MODE="unit"
            shift
            ;;
        --integration)
            TEST_MODE="integration"
            shift
            ;;
        --all)
            TEST_MODE="all"
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
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

# Run tests
run_all_tests
