#!/bin/bash

# Script to configure Grafana Prometheus data source
# This fixes the "No Data" issue in Grafana dashboards

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
echo "🔧 Grafana Prometheus Data Source Setup"
echo "========================================="
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl not found. Please install kubectl first."
    exit 1
fi

# Check if Grafana pod is running
print_info "Checking Grafana pod status..."
GRAFANA_POD=$(kubectl get pods -l app=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "$GRAFANA_POD" ]; then
    print_error "Grafana pod not found. Please deploy monitoring stack first:"
    echo "  kubectl apply -f deploy/k8s/monitoring.yaml"
    exit 1
fi

print_success "Grafana pod found: $GRAFANA_POD"

# Check if Prometheus service exists
print_info "Checking Prometheus service..."
if ! kubectl get service prometheus &> /dev/null; then
    print_error "Prometheus service not found. Please deploy monitoring stack first:"
    echo "  kubectl apply -f deploy/k8s/monitoring.yaml"
    exit 1
fi

print_success "Prometheus service found"

# Wait for Grafana to be ready
print_info "Waiting for Grafana to be ready..."
kubectl wait --for=condition=ready --timeout=60s pod -l app=grafana || {
    print_warning "Grafana pod not ready yet, continuing anyway..."
}

echo ""
print_info "Setting up port-forward to Grafana..."
kubectl port-forward service/grafana 3000:3000 &
PF_PID=$!
sleep 5

# Function to cleanup port-forward on exit
cleanup() {
    print_info "Cleaning up port-forward..."
    kill $PF_PID 2>/dev/null || true
}
trap cleanup EXIT

echo ""
print_info "Configuring Prometheus data source in Grafana..."

# Create data source via Grafana API
curl -X POST http://admin:admin@localhost:3000/api/datasources \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Prometheus",
    "type": "prometheus",
    "url": "http://prometheus:9090",
    "access": "proxy",
    "isDefault": true,
    "jsonData": {
      "httpMethod": "POST",
      "timeInterval": "15s"
    }
  }' 2>/dev/null || {
    print_warning "Data source might already exist, trying to update..."
    
    # Get existing data source ID
    DS_ID=$(curl -s http://admin:admin@localhost:3000/api/datasources/name/Prometheus | grep -o '"id":[0-9]*' | cut -d':' -f2)
    
    if [ -n "$DS_ID" ]; then
        # Update existing data source
        curl -X PUT http://admin:admin@localhost:3000/api/datasources/$DS_ID \
          -H "Content-Type: application/json" \
          -d '{
            "id": '$DS_ID',
            "name": "Prometheus",
            "type": "prometheus",
            "url": "http://prometheus:9090",
            "access": "proxy",
            "isDefault": true,
            "jsonData": {
              "httpMethod": "POST",
              "timeInterval": "15s"
            }
          }' 2>/dev/null
        print_success "Updated existing Prometheus data source"
    fi
}

echo ""
echo ""
print_success "Prometheus data source configured!"

echo ""
echo "========================================="
echo "📊 Next Steps"
echo "========================================="
echo ""
echo "1. Access Grafana: http://localhost:3000"
echo "   Login: admin / admin"
echo ""
echo "2. Verify data source:"
echo "   - Go to Configuration → Data Sources"
echo "   - Click 'Prometheus'"
echo "   - Click 'Save & Test' - should show green checkmark"
echo ""
echo "3. Import dashboard:"
echo "   - Click + icon → Import"
echo "   - Upload: grafana/heart-disease-api-dashboard.json"
echo "   - Select 'Prometheus' as data source"
echo "   - Click Import"
echo ""
echo "4. Make some predictions to generate metrics:"
echo "   kubectl port-forward service/heart-disease-api-service 8000:80"
echo "   # Then visit http://localhost:8000/docs and make predictions"
echo ""
echo "========================================="

print_info "Port-forward is still running. Press Ctrl+C to stop."
wait $PF_PID

