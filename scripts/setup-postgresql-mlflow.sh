#!/bin/bash
# Setup MLflow with PostgreSQL backend
# This script starts PostgreSQL and MLflow using Docker Compose

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}🚀 MLflow with PostgreSQL Setup${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running!${NC}"
    echo "Please start Docker and try again."
    exit 1
fi

echo -e "${GREEN}✅ Docker is running${NC}"
echo ""

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ docker-compose not found!${NC}"
    echo "Please install docker-compose and try again."
    exit 1
fi

echo -e "${GREEN}✅ docker-compose is available${NC}"
echo ""

# Navigate to project root
cd "$(dirname "$0")/.."

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo -e "${YELLOW}📝 Creating .env file from .env.example...${NC}"
    cp .env.example .env
    echo -e "${GREEN}✅ .env file created${NC}"
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi
echo ""

# Start services
echo -e "${BLUE}🚀 Starting services...${NC}"
echo ""

docker-compose -f deploy/docker/docker-compose.yml up -d postgres mlflow

echo ""
echo -e "${YELLOW}⏳ Waiting for PostgreSQL to be ready...${NC}"
sleep 10

# Check PostgreSQL health
if docker exec mlflow-postgres pg_isready -U mlflow >/dev/null 2>&1; then
    echo -e "${GREEN}✅ PostgreSQL is ready${NC}"
else
    echo -e "${RED}❌ PostgreSQL is not ready${NC}"
    echo "Check logs: docker logs mlflow-postgres"
    exit 1
fi

echo ""
echo -e "${YELLOW}⏳ Waiting for MLflow to be ready...${NC}"

# Wait for MLflow to be ready (max 60 seconds)
for i in {1..30}; do
    if curl -f http://localhost:5000/health >/dev/null 2>&1; then
        echo -e "${GREEN}✅ MLflow is ready${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}❌ MLflow failed to start${NC}"
        echo "Check logs: docker logs mlflow-server"
        exit 1
    fi
    sleep 2
done

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "${GREEN}📊 Services Running:${NC}"
echo ""
docker-compose -f deploy/docker/docker-compose.yml ps
echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}🌐 Access URLs:${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "  ${GREEN}MLflow UI:${NC}      http://localhost:5000"
echo -e "  ${GREEN}PostgreSQL:${NC}     localhost:5432"
echo -e "  ${GREEN}  User:${NC}         mlflow"
echo -e "  ${GREEN}  Password:${NC}     mlflow"
echo -e "  ${GREEN}  Database:${NC}     mlflow"
echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}📋 Next Steps:${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "  1. ${YELLOW}Train models:${NC}"
echo -e "     export MLFLOW_TRACKING_URI=http://localhost:5000"
echo -e "     python src/models/train.py"
echo ""
echo -e "  2. ${YELLOW}View experiments:${NC}"
echo -e "     open http://localhost:5000"
echo ""
echo -e "  3. ${YELLOW}Start API:${NC}"
echo -e "     docker-compose -f deploy/docker/docker-compose.yml up -d api"
echo -e "     open http://localhost:8000/docs"
echo ""
echo -e "  4. ${YELLOW}Start monitoring:${NC}"
echo -e "     docker-compose -f deploy/docker/docker-compose.yml up -d prometheus grafana"
echo -e "     open http://localhost:3000  # Grafana (admin/admin)"
echo ""
echo -e "  5. ${YELLOW}Stop services:${NC}"
echo -e "     docker-compose -f deploy/docker/docker-compose.yml down"
echo ""
echo -e "${GREEN}✅ No more YAML RepresenterError with PostgreSQL backend!${NC}"
echo ""

