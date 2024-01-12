#!/usr/bin/env bash

# Define the color codes
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Initialize counters
FAIL_COUNT=0
TOTAL_ATTEMPTS=0

# Record the start time
START_TIME=$(date +%s)

# Function to print stats and exit
print_stats_and_exit() {
    # Calculate time duration
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    # Convert duration to hours, minutes, and seconds
    HOURS=$((DURATION / 3600))
    MINUTES=$(((DURATION % 3600) / 60))
    SECONDS=$((DURATION % 60))

    echo -e "${YELLOW}Exiting...${NC}"
    echo -e "${YELLOW}Total attempts: $TOTAL_ATTEMPTS${NC}"
    echo -e "${RED}Failed attempts: $FAIL_COUNT${NC}"
    echo -e "${YELLOW}Time duration: ${HOURS}h ${MINUTES}m ${SECONDS}s${NC}"
    exit
}

# Trap the SIGINT signal (usually triggered by CTRL+C) to print stats before exiting
trap print_stats_and_exit SIGINT

while true; do
  # Increment the total attempts counter
  ((TOTAL_ATTEMPTS++))

  echo -e "${BLUE}$(date +"%H:%M:%S")${NC} connecting to ${GREEN}fx.internal.az-ms.com${NC}..."
  START_TIME=$(date +%s.%N)
  OUTPUT=$(curl -Ivs http://fx.internal.az-ms.com 2>&1)
  END_TIME=$(date +%s.%N)
  ELAPSED_TIME=$(echo "$END_TIME - $START_TIME" | bc)

  if echo "$OUTPUT" | grep -q "error"; then
    # Increment the failure counter
    ((FAIL_COUNT++))
    echo -e "${GREEN}$OUTPUT${NC}"
  else
    # Extract, color code the IP in 'Connected to' line, and display it
    CONNECTED_LINE=$(echo "$OUTPUT" | grep -E 'Connected to' | head -n 1)
    echo -e "${CONNECTED_LINE}" | sed -r 's/([0-9]{1,3}(\.[0-9]{1,3}){3})/'$'\e[33m''&'$'\e[39m''/'
    
    # Extract and display the line containing the HTTP response code
    RESPONSE_CODE_LINE=$(echo "$OUTPUT" | grep -E 'HTTP/' | tail -1)
    echo -e "${RESPONSE_CODE_LINE}"

    # Extract, color code, and display the 'location:' line
    LOCATION_LINE=$(echo "$OUTPUT" | grep -E 'location:' | head -n 1)
    if echo "$LOCATION_LINE" | grep -q "eastus"; then
      echo -e "${LOCATION_LINE}" | sed 's/eastus/'$'\e[34m''&'$'\e[39m''/'
    elif echo "$LOCATION_LINE" | grep -q "centralus"; then
      echo -e "${LOCATION_LINE}" | sed 's/centralus/'$'\e[32m''&'$'\e[39m''/'
    else
      echo -e "${LOCATION_LINE}"
    fi

    # Extract and display the 'x-envoy-upstream-service-time' line
    ENVOY_TIME_LINE=$(echo "$OUTPUT" | grep -E 'x-envoy-upstream-service-time:' | head -n 1)
    echo -e "${ENVOY_TIME_LINE}"



    # Display the time taken for the curl command
    echo -e "Time taken for request: ${ELAPSED_TIME}s"
  fi

  sleep 0.5
done
