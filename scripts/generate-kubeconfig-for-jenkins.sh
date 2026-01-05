#!/bin/bash

# Script to generate a kubeconfig with embedded certificates for Jenkins
# This kubeconfig will have base64-encoded certs, so no file paths are needed
# Run this on the machine where minikube is running

set -e

echo "🔧 Generating kubeconfig with embedded certificates for Jenkins..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

# Check if we can access the cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot access Kubernetes cluster. Make sure minikube is running."
    exit 1
fi

# Generate kubeconfig with embedded certs
OUTPUT_FILE="jenkins-kubeconfig.yaml"
kubectl config view --raw --minify --flatten > "$OUTPUT_FILE"

# Verify the file was created
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "❌ Failed to generate kubeconfig"
    exit 1
fi

# Check if certs are embedded (should contain certificate-authority-data, client-certificate-data, client-key-data)
if grep -q "client-certificate-data" "$OUTPUT_FILE" && grep -q "client-key-data" "$OUTPUT_FILE"; then
    echo "✅ Kubeconfig generated successfully with embedded certificates!"
    echo ""
    echo "📄 File: $OUTPUT_FILE"
    echo ""
    echo "Next steps:"
    echo "1. Copy this file to your local machine:"
    echo "   scp <user>@<jenkins-server>:$(pwd)/$OUTPUT_FILE ."
    echo ""
    echo "2. In Jenkins UI:"
    echo "   - Go to: Manage Jenkins > Credentials > System > Global credentials"
    echo "   - Click 'Add Credentials'"
    echo "   - Kind: Secret file"
    echo "   - File: Upload $OUTPUT_FILE"
    echo "   - ID: kubeconfig-minikube"
    echo "   - Description: Minikube kubeconfig with embedded certs"
    echo "   - Click 'Create'"
    echo ""
    echo "3. Trigger a new build - it will use the credential automatically"
    echo ""
else
    echo "⚠️  Warning: Kubeconfig may not have embedded certificates."
    echo "This might happen if your current kubeconfig uses file paths."
    echo ""
    echo "Trying alternative method..."
    
    # Alternative: manually embed the certificates
    CLUSTER_NAME=$(kubectl config view -o jsonpath='{.contexts[0].context.cluster}')
    USER_NAME=$(kubectl config view -o jsonpath='{.contexts[0].context.user}')
    SERVER=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}')
    
    # Get cert paths from current config
    CA_CERT=$(kubectl config view -o jsonpath='{.clusters[0].cluster.certificate-authority}')
    CLIENT_CERT=$(kubectl config view -o jsonpath='{.users[0].user.client-certificate}')
    CLIENT_KEY=$(kubectl config view -o jsonpath='{.users[0].user.client-key}')
    
    if [ -n "$CA_CERT" ] && [ -f "$CA_CERT" ]; then
        CA_DATA=$(cat "$CA_CERT" | base64 | tr -d '\n')
        CLIENT_CERT_DATA=$(cat "$CLIENT_CERT" | base64 | tr -d '\n')
        CLIENT_KEY_DATA=$(cat "$CLIENT_KEY" | base64 | tr -d '\n')
        
        # Create new kubeconfig with embedded data
        cat > "$OUTPUT_FILE" <<EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: $CA_DATA
    server: $SERVER
  name: $CLUSTER_NAME
contexts:
- context:
    cluster: $CLUSTER_NAME
    user: $USER_NAME
  name: $CLUSTER_NAME
current-context: $CLUSTER_NAME
users:
- name: $USER_NAME
  user:
    client-certificate-data: $CLIENT_CERT_DATA
    client-key-data: $CLIENT_KEY_DATA
EOF
        
        echo "✅ Kubeconfig generated with manually embedded certificates!"
        echo ""
        echo "📄 File: $OUTPUT_FILE"
        echo ""
        echo "Follow the steps above to upload to Jenkins."
    else
        echo "❌ Could not find certificate files to embed."
        echo "Please check your kubectl configuration."
        exit 1
    fi
fi

# Show file size
FILE_SIZE=$(wc -c < "$OUTPUT_FILE")
echo "📊 File size: $FILE_SIZE bytes"
echo ""
echo "⚠️  IMPORTANT: Keep this file secure! It contains credentials to access your cluster."

