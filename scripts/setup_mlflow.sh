#!/bin/bash
# Complete MLflow Setup Script
# This script downloads data, trains models, and starts MLflow UI

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}MLflow Complete Setup Script${NC}"
echo -e "${BLUE}========================================${NC}\n"

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

# Step 3: Verify MLflow runs
echo -e "${BLUE}Step 3: Verifying MLflow experiments...${NC}"
if [ -d "mlruns" ]; then
    RUN_COUNT=$(find mlruns -type d -name "meta.yaml" | wc -l)
    echo -e "${GREEN}✓ MLflow experiments created${NC}"
    echo -e "${GREEN}  Found experiment runs in mlruns/${NC}\n"
else
    echo -e "${RED}✗ MLflow runs not found${NC}"
    exit 1
fi

# Step 4: Instructions for starting MLflow UI
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "${YELLOW}To start MLflow UI, run:${NC}"
echo -e "${BLUE}  mlflow ui --host 0.0.0.0 --port 5000${NC}\n"

echo -e "${YELLOW}Then access from your browser:${NC}"
echo -e "${BLUE}  http://<YOUR_SERVER_IP>:5000${NC}\n"

echo -e "${YELLOW}Or use SSH port forwarding from your local machine:${NC}"
echo -e "${BLUE}  ssh -L 5000:localhost:5000 user@remote-server${NC}"
echo -e "${BLUE}  Then access: http://localhost:5000${NC}\n"

# Ask if user wants to start MLflow UI now
read -p "Start MLflow UI now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n${GREEN}Starting MLflow UI...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}\n"
    mlflow ui --host 0.0.0.0 --port 5000
fi

