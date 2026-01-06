#!/bin/bash
#
# Start Minikube with Low Memory Configuration
# 
# This script starts Minikube with reduced memory requirements
# for systems with limited RAM (2GB instead of 4GB)
#
# Usage:
#   ./scripts/start-minikube-low-memory.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Starting Minikube (Low Memory Mode)${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check if Minikube is already running
if minikube status 2>/dev/null | grep -q "Running"; then
    echo -e "${YELLOW}⚠️  Minikube is already running${NC}"
    echo -e "${BLUE}Current status:${NC}"
    minikube status
    echo ""
    echo -e "${YELLOW}Do you want to stop and restart with low memory settings? (y/N)${NC}"
    read -r RESTART
    if [[ "$RESTART" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Stopping Minikube...${NC}"
        minikube stop
        minikube delete 2>/dev/null || true
    else
        echo -e "${GREEN}Keeping current Minikube instance${NC}"
        exit 0
    fi
fi

# Memory options
# Option 1: Very Low (2GB) - Minimum for basic operations
MEMORY_2GB=2048
CPUS_2GB=2

# Option 2: Low (3GB) - Better performance
MEMORY_3GB=3072
CPUS_3GB=2

# Check available system memory
echo -e "${YELLOW}Checking system memory...${NC}"
if command -v free &> /dev/null; then
    AVAILABLE_MB=$(free -m | awk '/^Mem:/{print $7}')
    echo -e "${BLUE}Available memory: ${AVAILABLE_MB}MB${NC}"
    
    if [ "$AVAILABLE_MB" -lt 2500 ]; then
        echo -e "${RED}⚠️  Warning: Very low available memory (${AVAILABLE_MB}MB)${NC}"
        echo -e "${YELLOW}Using minimum configuration: 2GB RAM, 2 CPUs${NC}"
        SELECTED_MEMORY=$MEMORY_2GB
        SELECTED_CPUS=$CPUS_2GB
    elif [ "$AVAILABLE_MB" -lt 4000 ]; then
        echo -e "${YELLOW}Using low configuration: 2GB RAM, 2 CPUs${NC}"
        SELECTED_MEMORY=$MEMORY_2GB
        SELECTED_CPUS=$CPUS_2GB
    else
        echo -e "${GREEN}Using medium configuration: 3GB RAM, 2 CPUs${NC}"
        SELECTED_MEMORY=$MEMORY_3GB
        SELECTED_CPUS=$CPUS_3GB
    fi
else
    # Default to 2GB if we can't check
    echo -e "${YELLOW}Could not check system memory, using safe defaults: 2GB RAM, 2 CPUs${NC}"
    SELECTED_MEMORY=$MEMORY_2GB
    SELECTED_CPUS=$CPUS_2GB
fi

echo ""
echo -e "${BLUE}Starting Minikube with:${NC}"
echo -e "  Memory: ${SELECTED_MEMORY}MB (${SELECTED_MEMORY}MB)"
echo -e "  CPUs: ${SELECTED_CPUS}"
echo ""

# Start Minikube
echo -e "${YELLOW}Starting Minikube (this may take a few minutes)...${NC}"
if minikube start --driver=docker --cpus=$SELECTED_CPUS --memory=$SELECTED_MEMORY; then
    echo ""
    echo -e "${GREEN}✅ Minikube started successfully!${NC}"
    echo ""
    echo -e "${BLUE}Minikube status:${NC}"
    minikube status
    echo ""
    echo -e "${BLUE}Minikube IP:${NC}"
    minikube ip
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Next Steps:${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo "1. Configure Jenkins to access Minikube:"
    echo "   ${BLUE}sudo ./scripts/configure-jenkins-minikube.sh${NC}"
    echo ""
    echo "2. Deploy the application:"
    echo "   ${BLUE}make deploy${NC}"
    echo ""
    echo "3. Check deployment status:"
    echo "   ${BLUE}kubectl get pods${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}❌ Failed to start Minikube${NC}"
    echo ""
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo "1. Check Docker is running: ${BLUE}docker ps${NC}"
    echo "2. Check available memory: ${BLUE}free -h${NC}"
    echo "3. Try deleting and recreating:"
    echo "   ${BLUE}minikube delete${NC}"
    echo "   ${BLUE}./scripts/start-minikube-low-memory.sh${NC}"
    echo ""
    exit 1
fi

