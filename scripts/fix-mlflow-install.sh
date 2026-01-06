#!/bin/bash

# Fix MLflow installation issue on Rocky Linux
# This script resolves the "cannot uninstall requests" error

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Fixing MLflow Installation${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root: sudo $0${NC}"
    exit 1
fi

echo -e "${YELLOW}📦 Creating Python virtual environment for MLflow...${NC}"

# Remove any partial installation
rm -rf /opt/mlflow-env

# Create virtual environment
python3 -m venv /opt/mlflow-env

echo -e "${GREEN}✅ Virtual environment created${NC}"
echo ""

# Activate and install packages
echo -e "${YELLOW}📦 Installing MLflow and dependencies (this may take a few minutes)...${NC}"
source /opt/mlflow-env/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install packages
pip install mlflow scikit-learn pandas numpy matplotlib seaborn

deactivate

echo -e "${GREEN}✅ Packages installed${NC}"
echo ""

# Create wrapper script for mlflow command
echo -e "${YELLOW}🔧 Creating MLflow wrapper script...${NC}"
cat > /usr/local/bin/mlflow << 'EOF'
#!/bin/bash
source /opt/mlflow-env/bin/activate
exec python -m mlflow "$@"
EOF

chmod +x /usr/local/bin/mlflow

echo -e "${GREEN}✅ MLflow wrapper created${NC}"
echo ""

# Make accessible to jenkins user
echo -e "${YELLOW}🔧 Setting permissions for Jenkins...${NC}"
chown -R jenkins:jenkins /opt/mlflow-env

echo -e "${GREEN}✅ Permissions set${NC}"
echo ""

# Test MLflow
echo -e "${YELLOW}🧪 Testing MLflow installation...${NC}"
/usr/local/bin/mlflow --version

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  ✅ MLflow Installation Fixed!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${BLUE}MLflow is now installed in: /opt/mlflow-env${NC}"
echo -e "${BLUE}MLflow command: /usr/local/bin/mlflow${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Start MLflow: ${BLUE}./scripts/start-mlflow.sh${NC}"
echo "2. Or use simple starter: ${BLUE}./start-mlflow-simple.sh${NC}"
echo ""

