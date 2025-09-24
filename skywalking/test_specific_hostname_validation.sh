#!/bin/bash

echo "=== TESTING SPECIFIC HOSTNAME: basic.demo.example.com|gateway|*|* ==="

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

service_name="basic.demo.example.com|gateway|*|*"
passed=0
failed=0

echo "Testing hostname format: $service_name"
echo "Time range: 2025-09-23 1832 to 2025-09-23 1847"

for i in "${!metrics[@]}"; do
  expr="${metrics[$i]}"
  name="${names[$i]}"
  
  echo -e "\n[$((i+1))/12] $name"
  echo "Expression: $expr"
  
  response=$(curl -s -X POST http://localhost:12800/graphql \
    -H 'Content-Type: application/json' \
    -d "{
      \"query\": \"{ execExpression(expression: \\\"$expr\\\", entity: { serviceName: \\\"$service_name\\\", normal: true }, duration: { start: \\\"2025-09-23 1832\\\", end: \\\"2025-09-23 1847\\\", step: MINUTE }) { error results { values { id value } } } }\"
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
    echo "  ✗ No data - all values are null"
    failed=$((failed + 1))
  fi
done

echo -e "\n=== SPECIFIC HOSTNAME METRICS SUMMARY ==="
echo "Hostname: basic.demo.example.com"
echo "Format: $service_name"
echo "✓ Working metrics: $passed/12"
echo "✗ Failed metrics: $failed/12"

if [[ "$failed" -eq 0 ]]; then
  echo "🎉 ALL HOSTNAME METRICS WORKING WITH SPECIFIC HOSTNAME!"
else
  echo "⚠️  Some hostname metrics need attention"
fi

echo -e "\nFormat to use in UI buildSPMServiceName:"
echo "buildSPMServiceName('basic.demo.example.com', 'gateway', '*', '*')"
echo "Result: basic.demo.example.com|gateway|*|*"
