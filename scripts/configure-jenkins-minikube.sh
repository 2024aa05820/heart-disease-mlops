#!/bin/bash
#
# Configure Jenkins to Access Minikube
#
# This script must be run AFTER Minikube is started
# Run as: sudo ./scripts/configure-jenkins-minikube.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Configure Jenkins Minikube Access        ${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root: sudo $0${NC}"
    exit 1
fi

# Get the actual user (not root)
ACTUAL_USER=${SUDO_USER:-$USER}
echo -e "${BLUE}Configuring for user: $ACTUAL_USER${NC}"
echo ""

# Check if Minikube is running
echo -e "${YELLOW}1. Checking if Minikube is running...${NC}"
if ! minikube status &> /dev/null; then
    echo -e "${RED}❌ Minikube is not running!${NC}"
    echo -e "${YELLOW}Please start Minikube first:${NC}"
    echo -e "${BLUE}  minikube start --driver=docker --cpus=2 --memory=4096${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Minikube is running${NC}"
echo ""

# Copy Minikube configuration to Jenkins
echo -e "${YELLOW}2. Copying Minikube config to Jenkins...${NC}"

# Get the home directory of the actual user
USER_HOME=$(eval echo ~$ACTUAL_USER)

if [ -d "$USER_HOME/.minikube" ]; then
    # Copy minikube config
    cp -r $USER_HOME/.minikube/* /var/lib/jenkins/.minikube/ 2>/dev/null || true
    chown -R jenkins:jenkins /var/lib/jenkins/.minikube
    chmod -R 755 /var/lib/jenkins/.minikube
    echo -e "${GREEN}✅ Minikube config copied${NC}"
else
    echo -e "${RED}❌ Minikube config not found at $USER_HOME/.minikube${NC}"
    exit 1
fi
echo ""

# Copy kubectl config to Jenkins
echo -e "${YELLOW}3. Copying kubectl config to Jenkins...${NC}"
if [ -d "$USER_HOME/.kube" ]; then
    cp -r $USER_HOME/.kube/* /var/lib/jenkins/.kube/ 2>/dev/null || true
    chown -R jenkins:jenkins /var/lib/jenkins/.kube
    chmod -R 755 /var/lib/jenkins/.kube
    echo -e "${GREEN}✅ kubectl config copied${NC}"
else
    echo -e "${YELLOW}⚠️  kubectl config not found (this is OK)${NC}"
fi
echo ""

# Get the Minikube profile name
MINIKUBE_PROFILE=$(minikube profile 2>/dev/null || echo "minikube")
echo -e "${BLUE}Using Minikube profile: $MINIKUBE_PROFILE${NC}"
echo ""

# Set MINIKUBE_HOME environment variable for Jenkins
echo -e "${YELLOW}4. Setting environment variables for Jenkins...${NC}"
JENKINS_ENV_FILE="/etc/systemd/system/jenkins.service.d/override.conf"
mkdir -p /etc/systemd/system/jenkins.service.d/

cat > $JENKINS_ENV_FILE << EOF
[Service]
Environment="MINIKUBE_HOME=/var/lib/jenkins/.minikube"
Environment="KUBECONFIG=/var/lib/jenkins/.kube/config"
Environment="DOCKER_HOST=unix:///var/run/docker.sock"
Environment="MINIKUBE_ACTIVE_DOCKERD=$MINIKUBE_PROFILE"
EOF

echo -e "${GREEN}✅ Environment variables configured${NC}"
echo ""

# Ensure Jenkins can access Docker socket
echo -e "${YELLOW}5. Ensuring Jenkins can access Docker socket...${NC}"
chmod 666 /var/run/docker.sock 2>/dev/null || true
echo -e "${GREEN}✅ Docker socket permissions set${NC}"
echo ""

# Restart Jenkins to apply changes
echo -e "${YELLOW}6. Restarting Jenkins...${NC}"
systemctl daemon-reload
systemctl restart jenkins
sleep 5
echo -e "${GREEN}✅ Jenkins restarted${NC}"
echo ""

# Verify Jenkins can access Docker
echo -e "${YELLOW}7. Verifying Jenkins can access Docker...${NC}"
if sudo -u jenkins docker ps &> /dev/null; then
    echo -e "${GREEN}✅ Jenkins can access Docker!${NC}"
else
    echo -e "${RED}❌ Jenkins cannot access Docker${NC}"
    echo -e "${YELLOW}   This should have been fixed during installation${NC}"
    echo -e "${YELLOW}   Try: sudo systemctl restart jenkins${NC}"
fi
echo ""

# Verify Jenkins can access Minikube
echo -e "${YELLOW}8. Verifying Jenkins can access Minikube...${NC}"
sleep 5  # Wait for Jenkins to fully start

# Test with explicit environment variables
if sudo -u jenkins bash -c "MINIKUBE_HOME=/var/lib/jenkins/.minikube KUBECONFIG=/var/lib/jenkins/.kube/config minikube status" &> /dev/null; then
    echo -e "${GREEN}✅ Jenkins can access Minikube!${NC}"
else
    echo -e "${YELLOW}⚠️  Direct verification failed, trying alternative method...${NC}"

    # Try using docker context
    if sudo -u jenkins bash -c "eval \$(minikube docker-env) && docker ps" &> /dev/null; then
        echo -e "${GREEN}✅ Jenkins can access Minikube via Docker!${NC}"
    else
        echo -e "${RED}❌ Jenkins cannot access Minikube${NC}"
        echo -e "${YELLOW}   Debug commands:${NC}"
        echo -e "${BLUE}     sudo -u jenkins minikube status${NC}"
        echo -e "${BLUE}     sudo -u jenkins docker ps${NC}"
        echo -e "${BLUE}     ls -la /var/lib/jenkins/.minikube${NC}"
    fi
fi
echo ""

# Summary
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  ✅ Configuration Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Trigger a Jenkins build"
echo "2. Monitor the build console output"
echo "3. If issues persist, check: sudo -u jenkins minikube status"
echo ""

