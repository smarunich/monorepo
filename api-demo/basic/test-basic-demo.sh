#!/bin/bash

# HTTPBin Test Suite
# Configure these variables for your environment
IP_ADDRESS="4.255.92.108"
HOST_HEADER="basic.demo.example.com"

# Optional: Output directory for downloaded files
OUTPUT_DIR="./httpbin_test_output"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Function to print section headers
print_section() {
    echo -e "\n${GREEN}===================================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}===================================================${NC}\n"
}

# Function to run curl command with description
run_test() {
    echo -e "${YELLOW}Running: $1${NC}"
    shift
    "$@"
    echo ""
}

# Start testing
echo -e "${GREEN}Starting HTTPBin Test Suite${NC}"
echo -e "Target IP: ${IP_ADDRESS}"
echo -e "Host Header: ${HOST_HEADER}\n"

# ===== BASIC HTTP METHODS =====
print_section "BASIC HTTP METHODS"

run_test "GET request (headers only)" \
    curl -I "http://${IP_ADDRESS}/get" -H"Host: ${HOST_HEADER}"

run_test "GET request (full response)" \
    curl "http://${IP_ADDRESS}/get" -H"Host: ${HOST_HEADER}"

run_test "POST request" \
    curl -X POST "http://${IP_ADDRESS}/post" -H"Host: ${HOST_HEADER}" -d "test=data"

run_test "PUT request" \
    curl -X PUT "http://${IP_ADDRESS}/put" -H"Host: ${HOST_HEADER}" -d "test=data"

run_test "DELETE request" \
    curl -X DELETE "http://${IP_ADDRESS}/delete" -H"Host: ${HOST_HEADER}"

run_test "PATCH request" \
    curl -X PATCH "http://${IP_ADDRESS}/patch" -H"Host: ${HOST_HEADER}" -d "test=data"

# ===== STATUS CODES =====
print_section "STATUS CODES"

for code in 200 201 301 302 400 401 403 404 500 502 503; do
    run_test "Status code ${code}" \
        curl -I "http://${IP_ADDRESS}/status/${code}" -H"Host: ${HOST_HEADER}"
done

# ===== REQUEST INSPECTION =====
print_section "REQUEST INSPECTION"

run_test "Headers inspection" \
    curl "http://${IP_ADDRESS}/headers" -H"Host: ${HOST_HEADER}"

run_test "IP address" \
    curl "http://${IP_ADDRESS}/ip" -H"Host: ${HOST_HEADER}"

run_test "User agent" \
    curl "http://${IP_ADDRESS}/user-agent" -H"Host: ${HOST_HEADER}"

# ===== RESPONSE FORMATS =====
print_section "RESPONSE FORMATS"

run_test "JSON response" \
    curl "http://${IP_ADDRESS}/json" -H"Host: ${HOST_HEADER}"

run_test "XML response" \
    curl "http://${IP_ADDRESS}/xml" -H"Host: ${HOST_HEADER}"

run_test "HTML response" \
    curl "http://${IP_ADDRESS}/html" -H"Host: ${HOST_HEADER}"

run_test "UUID generation" \
    curl "http://${IP_ADDRESS}/uuid" -H"Host: ${HOST_HEADER}"

# ===== AUTHENTICATION TESTING =====
print_section "AUTHENTICATION TESTING"

run_test "Basic auth (will fail without credentials)" \
    curl "http://${IP_ADDRESS}/basic-auth/user/passwd" -H"Host: ${HOST_HEADER}"

run_test "Basic auth with credentials" \
    curl "http://${IP_ADDRESS}/basic-auth/user/passwd" -H"Host: ${HOST_HEADER}" -u user:passwd

run_test "Bearer token authentication" \
    curl "http://${IP_ADDRESS}/bearer" -H"Host: ${HOST_HEADER}" -H"Authorization: Bearer mytoken123"

# ===== REDIRECTION =====
print_section "REDIRECTION"

run_test "Single redirect" \
    curl -L "http://${IP_ADDRESS}/redirect/1" -H"Host: ${HOST_HEADER}"

run_test "Multiple redirects (3)" \
    curl -L "http://${IP_ADDRESS}/redirect/3" -H"Host: ${HOST_HEADER}"

run_test "Absolute redirect" \
    curl -L "http://${IP_ADDRESS}/absolute-redirect/2" -H"Host: ${HOST_HEADER}"

run_test "Relative redirect" \
    curl -L "http://${IP_ADDRESS}/relative-redirect/2" -H"Host: ${HOST_HEADER}"

# ===== RESPONSE MANIPULATION =====
print_section "RESPONSE MANIPULATION"

run_test "Delay response (2 seconds)" \
    curl "http://${IP_ADDRESS}/delay/2" -H"Host: ${HOST_HEADER}"

run_test "Stream data (5 lines)" \
    curl "http://${IP_ADDRESS}/stream/5" -H"Host: ${HOST_HEADER}"

run_test "Random bytes (1024)" \
    curl "http://${IP_ADDRESS}/bytes/1024" -H"Host: ${HOST_HEADER}" -o "${OUTPUT_DIR}/random_bytes.bin"

run_test "Drip data slowly" \
    curl "http://${IP_ADDRESS}/drip?duration=2&numbytes=10" -H"Host: ${HOST_HEADER}"

# ===== COOKIES =====
print_section "COOKIES"

run_test "Set cookies" \
    curl "http://${IP_ADDRESS}/cookies/set?test=value" -H"Host: ${HOST_HEADER}" -c "${OUTPUT_DIR}/cookies.txt"

run_test "Get cookies" \
    curl "http://${IP_ADDRESS}/cookies" -H"Host: ${HOST_HEADER}" -b "${OUTPUT_DIR}/cookies.txt"

# ===== COMPRESSION =====
print_section "COMPRESSION"

run_test "Gzip compression" \
    curl "http://${IP_ADDRESS}/gzip" -H"Host: ${HOST_HEADER}" -H"Accept-Encoding: gzip"

run_test "Deflate compression" \
    curl "http://${IP_ADDRESS}/deflate" -H"Host: ${HOST_HEADER}" -H"Accept-Encoding: deflate"

run_test "Brotli compression" \
    curl "http://${IP_ADDRESS}/brotli" -H"Host: ${HOST_HEADER}" -H"Accept-Encoding: br"

# ===== CACHE TESTING =====
print_section "CACHE TESTING"

run_test "Cache headers" \
    curl "http://${IP_ADDRESS}/cache" -H"Host: ${HOST_HEADER}"

run_test "Cache with 60 seconds" \
    curl "http://${IP_ADDRESS}/cache/60" -H"Host: ${HOST_HEADER}"

run_test "ETag testing" \
    curl "http://${IP_ADDRESS}/etag/test123" -H"Host: ${HOST_HEADER}"

# ===== IMAGES =====
print_section "IMAGES"

run_test "Generic image" \
    curl "http://${IP_ADDRESS}/image" -H"Host: ${HOST_HEADER}" -o "${OUTPUT_DIR}/image.file"

run_test "PNG image" \
    curl "http://${IP_ADDRESS}/image/png" -H"Host: ${HOST_HEADER}" -o "${OUTPUT_DIR}/test.png"

run_test "JPEG image" \
    curl "http://${IP_ADDRESS}/image/jpeg" -H"Host: ${HOST_HEADER}" -o "${OUTPUT_DIR}/test.jpg"

run_test "SVG image" \
    curl "http://${IP_ADDRESS}/image/svg" -H"Host: ${HOST_HEADER}" -o "${OUTPUT_DIR}/test.svg"

# ===== ADDITIONAL UTILITY ENDPOINTS =====
print_section "ADDITIONAL UTILITY ENDPOINTS"

run_test "Base64 decoding" \
    curl "http://${IP_ADDRESS}/base64/SFRUUEJJTiBpcyBhd2Vzb21l" -H"Host: ${HOST_HEADER}"

run_test "Robots.txt" \
    curl "http://${IP_ADDRESS}/robots.txt" -H"Host: ${HOST_HEADER}"

run_test "Response headers customization" \
    curl "http://${IP_ADDRESS}/response-headers?Content-Type=text/plain&X-Custom=test" -H"Host: ${HOST_HEADER}"

run_test "Anything endpoint (accepts any method)" \
    curl -X CUSTOM "http://${IP_ADDRESS}/anything" -H"Host: ${HOST_HEADER}" -d "test=data"

# ===== VERBOSE TESTING =====
print_section "VERBOSE TESTING"

run_test "Show full request/response headers" \
    curl -v "http://${IP_ADDRESS}/get" -H"Host: ${HOST_HEADER}"

run_test "Show timing information" \
    curl -w "\n\nTime_total: %{time_total}\n" "http://${IP_ADDRESS}/delay/1" -H"Host: ${HOST_HEADER}"

run_test "Follow redirects with verbose output" \
    curl -vL "http://${IP_ADDRESS}/redirect/2" -H"Host: ${HOST_HEADER}"

# ===== COMPLETION =====
print_section "TEST SUITE COMPLETED"
echo -e "${GREEN}All tests completed!${NC}"
echo -e "Output files saved in: ${OUTPUT_DIR}"
echo ""
echo "Summary:"
echo "- IP Address tested: ${IP_ADDRESS}"
echo "- Host Header used: ${HOST_HEADER}"
echo "- Output directory: ${OUTPUT_DIR}"

# Optional: Clean up
read -p "Do you want to clean up the output directory? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "${OUTPUT_DIR}"
    echo "Output directory cleaned up."
fi
