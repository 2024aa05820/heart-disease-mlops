#!/bin/bash

# Complete ML Workflow: Train → Register → Promote → Deploy
# This script runs the entire ML pipeline from training to deployment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_step() { echo -e "${CYAN}🔹 $1${NC}"; }

echo "========================================="
echo "🚀 Complete ML Workflow"
echo "========================================="
echo ""
echo "This script will:"
echo "  1. Start MLflow tracking server"
echo "  2. Train multiple models"
echo "  3. Register best model"
echo "  4. Promote to Production"
echo "  5. Build Docker image"
echo "  6. Deploy to Kubernetes"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "========================================="
echo "Step 1: Start MLflow Server"
echo "========================================="
echo ""

# Check if MLflow is already running
if lsof -Pi :5000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    print_success "MLflow server already running on port 5000"
else
    print_info "Starting MLflow server..."
    mlflow server \
        --backend-store-uri sqlite:///mlflow.db \
        --default-artifact-root ./mlruns \
        --host 0.0.0.0 \
        --port 5000 &
    
    MLFLOW_PID=$!
    echo $MLFLOW_PID > /tmp/mlflow.pid
    
    print_info "Waiting for MLflow server to start..."
    sleep 5
    
    if lsof -Pi :5000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_success "MLflow server started (PID: $MLFLOW_PID)"
        print_info "MLflow UI: http://localhost:5000"
    else
        print_error "Failed to start MLflow server"
        exit 1
    fi
fi

echo ""
echo "========================================="
echo "Step 2: Train Models"
echo "========================================="
echo ""

print_info "Training models with MLflow tracking..."
print_info "This will train: Logistic Regression, Random Forest"
echo ""

# Set MLflow tracking URI
export MLFLOW_TRACKING_URI=http://localhost:5000

# Run training
python scripts/train.py

if [ $? -eq 0 ]; then
    print_success "Training completed successfully!"
else
    print_error "Training failed!"
    exit 1
fi

echo ""
echo "========================================="
echo "Step 3: Verify Model Registration"
echo "========================================="
echo ""

print_info "Checking registered models..."
python scripts/promote-model.py --list

echo ""
echo "========================================="
echo "Step 4: Promote Best Model"
echo "========================================="
echo ""

print_info "Promoting best model to Production..."
python scripts/promote-model.py --auto

if [ $? -eq 0 ]; then
    print_success "Model promoted successfully!"
else
    print_warning "Auto-promotion failed. You may need to promote manually."
    echo ""
    echo "Manual promotion:"
    echo "  1. Visit MLflow UI: http://localhost:5000"
    echo "  2. Go to Models tab"
    echo "  3. Select the model with highest ROC-AUC"
    echo "  4. Click 'Stage' → 'Transition to Production'"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "========================================="
echo "Step 5: Build Docker Image"
echo "========================================="
echo ""

print_info "Building Docker image with latest model..."

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Build image
docker build -t heart-disease-api:latest .

if [ $? -eq 0 ]; then
    print_success "Docker image built successfully!"
else
    print_error "Docker build failed!"
    exit 1
fi

echo ""
echo "========================================="
echo "Step 6: Deploy to Kubernetes"
echo "========================================="
echo ""

print_info "Deploying to Kubernetes..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl not found. Please install kubectl first."
    exit 1
fi

# Apply deployment
kubectl apply -f deploy/k8s/deployment.yaml
kubectl apply -f deploy/k8s/service.yaml

print_info "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/heart-disease-api

if [ $? -eq 0 ]; then
    print_success "Deployment successful!"
else
    print_error "Deployment failed or timed out!"
    exit 1
fi

echo ""
echo "========================================="
echo "✅ Workflow Complete!"
echo "========================================="
echo ""
print_success "All steps completed successfully!"
echo ""
echo "📊 Next Steps:"
echo ""
echo "1. View MLflow UI:"
echo "   http://localhost:5000"
echo ""
echo "2. Test API:"
echo "   kubectl port-forward service/heart-disease-api-service 8000:80"
echo "   http://localhost:8000/docs"
echo ""
echo "3. View Grafana Dashboard:"
echo "   kubectl port-forward service/grafana 3000:3000"
echo "   http://localhost:3000 (admin/admin)"
echo ""
echo "4. Check deployment:"
echo "   kubectl get pods -l app=heart-disease-api"
echo "   kubectl logs -l app=heart-disease-api"
echo ""
echo "========================================="

