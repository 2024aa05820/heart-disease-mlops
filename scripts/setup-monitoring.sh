#!/bin/bash

# Setup Monitoring Stack (Prometheus + Grafana)
# This script deploys Prometheus and Grafana to Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "========================================="
echo "📊 Setting up Monitoring Stack"
echo "========================================="
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl not found. Please install kubectl first."
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

print_success "Connected to Kubernetes cluster"
echo ""

# Deploy monitoring stack
print_info "Deploying Prometheus and Grafana..."
kubectl apply -f deploy/k8s/monitoring.yaml

echo ""
print_info "Waiting for Prometheus to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/prometheus || true

echo ""
print_info "Waiting for Grafana to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/grafana || true

echo ""
print_success "Monitoring stack deployed!"

# Get service information
echo ""
echo "========================================="
echo "📊 Service Information"
echo "========================================="

echo ""
print_info "Prometheus:"
kubectl get service prometheus
PROM_PORT=$(kubectl get service prometheus -o jsonpath='{.spec.ports[0].nodePort}')
echo "   NodePort: $PROM_PORT"

echo ""
print_info "Grafana:"
kubectl get service grafana
GRAFANA_PORT=$(kubectl get service grafana -o jsonpath='{.spec.ports[0].nodePort}')
echo "   NodePort: $GRAFANA_PORT"
echo "   Default credentials: admin/admin"

echo ""
echo "========================================="
echo "🌐 Access URLs"
echo "========================================="

# Try to get minikube IP (if using minikube)
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "localhost")
    echo ""
    echo "Using Minikube:"
    echo "  Prometheus: http://$MINIKUBE_IP:$PROM_PORT"
    echo "  Grafana:    http://$MINIKUBE_IP:$GRAFANA_PORT"
fi

echo ""
echo "Using Port Forwarding (recommended):"
echo ""
echo "  1️⃣  Prometheus:"
echo "     kubectl port-forward service/prometheus 9090:9090"
echo "     Then visit: http://localhost:9090"
echo ""
echo "  2️⃣  Grafana:"
echo "     kubectl port-forward service/grafana 3000:3000"
echo "     Then visit: http://localhost:3000"
echo "     Login: admin/admin"
echo ""
echo "  3️⃣  API Metrics:"
echo "     kubectl port-forward service/heart-disease-api-service 8000:80"
echo "     Then visit: http://localhost:8000/metrics"
echo ""

echo "========================================="
echo "📝 Next Steps"
echo "========================================="
echo ""
echo "1. Access Grafana at http://localhost:3000 (after port-forward)"
echo "2. Login with admin/admin"
echo "3. Add Prometheus as a data source:"
echo "   - URL: http://prometheus:9090"
echo "   - Access: Server (default)"
echo "4. Import dashboard or create your own"
echo "5. Query metrics from heart-disease-api"
echo ""

print_success "Setup complete!"

