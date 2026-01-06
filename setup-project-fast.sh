#!/bin/bash
################################################################################
# Heart Disease MLOps - FAST Project Setup Script
# For Rocky Linux / RHEL / CentOS
#
# This is a faster version that SKIPS system updates
# Use this if you already have an updated system
#
# Usage:
#   sudo ./setup-project-fast.sh
#   sudo ./setup-project-fast.sh --sqlite
################################################################################

set -e

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
echo -e "${BLUE}║     Heart Disease MLOps - FAST Setup (No System Update)   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$USE_SQLITE" = true ]; then
    echo -e "${YELLOW}📊 Backend: SQLite${NC}"
    MLFLOW_BACKEND="sqlite:///$PROJECT_DIR/mlflow.db"
else
    echo -e "${YELLOW}📊 Backend: PostgreSQL${NC}"
    MLFLOW_BACKEND="postgresql://mlflow:mlflow@localhost:5432/mlflow"
fi
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Please run as root or with sudo${NC}"
    exit 1
fi

ACTUAL_USER=${SUDO_USER:-$USER}

echo -e "${BLUE}👤 Project user: $ACTUAL_USER${NC}"
echo -e "${BLUE}📁 Project directory: $PROJECT_DIR${NC}"
echo ""

################################################################################
# STEP 1: Install Only Required Packages (NO UPDATE)
################################################################################
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}STEP 1: Installing Required Packages (Skipping system update)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}📦 Installing Python 3.9...${NC}"
yum install -y python39 python39-devel python39-pip 2>&1 | tail -1

echo -e "${YELLOW}📦 Installing Git...${NC}"
yum install -y git 2>&1 | tail -1

echo -e "${YELLOW}📦 Installing build tools...${NC}"
yum install -y gcc gcc-c++ make openssl-devel 2>&1 | tail -1

if [ "$USE_SQLITE" = false ]; then
    echo -e "${YELLOW}📦 Installing PostgreSQL...${NC}"
    yum install -y postgresql-server postgresql-contrib 2>&1 | tail -1
fi

echo -e "${GREEN}✅ Required packages installed${NC}"
echo ""

################################################################################
# STEP 2: Database Setup
################################################################################
if [ "$USE_SQLITE" = false ]; then
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}STEP 2: Setting up PostgreSQL${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    if [ ! -d "/var/lib/pgsql/data/base" ]; then
        echo -e "${YELLOW}🔧 Initializing PostgreSQL...${NC}"
        postgresql-setup --initdb 2>&1 | tail -1
    fi

    echo -e "${YELLOW}🚀 Starting PostgreSQL...${NC}"
    systemctl start postgresql
    systemctl enable postgresql 2>&1 | tail -1

    echo -e "${YELLOW}🔧 Creating MLflow database...${NC}"
    sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname = 'mlflow'" | grep -q 1 || \
    sudo -u postgres psql > /dev/null 2>&1 <<EOF
CREATE DATABASE mlflow;
CREATE USER mlflow WITH PASSWORD 'mlflow';
GRANT ALL PRIVILEGES ON DATABASE mlflow TO mlflow;
ALTER DATABASE mlflow OWNER TO mlflow;
EOF

    echo -e "${YELLOW}🔧 Configuring PostgreSQL...${NC}"
    PG_HBA="/var/lib/pgsql/data/pg_hba.conf"
    cp $PG_HBA ${PG_HBA}.backup 2>/dev/null || true
    
    if ! grep -q "host.*all.*all.*127.0.0.1/32.*md5" $PG_HBA; then
        echo "host    all             all             127.0.0.1/32            md5" >> $PG_HBA
    fi
    sed -i 's/local.*all.*all.*peer/local   all             all                                     md5/' $PG_HBA
    
    systemctl restart postgresql
    sleep 2
    
    PGPASSWORD=mlflow psql -h localhost -U mlflow -d mlflow -c "SELECT 1;" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ PostgreSQL configured${NC}"
    else
        echo -e "${RED}❌ PostgreSQL connection failed, using SQLite${NC}"
        USE_SQLITE=true
        MLFLOW_BACKEND="sqlite:///$PROJECT_DIR/mlflow.db"
    fi
    echo ""
else
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}STEP 2: Using SQLite Backend${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}✅ SQLite backend configured${NC}"
    echo ""
fi

################################################################################
# STEP 3: Python Environment
################################################################################
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}STEP 3: Python Environment${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}🐍 Creating virtual environment...${NC}"
sudo -u $ACTUAL_USER python3.9 -m venv $VENV_DIR
echo -e "${GREEN}✅ Virtual environment created${NC}"

echo -e "${YELLOW}📦 Installing dependencies (2-3 minutes)...${NC}"
sudo -u $ACTUAL_USER $VENV_DIR/bin/pip install --upgrade pip --quiet
sudo -u $ACTUAL_USER $VENV_DIR/bin/pip install -r requirements.txt --quiet

if [ "$USE_SQLITE" = false ]; then
    sudo -u $ACTUAL_USER $VENV_DIR/bin/pip install mlflow psycopg2-binary --quiet
else
    sudo -u $ACTUAL_USER $VENV_DIR/bin/pip install mlflow --quiet
fi
echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

################################################################################
# STEP 4: Download Dataset
################################################################################
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}STEP 4: Dataset${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

sudo -u $ACTUAL_USER mkdir -p data/raw
if [ ! -f "data/raw/heart.csv" ]; then
    echo -e "${YELLOW}📊 Downloading dataset...${NC}"
    sudo -u $ACTUAL_USER $VENV_DIR/bin/python scripts/download_data.py
    echo -e "${GREEN}✅ Dataset downloaded${NC}"
else
    echo -e "${GREEN}✅ Dataset exists${NC}"
fi
echo ""

################################################################################
# STEP 5: MLflow Server
################################################################################
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}STEP 5: MLflow Server${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

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
systemctl start mlflow
systemctl enable mlflow 2>&1 | tail -1
sleep 3

if systemctl is-active --quiet mlflow; then
    echo -e "${GREEN}✅ MLflow server started${NC}"
else
    echo -e "${RED}❌ MLflow failed to start${NC}"
fi
echo ""

################################################################################
# STEP 6: Configure Environment
################################################################################
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}STEP 6: Configuration${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

sudo -u $ACTUAL_USER cat > $PROJECT_DIR/.env <<EOF
MLFLOW_TRACKING_URI=http://localhost:$MLFLOW_PORT
API_HOST=0.0.0.0
API_PORT=$API_PORT
MODEL_PATH=models/best_model.joblib
SCALER_PATH=models/preprocessing_pipeline.joblib
ENVIRONMENT=production
EOF

sudo -u $ACTUAL_USER sed -i "s|tracking_uri:.*|tracking_uri: \"http://localhost:$MLFLOW_PORT\"|" src/config/config.yaml
echo -e "${GREEN}✅ Configuration complete${NC}"
echo ""

################################################################################
# STEP 7: Train Models
################################################################################
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}STEP 7: Training Models (2-5 minutes)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

sudo -u $ACTUAL_USER bash -c "
    source $VENV_DIR/bin/activate
    export MLFLOW_TRACKING_URI=http://localhost:$MLFLOW_PORT
    cd $PROJECT_DIR
    python src/models/train.py
"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Models trained${NC}"
else
    echo -e "${RED}❌ Training failed${NC}"
fi
echo ""

################################################################################
# STEP 8: Create Helper Scripts
################################################################################
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}STEP 8: Helper Scripts${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

cat > $PROJECT_DIR/start-api.sh <<'EOF'
#!/bin/bash
source venv/bin/activate
export MLFLOW_TRACKING_URI=http://localhost:5000
uvicorn src.api.main:app --host 0.0.0.0 --port 8000
EOF
chmod +x $PROJECT_DIR/start-api.sh
chown $ACTUAL_USER:$ACTUAL_USER $PROJECT_DIR/start-api.sh

cat > $PROJECT_DIR/check-status.sh <<'EOF'
#!/bin/bash
echo "=== MLflow Status ==="
sudo systemctl status mlflow --no-pager | head -5
echo ""
curl -s http://localhost:5000/health || echo "Not responding"
echo ""
echo "=== Models ==="
ls -lh models/*.joblib 2>/dev/null || echo "No models"
EOF
chmod +x $PROJECT_DIR/check-status.sh
chown $ACTUAL_USER:$ACTUAL_USER $PROJECT_DIR/check-status.sh

echo -e "${GREEN}✅ Helper scripts created${NC}"
echo ""

################################################################################
# FINAL SUMMARY
################################################################################
SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ✅ SETUP COMPLETE! ✅                         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}MLflow UI:${NC}  http://localhost:$MLFLOW_PORT"
echo -e "${BLUE}           http://$SERVER_IP:$MLFLOW_PORT"
echo ""
echo -e "${YELLOW}Quick Commands:${NC}"
echo -e "  ./check-status.sh          # Check status"
echo -e "  ./start-api.sh             # Start API"
echo -e "  sudo journalctl -u mlflow -f  # View logs"
echo ""
echo -e "${GREEN}🎉 Ready to use!${NC}"
echo ""

