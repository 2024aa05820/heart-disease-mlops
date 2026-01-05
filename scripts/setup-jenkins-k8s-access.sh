#!/bin/bash

# One-time setup script to allow Jenkins to access Minikube
# Run this ONCE on your Jenkins server with sudo privileges

echo "🔧 Setting up Jenkins access to Minikube..."

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run with sudo: sudo ./scripts/setup-jenkins-k8s-access.sh"
    exit 1
fi

# Make Minikube certificates readable by all users
echo "📁 Making Minikube certificates readable..."
chmod -R a+rX /home/cloud/.minikube/

# Verify
if [ -r /home/cloud/.minikube/profiles/minikube/client.crt ]; then
    echo "✅ Certificates are now readable!"
else
    echo "❌ Failed to make certificates readable"
    exit 1
fi

# Add Jenkins user to docker group (if not already)
if groups jenkins | grep -q docker; then
    echo "✅ Jenkins user already in docker group"
else
    echo "➕ Adding Jenkins user to docker group..."
    usermod -aG docker jenkins
    echo "✅ Jenkins added to docker group (restart Jenkins service for this to take effect)"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Restart Jenkins service: sudo systemctl restart jenkins"
echo "2. Trigger a new build in Jenkins"
echo ""

