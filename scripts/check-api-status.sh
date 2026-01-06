#!/bin/bash
#
# Check API Status and Provide Connection Instructions
#

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

echo "========================================="
echo "🔍 API Status Check"
echo "========================================="
echo ""

# Check local API (port 8000)
print_info "Checking local API (http://localhost:8000)..."
if curl -s -f http://localhost:8000/health > /dev/null 2>&1; then
    print_success "API is running locally on port 8000"
    echo ""
    echo "You can run the traffic generator:"
    echo "  ./scripts/generate-prediction-traffic.sh"
    exit 0
else
    print_warning "API is not running locally"
fi
echo ""

# Check Docker
print_info "Checking Docker containers..."
if command -v docker &> /dev/null; then
    if docker ps --format '{{.Names}}' | grep -q "heart-api\|heart-disease"; then
        print_success "API container found"
        docker ps --format 'table {{.Names}}\t{{.Ports}}' | grep -E "heart-api|heart-disease|NAMES"
        echo ""
        echo "If container is running, API should be accessible at http://localhost:8000"
    else
        print_warning "No API Docker container found"
    fi
else
    print_warning "Docker not installed or not running"
fi
echo ""

# Check Kubernetes
print_info "Checking Kubernetes deployment..."
if command -v kubectl &> /dev/null; then
    if kubectl cluster-info &> /dev/null; then
        print_success "Kubernetes cluster is accessible"
        
        # Check if API is deployed
        if kubectl get deployment heart-disease-api &> /dev/null; then
            print_success "API deployment found in Kubernetes"
            echo ""
            echo "API pods:"
            kubectl get pods -l app=heart-disease-api
            echo ""
            echo "To access the API, run:"
            print_info "kubectl port-forward service/heart-disease-api-service 8000:80"
            echo ""
            echo "Then in another terminal, run:"
            print_info "API_URL=http://localhost:8000 ./scripts/generate-prediction-traffic.sh"
        else
            print_warning "API deployment not found in Kubernetes"
            echo ""
            echo "To deploy the API:"
            print_info "kubectl apply -f deploy/k8s/"
        fi
    else
        print_warning "Kubernetes cluster not accessible"
    fi
else
    print_warning "kubectl not found"
fi
echo ""

# Provide instructions to start API locally
echo "========================================="
echo "🚀 How to Start API Locally"
echo "========================================="
echo ""
echo "Option 1: Using uvicorn (recommended)"
echo "  source .venv/bin/activate  # or: conda activate heart-mlops"
echo "  uvicorn src.api.app:app --host 0.0.0.0 --port 8000 --reload"
echo ""
echo "Option 2: Using Makefile"
echo "  make serve"
echo ""
echo "Option 3: Using Python directly"
echo "  python -m uvicorn src.api.app:app --host 0.0.0.0 --port 8000"
echo ""
echo "Option 4: Using Docker"
echo "  docker build -t heart-disease-api:latest ."
echo "  docker run -d -p 8000:8000 --name heart-api heart-disease-api:latest"
echo ""
echo "After starting, verify with:"
echo "  curl http://localhost:8000/health"
echo ""
echo "Then run traffic generator:"
echo "  ./scripts/generate-prediction-traffic.sh"
echo ""

