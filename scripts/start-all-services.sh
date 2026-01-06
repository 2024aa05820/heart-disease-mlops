#!/bin/bash

# Start All Services Script
# This script starts all required services for the Heart Disease MLOps project
# in the correct order: Docker -> Minikube -> Jenkins -> MLflow -> Monitoring

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
MINIKUBE_CPUS=2
MINIKUBE_MEMORY=4096
MLFLOW_PORT=5001

echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  🚀 Starting All MLOps Services${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for service
wait_for_service() {
    local service_name=$1
    local check_command=$2
    local max_wait=${3:-30}
    local wait_time=0
    
    echo -e "${YELLOW}Waiting for $service_name to be ready...${NC}"
    while ! eval "$check_command" > /dev/null 2>&1; do
        if [ $wait_time -ge $max_wait ]; then
            echo -e "${RED}❌ Timeout waiting for $service_name${NC}"
            return 1
        fi
        sleep 2
        wait_time=$((wait_time + 2))
        echo -n "."
    done
    echo ""
    echo -e "${GREEN}✅ $service_name is ready${NC}"
    return 0
}

# Step 1: Check Docker
echo -e "${BLUE}[1/6] Checking Docker...${NC}"
if ! command_exists docker; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    exit 1
fi

if ! docker ps > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not accessible${NC}"
    echo -e "${YELLOW}Run: ./scripts/verify-docker-access.sh${NC}"
    exit 1
fi

if ! sudo systemctl is-active --quiet docker; then
    echo -e "${YELLOW}Starting Docker service...${NC}"
    sudo systemctl start docker
    wait_for_service "Docker" "docker ps"
else
    echo -e "${GREEN}✅ Docker is running${NC}"
fi
echo ""

# Step 2: Start Minikube
echo -e "${BLUE}[2/6] Starting Minikube...${NC}"
if ! command_exists minikube; then
    echo -e "${RED}❌ Minikube is not installed${NC}"
    exit 1
fi

if minikube status | grep -q "Running"; then
    echo -e "${GREEN}✅ Minikube is already running${NC}"
else
    echo -e "${YELLOW}Starting Minikube (this may take a minute)...${NC}"
    minikube start --driver=docker --cpus=$MINIKUBE_CPUS --memory=$MINIKUBE_MEMORY
    wait_for_service "Minikube" "minikube status | grep -q Running" 60
fi

# Verify kubectl works
if ! kubectl get nodes > /dev/null 2>&1; then
    echo -e "${RED}❌ kubectl cannot connect to Minikube${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Minikube cluster is ready${NC}"
echo ""

# Step 3: Start Jenkins
echo -e "${BLUE}[3/6] Checking Jenkins...${NC}"
if ! sudo systemctl is-active --quiet jenkins; then
    echo -e "${YELLOW}Starting Jenkins service...${NC}"
    sudo systemctl start jenkins
    wait_for_service "Jenkins" "sudo systemctl is-active --quiet jenkins" 60
else
    echo -e "${GREEN}✅ Jenkins is running${NC}"
fi

# Wait for Jenkins to be fully ready
echo -e "${YELLOW}Waiting for Jenkins to be fully ready...${NC}"
wait_for_service "Jenkins HTTP" "curl -s http://localhost:8080 > /dev/null" 90
echo ""

# Step 4: Configure Jenkins for Minikube (if needed)
echo -e "${BLUE}[4/6] Configuring Jenkins for Minikube...${NC}"
if sudo -u jenkins kubectl get nodes > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Jenkins can already access Minikube${NC}"
else
    echo -e "${YELLOW}Configuring Jenkins to access Minikube...${NC}"
    if [ -f "./scripts/configure-jenkins-minikube.sh" ]; then
        sudo ./scripts/configure-jenkins-minikube.sh
    else
        echo -e "${YELLOW}⚠️  configure-jenkins-minikube.sh not found, skipping${NC}"
    fi
fi
echo ""

# Step 5: Start MLflow
echo -e "${BLUE}[5/6] Starting MLflow...${NC}"
if pgrep -f "mlflow ui" > /dev/null; then
    echo -e "${GREEN}✅ MLflow is already running${NC}"
    echo -e "${BLUE}   PID: $(pgrep -f 'mlflow ui')${NC}"
else
    echo -e "${YELLOW}Starting MLflow UI...${NC}"
    
    # Get workspace directory
    if [ -d "/var/lib/jenkins/workspace/heart-disease-mlops" ]; then
        WORKSPACE="/var/lib/jenkins/workspace/heart-disease-mlops"
    else
        WORKSPACE="$PWD"
    fi
    
    # Create directories
    mkdir -p "$WORKSPACE/mlruns"
    mkdir -p "$WORKSPACE/logs"
    
    # Check for MLflow command
    if [ -d "/opt/mlflow-env" ]; then
        MLFLOW_CMD="/opt/mlflow-env/bin/mlflow"
    elif command_exists mlflow; then
        MLFLOW_CMD="mlflow"
    else
        echo -e "${RED}❌ MLflow is not installed${NC}"
        echo -e "${YELLOW}Run: sudo ./scripts/fix-mlflow-install.sh${NC}"
        exit 1
    fi
    
    # Start MLflow
    cd "$WORKSPACE"
    nohup $MLFLOW_CMD ui --host 0.0.0.0 --port $MLFLOW_PORT --backend-store-uri file:///$WORKSPACE/mlruns > logs/mlflow.log 2>&1 &
    
    sleep 3
    
    if pgrep -f "mlflow ui" > /dev/null; then
        echo -e "${GREEN}✅ MLflow started successfully${NC}"
        echo -e "${BLUE}   PID: $(pgrep -f 'mlflow ui')${NC}"
        echo -e "${BLUE}   Log: $WORKSPACE/logs/mlflow.log${NC}"
    else
        echo -e "${RED}❌ Failed to start MLflow${NC}"
        echo -e "${YELLOW}Check logs: tail -f $WORKSPACE/logs/mlflow.log${NC}"
    fi
fi
echo ""

# Step 6: Deploy Monitoring Stack (optional)
echo -e "${BLUE}[6/6] Checking Monitoring Stack...${NC}"
if kubectl get deployment grafana > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Monitoring stack is already deployed${NC}"
else
    echo -e "${YELLOW}Monitoring stack not found${NC}"
    echo -e "${YELLOW}Do you want to deploy it now? (y/N):${NC} "
    read -r DEPLOY_MONITORING
    
    if [[ "$DEPLOY_MONITORING" =~ ^[Yy]$ ]]; then
        if [ -f "./scripts/setup-monitoring.sh" ]; then
            echo -e "${YELLOW}Deploying monitoring stack...${NC}"
            ./scripts/setup-monitoring.sh
        else
            echo -e "${YELLOW}⚠️  setup-monitoring.sh not found, skipping${NC}"
        fi
    else
        echo -e "${YELLOW}⏭️  Skipping monitoring deployment${NC}"
        echo -e "${BLUE}   You can deploy it later with: ./scripts/setup-monitoring.sh${NC}"
    fi
fi
echo ""

# Summary
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  ✅ All Services Started!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${CYAN}📊 Service Status:${NC}"
echo ""

# Docker
echo -e "${BLUE}🐳 Docker:${NC}"
docker --version
echo ""

# Minikube
echo -e "${BLUE}☸️  Minikube:${NC}"
minikube status
echo ""

# Jenkins
echo -e "${BLUE}🔧 Jenkins:${NC}"
echo "   Status: $(sudo systemctl is-active jenkins)"
echo "   URL: http://$(hostname -I | awk '{print $1}'):8080"
echo ""

# MLflow
echo -e "${BLUE}📈 MLflow:${NC}"
if pgrep -f "mlflow ui" > /dev/null; then
    echo "   Status: Running"
    echo "   PID: $(pgrep -f 'mlflow ui')"
    echo "   Port: $MLFLOW_PORT"
    echo "   Access: ssh -L $MLFLOW_PORT:localhost:$MLFLOW_PORT cloud@$(hostname -I | awk '{print $1}')"
else
    echo "   Status: Not running"
fi
echo ""

# Kubernetes
echo -e "${BLUE}☸️  Kubernetes Pods:${NC}"
kubectl get pods 2>/dev/null || echo "   No pods running yet"
echo ""

echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  📚 Next Steps${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo "1. Access Jenkins:"
echo "   ${BLUE}http://$(hostname -I | awk '{print $1}'):8080${NC}"
echo ""
echo "2. Access MLflow (from local machine):"
echo "   ${BLUE}ssh -L $MLFLOW_PORT:localhost:$MLFLOW_PORT cloud@$(hostname -I | awk '{print $1}')${NC}"
echo "   Then visit: ${BLUE}http://localhost:$MLFLOW_PORT${NC}"
echo ""
echo "3. Check all services:"
echo "   ${BLUE}./scripts/check-all-services.sh${NC}"
echo ""
echo "4. View logs:"
echo "   Jenkins: ${BLUE}sudo journalctl -u jenkins -f${NC}"
echo "   MLflow: ${BLUE}tail -f logs/mlflow.log${NC}"
echo ""

