#!/bin/bash
# Debug script to help diagnose Docker container issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Docker Container Debug Script${NC}"
echo ""

# Step 1: Check if models exist locally
echo -e "${YELLOW}Step 1: Checking local models directory...${NC}"
if [ -f "models/best_model.joblib" ] && [ -f "models/preprocessing_pipeline.joblib" ]; then
    echo -e "${GREEN}✅ Model files found locally:${NC}"
    ls -lh models/*.joblib
else
    echo -e "${RED}❌ Model files NOT found locally!${NC}"
    echo "Contents of models/ directory:"
    ls -la models/
    echo ""
    echo -e "${YELLOW}💡 You need to train the models first:${NC}"
    echo "   python scripts/train.py"
    echo ""
    exit 1
fi
echo ""

# Step 2: Build Docker image
echo -e "${YELLOW}Step 2: Building Docker image...${NC}"
docker build -t heart-disease-api:debug .
echo -e "${GREEN}✅ Image built${NC}"
echo ""

# Step 3: Check what's in the image
echo -e "${YELLOW}Step 3: Checking models in Docker image...${NC}"
echo "Models directory in image:"
docker run --rm heart-disease-api:debug ls -lh /app/models/
echo ""

# Step 4: Try to start the container
echo -e "${YELLOW}Step 4: Starting container...${NC}"
CONTAINER_NAME="debug-api-$$"
docker run -d --name $CONTAINER_NAME -p 8002:8000 heart-disease-api:debug
echo -e "${GREEN}✅ Container started: $CONTAINER_NAME${NC}"
echo ""

# Step 5: Wait and show logs
echo -e "${YELLOW}Step 5: Waiting 5 seconds and showing logs...${NC}"
sleep 5
echo "Container logs:"
docker logs $CONTAINER_NAME
echo ""

# Step 6: Check if container is still running
echo -e "${YELLOW}Step 6: Checking container status...${NC}"
if docker ps | grep -q $CONTAINER_NAME; then
    echo -e "${GREEN}✅ Container is running${NC}"
    docker ps | grep $CONTAINER_NAME
    echo ""
    
    # Step 7: Test health endpoint
    echo -e "${YELLOW}Step 7: Testing health endpoint...${NC}"
    sleep 5  # Wait a bit more for app to fully start
    
    if curl -s -f http://localhost:8002/health > /dev/null; then
        echo -e "${GREEN}✅ Health check passed!${NC}"
        echo "Response:"
        curl -s http://localhost:8002/health | python3 -m json.tool || curl -s http://localhost:8002/health
    else
        echo -e "${RED}❌ Health check failed${NC}"
        echo "Trying to get response anyway:"
        curl -v http://localhost:8002/health || true
    fi
else
    echo -e "${RED}❌ Container is NOT running (crashed)${NC}"
    echo "Container logs:"
    docker logs $CONTAINER_NAME
fi
echo ""

# Cleanup
echo -e "${YELLOW}Cleaning up...${NC}"
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true
echo -e "${GREEN}✅ Cleanup complete${NC}"

