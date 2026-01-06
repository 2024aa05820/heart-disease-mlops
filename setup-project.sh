#!/bin/bash
################################################################################
# Heart Disease MLOps - Complete Project Setup Script
# For Rocky Linux / RHEL / CentOS
#
# This script sets up the entire project from scratch:
# - Python environment
# - PostgreSQL database
# - MLflow tracking server
# - Model training
# - API deployment
#
# Usage:
#   sudo ./setup-project.sh
#
# Or for SQLite backend (simpler, no PostgreSQL):
#   sudo ./setup-project.sh --sqlite
################################################################################

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
USE_SQLITE=false
PROJECT_DIR=$(pwd)
VENV_DIR="$PROJECT_DIR/venv"
MLFLOW_PORT=5000
API_PORT=8000

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --sqlite)
            USE_SQLITE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--sqlite]"
            exit 1
            ;;
    esac
done

# Print header
clear
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}║        Heart Disease MLOps - Project Setup                ║${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$USE_SQLITE" = true ]; then
    echo -e "${YELLOW}📊 Backend: SQLite (simpler, file-based)${NC}"
else
    echo -e "${YELLOW}📊 Backend: PostgreSQL (production-ready)${NC}"
fi
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Please run as root or with sudo${NC}"
    echo -e "${YELLOW}Usage: sudo ./setup-project.sh${NC}"
    exit 1
fi

# Get the actual user (not root)
ACTUAL_USER=${SUDO_USER:-$USER}
ACTUAL_HOME=$(eval echo ~$ACTUAL_USER)

echo -e "${BLUE}👤 Running as: root${NC}"
echo -e "${BLUE}👤 Project user: $ACTUAL_USER${NC}"
echo -e "${BLUE}📁 Project directory: $PROJECT_DIR${NC}"
echo ""

# Confirmation
read -p "Continue with setup? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Setup cancelled${NC}"
    exit 0
fi
echo ""

################################################################################
# STEP 1: System Dependencies
################################################################################
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}STEP 1: Installing System Dependencies${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}📦 Updating system packages...${NC}"
yum update -y > /dev/null 2>&1

echo -e "${YELLOW}📦 Installing development tools...${NC}"
yum groupinstall -y "Development Tools" > /dev/null 2>&1

echo -e "${YELLOW}📦 Installing Python 3.9...${NC}"
yum install -y python39 python39-devel python39-pip > /dev/null 2>&1

echo -e "${YELLOW}📦 Installing Git...${NC}"
yum install -y git > /dev/null 2>&1

echo -e "${YELLOW}📦 Installing system libraries...${NC}"
yum install -y \
    gcc \
    gcc-c++ \
    make \
    openssl-devel \
    bzip2-devel \
    libffi-devel \
    zlib-devel \
    wget \
    curl \
    > /dev/null 2>&1

echo -e "${GREEN}✅ System dependencies installed${NC}"
echo ""

################################################################################
# STEP 2: PostgreSQL Setup (if not using SQLite)
################################################################################
if [ "$USE_SQLITE" = false ]; then
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}STEP 2: Setting up PostgreSQL${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${YELLOW}📦 Installing PostgreSQL...${NC}"
    yum install -y postgresql-server postgresql-contrib > /dev/null 2>&1

    echo -e "${YELLOW}🔧 Initializing PostgreSQL...${NC}"
    if [ ! -d "/var/lib/pgsql/data/base" ]; then
        postgresql-setup --initdb > /dev/null 2>&1
        echo -e "${GREEN}✅ PostgreSQL initialized${NC}"
    else
        echo -e "${GREEN}✅ PostgreSQL already initialized${NC}"
    fi

    echo -e "${YELLOW}🚀 Starting PostgreSQL...${NC}"
    systemctl start postgresql
    systemctl enable postgresql > /dev/null 2>&1
    echo -e "${GREEN}✅ PostgreSQL started${NC}"

    echo -e "${YELLOW}🔧 Creating MLflow database...${NC}"
    sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname = 'mlflow'" | grep -q 1 || \
    sudo -u postgres psql > /dev/null 2>&1 <<EOF
CREATE DATABASE mlflow;
CREATE USER mlflow WITH PASSWORD 'mlflow';
GRANT ALL PRIVILEGES ON DATABASE mlflow TO mlflow;
ALTER DATABASE mlflow OWNER TO mlflow;
EOF
    echo -e "${GREEN}✅ MLflow database created${NC}"

    echo -e "${YELLOW}🔧 Configuring PostgreSQL authentication...${NC}"
    PG_HBA="/var/lib/pgsql/data/pg_hba.conf"
    cp $PG_HBA ${PG_HBA}.backup 2>/dev/null || true

    # Add md5 authentication
    if ! grep -q "host.*all.*all.*127.0.0.1/32.*md5" $PG_HBA; then
        echo "host    all             all             127.0.0.1/32            md5" >> $PG_HBA
    fi
    sed -i 's/local.*all.*all.*peer/local   all             all                                     md5/' $PG_HBA

    systemctl restart postgresql
    echo -e "${GREEN}✅ PostgreSQL configured${NC}"

    # Test connection
    echo -e "${YELLOW}🧪 Testing PostgreSQL connection...${NC}"
    sleep 2
    PGPASSWORD=mlflow psql -h localhost -U mlflow -d mlflow -c "SELECT 1;" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ PostgreSQL connection successful${NC}"
        MLFLOW_BACKEND="postgresql://mlflow:mlflow@localhost:5432/mlflow"
    else
        echo -e "${RED}❌ PostgreSQL connection failed, falling back to SQLite${NC}"
        USE_SQLITE=true
        MLFLOW_BACKEND="sqlite:///$PROJECT_DIR/mlflow.db"
    fi
    echo ""
else
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}STEP 2: Using SQLite Backend${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    MLFLOW_BACKEND="sqlite:///$PROJECT_DIR/mlflow.db"
    echo -e "${GREEN}✅ SQLite backend configured${NC}"
    echo ""
fi

################################################################################
# STEP 3: Python Virtual Environment
################################################################################
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}STEP 3: Setting up Python Virtual Environment${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}🐍 Creating virtual environment...${NC}"
sudo -u $ACTUAL_USER python3.9 -m venv $VENV_DIR
echo -e "${GREEN}✅ Virtual environment created${NC}"

echo -e "${YELLOW}📦 Upgrading pip...${NC}"
sudo -u $ACTUAL_USER $VENV_DIR/bin/pip install --upgrade pip > /dev/null 2>&1
echo -e "${GREEN}✅ Pip upgraded${NC}"

echo -e "${YELLOW}📦 Installing project dependencies...${NC}"
sudo -u $ACTUAL_USER $VENV_DIR/bin/pip install -r requirements.txt > /dev/null 2>&1
echo -e "${GREEN}✅ Project dependencies installed${NC}"

echo -e "${YELLOW}📦 Installing MLflow and database drivers...${NC}"
if [ "$USE_SQLITE" = false ]; then
    sudo -u $ACTUAL_USER $VENV_DIR/bin/pip install mlflow psycopg2-binary > /dev/null 2>&1
else
    sudo -u $ACTUAL_USER $VENV_DIR/bin/pip install mlflow > /dev/null 2>&1
fi
echo -e "${GREEN}✅ MLflow installed${NC}"
echo ""

################################################################################
# STEP 4: Download Dataset
################################################################################
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}STEP 4: Downloading Dataset${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}📊 Downloading heart disease dataset...${NC}"
sudo -u $ACTUAL_USER mkdir -p data/raw
if [ ! -f "data/raw/heart.csv" ]; then
    sudo -u $ACTUAL_USER $VENV_DIR/bin/python scripts/download_data.py
    echo -e "${GREEN}✅ Dataset downloaded${NC}"
else
    echo -e "${GREEN}✅ Dataset already exists${NC}"
fi
echo ""

################################################################################
# STEP 5: MLflow Server Setup
################################################################################
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}STEP 5: Setting up MLflow Tracking Server${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}📝 Creating MLflow systemd service...${NC}"
cat > /etc/systemd/system/mlflow.service <<EOF
[Unit]
Description=MLflow Tracking Server
After=network.target

[Service]
Type=simple
User=$ACTUAL_USER
WorkingDirectory=$PROJECT_DIR
Environment="PATH=$VENV_DIR/bin:/usr/local/bin:/usr/bin"
ExecStart=$VENV_DIR/bin/mlflow server \\
  --backend-store-uri $MLFLOW_BACKEND \\
  --default-artifact-root $PROJECT_DIR/mlruns \\
  --host 0.0.0.0 \\
  --port $MLFLOW_PORT
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
echo -e "${GREEN}✅ MLflow service created${NC}"

echo -e "${YELLOW}🚀 Starting MLflow server...${NC}"
systemctl start mlflow
systemctl enable mlflow > /dev/null 2>&1
sleep 5

# Check if MLflow is running
if systemctl is-active --quiet mlflow; then
    echo -e "${GREEN}✅ MLflow server started${NC}"
else
    echo -e "${RED}❌ MLflow server failed to start${NC}"
    echo -e "${YELLOW}Check logs: sudo journalctl -u mlflow -n 50${NC}"
fi
echo ""

################################################################################
# STEP 6: Configure Environment
################################################################################
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}STEP 6: Configuring Environment${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}📝 Creating .env file...${NC}"
sudo -u $ACTUAL_USER cat > $PROJECT_DIR/.env <<EOF
# MLflow Configuration
MLFLOW_TRACKING_URI=http://localhost:$MLFLOW_PORT

# API Configuration
API_HOST=0.0.0.0
API_PORT=$API_PORT

# Model Configuration
MODEL_PATH=models/best_model.joblib
SCALER_PATH=models/preprocessing_pipeline.joblib

# Environment
ENVIRONMENT=production
EOF
echo -e "${GREEN}✅ Environment configured${NC}"

echo -e "${YELLOW}📝 Updating config.yaml...${NC}"
sudo -u $ACTUAL_USER sed -i "s|tracking_uri:.*|tracking_uri: \"http://localhost:$MLFLOW_PORT\"|" src/config/config.yaml
echo -e "${GREEN}✅ Config updated${NC}"
echo ""

################################################################################
# STEP 7: Train Models
################################################################################
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}STEP 7: Training ML Models${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}🤖 Training models (this may take 2-5 minutes)...${NC}"
sudo -u $ACTUAL_USER bash -c "
    source $VENV_DIR/bin/activate
    export MLFLOW_TRACKING_URI=http://localhost:$MLFLOW_PORT
    cd $PROJECT_DIR
    python src/models/train.py
"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Models trained successfully${NC}"
else
    echo -e "${RED}❌ Model training failed${NC}"
    echo -e "${YELLOW}Check logs above for errors${NC}"
fi
echo ""

################################################################################
# STEP 8: Verify Installation
################################################################################
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}STEP 8: Verifying Installation${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}🔍 Checking services...${NC}"

# Check MLflow
if curl -f http://localhost:$MLFLOW_PORT/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ MLflow server is running${NC}"
else
    echo -e "${RED}❌ MLflow server is not responding${NC}"
fi

# Check models
if [ -f "$PROJECT_DIR/models/best_model.joblib" ]; then
    echo -e "${GREEN}✅ Model files exist${NC}"
else
    echo -e "${RED}❌ Model files not found${NC}"
fi

# Check database
if [ "$USE_SQLITE" = false ]; then
    if PGPASSWORD=mlflow psql -h localhost -U mlflow -d mlflow -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PostgreSQL is accessible${NC}"
    else
        echo -e "${RED}❌ PostgreSQL is not accessible${NC}"
    fi
else
    if [ -f "$PROJECT_DIR/mlflow.db" ]; then
        echo -e "${GREEN}✅ SQLite database exists${NC}"
    else
        echo -e "${YELLOW}⚠️  SQLite database will be created on first use${NC}"
    fi
fi
echo ""

################################################################################
# STEP 9: Firewall Configuration (Optional)
################################################################################
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}STEP 9: Firewall Configuration (Optional)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

if systemctl is-active --quiet firewalld; then
    read -p "Configure firewall to allow MLflow port $MLFLOW_PORT? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        firewall-cmd --permanent --add-port=$MLFLOW_PORT/tcp > /dev/null 2>&1
        firewall-cmd --permanent --add-port=$API_PORT/tcp > /dev/null 2>&1
        firewall-cmd --reload > /dev/null 2>&1
        echo -e "${GREEN}✅ Firewall configured${NC}"
    else
        echo -e "${YELLOW}⚠️  Firewall not configured${NC}"
        echo -e "${YELLOW}   To configure later: sudo firewall-cmd --permanent --add-port=$MLFLOW_PORT/tcp${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Firewalld not running, skipping firewall configuration${NC}"
fi
echo ""

################################################################################
# STEP 10: Create Helper Scripts
################################################################################
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}STEP 10: Creating Helper Scripts${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Start API script
cat > $PROJECT_DIR/start-api.sh <<'EOF'
#!/bin/bash
source venv/bin/activate
export MLFLOW_TRACKING_URI=http://localhost:5000
uvicorn src.api.main:app --host 0.0.0.0 --port 8000
EOF
chmod +x $PROJECT_DIR/start-api.sh
chown $ACTUAL_USER:$ACTUAL_USER $PROJECT_DIR/start-api.sh
echo -e "${GREEN}✅ Created start-api.sh${NC}"

# Stop all services script
cat > $PROJECT_DIR/stop-services.sh <<'EOF'
#!/bin/bash
echo "Stopping MLflow..."
sudo systemctl stop mlflow
echo "✅ All services stopped"
EOF
chmod +x $PROJECT_DIR/stop-services.sh
chown $ACTUAL_USER:$ACTUAL_USER $PROJECT_DIR/stop-services.sh
echo -e "${GREEN}✅ Created stop-services.sh${NC}"

# Status check script
cat > $PROJECT_DIR/check-status.sh <<'EOF'
#!/bin/bash
echo "=== Service Status ==="
echo ""
echo "MLflow Server:"
sudo systemctl status mlflow --no-pager | head -5
echo ""
echo "MLflow Health:"
curl -s http://localhost:5000/health || echo "Not responding"
echo ""
echo ""
echo "Models:"
ls -lh models/*.joblib 2>/dev/null || echo "No models found"
EOF
chmod +x $PROJECT_DIR/check-status.sh
chown $ACTUAL_USER:$ACTUAL_USER $PROJECT_DIR/check-status.sh
echo -e "${GREEN}✅ Created check-status.sh${NC}"
echo ""

################################################################################
# FINAL SUMMARY
################################################################################
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║              ✅ SETUP COMPLETE! ✅                         ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}📊 Installation Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Backend:${NC}        $([ "$USE_SQLITE" = true ] && echo "SQLite" || echo "PostgreSQL")"
echo -e "${YELLOW}MLflow URI:${NC}     $MLFLOW_BACKEND"
echo -e "${YELLOW}Project Dir:${NC}    $PROJECT_DIR"
echo -e "${YELLOW}Virtual Env:${NC}    $VENV_DIR"
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🌐 Access URLs${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}MLflow UI:${NC}"
echo -e "  Local:  http://localhost:$MLFLOW_PORT"
echo -e "  Remote: http://$SERVER_IP:$MLFLOW_PORT"
echo ""
echo -e "${GREEN}SSH Tunnel (from your local machine):${NC}"
echo -e "  ssh -L $MLFLOW_PORT:localhost:$MLFLOW_PORT $ACTUAL_USER@$SERVER_IP"
echo -e "  Then visit: http://localhost:$MLFLOW_PORT"
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🚀 Quick Commands${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Check status:${NC}"
echo -e "  ./check-status.sh"
echo ""
echo -e "${GREEN}View MLflow logs:${NC}"
echo -e "  sudo journalctl -u mlflow -f"
echo ""
echo -e "${GREEN}Restart MLflow:${NC}"
echo -e "  sudo systemctl restart mlflow"
echo ""
echo -e "${GREEN}Start API:${NC}"
echo -e "  ./start-api.sh"
echo ""
echo -e "${GREEN}Train models again:${NC}"
echo -e "  source venv/bin/activate"
echo -e "  export MLFLOW_TRACKING_URI=http://localhost:$MLFLOW_PORT"
echo -e "  python src/models/train.py"
echo ""
echo -e "${GREEN}Stop all services:${NC}"
echo -e "  ./stop-services.sh"
echo ""

if [ "$USE_SQLITE" = false ]; then
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}🗄️  PostgreSQL Commands${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}Connect to database:${NC}"
    echo -e "  PGPASSWORD=mlflow psql -h localhost -U mlflow -d mlflow"
    echo ""
    echo -e "${GREEN}Check PostgreSQL status:${NC}"
    echo -e "  sudo systemctl status postgresql"
    echo ""
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}📚 Documentation${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  docs/POSTGRESQL-MLFLOW-SETUP.md"
echo -e "  docs/QUICK-REFERENCE.md"
echo -e "  docs/DEPLOYMENT-SUMMARY.md"
echo ""

echo -e "${GREEN}🎉 Your Heart Disease MLOps project is ready!${NC}"
echo ""

