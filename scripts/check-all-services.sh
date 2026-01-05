#!/bin/bash

# Check and display status of all services
# Run this on the Jenkins server to verify everything is running

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo ""
    echo "========================================="
    echo "$1"
    echo "========================================="
}

print_service() {
    local name=$1
    local status=$2
    local url=$3
    
    if [ "$status" = "running" ]; then
        echo -e "${GREEN}✅ $name${NC}"
        echo -e "   Status: ${GREEN}Running${NC}"
        echo -e "   URL: ${BLUE}$url${NC}"
    else
        echo -e "${RED}❌ $name${NC}"
        echo -e "   Status: ${RED}Not Running${NC}"
        echo -e "   Expected URL: ${YELLOW}$url${NC}"
    fi
    echo ""
}

SERVER_IP=$(hostname -I | awk '{print $1}')

print_header "🔍 Service Status Check"

# Check MLflow
echo "Checking MLflow UI..."
if pgrep -f "mlflow ui" > /dev/null; then
    MLFLOW_STATUS="running"
    MLFLOW_PORT=$(netstat -tlnp 2>/dev/null | grep "mlflow" | grep -oP ':\K[0-9]+' | head -1 || echo "5001")
else
    MLFLOW_STATUS="stopped"
    MLFLOW_PORT="5001"
fi

# Check Kubernetes services
echo "Checking Kubernetes services..."

# Check if kubectl is configured
if kubectl cluster-info &> /dev/null; then
    K8S_CONNECTED="yes"
    
    # Check API pods
    if kubectl get pods -l app=heart-disease-api 2>/dev/null | grep -q "Running"; then
        API_STATUS="running"
    else
        API_STATUS="stopped"
    fi
    
    # Check Grafana
    if kubectl get pods -l app=grafana 2>/dev/null | grep -q "Running"; then
        GRAFANA_STATUS="running"
    else
        GRAFANA_STATUS="stopped"
    fi
    
    # Check Prometheus
    if kubectl get pods -l app=prometheus 2>/dev/null | grep -q "Running"; then
        PROMETHEUS_STATUS="running"
    else
        PROMETHEUS_STATUS="stopped"
    fi
else
    K8S_CONNECTED="no"
    API_STATUS="unknown"
    GRAFANA_STATUS="unknown"
    PROMETHEUS_STATUS="unknown"
fi

print_header "📊 Service Status"

# MLflow
print_service "MLflow UI" "$MLFLOW_STATUS" "http://$SERVER_IP:$MLFLOW_PORT"

# API
if [ "$K8S_CONNECTED" = "yes" ]; then
    print_service "Heart Disease API" "$API_STATUS" "kubectl port-forward service/heart-disease-api-service 8000:80"
fi

# Grafana
if [ "$K8S_CONNECTED" = "yes" ]; then
    print_service "Grafana" "$GRAFANA_STATUS" "kubectl port-forward service/grafana 3000:3000"
fi

# Prometheus
if [ "$K8S_CONNECTED" = "yes" ]; then
    print_service "Prometheus" "$PROMETHEUS_STATUS" "kubectl port-forward service/prometheus 9090:9090"
fi

print_header "🚀 How to Access Services"

echo "From your LOCAL machine, run these commands:"
echo ""

echo "1️⃣  MLflow UI:"
if [ "$MLFLOW_STATUS" = "running" ]; then
    echo -e "   ${GREEN}ssh -L 5001:localhost:$MLFLOW_PORT cloud@$SERVER_IP${NC}"
    echo "   Then visit: http://localhost:5001"
else
    echo -e "   ${RED}MLflow is not running. Start it first:${NC}"
    echo "   cd /var/lib/jenkins/workspace/heart-disease-mlops"
    echo "   nohup mlflow ui --host 0.0.0.0 --port 5001 > mlflow.log 2>&1 &"
fi
echo ""

echo "2️⃣  Grafana:"
if [ "$GRAFANA_STATUS" = "running" ]; then
    echo -e "   ${GREEN}kubectl port-forward service/grafana 3000:3000${NC}"
    echo "   Then visit: http://localhost:3000 (admin/admin)"
elif [ "$GRAFANA_STATUS" = "stopped" ]; then
    echo -e "   ${RED}Grafana is not deployed. Deploy it first:${NC}"
    echo "   ./scripts/setup-monitoring.sh"
fi
echo ""

echo "3️⃣  Prometheus:"
if [ "$PROMETHEUS_STATUS" = "running" ]; then
    echo -e "   ${GREEN}kubectl port-forward service/prometheus 9090:9090${NC}"
    echo "   Then visit: http://localhost:9090"
elif [ "$PROMETHEUS_STATUS" = "stopped" ]; then
    echo -e "   ${RED}Prometheus is not deployed. Deploy it first:${NC}"
    echo "   ./scripts/setup-monitoring.sh"
fi
echo ""

echo "4️⃣  API:"
if [ "$API_STATUS" = "running" ]; then
    echo -e "   ${GREEN}kubectl port-forward service/heart-disease-api-service 8000:80${NC}"
    echo "   Then visit: http://localhost:8000/docs"
fi
echo ""

print_header "🔧 Quick Fixes"

if [ "$MLFLOW_STATUS" = "stopped" ]; then
    echo "Start MLflow:"
    echo "  cd /var/lib/jenkins/workspace/heart-disease-mlops"
    echo "  nohup mlflow ui --host 0.0.0.0 --port 5001 > mlflow.log 2>&1 &"
    echo ""
fi

if [ "$GRAFANA_STATUS" = "stopped" ] || [ "$PROMETHEUS_STATUS" = "stopped" ]; then
    echo "Deploy monitoring stack:"
    echo "  ./scripts/setup-monitoring.sh"
    echo ""
fi

if [ "$API_STATUS" = "stopped" ]; then
    echo "Check API deployment:"
    echo "  kubectl get pods -l app=heart-disease-api"
    echo "  kubectl logs -l app=heart-disease-api"
    echo ""
fi

echo "========================================="

