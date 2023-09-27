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

  echo -e "${BLUE}$(date +"%H:%M:%S")${NC} connecting to ${GREEN}https://bookinfo.tetrate.com${NC}..."
  OUTPUT=$(http -h --verify false https://bookinfo.tetrate.com --timeout 1 2>&1)

  if echo "$OUTPUT" | grep -q "error"; then
    # Increment the failure counter
    ((FAIL_COUNT++))
    echo -e "${RED}$OUTPUT${NC}"
  else
    echo -e "${GREEN}$OUTPUT${NC}" | grep --color=always -E "HTTP|tier1-region|tier2-region"
  fi

  sleep 0.5
done
