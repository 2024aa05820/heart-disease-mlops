#!/bin/bash
# Complete MLflow Setup Script with PostgreSQL Backend
# This script starts PostgreSQL + MLflow, downloads data, and trains models

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}MLflow Complete Setup (PostgreSQL)${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "${YELLOW}⚠️  DEPRECATED: Use ./scripts/setup-postgresql-mlflow.sh instead${NC}"
echo -e "${YELLOW}This script is kept for backward compatibility${NC}\n"

# Check if we're in the right directory
if [ ! -f "requirements.txt" ]; then
    echo -e "${RED}Error: Not in project root directory${NC}"
    echo -e "${YELLOW}Please navigate to: heart-disease-mlops/${NC}"
    exit 1
fi

# Check if virtual environment is activated
if [ -z "$VIRTUAL_ENV" ]; then
    echo -e "${YELLOW}Warning: Virtual environment not activated${NC}"
    echo -e "${YELLOW}Attempting to activate...${NC}"
    
    if [ -f ".venv/bin/activate" ]; then
        source .venv/bin/activate
        echo -e "${GREEN}✓ Virtual environment activated${NC}\n"
    else
        echo -e "${RED}Error: Virtual environment not found${NC}"
        echo -e "${YELLOW}Run: make init${NC}"
        exit 1
    fi
fi

# Step 1: Download dataset
echo -e "${BLUE}Step 1: Downloading dataset...${NC}"
if [ -f "data/raw/heart.csv" ]; then
    echo -e "${GREEN}✓ Dataset already exists${NC}\n"
else
    python scripts/download_data.py
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Dataset downloaded successfully${NC}\n"
    else
        echo -e "${RED}✗ Failed to download dataset${NC}"
        exit 1
    fi
fi

# Step 2: Train models
echo -e "${BLUE}Step 2: Training models (this may take 2-5 minutes)...${NC}"
python scripts/train.py
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Models trained successfully${NC}\n"
else
    echo -e "${RED}✗ Failed to train models${NC}"
    exit 1
fi

# Step 3: Start PostgreSQL + MLflow
echo -e "${BLUE}Step 3: Starting PostgreSQL + MLflow...${NC}"
./scripts/setup-postgresql-mlflow.sh

# Step 4: Instructions
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "${GREEN}MLflow UI is running at: http://localhost:5000${NC}"
echo -e "${GREEN}PostgreSQL backend - No YAML errors!${NC}\n"

echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Train models: python src/models/train.py"
echo -e "  2. View experiments: http://localhost:5000"
echo -e "  3. Start API: docker-compose -f deploy/docker/docker-compose.yml up -d api"
echo ""

