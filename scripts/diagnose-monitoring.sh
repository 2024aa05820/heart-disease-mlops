#!/bin/bash

# Script to diagnose Grafana "No Data" issues
# Checks Prometheus, Grafana, and API metrics

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
echo "🔍 Monitoring Stack Diagnostics"
echo "========================================="
echo ""

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl not found"
    exit 1
fi

# 1. Check Prometheus Pod
echo "1️⃣  Checking Prometheus Pod..."
PROM_POD=$(kubectl get pods -l app=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -z "$PROM_POD" ]; then
    print_error "Prometheus pod not found"
    echo "   Fix: kubectl apply -f deploy/k8s/monitoring.yaml"
else
    PROM_STATUS=$(kubectl get pod $PROM_POD -o jsonpath='{.status.phase}')
    if [ "$PROM_STATUS" == "Running" ]; then
        print_success "Prometheus pod is running: $PROM_POD"
    else
        print_error "Prometheus pod status: $PROM_STATUS"
    fi
fi
echo ""

# 2. Check Prometheus Service
echo "2️⃣  Checking Prometheus Service..."
if kubectl get service prometheus &> /dev/null; then
    PROM_PORT=$(kubectl get service prometheus -o jsonpath='{.spec.ports[0].port}')
    print_success "Prometheus service exists (port: $PROM_PORT)"
else
    print_error "Prometheus service not found"
fi
echo ""

# 3. Check Grafana Pod
echo "3️⃣  Checking Grafana Pod..."
GRAFANA_POD=$(kubectl get pods -l app=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -z "$GRAFANA_POD" ]; then
    print_error "Grafana pod not found"
else
    GRAFANA_STATUS=$(kubectl get pod $GRAFANA_POD -o jsonpath='{.status.phase}')
    if [ "$GRAFANA_STATUS" == "Running" ]; then
        print_success "Grafana pod is running: $GRAFANA_POD"
    else
        print_error "Grafana pod status: $GRAFANA_STATUS"
    fi
fi
echo ""

# 4. Check API Pods
echo "4️⃣  Checking API Pods..."
API_PODS=$(kubectl get pods -l app=heart-disease-api -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
if [ -z "$API_PODS" ]; then
    print_warning "No API pods found"
    echo "   This is OK if you haven't deployed the API yet"
else
    API_COUNT=$(echo $API_PODS | wc -w)
    print_success "Found $API_COUNT API pod(s)"
    
    # Check pod annotations
    for pod in $API_PODS; do
        SCRAPE=$(kubectl get pod $pod -o jsonpath='{.metadata.annotations.prometheus\.io/scrape}' 2>/dev/null || echo "")
        if [ "$SCRAPE" == "true" ]; then
            print_success "  Pod $pod has prometheus.io/scrape=true"
        else
            print_warning "  Pod $pod missing prometheus.io/scrape annotation"
        fi
    done
fi
echo ""

# 5. Check Prometheus Targets (if Prometheus is running)
if [ -n "$PROM_POD" ] && [ "$PROM_STATUS" == "Running" ]; then
    echo "5️⃣  Checking Prometheus Targets..."
    print_info "Port-forwarding to Prometheus..."
    kubectl port-forward service/prometheus 9090:9090 &
    PF_PID=$!
    sleep 3
    
    # Query Prometheus API
    TARGETS=$(curl -s http://localhost:9090/api/v1/targets 2>/dev/null || echo "")
    
    if [ -n "$TARGETS" ]; then
        # Count active targets
        ACTIVE_COUNT=$(echo "$TARGETS" | grep -o '"health":"up"' | wc -l)
        print_success "Prometheus has $ACTIVE_COUNT active target(s)"
        
        # Check for heart-disease-api
        if echo "$TARGETS" | grep -q "heart-disease-api"; then
            print_success "  Found 'heart-disease-api' target"
        else
            print_warning "  'heart-disease-api' target not found"
            echo "     This is normal if API pods are not running"
        fi
    else
        print_warning "Could not query Prometheus targets"
    fi
    
    kill $PF_PID 2>/dev/null || true
    echo ""
fi

# 6. Check for metrics
if [ -n "$PROM_POD" ] && [ "$PROM_STATUS" == "Running" ]; then
    echo "6️⃣  Checking for Metrics..."
    print_info "Port-forwarding to Prometheus..."
    kubectl port-forward service/prometheus 9090:9090 &
    PF_PID=$!
    sleep 3
    
    # Query for predictions_total metric
    METRICS=$(curl -s 'http://localhost:9090/api/v1/query?query=predictions_total' 2>/dev/null || echo "")
    
    if echo "$METRICS" | grep -q '"status":"success"'; then
        RESULT_COUNT=$(echo "$METRICS" | grep -o '"result":\[' | wc -l)
        if [ "$RESULT_COUNT" -gt 0 ]; then
            print_success "Found 'predictions_total' metric with data"
        else
            print_warning "'predictions_total' metric exists but has no data"
            echo "     Make some predictions to generate metrics"
        fi
    else
        print_warning "'predictions_total' metric not found"
        echo "     This is normal if no predictions have been made yet"
    fi
    
    kill $PF_PID 2>/dev/null || true
    echo ""
fi

# Summary
echo "========================================="
echo "📋 Summary"
echo "========================================="
echo ""

if [ -n "$PROM_POD" ] && [ "$PROM_STATUS" == "Running" ] && [ -n "$GRAFANA_POD" ] && [ "$GRAFANA_STATUS" == "Running" ]; then
    print_success "Monitoring stack is running!"
    echo ""
    echo "Next steps:"
    echo "1. Configure Grafana data source:"
    echo "   ./scripts/fix-grafana-datasource.sh"
    echo ""
    echo "2. Access Grafana:"
    echo "   kubectl port-forward service/grafana 3000:3000"
    echo "   http://localhost:3000 (admin/admin)"
    echo ""
    echo "3. Make predictions to generate metrics:"
    echo "   kubectl port-forward service/heart-disease-api-service 8000:80"
    echo "   http://localhost:8000/docs"
else
    print_warning "Monitoring stack has issues"
    echo ""
    echo "Fix:"
    echo "  kubectl apply -f deploy/k8s/monitoring.yaml"
    echo "  kubectl wait --for=condition=ready pod -l app=prometheus"
    echo "  kubectl wait --for=condition=ready pod -l app=grafana"
fi

echo ""
echo "For detailed troubleshooting, see:"
echo "  docs/GRAFANA-NO-DATA-FIX.md"
echo ""

