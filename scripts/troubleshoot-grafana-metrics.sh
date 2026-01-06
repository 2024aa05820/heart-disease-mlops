#!/bin/bash
#
# Troubleshoot Grafana "No Data" Issue
# This script checks all components needed for metrics to appear in Grafana
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Troubleshooting Grafana Metrics Issue   ${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Step 1: Check if API pods are running
echo -e "${YELLOW}[1/7] Checking API pods...${NC}"
API_PODS=$(kubectl get pods -l app=heart-disease-api --no-headers 2>/dev/null | wc -l)
if [ "$API_PODS" -eq 0 ]; then
    echo -e "${RED}❌ No API pods found${NC}"
    echo -e "${YELLOW}   Deploy API: kubectl apply -f deploy/k8s/deployment.yaml${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Found $API_PODS API pod(s)${NC}"
    kubectl get pods -l app=heart-disease-api
fi
echo ""

# Step 2: Check if API is exposing metrics
echo -e "${YELLOW}[2/7] Checking API metrics endpoint...${NC}"
API_POD=$(kubectl get pods -l app=heart-disease-api -o jsonpath='{.items[0].metadata.name}')
if [ -z "$API_POD" ]; then
    echo -e "${RED}❌ Could not find API pod${NC}"
    exit 1
fi

echo -e "${BLUE}   Testing metrics endpoint on pod: $API_POD${NC}"
METRICS_RESPONSE=$(kubectl exec $API_POD -- curl -s http://localhost:8000/metrics 2>/dev/null || echo "FAILED")

if echo "$METRICS_RESPONSE" | grep -q "predictions_total\|request_count_total"; then
    echo -e "${GREEN}✅ API is exposing metrics${NC}"
    echo -e "${BLUE}   Sample metrics found:${NC}"
    echo "$METRICS_RESPONSE" | grep -E "predictions_total|request_count_total|prediction_latency" | head -3
else
    echo -e "${RED}❌ API metrics endpoint not working${NC}"
    echo -e "${YELLOW}   Response:${NC}"
    echo "$METRICS_RESPONSE" | head -5
    echo ""
    echo -e "${YELLOW}   Checking if API is healthy...${NC}"
    kubectl exec $API_POD -- curl -s http://localhost:8000/health || echo "Health check failed"
fi
echo ""

# Step 3: Check Prometheus pod
echo -e "${YELLOW}[3/7] Checking Prometheus pod...${NC}"
PROM_POD=$(kubectl get pods -l app=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -z "$PROM_POD" ]; then
    echo -e "${RED}❌ Prometheus pod not found${NC}"
    echo -e "${YELLOW}   Deploy: kubectl apply -f deploy/k8s/monitoring.yaml${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Prometheus pod: $PROM_POD${NC}"
    kubectl get pods -l app=prometheus
fi
echo ""

# Step 4: Check Prometheus targets
echo -e "${YELLOW}[4/7] Checking Prometheus targets...${NC}"
echo -e "${BLUE}   Port forwarding Prometheus (will close automatically)...${NC}"
kubectl port-forward service/prometheus 9090:9090 > /dev/null 2>&1 &
PF_PID=$!
sleep 3

TARGETS=$(curl -s http://localhost:9090/api/v1/targets 2>/dev/null || echo "FAILED")
kill $PF_PID 2>/dev/null || true

if echo "$TARGETS" | grep -q "heart-disease-api"; then
    echo -e "${GREEN}✅ Prometheus has heart-disease-api target configured${NC}"
    # Check target status
    TARGET_STATUS=$(echo "$TARGETS" | grep -o '"health":"[^"]*' | head -1 | cut -d'"' -f4)
    if [ "$TARGET_STATUS" = "up" ]; then
        echo -e "${GREEN}   Target status: UP${NC}"
    else
        echo -e "${RED}   Target status: $TARGET_STATUS${NC}"
    fi
else
    echo -e "${RED}❌ Prometheus target not found${NC}"
    echo -e "${YELLOW}   Prometheus may not be scraping the API${NC}"
fi
echo ""

# Step 5: Check Prometheus metrics
echo -e "${YELLOW}[5/7] Checking if Prometheus has collected metrics...${NC}"
kubectl port-forward service/prometheus 9090:9090 > /dev/null 2>&1 &
PF_PID=$!
sleep 3

# Query for API metrics
PREDICTIONS_METRIC=$(curl -s 'http://localhost:9090/api/v1/query?query=predictions_total' 2>/dev/null || echo "FAILED")
kill $PF_PID 2>/dev/null || true

if echo "$PREDICTIONS_METRIC" | grep -q "predictions_total"; then
    echo -e "${GREEN}✅ Prometheus has collected predictions_total metric${NC}"
else
    echo -e "${RED}❌ Prometheus has NOT collected predictions_total metric${NC}"
    echo -e "${YELLOW}   This means Prometheus is not scraping the API correctly${NC}"
fi
echo ""

# Step 6: Check Grafana datasource
echo -e "${YELLOW}[6/7] Checking Grafana datasource configuration...${NC}"
GRAFANA_POD=$(kubectl get pods -l app=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -z "$GRAFANA_POD" ]; then
    echo -e "${RED}❌ Grafana pod not found${NC}"
else
    echo -e "${GREEN}✅ Grafana pod: $GRAFANA_POD${NC}"
    echo -e "${BLUE}   To check datasource:${NC}"
    echo -e "${YELLOW}   1. kubectl port-forward service/grafana 3000:3000${NC}"
    echo -e "${YELLOW}   2. Visit http://localhost:3000${NC}"
    echo -e "${YELLOW}   3. Go to Configuration → Data Sources → Prometheus${NC}"
    echo -e "${YELLOW}   4. Test connection${NC}"
fi
echo ""

# Step 7: Provide fixes
echo -e "${YELLOW}[7/7] Recommended fixes...${NC}"
echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Fix Steps${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check if static config exists in Prometheus
echo -e "${YELLOW}Fix 1: Update Prometheus configuration${NC}"
echo -e "${BLUE}   The Prometheus config needs to scrape the API service directly${NC}"
echo ""
echo -e "${YELLOW}Fix 2: Verify API service is accessible${NC}"
echo -e "${BLUE}   Run: kubectl get svc heart-disease-api-service${NC}"
echo ""

# Check service
echo -e "${YELLOW}Checking API service...${NC}"
kubectl get svc heart-disease-api-service 2>/dev/null && {
    echo -e "${GREEN}✅ Service exists${NC}"
} || {
    echo -e "${RED}❌ Service not found${NC}"
    echo -e "${YELLOW}   Deploy: kubectl apply -f deploy/k8s/service.yaml${NC}"
}
echo ""

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Quick Fix Commands${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${YELLOW}# 1. Restart Prometheus with updated config${NC}"
echo -e "${BLUE}kubectl apply -f deploy/k8s/monitoring.yaml${NC}"
echo -e "${BLUE}kubectl rollout restart deployment/prometheus${NC}"
echo ""
echo -e "${YELLOW}# 2. Check Prometheus targets${NC}"
echo -e "${BLUE}kubectl port-forward service/prometheus 9090:9090${NC}"
echo -e "${BLUE}# Visit http://localhost:9090/targets${NC}"
echo ""
echo -e "${YELLOW}# 3. Generate some traffic to create metrics${NC}"
echo -e "${BLUE}kubectl port-forward service/heart-disease-api-service 8000:80${NC}"
echo -e "${BLUE}curl http://localhost:8000/health${NC}"
echo -e "${BLUE}curl -X POST http://localhost:8000/predict -H 'Content-Type: application/json' -d '{\"age\":63,\"sex\":1,\"cp\":3,\"trestbps\":145,\"chol\":233,\"fbs\":1,\"restecg\":0,\"thalach\":150,\"exang\":0,\"oldpeak\":2.3,\"slope\":0,\"ca\":0,\"thal\":1}'${NC}"
echo ""

