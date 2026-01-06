#!/bin/bash

# Stop All Services Script
# This script stops all MLOps services in the correct order

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  🛑 Stopping All MLOps Services${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

# Step 1: Stop MLflow
echo -e "${BLUE}[1/4] Stopping MLflow...${NC}"
if pgrep -f "mlflow ui" > /dev/null; then
    echo -e "${YELLOW}Stopping MLflow UI...${NC}"
    pkill -f "mlflow ui"
    sleep 2
    if pgrep -f "mlflow ui" > /dev/null; then
        echo -e "${RED}❌ Failed to stop MLflow gracefully, forcing...${NC}"
        pkill -9 -f "mlflow ui"
    fi
    echo -e "${GREEN}✅ MLflow stopped${NC}"
else
    echo -e "${YELLOW}⏭️  MLflow is not running${NC}"
fi
echo ""

# Step 2: Stop Jenkins (optional)
echo -e "${BLUE}[2/4] Stopping Jenkins...${NC}"
echo -e "${YELLOW}Do you want to stop Jenkins? (y/N):${NC} "
read -r STOP_JENKINS

if [[ "$STOP_JENKINS" =~ ^[Yy]$ ]]; then
    if sudo systemctl is-active --quiet jenkins; then
        echo -e "${YELLOW}Stopping Jenkins service...${NC}"
        sudo systemctl stop jenkins
        echo -e "${GREEN}✅ Jenkins stopped${NC}"
    else
        echo -e "${YELLOW}⏭️  Jenkins is not running${NC}"
    fi
else
    echo -e "${YELLOW}⏭️  Keeping Jenkins running${NC}"
fi
echo ""

# Step 3: Stop Minikube
echo -e "${BLUE}[3/4] Stopping Minikube...${NC}"
if command -v minikube >/dev/null 2>&1; then
    if minikube status | grep -q "Running"; then
        echo -e "${YELLOW}Stopping Minikube cluster...${NC}"
        minikube stop
        echo -e "${GREEN}✅ Minikube stopped${NC}"
    else
        echo -e "${YELLOW}⏭️  Minikube is not running${NC}"
    fi
else
    echo -e "${YELLOW}⏭️  Minikube is not installed${NC}"
fi
echo ""

# Step 4: Stop Docker (optional)
echo -e "${BLUE}[4/4] Stopping Docker...${NC}"
echo -e "${YELLOW}Do you want to stop Docker? (y/N):${NC} "
read -r STOP_DOCKER

if [[ "$STOP_DOCKER" =~ ^[Yy]$ ]]; then
    if sudo systemctl is-active --quiet docker; then
        echo -e "${YELLOW}Stopping Docker service...${NC}"
        sudo systemctl stop docker
        echo -e "${GREEN}✅ Docker stopped${NC}"
    else
        echo -e "${YELLOW}⏭️  Docker is not running${NC}"
    fi
else
    echo -e "${YELLOW}⏭️  Keeping Docker running${NC}"
fi
echo ""

# Summary
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  ✅ Services Stopped!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${CYAN}📊 Current Status:${NC}"
echo ""

# MLflow
echo -e "${BLUE}📈 MLflow:${NC}"
if pgrep -f "mlflow ui" > /dev/null; then
    echo "   Status: Still running (PID: $(pgrep -f 'mlflow ui'))"
else
    echo "   Status: Stopped"
fi
echo ""

# Jenkins
echo -e "${BLUE}🔧 Jenkins:${NC}"
if sudo systemctl is-active --quiet jenkins; then
    echo "   Status: Running"
else
    echo "   Status: Stopped"
fi
echo ""

# Minikube
echo -e "${BLUE}☸️  Minikube:${NC}"
if command -v minikube >/dev/null 2>&1; then
    if minikube status | grep -q "Running"; then
        echo "   Status: Running"
    else
        echo "   Status: Stopped"
    fi
else
    echo "   Status: Not installed"
fi
echo ""

# Docker
echo -e "${BLUE}🐳 Docker:${NC}"
if sudo systemctl is-active --quiet docker; then
    echo "   Status: Running"
else
    echo "   Status: Stopped"
fi
echo ""

echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  📚 Next Steps${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo "To start all services again:"
echo "   ${BLUE}./scripts/start-all-services.sh${NC}"
echo ""
echo "To start individual services:"
echo "   Docker: ${BLUE}sudo systemctl start docker${NC}"
echo "   Minikube: ${BLUE}minikube start${NC}"
echo "   Jenkins: ${BLUE}sudo systemctl start jenkins${NC}"
echo "   MLflow: ${BLUE}./scripts/start-mlflow.sh${NC}"
echo ""

