#!/bin/bash

################################################################################
# Jenkins Deployment Helper Script
# 
# This script is called by Jenkins to deploy the application to Minikube.
# It can also be run manually for testing.
# 
# Usage:
#   ./scripts/jenkins_deploy.sh [docker-image-tag]
#
# Example:
#   ./scripts/jenkins_deploy.sh latest
#   ./scripts/jenkins_deploy.sh 42
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
IMAGE_TAG="${1:-latest}"
NAMESPACE="default"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Check if Minikube is running
check_minikube() {
    print_header "Checking Minikube Status"
    
    if ! minikube status &> /dev/null; then
        print_error "Minikube is not running"
        print_info "Start Minikube with: minikube start"
        exit 1
    fi
    
    print_success "Minikube is running"
    echo ""
}

# Load Docker image into Minikube
load_image() {
    print_header "Loading Docker Image into Minikube"
    
    print_info "Loading ${IMAGE_NAME}:${IMAGE_TAG}..."
    minikube image load "${IMAGE_NAME}:${IMAGE_TAG}"
    
    # Verify
    if minikube image ls | grep -q "${IMAGE_NAME}:${IMAGE_TAG}"; then
        print_success "Image loaded successfully"
    else
        print_error "Failed to load image"
        exit 1
    fi
    
    echo ""
}

# Deploy to Kubernetes
deploy_k8s() {
    print_header "Deploying to Kubernetes"
    
    # Check if deployment exists
    if kubectl get deployment heart-disease-api &> /dev/null; then
        print_info "Deployment exists, updating..."
        
        # Update image
        kubectl set image deployment/heart-disease-api \
            heart-disease-api="${IMAGE_NAME}:${IMAGE_TAG}"
        
        # Restart deployment
        kubectl rollout restart deployment/heart-disease-api
        
        # Wait for rollout
        print_info "Waiting for rollout to complete..."
        kubectl rollout status deployment/heart-disease-api --timeout=300s
        
        print_success "Deployment updated"
    else
        print_info "Creating new deployment..."
        
        # Apply manifests
        kubectl apply -f deploy/k8s/
        
        # Wait for deployment
        print_info "Waiting for deployment to be ready..."
        kubectl wait --for=condition=available --timeout=300s deployment/heart-disease-api
        
        print_success "Deployment created"
    fi
    
    echo ""
}

# Verify deployment
verify_deployment() {
    print_header "Verifying Deployment"
    
    # Check pods
    print_info "Checking pods..."
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
        print_info "Health response:"
        curl -s "$SERVICE_URL/health" | python3 -m json.tool || curl -s "$SERVICE_URL/health"
    else
        print_warning "Health check failed"
        print_info "Checking pod logs..."
        POD_NAME=$(kubectl get pods -l app=heart-disease-api -o jsonpath='{.items[0].metadata.name}')
        kubectl logs "$POD_NAME" | tail -20
    fi
    
    echo ""
}

# Start MLflow UI
start_mlflow() {
    print_header "Starting MLflow UI"
    
    # Check if MLflow is already running
    if pgrep -f "mlflow ui" > /dev/null; then
        print_info "MLflow UI is already running"
        print_success "MLflow UI: http://$(hostname -I | awk '{print $1}'):5001"
    else
        print_info "Starting MLflow UI..."
        nohup mlflow ui --host 0.0.0.0 --port 5001 > mlflow.log 2>&1 &
        sleep 2
        
        if pgrep -f "mlflow ui" > /dev/null; then
            print_success "MLflow UI started"
            print_success "MLflow UI: http://$(hostname -I | awk '{print $1}'):5001"
        else
            print_warning "Failed to start MLflow UI"
            print_info "Check mlflow.log for errors"
        fi
    fi
    
    echo ""
}

# Show deployment summary
show_summary() {
    print_header "Deployment Summary"
    
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}Docker Image:${NC} ${IMAGE_NAME}:${IMAGE_TAG}"
    echo ""
    echo -e "${BLUE}Kubernetes Resources:${NC}"
    kubectl get all -l app=heart-disease-api
    echo ""
    echo -e "${BLUE}Service URL:${NC}"
    minikube service heart-disease-api-service --url
    echo ""
    echo -e "${BLUE}MLflow UI:${NC}"
    echo "  http://$(hostname -I | awk '{print $1}'):5001"
    echo ""
    echo -e "${BLUE}Quick Tests:${NC}"
    SERVICE_URL=$(minikube service heart-disease-api-service --url)
    echo "  Health: curl $SERVICE_URL/health"
    echo "  Predict: curl -X POST $SERVICE_URL/predict -H 'Content-Type: application/json' -d '{...}'"
    echo ""
}

# Main function
main() {
    print_header "🚀 Jenkins Deployment Script"
    echo ""
    
    print_info "Deploying ${IMAGE_NAME}:${IMAGE_TAG}"
    echo ""
    
    check_minikube
    load_image
    deploy_k8s
    verify_deployment
    start_mlflow
    show_summary
    
    print_success "All done! 🚀"
}

# Run main
main "$@"

