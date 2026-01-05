#!/bin/bash
#
# Verification Script for Heart Disease MLOps on Rocky Linux
#
# This script verifies all components are installed and running correctly
#

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Heart Disease MLOps - Verification       ${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Function to check command
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✅ $1 is installed${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 is NOT installed${NC}"
        return 1
    fi
}

# Function to check service
check_service() {
    if sudo systemctl is-active --quiet $1; then
        echo -e "${GREEN}✅ $1 is running${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 is NOT running${NC}"
        return 1
    fi
}

# Check installed components
echo -e "${YELLOW}📦 Checking Installed Components...${NC}"
check_command java
check_command docker
check_command kubectl
check_command minikube
check_command git
check_command python3
echo ""

# Check versions
echo -e "${YELLOW}📋 Component Versions:${NC}"
echo -n "Java: "
java -version 2>&1 | head -1
echo -n "Docker: "
docker --version
echo -n "kubectl: "
kubectl version --client --short 2>/dev/null || kubectl version --client
echo -n "Minikube: "
minikube version --short 2>/dev/null || minikube version
echo ""

# Check services
echo -e "${YELLOW}🔧 Checking Services...${NC}"
check_service docker
check_service jenkins
echo ""

# Check Docker access
echo -e "${YELLOW}🐳 Checking Docker Access...${NC}"
if docker ps &> /dev/null; then
    echo -e "${GREEN}✅ Can run docker without sudo${NC}"
else
    echo -e "${RED}❌ Cannot run docker without sudo${NC}"
    echo -e "${YELLOW}   Run: sudo usermod -aG docker \$USER${NC}"
    echo -e "${YELLOW}   Then log out and back in${NC}"
fi
echo ""

# Check Minikube
echo -e "${YELLOW}☸️  Checking Minikube...${NC}"
if minikube status &> /dev/null; then
    echo -e "${GREEN}✅ Minikube is running${NC}"
    minikube status
    
    # Check kubectl connection
    echo ""
    echo -e "${YELLOW}🔗 Checking kubectl connection...${NC}"
    if kubectl get nodes &> /dev/null; then
        echo -e "${GREEN}✅ kubectl can connect to cluster${NC}"
        kubectl get nodes
    else
        echo -e "${RED}❌ kubectl cannot connect to cluster${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Minikube is not running${NC}"
    echo -e "${YELLOW}   Start with: minikube start --driver=docker --cpus=2 --memory=4096${NC}"
fi
echo ""

# Check Kubernetes deployment
echo -e "${YELLOW}📦 Checking Kubernetes Deployment...${NC}"
if kubectl get deployment heart-disease-api &> /dev/null; then
    echo -e "${GREEN}✅ Deployment exists${NC}"
    kubectl get deployment heart-disease-api
    
    echo ""
    echo -e "${YELLOW}🔍 Checking Pods...${NC}"
    kubectl get pods -l app=heart-disease-api
    
    echo ""
    echo -e "${YELLOW}🌐 Checking Service...${NC}"
    kubectl get service heart-disease-api-service
else
    echo -e "${YELLOW}⚠️  Deployment not found${NC}"
    echo -e "${YELLOW}   Deploy with: make deploy${NC}"
fi
echo ""

# Check API health
echo -e "${YELLOW}🏥 Checking API Health...${NC}"
if kubectl get service heart-disease-api-service &> /dev/null; then
    API_URL=$(minikube service heart-disease-api-service --url 2>/dev/null)
    if [ ! -z "$API_URL" ]; then
        echo "API URL: $API_URL"
        
        # Test health endpoint
        if curl -s -f "$API_URL/health" &> /dev/null; then
            HEALTH=$(curl -s "$API_URL/health")
            echo -e "${GREEN}✅ API is healthy: $HEALTH${NC}"
        else
            echo -e "${RED}❌ API health check failed${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Could not get API URL${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Service not found${NC}"
fi
echo ""

# Check firewall
echo -e "${YELLOW}🔥 Checking Firewall...${NC}"
if sudo firewall-cmd --list-ports | grep -q "8080"; then
    echo -e "${GREEN}✅ Port 8080 (Jenkins) is open${NC}"
else
    echo -e "${RED}❌ Port 8080 (Jenkins) is NOT open${NC}"
fi

if sudo firewall-cmd --list-ports | grep -q "5001"; then
    echo -e "${GREEN}✅ Port 5001 (MLflow) is open${NC}"
else
    echo -e "${RED}❌ Port 5001 (MLflow) is NOT open${NC}"
fi
echo ""

# Get URLs
echo -e "${YELLOW}🌐 Service URLs:${NC}"
SERVER_IP=$(hostname -I | awk '{print $1}')
MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "not-running")

echo "Jenkins:    http://$SERVER_IP:8080"
echo "MLflow:     http://$SERVER_IP:5001"
echo "API:        http://$MINIKUBE_IP:30080"
echo "Swagger:    http://$MINIKUBE_IP:30080/docs"
echo ""

# Summary
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Verification Complete!${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Access Jenkins: http://$SERVER_IP:8080"
echo "2. Start MLflow: make mlflow-ui"
echo "3. Test API: curl http://$MINIKUBE_IP:30080/health"
echo "4. View Swagger: http://$MINIKUBE_IP:30080/docs"
echo ""

