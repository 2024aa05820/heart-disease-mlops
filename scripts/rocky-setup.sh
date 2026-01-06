#!/bin/bash
#
# Rocky Linux Setup Script for Heart Disease MLOps
#
# This script installs all prerequisites on Rocky Linux:
# - Java 17, Docker, kubectl, Minikube, Jenkins, Python, Tools
#
# Usage:
#   sudo ./scripts/rocky-setup.sh              # Will prompt for system update
#   sudo ./scripts/rocky-setup.sh --skip-update # Skip system update
#   sudo ./scripts/rocky-setup.sh --update      # Force system update
#

set -e

# Parse command line arguments
SKIP_UPDATE=false
FORCE_UPDATE=false

for arg in "$@"; do
    case $arg in
        --skip-update)
            SKIP_UPDATE=true
            shift
            ;;
        --update)
            FORCE_UPDATE=true
            shift
            ;;
        --help|-h)
            echo "Usage: sudo $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-update    Skip system update (faster)"
            echo "  --update         Force system update"
            echo "  --help, -h       Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Ensure /usr/local/bin is in PATH
export PATH="/usr/local/bin:$PATH"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Heart Disease MLOps - Rocky Linux Setup  ${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root: sudo $0${NC}"
    exit 1
fi

# Get the actual user (not root)
ACTUAL_USER=${SUDO_USER:-$USER}
echo -e "${BLUE}Installing for user: $ACTUAL_USER${NC}"
echo ""

# Handle system update based on flags
if [ "$FORCE_UPDATE" = true ]; then
    echo -e "${YELLOW}📦 Updating system (forced)...${NC}"
    dnf update -y
    echo -e "${GREEN}✅ System updated${NC}"
elif [ "$SKIP_UPDATE" = true ]; then
    echo -e "${YELLOW}⏭️  Skipping system update (--skip-update flag)${NC}"
else
    # Ask if user wants to update system
    echo -e "${YELLOW}Do you want to update the system? (This may take several minutes)${NC}"
    echo -e "${BLUE}[y/N]:${NC} "
    read -r UPDATE_SYSTEM

    if [[ "$UPDATE_SYSTEM" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}📦 Updating system...${NC}"
        dnf update -y
        echo -e "${GREEN}✅ System updated${NC}"
    else
        echo -e "${YELLOW}⏭️  Skipping system update${NC}"
    fi
fi

# Install EPEL repository (required for some packages)
echo -e "${YELLOW}📦 Installing EPEL repository...${NC}"
dnf install -y epel-release
echo -e "${GREEN}✅ EPEL repository installed${NC}"
echo ""

# Install Java 17
echo -e "${YELLOW}📦 Installing Java 17...${NC}"
dnf install -y java-17-openjdk java-17-openjdk-devel
echo -e "${GREEN}✅ Java installed:${NC}"
java -version
echo ""

# Install Docker
echo -e "${YELLOW}📦 Installing Docker...${NC}"
dnf install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl start docker
systemctl enable docker

# Add user to docker group
usermod -aG docker $ACTUAL_USER

echo -e "${GREEN}✅ Docker installed:${NC}"
docker --version
echo ""

# Install kubectl
echo -e "${YELLOW}📦 Installing kubectl...${NC}"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl
echo -e "${GREEN}✅ kubectl installed:${NC}"
/usr/local/bin/kubectl version --client
echo ""

# Install Minikube
echo -e "${YELLOW}📦 Installing Minikube...${NC}"
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube
rm -f minikube-linux-amd64
echo -e "${GREEN}✅ Minikube installed:${NC}"
/usr/local/bin/minikube version
echo ""

# Install Jenkins
echo -e "${YELLOW}📦 Installing Jenkins...${NC}"
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf install -y jenkins

# Add jenkins to docker group (Issue 2 fix)
echo -e "${YELLOW}🔧 Configuring Jenkins Docker access...${NC}"
usermod -aG docker jenkins

# Create and configure Minikube directory for Jenkins (Issue 3 fix)
echo -e "${YELLOW}🔧 Configuring Jenkins Minikube access...${NC}"
mkdir -p /var/lib/jenkins/.minikube
mkdir -p /var/lib/jenkins/.kube
chown -R jenkins:jenkins /var/lib/jenkins/.minikube
chown -R jenkins:jenkins /var/lib/jenkins/.kube
chmod -R 755 /var/lib/jenkins/.minikube
chmod -R 755 /var/lib/jenkins/.kube

systemctl daemon-reload
systemctl start jenkins
systemctl enable jenkins

echo -e "${GREEN}✅ Jenkins installed and configured${NC}"
echo ""

# Install additional tools
echo -e "${YELLOW}📦 Installing additional tools...${NC}"
dnf install -y git curl wget jq unzip python3 python3-pip
echo -e "${GREEN}✅ Tools installed${NC}"
echo ""

# Install MLflow and dependencies
echo -e "${YELLOW}📦 Installing MLflow and Python dependencies...${NC}"
pip3 install --upgrade pip
pip3 install mlflow scikit-learn pandas numpy matplotlib seaborn
echo -e "${GREEN}✅ MLflow and dependencies installed${NC}"
mlflow --version
echo ""

# Configure firewall
echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
firewall-cmd --permanent --add-port=8080/tcp  # Jenkins
firewall-cmd --permanent --add-port=5001/tcp  # MLflow
firewall-cmd --permanent --add-port=3000/tcp  # Grafana
firewall-cmd --permanent --add-port=9090/tcp  # Prometheus
firewall-cmd --reload
echo -e "${GREEN}✅ Firewall configured${NC}"
echo ""

# Create MLflow directories
echo -e "${YELLOW}📁 Creating MLflow directories...${NC}"
mkdir -p /var/lib/jenkins/workspace/heart-disease-mlops/mlruns
mkdir -p /var/lib/jenkins/workspace/heart-disease-mlops/logs
chown -R jenkins:jenkins /var/lib/jenkins/workspace/heart-disease-mlops
echo -e "${GREEN}✅ MLflow directories created${NC}"
echo ""

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

# Wait for Jenkins to start
echo -e "${YELLOW}⏳ Waiting for Jenkins to start...${NC}"
sleep 10

# Summary
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  ✅ INSTALLATION COMPLETE!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${BLUE}📋 Installed Components:${NC}"
echo "  ✅ Java 17"
echo "  ✅ Docker"
echo "  ✅ kubectl"
echo "  ✅ Minikube"
echo "  ✅ Jenkins"
echo "  ✅ Python 3 + Tools"
echo "  ✅ MLflow + ML Libraries"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT NEXT STEPS (Follow in Order):${NC}"
echo ""
echo "1. ${YELLOW}Log out and log back in${NC} (for docker group to take effect)"
echo "   Or run: ${BLUE}newgrp docker${NC}"
echo ""
echo "2. ${YELLOW}Start Minikube:${NC}"
echo "   ${BLUE}minikube start --driver=docker --cpus=2 --memory=4096${NC}"
echo ""
echo "   ${GREEN}Wait for Minikube to fully start, then verify:${NC}"
echo "   ${BLUE}minikube status${NC}"
echo ""
echo "3. ${YELLOW}Configure Jenkins to Access Minikube (CRITICAL):${NC}"
echo "   ${BLUE}sudo ./scripts/configure-jenkins-minikube.sh${NC}"
echo ""
echo "   ${GREEN}This script fixes the following issues:${NC}"
echo "   ✅ Copies Minikube config to Jenkins user"
echo "   ✅ Sets up Docker environment variables"
echo "   ✅ Configures Jenkins to use Minikube's Docker daemon"
echo "   ✅ Enables Jenkins to build images directly in Minikube"
echo "   ✅ Fixes 'cluster minikube does not exist' error"
echo "   ✅ Fixes 'pull access denied' error"
echo ""
echo "   ${RED}⚠️  WITHOUT THIS STEP, JENKINS BUILDS WILL FAIL!${NC}"
echo ""
echo "4. ${YELLOW}Access Jenkins:${NC}"
echo "   URL: ${BLUE}http://${SERVER_IP}:8080${NC}"
echo "   Password:"
cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "   (wait a few seconds and run: ${BLUE}sudo cat /var/lib/jenkins/secrets/initialAdminPassword${NC})"
echo ""
echo "5. ${YELLOW}Configure Jenkins UI:${NC}"
echo "   - Install suggested plugins"
echo "   - Create admin user"
echo "   - Add GitHub token (Settings → Credentials → Add)"
echo "     - Kind: Secret text"
echo "     - ID: ${BLUE}github-token${NC}"
echo "     - Secret: Your GitHub Personal Access Token"
echo "   - Create pipeline job pointing to your repository"
echo ""
echo "6. ${YELLOW}Trigger First Build:${NC}"
echo "   - Click 'Build Now' in Jenkins"
echo "   - Monitor console output"
echo "   - All stages should pass ✅"
echo ""
echo "7. ${YELLOW}Access Services:${NC}"
echo ""
echo "   ${BLUE}MLflow UI (Port 5001):${NC}"
echo "   - Check status: ${BLUE}./scripts/check-all-services.sh${NC}"
echo "   - Start MLflow: ${BLUE}./scripts/start-mlflow.sh${NC}"
echo "   - From local machine: ${BLUE}ssh -L 5001:localhost:5001 cloud@${SERVER_IP}${NC}"
echo "   - Then visit: ${BLUE}http://localhost:5001${NC}"
echo ""
echo "   ${BLUE}Grafana (Port 3000):${NC}"
echo "   - Port forward: ${BLUE}kubectl port-forward service/grafana 3000:3000${NC}"
echo "   - Visit: ${BLUE}http://localhost:3000${NC} (admin/admin)"
echo ""
echo "   ${BLUE}Prometheus (Port 9090):${NC}"
echo "   - Port forward: ${BLUE}kubectl port-forward service/prometheus 9090:9090${NC}"
echo "   - Visit: ${BLUE}http://localhost:9090${NC}"
echo ""
echo "   ${BLUE}API (Port 8000):${NC}"
echo "   - Port forward: ${BLUE}kubectl port-forward service/heart-disease-api-service 8000:80${NC}"
echo "   - Visit: ${BLUE}http://localhost:8000/docs${NC}"
echo ""
echo "   ${GREEN}📖 Full guide: ACCESS-SERVICES.md${NC}"
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  📚 Additional Resources${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "📖 Full setup guide: ${BLUE}ROCKY_LINUX_SETUP.md${NC}"
echo "🔧 Service management: ${BLUE}./scripts/manage-services.sh${NC}"
echo "🐛 Fix common issues: ${BLUE}./scripts/fix-jenkins-issues.sh${NC}"
echo "🔍 Alternative setup: ${BLUE}./scripts/setup-jenkins-docker-env.sh${NC}"
echo ""
echo -e "${YELLOW}💡 Troubleshooting Common Errors:${NC}"
echo ""
echo "❌ Error: 'cluster minikube does not exist'"
echo "   Solution:"
echo "   1. Verify Minikube is running: ${BLUE}minikube status${NC}"
echo "   2. Re-run configuration: ${BLUE}sudo ./scripts/configure-jenkins-minikube.sh${NC}"
echo "   3. Check Jenkins can access Docker: ${BLUE}sudo -u jenkins docker ps${NC}"
echo ""
echo "❌ Error: 'pull access denied for heart-disease-api'"
echo "   Solution:"
echo "   - This is already fixed in the Jenkinsfile"
echo "   - All stages now use Minikube's Docker daemon"
echo "   - Just pull latest code: ${BLUE}git pull origin main${NC}"
echo ""
echo "❌ Error: 'Unable to find image locally'"
echo "   Solution:"
echo "   - Already fixed - images are built in Minikube's Docker"
echo "   - No need to pull from registry"
echo "   - Ensure you ran: ${BLUE}sudo ./scripts/configure-jenkins-minikube.sh${NC}"
echo ""
echo "❌ Error: 'MLflow not accessible'"
echo "   Solution:"
echo "   1. Check if running: ${BLUE}pgrep -f 'mlflow ui'${NC}"
echo "   2. Start MLflow: ${BLUE}./scripts/start-mlflow.sh${NC}"
echo "   3. Check logs: ${BLUE}tail -f logs/mlflow.log${NC}"
echo "   4. Verify port: ${BLUE}netstat -tlnp | grep 5001${NC}"
echo ""
echo "❌ Error: 'Grafana/Prometheus not accessible'"
echo "   Solution:"
echo "   1. Check pods: ${BLUE}kubectl get pods${NC}"
echo "   2. Deploy monitoring: ${BLUE}./scripts/setup-monitoring.sh${NC}"
echo "   3. Port forward: ${BLUE}kubectl port-forward service/grafana 3000:3000${NC}"
echo ""
echo -e "${GREEN}============================================${NC}"
echo ""

