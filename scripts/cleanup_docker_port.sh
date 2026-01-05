#!/bin/bash

################################################################################
# Docker Port Cleanup Script
# 
# This script cleans up Docker containers that are using port 8001
# Run this on your Jenkins/remote machine if you encounter port conflicts
# 
# Usage:
#   ./scripts/cleanup_docker_port.sh
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_header "Docker Port 8001 Cleanup"

# Check if running with Minikube Docker daemon
if command -v minikube &> /dev/null; then
    print_info "Minikube found, using Minikube's Docker daemon"
    eval $(minikube docker-env) || print_error "Failed to set Minikube Docker env"
fi

# Show current containers using port 8001
print_info "Containers currently using port 8001:"
docker ps -a --format '{{.ID}} {{.Names}} {{.Ports}}' | grep '8001' || echo "None found"
echo ""

# Stop running containers on port 8001
print_info "Stopping containers using port 8001..."
RUNNING_CONTAINERS=$(docker ps --filter "publish=8001" -q)
if [ -n "$RUNNING_CONTAINERS" ]; then
    echo "$RUNNING_CONTAINERS" | xargs docker stop
    print_success "Stopped running containers"
else
    print_info "No running containers found on port 8001"
fi
echo ""

# Remove all containers (running or stopped) using port 8001
print_info "Removing all containers using port 8001..."
ALL_CONTAINERS=$(docker ps -a --filter "publish=8001" -q)
if [ -n "$ALL_CONTAINERS" ]; then
    echo "$ALL_CONTAINERS" | xargs docker rm -f
    print_success "Removed containers"
else
    print_info "No containers found on port 8001"
fi
echo ""

# Clean up test-api containers
print_info "Cleaning up test-api-* containers..."
TEST_CONTAINERS=$(docker ps -a | grep 'test-api-' | awk '{print $1}')
if [ -n "$TEST_CONTAINERS" ]; then
    echo "$TEST_CONTAINERS" | xargs docker rm -f
    print_success "Removed test-api containers"
else
    print_info "No test-api containers found"
fi
echo ""

# Double check with grep
print_info "Final cleanup - checking for any remaining containers with port 8001..."
REMAINING=$(docker ps -a --format '{{.ID}} {{.Ports}}' | grep '8001' | awk '{print $1}')
if [ -n "$REMAINING" ]; then
    echo "$REMAINING" | xargs docker rm -f
    print_success "Removed remaining containers"
else
    print_info "No remaining containers found"
fi
echo ""

# Verify cleanup
print_header "Verification"
print_info "Checking for containers on port 8001..."
if docker ps -a --format '{{.ID}} {{.Names}} {{.Ports}}' | grep -q '8001'; then
    print_error "Some containers still using port 8001:"
    docker ps -a --format '{{.ID}} {{.Names}} {{.Ports}}' | grep '8001'
else
    print_success "Port 8001 is now free!"
fi
echo ""

print_info "All test-api containers:"
docker ps -a | grep 'test-api-' || echo "None found"
echo ""

print_success "Cleanup completed!"

