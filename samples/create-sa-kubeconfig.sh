#!/bin/bash

# File paths for YAML manifests and kubeconfig
SA_YAML="static-admin-sa.yaml"
SECRET_YAML="static-admin-secret.yaml"
BINDING_YAML="static-admin-binding.yaml"
KUBECONFIG_FILE="admin-kubeconfig.yaml"

# Kubernetes namespace, ServiceAccount, and ClusterRoleBinding names
NAMESPACE="kube-system"
SERVICE_ACCOUNT_NAME="static-admin"
SECRET_NAME="${SERVICE_ACCOUNT_NAME}-token"
CLUSTER_ROLE="cluster-admin"
ROLE_BINDING_NAME="${SERVICE_ACCOUNT_NAME}-binding"

# Create YAML manifests for the resources
function create_yaml_files() {
    # ServiceAccount YAML
    cat <<EOF > ${SA_YAML}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${SERVICE_ACCOUNT_NAME}
  namespace: ${NAMESPACE}
EOF

    # Secret YAML with annotation for the Service Account token
    cat <<EOF > ${SECRET_YAML}
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
  namespace: ${NAMESPACE}
  annotations:
    kubernetes.io/service-account.name: ${SERVICE_ACCOUNT_NAME}
type: kubernetes.io/service-account-token
EOF

    # ClusterRoleBinding YAML
    cat <<EOF > ${BINDING_YAML}
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ${ROLE_BINDING_NAME}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ${CLUSTER_ROLE}
subjects:
- kind: ServiceAccount
  name: ${SERVICE_ACCOUNT_NAME}
  namespace: ${NAMESPACE}
EOF
}

# Apply the YAML manifests to create resources
function apply_manifests() {
    echo "Creating resources..."
    kubectl apply -f ${SA_YAML}
    kubectl apply -f ${SECRET_YAML}
    kubectl apply -f ${BINDING_YAML}
    echo "Resources created successfully."

    # Wait a few seconds to ensure the token is generated
    sleep 5

    # Generate kubeconfig file
    generate_kubeconfig
}

# Generate kubeconfig file for the ServiceAccount
function generate_kubeconfig() {
    echo "Generating kubeconfig for ${SERVICE_ACCOUNT_NAME}..."

    # Retrieve the API server URL, cluster name, and CA certificate
    SERVER_URL=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
    CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
    CA_CERT=$(kubectl get secret/${SECRET_NAME} -n ${NAMESPACE} -o jsonpath='{.data.ca\.crt}')
    TOKEN=$(kubectl get secret/${SECRET_NAME} -n ${NAMESPACE} -o jsonpath='{.data.token}' | base64 --decode)

    # Generate the kubeconfig file
    cat <<EOF > ${KUBECONFIG_FILE}
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: ${CA_CERT}
    server: ${SERVER_URL}
  name: ${CLUSTER_NAME}
contexts:
- context:
    cluster: ${CLUSTER_NAME}
    user: ${SERVICE_ACCOUNT_NAME}
  name: ${SERVICE_ACCOUNT_NAME}-context
current-context: ${SERVICE_ACCOUNT_NAME}-context
users:
- name: ${SERVICE_ACCOUNT_NAME}
  user:
    token: ${TOKEN}
EOF

    echo "Kubeconfig generated at ${KUBECONFIG_FILE}"
}

# Delete the resources using YAML manifests
function delete_manifests() {
    echo "Deleting resources..."
    kubectl delete -f ${BINDING_YAML}
    kubectl delete -f ${SECRET_YAML}
    kubectl delete -f ${SA_YAML}

    # Clean up YAML files and kubeconfig
    rm -f ${SA_YAML} ${SECRET_YAML} ${BINDING_YAML} ${KUBECONFIG_FILE}
    echo "Resources and files deleted successfully."
}

# Main logic to create or delete resources
if [[ "$1" == "create" ]]; then
    create_yaml_files
    apply_manifests
elif [[ "$1" == "delete" ]]; then
    delete_manifests
else
    echo "Usage: $0 {create|delete}"
    exit 1
fi
