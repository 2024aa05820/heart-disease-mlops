#!/bin/bash
#
# Alternative Setup: Configure Jenkins to use Minikube's Docker daemon
#
# This approach makes Jenkins use the same Docker daemon as Minikube
# instead of trying to access Minikube directly
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Setup Jenkins Docker Environment         ${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root: sudo $0${NC}"
    exit 1
fi

# Get the actual user
ACTUAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo ~$ACTUAL_USER)

echo -e "${YELLOW}1. Checking Minikube status...${NC}"
if ! sudo -u $ACTUAL_USER minikube status &> /dev/null; then
    echo -e "${RED}❌ Minikube is not running!${NC}"
    echo -e "${YELLOW}Please start Minikube first (as user $ACTUAL_USER): minikube start --driver=docker${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Minikube is running${NC}"
echo ""

echo -e "${YELLOW}2. Getting Minikube Docker environment...${NC}"
# Get Minikube docker-env settings (as the actual user)
DOCKER_ENV=$(sudo -u $ACTUAL_USER minikube docker-env --shell bash)
echo -e "${GREEN}✅ Docker environment retrieved${NC}"
echo ""

echo -e "${YELLOW}3. Creating Jenkins environment script...${NC}"
# Create a script that Jenkins can source
cat > /var/lib/jenkins/minikube-docker-env.sh << 'ENVEOF'
#!/bin/bash
# Source this file to use Minikube's Docker daemon
eval $(minikube docker-env 2>/dev/null || echo "")
ENVEOF

chmod +x /var/lib/jenkins/minikube-docker-env.sh
chown jenkins:jenkins /var/lib/jenkins/minikube-docker-env.sh
echo -e "${GREEN}✅ Environment script created${NC}"
echo ""

echo -e "${YELLOW}4. Copying Minikube certificates to Jenkins...${NC}"
# Copy Minikube certs
if [ -d "$USER_HOME/.minikube/certs" ]; then
    mkdir -p /var/lib/jenkins/.minikube/certs
    cp -r $USER_HOME/.minikube/certs/* /var/lib/jenkins/.minikube/certs/ 2>/dev/null || true
    chown -R jenkins:jenkins /var/lib/jenkins/.minikube
    chmod -R 755 /var/lib/jenkins/.minikube
    echo -e "${GREEN}✅ Certificates copied${NC}"
else
    echo -e "${YELLOW}⚠️  Certificates not found (may not be needed)${NC}"
fi
echo ""

echo -e "${YELLOW}5. Copying Minikube profiles to Jenkins...${NC}"
# Copy profiles
if [ -d "$USER_HOME/.minikube/profiles" ]; then
    mkdir -p /var/lib/jenkins/.minikube/profiles
    cp -r $USER_HOME/.minikube/profiles/* /var/lib/jenkins/.minikube/profiles/ 2>/dev/null || true
    chown -R jenkins:jenkins /var/lib/jenkins/.minikube
    echo -e "${GREEN}✅ Profiles copied${NC}"
else
    echo -e "${YELLOW}⚠️  Profiles not found${NC}"
fi
echo ""

echo -e "${YELLOW}6. Setting Docker socket permissions...${NC}"
chmod 666 /var/run/docker.sock
echo -e "${GREEN}✅ Docker socket accessible${NC}"
echo ""

echo -e "${YELLOW}7. Testing Jenkins Docker access...${NC}"
if sudo -u jenkins docker ps &> /dev/null; then
    echo -e "${GREEN}✅ Jenkins can access Docker!${NC}"
else
    echo -e "${RED}❌ Jenkins cannot access Docker${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}8. Testing Jenkins Minikube Docker access...${NC}"
if sudo -u jenkins bash -c "eval \$(sudo -u $ACTUAL_USER minikube docker-env) && docker ps" &> /dev/null; then
    echo -e "${GREEN}✅ Jenkins can access Minikube Docker daemon!${NC}"
else
    echo -e "${YELLOW}⚠️  Cannot verify Minikube Docker access${NC}"
    echo -e "${YELLOW}   This may still work in Jenkins pipeline${NC}"
fi
echo ""

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  ✅ Setup Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Trigger a Jenkins build"
echo "2. The pipeline will use Minikube's Docker daemon"
echo "3. Images will be built directly in Minikube"
echo ""
echo -e "${BLUE}Note: The Jenkinsfile has been updated to handle this automatically${NC}"
echo ""

