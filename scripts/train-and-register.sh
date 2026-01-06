#!/bin/bash

# Train models and register them in MLflow
# This is the FIRST step before promotion

set -e

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
echo "🎯 Train & Register Models"
echo "========================================="
echo ""

# Check if Python is available
if ! command -v python &> /dev/null; then
    print_error "Python not found. Please install Python first."
    exit 1
fi

# Check if required packages are installed
print_info "Checking dependencies..."
python -c "import mlflow, sklearn, pandas, numpy" 2>/dev/null || {
    print_error "Missing dependencies. Installing..."
    pip install -r requirements.txt
}

print_success "Dependencies OK"
echo ""

# Check if MLflow server is running
print_info "Checking MLflow server..."
if lsof -Pi :5000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    print_success "MLflow server is running on port 5000"
    MLFLOW_RUNNING=true
else
    print_warning "MLflow server not running on port 5000"
    print_info "Starting MLflow server..."
    
    # Start MLflow server in background
    mlflow server \
        --backend-store-uri sqlite:///mlflow.db \
        --default-artifact-root ./mlruns \
        --host 0.0.0.0 \
        --port 5000 > /tmp/mlflow.log 2>&1 &
    
    MLFLOW_PID=$!
    echo $MLFLOW_PID > /tmp/mlflow.pid
    
    print_info "Waiting for MLflow server to start..."
    sleep 5
    
    if lsof -Pi :5000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_success "MLflow server started (PID: $MLFLOW_PID)"
        print_info "MLflow UI: http://localhost:5000"
        MLFLOW_RUNNING=true
    else
        print_error "Failed to start MLflow server"
        print_info "Check logs: cat /tmp/mlflow.log"
        exit 1
    fi
fi

echo ""
echo "========================================="
echo "🏋️  Training Models"
echo "========================================="
echo ""

print_info "Training models with MLflow tracking..."
print_info "Models to train:"
echo "  - Logistic Regression"
echo "  - Random Forest"
echo ""
print_info "This may take a few minutes..."
echo ""

# Set MLflow tracking URI
export MLFLOW_TRACKING_URI=http://localhost:5000

# Run training
python scripts/train.py

if [ $? -eq 0 ]; then
    echo ""
    print_success "Training completed successfully!"
else
    echo ""
    print_error "Training failed!"
    print_info "Check the error messages above"
    exit 1
fi

echo ""
echo "========================================="
echo "📋 Registered Models"
echo "========================================="
echo ""

print_info "Listing registered models..."
python scripts/promote-model.py --list

echo ""
echo "========================================="
echo "✅ Training Complete!"
echo "========================================="
echo ""
print_success "Models have been trained and registered in MLflow"
echo ""
echo "📊 Next Steps:"
echo ""
echo "1. View experiments in MLflow UI:"
echo "   http://localhost:5000"
echo ""
echo "2. Promote best model to Production:"
echo "   python scripts/promote-model.py --auto"
echo "   # OR manually in MLflow UI"
echo ""
echo "3. Build and deploy:"
echo "   docker build -t heart-disease-api:latest ."
echo "   kubectl apply -f deploy/k8s/"
echo ""
echo "========================================="

# Keep MLflow server running
if [ "$MLFLOW_RUNNING" = true ]; then
    echo ""
    print_info "MLflow server is running in the background"
    print_info "To stop: kill \$(cat /tmp/mlflow.pid)"
    print_info "To view logs: cat /tmp/mlflow.log"
fi

