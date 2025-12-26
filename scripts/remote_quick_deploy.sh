#!/bin/bash

################################################################################
# Heart Disease MLOps - Quick Remote Deployment Script
# 
# This script performs a complete deployment:
# 1. Builds Docker image
# 2. Deploys to Minikube
# 3. Starts MLflow UI
# 4. Verifies everything is working
# 
# Usage:
#   ./scripts/remote_quick_deploy.sh
################################################################################

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║  $1${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Make scripts executable
chmod +x scripts/deploy_to_minikube.sh
chmod +x scripts/start_mlflow_ui.sh

# Main deployment
print_header "🚀 Heart Disease MLOps - Quick Deployment"

echo -e "${BLUE}This script will:${NC}"
echo "  1. ✅ Check prerequisites"
echo "  2. 🐳 Build Docker image"
echo "  3. ☸️  Deploy to Minikube"
echo "  4. 📊 Start MLflow UI"
echo "  5. 🧪 Verify deployment"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Deployment cancelled"
    exit 0
fi

# Step 1: Deploy to Minikube
print_header "Step 1/3: Deploying to Minikube"
./scripts/deploy_to_minikube.sh

# Step 2: Start MLflow UI
print_header "Step 2/3: Starting MLflow UI"
./scripts/start_mlflow_ui.sh --background

# Step 3: Final verification
print_header "Step 3/3: Final Verification"

sleep 5

# Get service URL
SERVICE_URL=$(minikube service heart-disease-api-service --url)

print_info "Testing API..."
if curl -s -f "${SERVICE_URL}/health" > /dev/null; then
    print_success "API is healthy!"
    echo ""
    curl -s "${SERVICE_URL}/health" | python3 -m json.tool
else
    print_error "API health check failed"
fi

echo ""

# Final summary
print_header "🎉 Deployment Complete!"

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    ACCESS INFORMATION                      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📡 API Service:${NC}"
echo -e "   URL: ${SERVICE_URL}"
echo ""

echo -e "${BLUE}📊 MLflow UI:${NC}"
echo -e "   Local:  http://localhost:5001"
echo -e "   Remote: http://$(hostname -I | awk '{print $1}'):5001"
echo ""

echo -e "${BLUE}🧪 Quick Tests:${NC}"
echo ""
echo -e "${YELLOW}Health Check:${NC}"
echo "   curl ${SERVICE_URL}/health"
echo ""
echo -e "${YELLOW}Make Prediction:${NC}"
echo "   curl -X POST ${SERVICE_URL}/predict \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"age\":63,\"sex\":1,\"cp\":3,\"trestbps\":145,\"chol\":233,\"fbs\":1,\"restecg\":0,\"thalach\":150,\"exang\":0,\"oldpeak\":2.3,\"slope\":0,\"ca\":0,\"thal\":1}'"
echo ""

echo -e "${BLUE}📋 Useful Commands:${NC}"
echo "   View pods:        kubectl get pods"
echo "   View logs:        kubectl logs -f <pod-name>"
echo "   MLflow status:    ./scripts/start_mlflow_ui.sh --status"
echo "   Stop MLflow:      ./scripts/start_mlflow_ui.sh --stop"
echo "   Cleanup:          kubectl delete -f deploy/k8s/"
echo ""

echo -e "${BLUE}🌐 SSH Tunnel (from local machine):${NC}"
echo "   ssh -L 5001:localhost:5001 -L 8000:$(minikube ip):30080 $(whoami)@$(hostname -I | awk '{print $1}')"
echo "   Then access:"
echo "     API:    http://localhost:8000"
echo "     MLflow: http://localhost:5001"
echo ""

print_success "All services are running! 🚀"

