#!/bin/bash
#
# Fix Prometheus Scraping Configuration
# This script updates Prometheus to properly scrape the Heart Disease API metrics
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Fixing Prometheus Scraping Configuration ${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Step 1: Check if API pods exist
echo -e "${YELLOW}[1/5] Checking API pods...${NC}"
API_PODS=$(kubectl get pods -l app=heart-disease-api --no-headers 2>/dev/null | wc -l)
if [ "$API_PODS" -eq 0 ]; then
    echo -e "${RED}❌ No API pods found. Deploy API first:${NC}"
    echo -e "${BLUE}   kubectl apply -f deploy/k8s/deployment.yaml${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Found $API_PODS API pod(s)${NC}"
echo ""

# Step 2: Test API metrics endpoint
echo -e "${YELLOW}[2/5] Testing API metrics endpoint...${NC}"
API_POD=$(kubectl get pods -l app=heart-disease-api -o jsonpath='{.items[0].metadata.name}')
echo -e "${BLUE}   Testing pod: $API_POD${NC}"

# Test metrics endpoint
if kubectl exec $API_POD -- curl -s http://localhost:8000/metrics 2>/dev/null | grep -q "predictions_total\|request_count_total"; then
    echo -e "${GREEN}✅ API metrics endpoint is working${NC}"
else
    echo -e "${RED}❌ API metrics endpoint not accessible${NC}"
    echo -e "${YELLOW}   Checking API health...${NC}"
    kubectl exec $API_POD -- curl -s http://localhost:8000/health || echo "Health check failed"
    exit 1
fi
echo ""

# Step 3: Update Prometheus config
echo -e "${YELLOW}[3/5] Updating Prometheus configuration...${NC}"
kubectl apply -f deploy/k8s/monitoring.yaml
echo -e "${GREEN}✅ Prometheus config updated${NC}"
echo ""

# Step 4: Restart Prometheus
echo -e "${YELLOW}[4/5] Restarting Prometheus...${NC}"
kubectl rollout restart deployment/prometheus
echo -e "${BLUE}   Waiting for Prometheus to restart...${NC}"
kubectl rollout status deployment/prometheus --timeout=120s
echo -e "${GREEN}✅ Prometheus restarted${NC}"
echo ""

# Step 5: Verify scraping
echo -e "${YELLOW}[5/5] Verifying Prometheus is scraping...${NC}"
echo -e "${BLUE}   Waiting 10 seconds for Prometheus to scrape...${NC}"
sleep 10

# Port forward and check
kubectl port-forward service/prometheus 9090:9090 > /dev/null 2>&1 &
PF_PID=$!
sleep 3

# Check targets
TARGETS=$(curl -s http://localhost:9090/api/v1/targets 2>/dev/null || echo "{}")
kill $PF_PID 2>/dev/null || true

if echo "$TARGETS" | grep -q "heart-disease-api"; then
    echo -e "${GREEN}✅ Prometheus has heart-disease-api target${NC}"
    
    # Check if target is up
    TARGET_HEALTH=$(echo "$TARGETS" | grep -o '"health":"[^"]*' | head -1 | cut -d'"' -f4 || echo "unknown")
    if [ "$TARGET_HEALTH" = "up" ]; then
        echo -e "${GREEN}   Target status: UP ✅${NC}"
    else
        echo -e "${YELLOW}   Target status: $TARGET_HEALTH${NC}"
        echo -e "${YELLOW}   This may take a few more seconds...${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Target not found yet (may need more time)${NC}"
fi

# Check if metrics are being collected
kubectl port-forward service/prometheus 9090:9090 > /dev/null 2>&1 &
PF_PID=$!
sleep 3

METRICS_QUERY=$(curl -s 'http://localhost:9090/api/v1/query?query=predictions_total' 2>/dev/null || echo "{}")
kill $PF_PID 2>/dev/null || true

if echo "$METRICS_QUERY" | grep -q "predictions_total"; then
    echo -e "${GREEN}✅ Prometheus is collecting metrics!${NC}"
else
    echo -e "${YELLOW}⚠️  Metrics not collected yet (this is normal if no requests have been made)${NC}"
    echo -e "${BLUE}   Generate some traffic to create metrics:${NC}"
    echo -e "${YELLOW}   kubectl port-forward service/heart-disease-api-service 8000:80${NC}"
    echo -e "${YELLOW}   curl http://localhost:8000/health${NC}"
fi
echo ""

# Summary
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  ✅ Fix Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo ""
echo -e "${YELLOW}1. Generate some API traffic to create metrics:${NC}"
echo -e "${BLUE}   kubectl port-forward service/heart-disease-api-service 8000:80${NC}"
echo -e "${BLUE}   curl http://localhost:8000/health${NC}"
echo -e "${BLUE}   curl -X POST http://localhost:8000/predict -H 'Content-Type: application/json' -d '{\"age\":63,\"sex\":1,\"cp\":3,\"trestbps\":145,\"chol\":233,\"fbs\":1,\"restecg\":0,\"thalach\":150,\"exang\":0,\"oldpeak\":2.3,\"slope\":0,\"ca\":0,\"thal\":1}'${NC}"
echo ""
echo -e "${YELLOW}2. Check Prometheus targets:${NC}"
echo -e "${BLUE}   kubectl port-forward service/prometheus 9090:9090${NC}"
echo -e "${BLUE}   Visit: http://localhost:9090/targets${NC}"
echo ""
echo -e "${YELLOW}3. Refresh Grafana dashboard${NC}"
echo -e "${BLUE}   Metrics should appear within 15-30 seconds${NC}"
echo ""

