#!/bin/bash
#
# Fix Prometheus Target Discovery
# This script applies RBAC permissions and updates Prometheus config to discover API targets
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Fixing Prometheus Target Discovery       ${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Step 1: Apply RBAC and updated monitoring config
echo -e "${YELLOW}[1/3] Applying Prometheus RBAC and configuration...${NC}"
kubectl apply -f deploy/k8s/monitoring.yaml
echo -e "${GREEN}✅ Configuration applied${NC}"
echo ""

# Step 2: Restart Prometheus to pick up new config
echo -e "${YELLOW}[2/3] Restarting Prometheus...${NC}"
kubectl rollout restart deployment/prometheus
echo -e "${BLUE}   Waiting for Prometheus to be ready...${NC}"
kubectl rollout status deployment/prometheus --timeout=120s
echo -e "${GREEN}✅ Prometheus restarted${NC}"
echo ""

# Step 3: Verify targets
echo -e "${YELLOW}[3/3] Verifying Prometheus can discover targets...${NC}"
echo -e "${BLUE}   Waiting 10 seconds for Prometheus to discover targets...${NC}"
sleep 10

# Check if API pods exist
API_PODS=$(kubectl get pods -l app=heart-disease-api --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [ "$API_PODS" -eq 0 ]; then
    echo -e "${RED}❌ No API pods found. Please deploy the API first:${NC}"
    echo -e "${BLUE}   kubectl apply -f deploy/k8s/deployment.yaml${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Found $API_PODS API pod(s)${NC}"

# Check Prometheus targets via API
PROM_POD=$(kubectl get pods -l app=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$PROM_POD" ]; then
    echo -e "${RED}❌ Prometheus pod not found${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Checking Prometheus targets...${NC}"
echo -e "${YELLOW}You can also check manually:${NC}"
echo -e "${BLUE}   kubectl port-forward service/prometheus 9090:9090${NC}"
echo -e "${BLUE}   Then visit: http://localhost:9090/targets${NC}"
echo ""

# Try to query targets endpoint
TARGETS=$(kubectl exec $PROM_POD -- wget -qO- http://localhost:9090/api/v1/targets 2>/dev/null | grep -o '"health":"up"' | wc -l | tr -d ' ' || echo "0")

if [ "$TARGETS" -gt "0" ]; then
    echo -e "${GREEN}✅ Prometheus is discovering $TARGETS healthy target(s)${NC}"
else
    echo -e "${YELLOW}⚠️  No healthy targets found yet. This might be normal if:${NC}"
    echo -e "${YELLOW}   - API pods are still starting${NC}"
    echo -e "${YELLOW}   - Prometheus needs more time to discover targets${NC}"
    echo -e "${YELLOW}   - Check Prometheus UI at http://localhost:9090/targets${NC}"
fi

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${GREEN}✅ Fix Applied!${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Port-forward Prometheus: kubectl port-forward service/prometheus 9090:9090"
echo "2. Visit http://localhost:9090/targets to verify targets are discovered"
echo "3. Check that 'heart-disease-api-pods' and 'heart-disease-api-service' show targets"
echo ""

