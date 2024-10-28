#!/bin/bash

# Set variables
SERVICE_ACCOUNT_NAME="example-sa" # Set your service account name
NAMESPACE="default"               # Set your desired namespace
KUBECONFIG_FILE="sa-kubeconfig.yaml"

# Create the service account
kubectl create serviceaccount $SERVICE_ACCOUNT_NAME -n $NAMESPACE

# Grant admin role to the service account
kubectl create clusterrolebinding ${SERVICE_ACCOUNT_NAME}-admin-binding \
  --clusterrole=admin \
  --serviceaccount=$NAMESPACE:$SERVICE_ACCOUNT_NAME

# Retrieve the service account's token
SECRET_NAME=$(kubectl get sa $SERVICE_ACCOUNT_NAME -n $NAMESPACE -o jsonpath='{.secrets[0].name}')
TOKEN=$(kubectl get secret $SECRET_NAME -n $NAMESPACE -o jsonpath='{.data.token}' | base64 --decode)

# Retrieve the Kubernetes API server URL
SERVER_URL=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

# Generate the kubeconfig file
kubectl config --kubeconfig=$KUBECONFIG_FILE set-cluster kubernetes \
  --server=$SERVER_URL \
  --insecure-skip-tls-verify=true

kubectl config --kubeconfig=$KUBECONFIG_FILE set-credentials $SERVICE_ACCOUNT_NAME \
  --token=$TOKEN

kubectl config --kubeconfig=$KUBECONFIG_FILE set-context sa-context \
  --cluster=kubernetes \
  --user=$SERVICE_ACCOUNT_NAME \
  --namespace=$NAMESPACE

kubectl config --kubeconfig=$KUBECONFIG_FILE use-context sa-context

# Print completion message
echo "Service account '$SERVICE_ACCOUNT_NAME' created with admin permissions in namespace '$NAMESPACE'."
echo "Kubeconfig file generated: $KUBECONFIG_FILE"
