#!/bin/bash

# Verify Docker Access Script
# This script checks if the current user has proper Docker access

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Docker Access Verification${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check current user
echo -e "${YELLOW}Current user:${NC} $(whoami)"
echo ""

# Check group membership
echo -e "${YELLOW}Current groups:${NC}"
groups
echo ""

# Check if docker group exists
if getent group docker > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker group exists${NC}"
else
    echo -e "${RED}❌ Docker group does not exist${NC}"
    exit 1
fi
echo ""

# Check if user is in docker group (in /etc/group file)
if groups $(whoami) | grep -q '\bdocker\b'; then
    echo -e "${GREEN}✅ User $(whoami) is in docker group (in current session)${NC}"
    IN_DOCKER_GROUP_SESSION=true
else
    echo -e "${RED}❌ User $(whoami) is NOT in docker group (in current session)${NC}"
    IN_DOCKER_GROUP_SESSION=false
fi

# Check if user is in docker group (in /etc/group file)
if id -nG $(whoami) | grep -q '\bdocker\b'; then
    echo -e "${GREEN}✅ User $(whoami) is in docker group (in /etc/group file)${NC}"
    IN_DOCKER_GROUP_FILE=true
else
    echo -e "${RED}❌ User $(whoami) is NOT in docker group (in /etc/group file)${NC}"
    IN_DOCKER_GROUP_FILE=false
fi
echo ""

# Check Docker socket
echo -e "${YELLOW}Docker socket permissions:${NC}"
ls -l /var/run/docker.sock
echo ""

# Try to access Docker
echo -e "${YELLOW}Testing Docker access:${NC}"
if docker ps > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker access works!${NC}"
    docker version --format 'Client: {{.Client.Version}} | Server: {{.Server.Version}}'
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  ✅ All checks passed!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo -e "${BLUE}You can now run:${NC}"
    echo -e "  ${BLUE}minikube start --driver=docker --cpus=2 --memory=4096${NC}"
    exit 0
else
    echo -e "${RED}❌ Docker access failed${NC}"
    echo ""
    echo -e "${YELLOW}============================================${NC}"
    echo -e "${YELLOW}  Diagnosis and Solution${NC}"
    echo -e "${YELLOW}============================================${NC}"
    echo ""
    
    if [ "$IN_DOCKER_GROUP_FILE" = true ] && [ "$IN_DOCKER_GROUP_SESSION" = false ]; then
        echo -e "${YELLOW}📋 Diagnosis:${NC}"
        echo "  - You ARE in the docker group (in /etc/group)"
        echo "  - But your current session doesn't have it active"
        echo ""
        echo -e "${YELLOW}🔧 Solution:${NC}"
        echo "  You need to log out and log back in for the group to take effect."
        echo ""
        echo -e "${BLUE}Option 1 (Recommended):${NC}"
        echo "  1. Exit this session: ${BLUE}exit${NC}"
        echo "  2. SSH back in: ${BLUE}ssh cloud@YOUR_SERVER_IP${NC}"
        echo "  3. Run this script again to verify: ${BLUE}./scripts/verify-docker-access.sh${NC}"
        echo ""
        echo -e "${BLUE}Option 2 (Quick fix for current session only):${NC}"
        echo "  Run: ${BLUE}newgrp docker${NC}"
        echo "  Then: ${BLUE}minikube start --driver=docker --cpus=2 --memory=4096${NC}"
        echo "  ${YELLOW}Note: This only works for the current terminal${NC}"
        
    elif [ "$IN_DOCKER_GROUP_FILE" = false ]; then
        echo -e "${YELLOW}📋 Diagnosis:${NC}"
        echo "  - You are NOT in the docker group"
        echo ""
        echo -e "${YELLOW}🔧 Solution:${NC}"
        echo "  Run: ${BLUE}sudo usermod -aG docker \$USER${NC}"
        echo "  Then log out and log back in"
        
    else
        echo -e "${YELLOW}📋 Diagnosis:${NC}"
        echo "  - Unknown issue with Docker access"
        echo ""
        echo -e "${YELLOW}🔧 Solution:${NC}"
        echo "  1. Check Docker service: ${BLUE}sudo systemctl status docker${NC}"
        echo "  2. Restart Docker: ${BLUE}sudo systemctl restart docker${NC}"
        echo "  3. Check socket permissions: ${BLUE}ls -l /var/run/docker.sock${NC}"
    fi
    
    exit 1
fi

