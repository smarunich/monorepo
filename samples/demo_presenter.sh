#!/bin/bash

# ANSI color codes for styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to execute and display a command
execute_command() {
    echo -e "${YELLOW}$1${NC}"  # Display the description in yellow
    if [ ! -z "$2" ]; then  # If no command is passed, skip
        echo -e "${GREEN}Executing Command: $2${NC}"  # Display the command in green
    fi
    read -p "Press Enter to proceed"  # Prompt in blue to proceed
    echo -e "${BLUE}"  # Change the color to red for command output
    $2  # Execute the command
    echo -e "${NC}"  # Reset color to default
}

# Script usage examples
execute_command "Starting the demonstration" ""
execute_command "Checking edge gateways deployment status in US East region, *eastus-0* cluster" "kubectl --context aks-gd1-eastus-0 get pod -n edge"
execute_command "Checking edge gateways deployment status in US East region, *eastus-2* cluster" "kubectl --context aks-gd1-eastus-2 get pod -n edge"
execute_command "Validating DNS resolution from the client located in US East region" ""
execute_command "Validating existing traffic flows from US East and US Central clients" ""

execute_command "Cluster Failure Scenario" ""
execute_command "Failing a *eastus-0* cluster in US East region" "kubectl --context aks-gd1-eastus-0 scale deployment edge-gw --replicas=0 -n edge"
execute_command "Observing Tetrate GSLB controller logs and the impact on the client resolution within US East region" ""

execute_command "Regional Failure Scenario" ""
execute_command "Failing a second and last cluster *eastus-2* in US East region" "kubectl --context aks-gd1-eastus-2 scale deployment edge-gw --replicas=0 -n edge"
execute_command "Observing Tetrate GSLB controller logs and the impact on the client resolution within US East region" ""

execute_command "Recover a *eastus-0* cluster in US East region" "kubectl --context aks-gd1-eastus-0 scale deployment edge-gw --replicas=1 -n edge"
execute_command "Recover a *eastus-2* cluster in US East region" "kubectl --context aks-gd1-eastus-2 scale deployment edge-gw --replicas=1 -n edge"
