#!/bin/bash

# Fix Minikube certificate permissions for Jenkins
# Run this script ONCE on your Jenkins server as the user who started Minikube

echo "🔧 Fixing Minikube certificate permissions..."

# Find the Minikube directory
MINIKUBE_DIR="${HOME}/.minikube"

if [ ! -d "$MINIKUBE_DIR" ]; then
    echo "❌ Minikube directory not found at $MINIKUBE_DIR"
    echo "Please run this script as the user who started Minikube"
    exit 1
fi

# Make certificates readable by all users
echo "📁 Setting permissions on $MINIKUBE_DIR"
chmod -R a+rX "$MINIKUBE_DIR"

# Verify permissions
if [ -r "$MINIKUBE_DIR/profiles/minikube/client.crt" ]; then
    echo "✅ Permissions fixed successfully!"
    echo "Jenkins should now be able to access Minikube certificates"
else
    echo "⚠️  Warning: Could not verify certificate permissions"
    echo "You may need to run: sudo chmod -R a+rX $MINIKUBE_DIR"
fi

