#!/bin/bash
#
# Fix Common Jenkins Issues on Rocky Linux
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Fixing Jenkins Issues                    ${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root: sudo $0${NC}"
    exit 1
fi

# 1. Ensure Jenkins can access Docker
echo -e "${YELLOW}1. Checking Jenkins Docker access...${NC}"
if groups jenkins | grep -q docker; then
    echo -e "${GREEN}✅ Jenkins is in docker group${NC}"
else
    echo -e "${YELLOW}⚠️  Adding jenkins to docker group...${NC}"
    usermod -aG docker jenkins
    echo -e "${GREEN}✅ Jenkins added to docker group${NC}"
fi
echo ""

# 2. Restart Jenkins to apply group changes
echo -e "${YELLOW}2. Restarting Jenkins...${NC}"
systemctl restart jenkins
sleep 5
echo -e "${GREEN}✅ Jenkins restarted${NC}"
echo ""

# 3. Check if Minikube is running
echo -e "${YELLOW}3. Checking Minikube status...${NC}"
if sudo -u jenkins minikube status &> /dev/null; then
    echo -e "${GREEN}✅ Minikube is accessible to Jenkins${NC}"
else
    echo -e "${YELLOW}⚠️  Minikube not accessible to Jenkins${NC}"
    echo -e "${YELLOW}   Setting up Minikube for Jenkins...${NC}"
    
    # Create .minikube directory for jenkins
    mkdir -p /var/lib/jenkins/.minikube
    chown -R jenkins:jenkins /var/lib/jenkins/.minikube
    chmod -R 755 /var/lib/jenkins/.minikube
    
    # Copy minikube config if exists
    if [ -d "$HOME/.minikube" ]; then
        cp -r $HOME/.minikube/* /var/lib/jenkins/.minikube/ 2>/dev/null || true
        chown -R jenkins:jenkins /var/lib/jenkins/.minikube
    fi
    
    echo -e "${GREEN}✅ Minikube directory configured${NC}"
fi
echo ""

# 4. Check if models directory exists
echo -e "${YELLOW}4. Checking models directory...${NC}"
if [ -d "models" ] && [ "$(ls -A models/*.joblib 2>/dev/null)" ]; then
    echo -e "${GREEN}✅ Models directory exists with trained models${NC}"
else
    echo -e "${RED}❌ Models directory missing or empty${NC}"
    echo -e "${YELLOW}   You need to train models first!${NC}"
    echo -e "${YELLOW}   Run these commands:${NC}"
    echo -e "${BLUE}     python3 -m venv venv${NC}"
    echo -e "${BLUE}     source venv/bin/activate${NC}"
    echo -e "${BLUE}     pip install -r requirements.txt${NC}"
    echo -e "${BLUE}     python scripts/download_data.py${NC}"
    echo -e "${BLUE}     python scripts/train.py${NC}"
fi
echo ""

# 5. Kill any processes using port 8001
echo -e "${YELLOW}5. Checking port 8001...${NC}"
if lsof -i :8001 &> /dev/null; then
    echo -e "${YELLOW}⚠️  Port 8001 is in use, killing process...${NC}"
    lsof -ti :8001 | xargs kill -9 2>/dev/null || true
    echo -e "${GREEN}✅ Port 8001 freed${NC}"
else
    echo -e "${GREEN}✅ Port 8001 is available${NC}"
fi
echo ""

# 6. Clean up old Docker containers
echo -e "${YELLOW}6. Cleaning up old test containers...${NC}"
docker ps -a | grep "test-api-" | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null || true
echo -e "${GREEN}✅ Old containers cleaned${NC}"
echo ""

# 7. Verify Docker access
echo -e "${YELLOW}7. Verifying Jenkins can run Docker...${NC}"
if sudo -u jenkins docker ps &> /dev/null; then
    echo -e "${GREEN}✅ Jenkins can access Docker${NC}"
else
    echo -e "${RED}❌ Jenkins still cannot access Docker${NC}"
    echo -e "${YELLOW}   You may need to log out and back in, or reboot the system${NC}"
fi
echo ""

# 8. Verify Minikube access
echo -e "${YELLOW}8. Verifying Jenkins can access Minikube...${NC}"
if sudo -u jenkins minikube status &> /dev/null; then
    echo -e "${GREEN}✅ Jenkins can access Minikube${NC}"
else
    echo -e "${YELLOW}⚠️  Jenkins cannot access Minikube${NC}"
    echo -e "${YELLOW}   Start Minikube first: minikube start --driver=docker${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Fix Complete!${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Ensure models are trained (see step 4 above if needed)"
echo "2. Trigger a new Jenkins build"
echo "3. Monitor the build in Jenkins console"
echo ""
echo -e "${GREEN}If issues persist, check the full Jenkins console output${NC}"
echo ""

