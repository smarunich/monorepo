#!/bin/bash

# Define the organization name
ORG="tetrate"

# Discover all tenants within the specified organization and extract names using jq
echo "Discovering Tenants in Org $ORG..."
TENANTS=$(tctl get tenant --org $ORG -o json | jq -r 'if type == "array" then .[] else . end | .metadata.name')

# Loop through each tenant and discover workspaces
for TENANT in $TENANTS; do
    echo "  - Processing Tenant: $TENANT"
    
    # Discover workspaces within the current tenant
    WORKSPACES=$(tctl get workspace --org $ORG --tenant $TENANT -o json | jq -r 'if type == "array" then .[] else . end | .metadata.name')
    
    # Loop through each workspace and discover gateway groups
    for WS in $WORKSPACES; do
        echo "    - Processing Workspace: $WS"
        
        # Discover gateway groups within the current workspace
        GATEWAY_GROUPS=$(tctl get gatewaygroups --workspace $WS --tenant $TENANT --org $ORG -o json | jq -r 'if type == "array" then .[] else . end | .metadata.name')
        
        if [ -z "$GATEWAY_GROUPS" ]; then
            echo "      No Gateway Groups found."
        else
            for GG in $GATEWAY_GROUPS; do
                echo "      - Processing Gateway Group: $GG"
                
                # Fetch the detailed gateway configuration and save it to a file
                tctl get gateway.tsb.tetrate.io/v2/Gateway  --workspace $WS --tenant $TENANT --org $ORG --gatewaygroup $GG -o yaml > "$TENANT-$WS-$GG-gateways.yaml"
                
                echo "      Gateway configuration saved to: $TENANT-$WS-$GG-gateway.yaml"
            done
        fi
    done
done
