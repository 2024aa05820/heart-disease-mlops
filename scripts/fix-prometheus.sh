#!/bin/bash
#
# Fix Prometheus Issues
# Comprehensive troubleshooting and fix script for Prometheus
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Prometheus Troubleshooting & Fix         ${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Step 1: Check Prometheus pod
echo -e "${YELLOW}[1/8] Checking Prometheus pod...${NC}"
PROM_POD=$(kubectl get pods -l app=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -z "$PROM_POD" ]; then
    echo -e "${RED}❌ Prometheus pod not found${NC}"
    echo -e "${YELLOW}   Deploying Prometheus...${NC}"
    kubectl apply -f deploy/k8s/monitoring.yaml
    echo -e "${YELLOW}   Waiting for Prometheus to start...${NC}"
    kubectl wait --for=condition=ready pod -l app=prometheus --timeout=120s || {
        echo -e "${RED}❌ Prometheus failed to start${NC}"
        exit 1
    }
    PROM_POD=$(kubectl get pods -l app=prometheus -o jsonpath='{.items[0].metadata.name}')
    echo -e "${GREEN}✅ Prometheus pod: $PROM_POD${NC}"
else
    echo -e "${GREEN}✅ Prometheus pod: $PROM_POD${NC}"
    kubectl get pods -l app=prometheus
fi
echo ""

# Step 2: Check pod status
echo -e "${YELLOW}[2/8] Checking pod status...${NC}"
POD_STATUS=$(kubectl get pod $PROM_POD -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo -e "${RED}❌ Pod status: $POD_STATUS${NC}"
    echo -e "${YELLOW}   Checking pod logs...${NC}"
    kubectl logs $PROM_POD --tail=20
    echo ""
    echo -e "${YELLOW}   Checking pod events...${NC}"
    kubectl describe pod $PROM_POD | grep -A 10 "Events:"
    exit 1
else
    echo -e "${GREEN}✅ Pod is Running${NC}"
fi
echo ""

# Step 3: Check Prometheus logs
echo -e "${YELLOW}[3/8] Checking Prometheus logs...${NC}"
echo -e "${BLUE}   Recent log entries:${NC}"
kubectl logs $PROM_POD --tail=30 | grep -E "error|Error|ERROR|level=error|failed|Failed" || echo -e "${GREEN}   No errors found${NC}"
echo ""

# Step 4: Check Prometheus service
echo -e "${YELLOW}[4/8] Checking Prometheus service...${NC}"
PROM_SVC=$(kubectl get svc prometheus 2>/dev/null || echo "")
if [ -z "$PROM_SVC" ]; then
    echo -e "${RED}❌ Prometheus service not found${NC}"
    echo -e "${YELLOW}   Service should be created by monitoring.yaml${NC}"
    kubectl apply -f deploy/k8s/monitoring.yaml
    sleep 5
else
    echo -e "${GREEN}✅ Prometheus service exists${NC}"
    kubectl get svc prometheus
fi
echo ""

# Step 5: Check Prometheus config
echo -e "${YELLOW}[5/8] Checking Prometheus configuration...${NC}"
CONFIG_MAP=$(kubectl get configmap prometheus-config 2>/dev/null || echo "")
if [ -z "$CONFIG_MAP" ]; then
    echo -e "${RED}❌ Prometheus config not found${NC}"
    echo -e "${YELLOW}   Applying monitoring configuration...${NC}"
    kubectl apply -f deploy/k8s/monitoring.yaml
    sleep 5
else
    echo -e "${GREEN}✅ ConfigMap exists${NC}"
fi

# Verify config is loaded
echo -e "${BLUE}   Checking if config is valid...${NC}"
kubectl exec $PROM_POD -- cat /etc/prometheus/prometheus.yml | head -20
echo ""

# Step 6: Test Prometheus endpoint
echo -e "${YELLOW}[6/8] Testing Prometheus endpoint...${NC}"
kubectl port-forward service/prometheus 9090:9090 > /dev/null 2>&1 &
PF_PID=$!
sleep 3

# Test health endpoint
HEALTH=$(curl -s http://localhost:9090/-/healthy 2>/dev/null || echo "FAILED")
if [ "$HEALTH" = "Prometheus is Healthy." ]; then
    echo -e "${GREEN}✅ Prometheus is healthy${NC}"
else
    echo -e "${RED}❌ Prometheus health check failed: $HEALTH${NC}"
    kill $PF_PID 2>/dev/null || true
    exit 1
fi

# Test ready endpoint
READY=$(curl -s http://localhost:9090/-/ready 2>/dev/null || echo "FAILED")
if [ "$READY" = "Prometheus is Ready." ]; then
    echo -e "${GREEN}✅ Prometheus is ready${NC}"
else
    echo -e "${YELLOW}⚠️  Prometheus not ready yet: $READY${NC}"
fi
echo ""

# Step 7: Check targets
echo -e "${YELLOW}[7/8] Checking Prometheus targets...${NC}"
TARGETS=$(curl -s http://localhost:9090/api/v1/targets 2>/dev/null || echo "{}")
if echo "$TARGETS" | grep -q "heart-disease-api"; then
    echo -e "${GREEN}✅ Targets configured${NC}"
    echo -e "${BLUE}   Target status:${NC}"
    echo "$TARGETS" | grep -o '"health":"[^"]*' | head -3
else
    echo -e "${YELLOW}⚠️  No targets found (this may be normal if API is not deployed)${NC}"
fi
echo ""

# Step 8: Restart Prometheus if needed
echo -e "${YELLOW}[8/8] Restarting Prometheus to apply any config changes...${NC}"
kill $PF_PID 2>/dev/null || true
kubectl rollout restart deployment/prometheus
echo -e "${BLUE}   Waiting for restart...${NC}"
kubectl rollout status deployment/prometheus --timeout=120s
echo -e "${GREEN}✅ Prometheus restarted${NC}"
echo ""

# Summary
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  ✅ Prometheus Fix Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${BLUE}Access Prometheus:${NC}"
echo -e "${YELLOW}  kubectl port-forward service/prometheus 9090:9090${NC}"
echo -e "${YELLOW}  Then visit: http://localhost:9090${NC}"
echo ""
echo -e "${BLUE}Useful Prometheus URLs:${NC}"
echo -e "  - Targets: http://localhost:9090/targets"
echo -e "  - Alerts: http://localhost:9090/alerts"
echo -e "  - Graph: http://localhost:9090/graph"
echo ""
echo -e "${BLUE}Test queries:${NC}"
echo -e "  - up"
echo -e "  - predictions_total"
echo -e "  - rate(request_count_total[5m])"
echo ""

