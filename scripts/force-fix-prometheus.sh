#!/bin/bash
#
# Force Fix Prometheus - Delete and Recreate with Correct Config
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Force Fix Prometheus (Delete & Recreate)${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Step 1: Delete existing Prometheus
echo -e "${YELLOW}[1/5] Deleting existing Prometheus deployment...${NC}"
kubectl delete deployment prometheus --ignore-not-found=true
kubectl delete configmap prometheus-config --ignore-not-found=true
kubectl delete configmap prometheus-alerts --ignore-not-found=true
sleep 5
echo -e "${GREEN}✅ Old Prometheus deleted${NC}"
echo ""

# Step 2: Apply fresh configuration
echo -e "${YELLOW}[2/5] Applying fresh Prometheus configuration...${NC}"
kubectl apply -f deploy/k8s/monitoring.yaml
kubectl apply -f deploy/k8s/prometheus-alerts.yaml
echo -e "${GREEN}✅ Configuration applied${NC}"
echo ""

# Step 3: Wait for Prometheus to start
echo -e "${YELLOW}[3/5] Waiting for Prometheus to start...${NC}"
kubectl wait --for=condition=ready pod -l app=prometheus --timeout=120s || {
    echo -e "${RED}❌ Prometheus failed to start${NC}"
    echo -e "${YELLOW}   Checking logs...${NC}"
    PROM_POD=$(kubectl get pods -l app=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    if [ -n "$PROM_POD" ]; then
        kubectl logs $PROM_POD --tail=30
    fi
    exit 1
}
echo -e "${GREEN}✅ Prometheus started${NC}"
echo ""

# Step 4: Verify Prometheus is healthy
echo -e "${YELLOW}[4/5] Verifying Prometheus health...${NC}"
PROM_POD=$(kubectl get pods -l app=prometheus -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward service/prometheus 9090:9090 > /dev/null 2>&1 &
PF_PID=$!
sleep 5

HEALTH=$(curl -s http://localhost:9090/-/healthy 2>/dev/null || echo "FAILED")
if [ "$HEALTH" = "Prometheus is Healthy." ]; then
    echo -e "${GREEN}✅ Prometheus is healthy${NC}"
else
    echo -e "${RED}❌ Health check failed: $HEALTH${NC}"
    kill $PF_PID 2>/dev/null || true
    exit 1
fi

READY=$(curl -s http://localhost:9090/-/ready 2>/dev/null || echo "FAILED")
if [ "$READY" = "Prometheus is Ready." ]; then
    echo -e "${GREEN}✅ Prometheus is ready${NC}"
else
    echo -e "${YELLOW}⚠️  Prometheus not ready yet: $READY${NC}"
fi

kill $PF_PID 2>/dev/null || true
echo ""

# Step 5: Check logs for errors
echo -e "${YELLOW}[5/5] Checking Prometheus logs...${NC}"
kubectl logs $PROM_POD --tail=20 | grep -E "error|Error|ERROR|level=error" || echo -e "${GREEN}   No errors found${NC}"
echo ""

# Summary
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  ✅ Prometheus Fixed!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${BLUE}Access Prometheus:${NC}"
echo -e "${YELLOW}  kubectl port-forward service/prometheus 9090:9090${NC}"
echo -e "${YELLOW}  Then visit: http://localhost:9090${NC}"
echo ""
echo -e "${BLUE}Check targets:${NC}"
echo -e "${YELLOW}  Visit: http://localhost:9090/targets${NC}"
echo ""

