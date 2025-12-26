#!/bin/bash

################################################################################
# Heart Disease MLOps - Minikube Deployment Script
# 
# This script automates the deployment of the Heart Disease API to Minikube
# 
# Usage:
#   ./scripts/deploy_to_minikube.sh [options]
#
# Options:
#   --build-only    Only build the Docker image
#   --deploy-only   Only deploy to Kubernetes (skip build)
#   --clean         Clean up existing deployment first
#   --help          Show this help message
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="heart-disease-api"
IMAGE_TAG="latest"
NAMESPACE="default"
DEPLOYMENT_NAME="heart-disease-api"

# Functions
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

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if Minikube is installed
    if ! command -v minikube &> /dev/null; then
        print_error "Minikube is not installed"
        exit 1
    fi
    print_success "Minikube is installed"
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    print_success "kubectl is installed"
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    print_success "Docker is installed"
    
    # Check if Minikube is running
    if ! minikube status &> /dev/null; then
        print_warning "Minikube is not running. Starting Minikube..."
        minikube start --driver=docker --cpus=4 --memory=8192
        print_success "Minikube started"
    else
        print_success "Minikube is running"
    fi
    
    echo ""
}

build_docker_image() {
    print_header "Building Docker Image"
    
    print_info "Building image: ${IMAGE_NAME}:${IMAGE_TAG}"
    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
    
    print_success "Docker image built successfully"
    
    print_info "Loading image into Minikube..."
    minikube image load ${IMAGE_NAME}:${IMAGE_TAG}
    
    print_success "Image loaded into Minikube"
    
    # Verify image is in Minikube
    print_info "Verifying image in Minikube..."
    if minikube image ls | grep -q ${IMAGE_NAME}; then
        print_success "Image verified in Minikube"
    else
        print_error "Image not found in Minikube"
        exit 1
    fi
    
    echo ""
}

clean_deployment() {
    print_header "Cleaning Existing Deployment"
    
    print_info "Deleting existing resources..."
    kubectl delete -f deploy/k8s/ --ignore-not-found=true
    
    print_info "Waiting for resources to be deleted..."
    sleep 5
    
    print_success "Cleanup completed"
    echo ""
}

deploy_to_kubernetes() {
    print_header "Deploying to Kubernetes"
    
    print_info "Applying Kubernetes manifests..."
    kubectl apply -f deploy/k8s/
    
    print_info "Waiting for deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/${DEPLOYMENT_NAME}
    
    print_success "Deployment completed successfully"
    echo ""
}

verify_deployment() {
    print_header "Verifying Deployment"
    
    # Check deployments
    print_info "Deployments:"
    kubectl get deployments
    echo ""
    
    # Check pods
    print_info "Pods:"
    kubectl get pods -l app=${DEPLOYMENT_NAME}
    echo ""
    
    # Check services
    print_info "Services:"
    kubectl get services
    echo ""
    
    # Get service URL
    print_info "Getting service URL..."
    SERVICE_URL=$(minikube service heart-disease-api-service --url)
    print_success "Service URL: ${SERVICE_URL}"
    echo ""
    
    # Test health endpoint
    print_info "Testing health endpoint..."
    sleep 10  # Wait for pods to be fully ready
    
    if curl -s -f "${SERVICE_URL}/health" > /dev/null; then
        print_success "Health check passed!"
        echo ""
        print_info "Health response:"
        curl -s "${SERVICE_URL}/health" | python3 -m json.tool
    else
        print_warning "Health check failed. Checking pod logs..."
        POD_NAME=$(kubectl get pods -l app=${DEPLOYMENT_NAME} -o jsonpath='{.items[0].metadata.name}')
        kubectl logs ${POD_NAME}
    fi
    
    echo ""
}

show_access_info() {
    print_header "Access Information"
    
    SERVICE_URL=$(minikube service heart-disease-api-service --url)
    
    echo -e "${GREEN}🎉 Deployment Successful!${NC}"
    echo ""
    echo -e "${BLUE}API Service URL:${NC}"
    echo -e "  ${SERVICE_URL}"
    echo ""
    echo -e "${BLUE}Test Commands:${NC}"
    echo -e "  Health Check:"
    echo -e "    curl ${SERVICE_URL}/health"
    echo ""
    echo -e "  Make Prediction:"
    echo -e "    curl -X POST ${SERVICE_URL}/predict \\"
    echo -e "      -H 'Content-Type: application/json' \\"
    echo -e "      -d '{\"age\":63,\"sex\":1,\"cp\":3,\"trestbps\":145,\"chol\":233,\"fbs\":1,\"restecg\":0,\"thalach\":150,\"exang\":0,\"oldpeak\":2.3,\"slope\":0,\"ca\":0,\"thal\":1}'"
    echo ""
    echo -e "${BLUE}Useful Commands:${NC}"
    echo -e "  View pods:        kubectl get pods"
    echo -e "  View logs:        kubectl logs -f <pod-name>"
    echo -e "  View services:    kubectl get services"
    echo -e "  Delete deployment: kubectl delete -f deploy/k8s/"
    echo ""
}

show_help() {
    echo "Heart Disease MLOps - Minikube Deployment Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --build-only    Only build the Docker image"
    echo "  --deploy-only   Only deploy to Kubernetes (skip build)"
    echo "  --clean         Clean up existing deployment first"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Full deployment (build + deploy)"
    echo "  $0 --build-only       # Only build Docker image"
    echo "  $0 --deploy-only      # Only deploy to Kubernetes"
    echo "  $0 --clean            # Clean and redeploy"
    echo ""
}

# Main script
main() {
    BUILD=true
    DEPLOY=true
    CLEAN=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --build-only)
                DEPLOY=false
                shift
                ;;
            --deploy-only)
                BUILD=false
                shift
                ;;
            --clean)
                CLEAN=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Execute deployment steps
    check_prerequisites
    
    if [ "$CLEAN" = true ]; then
        clean_deployment
    fi
    
    if [ "$BUILD" = true ]; then
        build_docker_image
    fi
    
    if [ "$DEPLOY" = true ]; then
        deploy_to_kubernetes
        verify_deployment
        show_access_info
    fi
    
    print_success "All done! 🚀"
}

# Run main function
main "$@"

