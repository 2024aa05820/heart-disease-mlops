#!/bin/bash
#
# Setup Grafana Dashboards and Alerts
# This script imports dashboards and configures alerts for the Heart Disease MLOps project
#
# Usage:
#   ./scripts/setup-grafana-dashboards.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Setting up Grafana Dashboards & Alerts  ${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl not found. Please install kubectl first.${NC}"
    exit 1
fi

# Check if Grafana pod is running
echo -e "${YELLOW}1. Checking Grafana pod status...${NC}"
if ! kubectl get pods -l app=grafana | grep -q Running; then
    echo -e "${RED}❌ Grafana pod is not running${NC}"
    echo -e "${YELLOW}   Deploying monitoring stack...${NC}"
    kubectl apply -f deploy/k8s/monitoring.yaml
    echo -e "${YELLOW}   Waiting for Grafana to be ready...${NC}"
    kubectl wait --for=condition=ready pod -l app=grafana --timeout=120s || {
        echo -e "${RED}❌ Grafana failed to start${NC}"
        exit 1
    }
fi
echo -e "${GREEN}✅ Grafana is running${NC}"
echo ""

# Get Grafana admin credentials
GRAFANA_USER="admin"
GRAFANA_PASS="admin"

# Port forward Grafana
echo -e "${YELLOW}2. Setting up port forward to Grafana...${NC}"
kubectl port-forward service/grafana 3000:3000 > /dev/null 2>&1 &
PF_PID=$!
sleep 3
echo -e "${GREEN}✅ Port forward established (PID: $PF_PID)${NC}"
echo ""

# Function to cleanup port forward
cleanup() {
    echo ""
    echo -e "${YELLOW}Cleaning up port forward...${NC}"
    kill $PF_PID 2>/dev/null || true
}

trap cleanup EXIT

# Wait for Grafana to be ready
echo -e "${YELLOW}3. Waiting for Grafana to be ready...${NC}"
for i in {1..30}; do
    if curl -s -u "$GRAFANA_USER:$GRAFANA_PASS" http://localhost:3000/api/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Grafana is ready${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}❌ Grafana failed to respond${NC}"
        exit 1
    fi
    sleep 2
done
echo ""

# Get or create API key
echo -e "${YELLOW}4. Creating Grafana API key...${NC}"
API_KEY_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASS" \
    -d '{"name":"heart-disease-mlops","role":"Admin"}' \
    http://localhost:3000/api/auth/keys)

API_KEY=$(echo $API_KEY_RESPONSE | grep -o '"key":"[^"]*' | cut -d'"' -f4)

if [ -z "$API_KEY" ]; then
    echo -e "${YELLOW}⚠️  Could not create API key, trying to get existing key...${NC}"
    # Try to get existing keys
    EXISTING_KEYS=$(curl -s -u "$GRAFANA_USER:$GRAFANA_PASS" http://localhost:3000/api/auth/keys)
    API_KEY=$(echo $EXISTING_KEYS | grep -o '"key":"[^"]*' | head -1 | cut -d'"' -f4)
    
    if [ -z "$API_KEY" ]; then
        echo -e "${RED}❌ Could not get API key. Please create one manually in Grafana UI${NC}"
        echo -e "${YELLOW}   Go to: http://localhost:3000/org/apikeys${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✅ API key obtained${NC}"
echo ""

# Import dashboards
echo -e "${YELLOW}5. Importing dashboards...${NC}"

# Function to import dashboard
import_dashboard() {
    local dashboard_file=$1
    local dashboard_name=$(basename "$dashboard_file" .json)
    
    echo -e "${BLUE}   Importing $dashboard_name...${NC}"
    
    # Read dashboard JSON
    DASHBOARD_JSON=$(cat "$dashboard_file")
    
    # Import dashboard
    RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $API_KEY" \
        -d "{\"dashboard\":$DASHBOARD_JSON,\"overwrite\":true}" \
        http://localhost:3000/api/dashboards/db)
    
    if echo "$RESPONSE" | grep -q '"status":"success"'; then
        echo -e "${GREEN}   ✅ $dashboard_name imported successfully${NC}"
    else
        echo -e "${YELLOW}   ⚠️  $dashboard_name import had issues (may already exist)${NC}"
        echo "   Response: $RESPONSE" | head -3
    fi
}

# Import all dashboards
if [ -f "grafana/heart-disease-api-dashboard.json" ]; then
    import_dashboard "grafana/heart-disease-api-dashboard.json"
fi

if [ -f "grafana/comprehensive-dashboard.json" ]; then
    import_dashboard "grafana/comprehensive-dashboard.json"
fi

echo ""

# Configure Prometheus datasource if not exists
echo -e "${YELLOW}6. Configuring Prometheus datasource...${NC}"
DATASOURCE_CONFIG='{
  "name": "Prometheus",
  "type": "prometheus",
  "url": "http://prometheus:9090",
  "access": "proxy",
  "isDefault": true
}'

# Check if datasource exists
EXISTING_DS=$(curl -s -H "Authorization: Bearer $API_KEY" \
    http://localhost:3000/api/datasources/name/Prometheus)

if echo "$EXISTING_DS" | grep -q '"name":"Prometheus"'; then
    echo -e "${GREEN}   ✅ Prometheus datasource already exists${NC}"
else
    # Create datasource
    RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $API_KEY" \
        -d "$DATASOURCE_CONFIG" \
        http://localhost:3000/api/datasources)
    
    if echo "$RESPONSE" | grep -q '"datasource"'; then
        echo -e "${GREEN}   ✅ Prometheus datasource created${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Could not create datasource (may already exist)${NC}"
    fi
fi
echo ""

# Deploy Prometheus alerts
echo -e "${YELLOW}7. Deploying Prometheus alert rules...${NC}"
if [ -f "deploy/k8s/prometheus-alerts.yaml" ]; then
    kubectl apply -f deploy/k8s/prometheus-alerts.yaml
    echo -e "${GREEN}✅ Alert rules deployed${NC}"
    
    # Restart Prometheus to load new rules
    echo -e "${YELLOW}   Restarting Prometheus to load alert rules...${NC}"
    kubectl rollout restart deployment/prometheus
    kubectl rollout status deployment/prometheus --timeout=60s
    echo -e "${GREEN}✅ Prometheus restarted${NC}"
else
    echo -e "${YELLOW}⚠️  prometheus-alerts.yaml not found, skipping${NC}"
fi
echo ""

# Summary
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  ✅ Setup Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${BLUE}📊 Access Grafana:${NC}"
echo "   URL: http://localhost:3000"
echo "   Username: admin"
echo "   Password: admin"
echo ""
echo -e "${BLUE}📋 Available Dashboards:${NC}"
echo "   - Heart Disease API Monitoring"
echo "   - Heart Disease API - Comprehensive Monitoring"
echo ""
echo -e "${BLUE}🚨 Alert Rules Configured:${NC}"
echo "   - High Error Rate (Warning: >5%, Critical: >10%)"
echo "   - High Latency (Warning: P95 >1s, Critical: P95 >2s)"
echo "   - Service Down"
echo "   - Low Request Rate"
echo "   - High Prediction Failure Rate"
echo "   - Resource Usage (CPU/Memory)"
echo ""
echo -e "${YELLOW}💡 Note: Port forward will close when script exits${NC}"
echo -e "${YELLOW}   To keep it running, use:${NC}"
echo -e "${BLUE}   kubectl port-forward service/grafana 3000:3000${NC}"
echo ""

