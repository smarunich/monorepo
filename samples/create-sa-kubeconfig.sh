#!/bin/bash

# Set default variables, can be overridden by passing environment variables
SERVICE_ACCOUNT_NAME="admin-account"   # Service account name
NAMESPACE="default"                    # Kubernetes namespace
SA_CONTEXT="${SA_CONTEXT:-sa-context}" # Context name
CLUSTER_NAME="${CLUSTER_NAME:-kubernetes}" # Cluster name
KUBECONFIG_FILE="${SA_CONTEXT}-kubeconfig.yaml" # Kubeconfig output file based on context name

# Create the service account
kubectl create serviceaccount $SERVICE_ACCOUNT_NAME -n $NAMESPACE

# Grant admin role to the service account
kubectl create clusterrolebinding ${SERVICE_ACCOUNT_NAME}-admin-binding \
  --clusterrole=admin \
  --serviceaccount=$NAMESPACE:$SERVICE_ACCOUNT_NAME

# Retrieve the service account's token name
SECRET_NAME=$(kubectl get sa $SERVICE_ACCOUNT_NAME -n $NAMESPACE -o jsonpath='{.secrets[0].name}')

# Patch the secret to extend token lifetime (disables expiration)
kubectl patch secret $SECRET_NAME -n $NAMESPACE -p '{"metadata": {"annotations": {"kubernetes.io/service-account-token": "true"}}}'

# Extract the token value
TOKEN=$(kubectl get secret $SECRET_NAME -n $NAMESPACE -o jsonpath='{.data.token}' | base64 --decode)

# Retrieve the Kubernetes API server URL
SERVER_URL=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

# Generate the kubeconfig file and embed the token directly in the configuration
cat <<EOF > $KUBECONFIG_FILE
apiVersion: v1
kind: Config
clusters:
- name: $CLUSTER_NAME
  cluster:
    server: $SERVER_URL
    insecure-skip-tls-verify: true
contexts:
- name: $SA_CONTEXT
  context:
    cluster: $CLUSTER_NAME
    user: $SERVICE_ACCOUNT_NAME
    namespace: $NAMESPACE
current-context: $SA_CONTEXT
users:
- name: $SERVICE_ACCOUNT_NAME
  user:
    token: $TOKEN
EOF

# Export KUBECONFIG environment variable for the generated profile
export KUBECONFIG=$(realpath $KUBECONFIG_FILE)
echo "KUBECONFIG exported to: $KUBECONFIG"

# Print completion message
echo "Service account '$SERVICE_ACCOUNT_NAME' created with admin permissions in namespace '$NAMESPACE'."
echo "Kubeconfig file generated: $KUBECONFIG_FILE (including token for sharing)"
echo "Context name: $SA_CONTEXT, Cluster name: $CLUSTER_NAME"
