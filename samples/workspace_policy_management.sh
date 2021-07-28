#!/bin/bash
while getopts c: flag
do
    case "${flag}" in
        c) cluster=${OPTARG};;
    esac
done

# Define mappings across clusters, tenants for workspaces configuration validation
clusters["cluster1"]="tenant1"

if [ "$cluster" = "all" ];
then
  # Refresh clusters list
  CLUSTERS=`(tctl get clusters -o json | jq -r '.[] | .metadata.name')`;
  echo $CLUSTERS;
  # Refresh tenants list
  TENANTS=`(tctl get tenant -o json | jq -r '.[] | .metadata.name')`;
  echo $TENANTS;
  # Refresh workspaces list
else
  TENANTS="${clusters[$cluster]}";
fi

WORKSPACES=()
for tenant in $TENANTS; 
do 
       export tenant=$tenant
       echo "TENANT:$tenant"; 
       export workspace=`(tctl get workspace --tenant $tenant  -o json | jq -r '.metadata.name')`;
       echo "WORKSPACE: $workspace"; 
       workspace_clusters=`(tctl get workspace --tenant $tenant  -o json | jq -r '.spec.namespaceSelector.names')`;
       echo "WORKSPACE_CLUSTERS: $workspace_clusters";
       # Insert cluster mapping validation within workspace
       export workspacesettings=`(tctl get workspacesettings --tenant $tenant --workspace $workspace  -o json | jq -r '.metadata.name')`;
       echo "WORKSPACESETTINGS: $workspacesettings";
       # If workspacesettings are not applied, apply
       if [ -z $workspacesettings ];
       then
          echo "APPLYING POLICY...FROM GITHUB"
          #curl https://raw.githubusercontent.com/smarunich/monorepo/main/samples/globalpolicy-workspacesettings.yaml | envsubst
          curl -s https://raw.githubusercontent.com/smarunich/monorepo/main/samples/globalpolicy-workspacesettings.yaml | envsubst | tctl apply -f - 
       # If  applied workspacesettings are applied, compare and apply
        echo "THE POLICY WAS SUCCESFULLY COMPLETED"
       else
          echo "APPLIED POLICY IS UP TO DATE"
       fi
       echo ""
done
