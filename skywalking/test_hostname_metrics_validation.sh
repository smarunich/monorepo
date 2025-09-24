#!/bin/bash

echo "=== HOSTNAME-BASED SERVICE VALIDATION ==="
echo "Testing basic.api.example.com with all 12 metrics"

declare -a metrics=(
  "service_status_code"
  "service_percentile"
  "service_cpm / 60"
  "(10000 - service_sla) / 100"
  "service_resp_time"
  "service_apdex / 10000"
  "service_sidecar_internal_req_latency_nanos"
  "service_sidecar_internal_resp_latency_nanos"
  "service_cpm"
  "service_sla / 100"
  "service_sidecar_internal_req_latency_nanos / 1000000"
  "service_sidecar_internal_resp_latency_nanos / 1000000"
)

declare -a names=(
  "Status Code Distribution"
  "Response Time Percentiles"  
  "Request Rate (RPS)"
  "Error Rate"
  "Average Response Time"
  "Apdex Score"
  "Sidecar Internal Req Latency (ns)"
  "Sidecar Internal Resp Latency (ns)"
  "Request Throughput (CPM)"
  "Success Rate (SLA)"
  "Sidecar Internal Req Latency (ms)"
  "Sidecar Internal Resp Latency (ms)"
)

# Test different hostname formats
hostname_formats=(
  "basic.api.example.com|gateway|*|*|*"
  "*|basic.api.example.com|gateway|*|*"
  "basic.api.example.com|gateway|tetrate-system|*|*"
  "*|gateway|tetrate-system|*|*"
)

echo "First, testing which hostname format works..."
for format in "${hostname_formats[@]}"; do
  echo -e "\nTesting format: $format"
  
  result=$(curl -s -X POST http://localhost:12800/graphql \
    -H 'Content-Type: application/json' \
    -d "{
      \"query\": \"{ execExpression(expression: \\\"service_resp_time\\\", entity: { serviceName: \\\"$format\\\", normal: true }, duration: { start: \\\"2025-09-23 1832\\\", end: \\\"2025-09-23 1847\\\", step: MINUTE }) { error results { values { id value } } } }\"
    }" | jq -r '(.data.execExpression.results[0].values // []) | map(select(.value != null and .value != "null")) | length')
  
  echo "  Non-null values: $result"
  
  if [[ "$result" -gt 0 ]]; then
    echo "  ✓ HOSTNAME FORMAT WORKS!"
    working_format="$format"
    break
  fi
done

if [[ -z "$working_format" ]]; then
  echo "❌ No working hostname format found for basic.api.example.com"
  exit 1
fi

echo -e "\n=== Using working format: $working_format ==="
echo "Testing all 12 metrics..."

passed=0
failed=0

for i in "${!metrics[@]}"; do
  expr="${metrics[$i]}"
  name="${names[$i]}"
  
  echo -e "\n[$((i+1))/12] $name"
  
  response=$(curl -s -X POST http://localhost:12800/graphql \
    -H 'Content-Type: application/json' \
    -d "{
      \"query\": \"{ execExpression(expression: \\\"$expr\\\", entity: { serviceName: \\\"$working_format\\\", normal: true }, duration: { start: \\\"2025-09-23 1832\\\", end: \\\"2025-09-23 1847\\\", step: MINUTE }) { error results { values { id value } } } }\"
    }")
  
  error=$(echo "$response" | jq -r '.data.execExpression.error // "null"')
  if [[ "$error" != "null" ]]; then
    echo "  ✗ GraphQL Error: $error"
    failed=$((failed + 1))
    continue
  fi
  
  non_null_count=$(echo "$response" | jq -r '(.data.execExpression.results[0].values // []) | map(select(.value != null and .value != "null")) | length')
  
  if [[ "$non_null_count" -gt 0 ]]; then
    sample_value=$(echo "$response" | jq -r '(.data.execExpression.results[0].values // []) | map(select(.value != null and .value != "null")) | .[0].value')
    echo "  ✓ WORKS! ($non_null_count values) - Sample: $sample_value"
    passed=$((passed + 1))
  else
    echo "  ✗ No data"
    failed=$((failed + 1))
  fi
done

echo -e "\n=== HOSTNAME METRICS SUMMARY ==="
echo "Format used: $working_format"
echo "✓ Working metrics: $passed/12"
echo "✗ Failed metrics: $failed/12"

if [[ "$failed" -eq 0 ]]; then
  echo "🎉 ALL HOSTNAME METRICS WORKING!"
else
  echo "⚠️  Some hostname metrics need attention"
fi
