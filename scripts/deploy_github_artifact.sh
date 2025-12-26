#!/bin/bash

################################################################################
# Deploy GitHub Actions Artifact to Minikube
# 
# This script loads a Docker image artifact from GitHub Actions and deploys
# it to Minikube on your remote machine.
# 
# Prerequisites:
#   - Docker image artifact file (docker-image.tar.gz) in current directory
#   - Minikube running
#   - kubectl configured
# 
# Usage:
#   ./scripts/deploy_github_artifact.sh [path-to-artifact]
#
# Example:
#   ./scripts/deploy_github_artifact.sh ~/docker-image.tar.gz
################################################################################

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
IMAGE_NAME="heart-disease-api"
ARTIFACT_FILE="${1:-docker-image.tar.gz}"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Check if artifact file exists
check_artifact() {
    print_header "Checking Artifact File"
    
    if [ ! -f "$ARTIFACT_FILE" ]; then
        print_error "Artifact file not found: $ARTIFACT_FILE"
        echo ""
        print_info "Please provide the path to docker-image.tar.gz"
        print_info "Usage: $0 <path-to-artifact>"
        echo ""
        print_info "To download from GitHub:"
        echo "  1. Go to: https://github.com/2024aa05820/heart-disease-mlops/actions"
        echo "  2. Click on latest successful workflow"
        echo "  3. Download 'docker-image' artifact"
        echo "  4. Extract the zip file to get docker-image.tar.gz"
        echo ""
        print_info "Or use GitHub CLI:"
        echo "  gh run download --name docker-image --repo 2024aa05820/heart-disease-mlops"
        exit 1
    fi
    
    print_success "Found artifact: $ARTIFACT_FILE"
    
    # Check file size
    SIZE=$(du -h "$ARTIFACT_FILE" | cut -f1)
    print_info "Artifact size: $SIZE"
    echo ""
}

# Load Docker image
load_image() {
    print_header "Loading Docker Image"
    
    print_info "Extracting and loading image..."
    gunzip -c "$ARTIFACT_FILE" | docker load
    
    print_success "Image loaded successfully"
    
    # Get the loaded image name and tag
    IMAGE_TAG=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "$IMAGE_NAME" | head -1)
    print_info "Loaded image: $IMAGE_TAG"
    
    # Tag as latest
    print_info "Tagging as latest..."
    docker tag "$IMAGE_TAG" "${IMAGE_NAME}:latest"
    
    print_success "Tagged as ${IMAGE_NAME}:latest"
    echo ""
}

# Load into Minikube
load_to_minikube() {
    print_header "Loading Image into Minikube"
    
    # Check if Minikube is running
    if ! minikube status &> /dev/null; then
        print_error "Minikube is not running"
        print_info "Start Minikube with: minikube start"
        exit 1
    fi
    
    print_info "Loading image into Minikube..."
    minikube image load "${IMAGE_NAME}:latest"
    
    # Verify
    print_info "Verifying image in Minikube..."
    if minikube image ls | grep -q "$IMAGE_NAME"; then
        print_success "Image loaded into Minikube successfully"
    else
        print_error "Failed to load image into Minikube"
        exit 1
    fi
    
    echo ""
}

# Deploy to Kubernetes
deploy_to_k8s() {
    print_header "Deploying to Kubernetes"
    
    # Check if deployment already exists
    if kubectl get deployment heart-disease-api &> /dev/null; then
        print_warning "Deployment already exists"
        read -p "Do you want to restart the deployment? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Restarting deployment..."
            kubectl rollout restart deployment/heart-disease-api
            kubectl wait --for=condition=available --timeout=300s deployment/heart-disease-api
            print_success "Deployment restarted"
        fi
    else
        print_info "Applying Kubernetes manifests..."
        kubectl apply -f deploy/k8s/
        
        print_info "Waiting for deployment to be ready..."
        kubectl wait --for=condition=available --timeout=300s deployment/heart-disease-api
        
        print_success "Deployment completed"
    fi
    
    echo ""
}

# Verify deployment
verify_deployment() {
    print_header "Verifying Deployment"
    
    # Check pods
    print_info "Pods:"
    kubectl get pods -l app=heart-disease-api
    echo ""
    
    # Get service URL
    print_info "Getting service URL..."
    SERVICE_URL=$(minikube service heart-disease-api-service --url)
    print_success "Service URL: $SERVICE_URL"
    echo ""
    
    # Test health endpoint
    print_info "Testing health endpoint..."
    sleep 5  # Wait for pods to be fully ready
    
    if curl -s -f "$SERVICE_URL/health" > /dev/null; then
        print_success "Health check passed!"
        echo ""
        curl -s "$SERVICE_URL/health" | python3 -m json.tool
    else
        print_warning "Health check failed. Checking pod logs..."
        POD_NAME=$(kubectl get pods -l app=heart-disease-api -o jsonpath='{.items[0].metadata.name}')
        kubectl logs "$POD_NAME" | tail -20
    fi
    
    echo ""
}

# Show access info
show_info() {
    print_header "Deployment Complete!"
    
    SERVICE_URL=$(minikube service heart-disease-api-service --url)
    
    echo -e "${GREEN}🎉 Successfully deployed GitHub Actions artifact!${NC}"
    echo ""
    echo -e "${BLUE}API Service URL:${NC}"
    echo -e "  $SERVICE_URL"
    echo ""
    echo -e "${BLUE}Quick Tests:${NC}"
    echo -e "  Health: curl $SERVICE_URL/health"
    echo -e "  Predict: curl -X POST $SERVICE_URL/predict -H 'Content-Type: application/json' -d '{...}'"
    echo ""
    echo -e "${BLUE}Useful Commands:${NC}"
    echo -e "  View pods:    kubectl get pods"
    echo -e "  View logs:    kubectl logs -f <pod-name>"
    echo -e "  Restart:      kubectl rollout restart deployment/heart-disease-api"
    echo ""
}

# Main function
main() {
    print_header "🚀 Deploy GitHub Actions Artifact to Minikube"
    echo ""
    
    check_artifact
    load_image
    load_to_minikube
    deploy_to_k8s
    verify_deployment
    show_info
    
    print_success "All done! 🚀"
}

# Run main
main "$@"

