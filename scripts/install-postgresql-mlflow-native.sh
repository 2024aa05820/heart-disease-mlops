#!/bin/bash
# Install PostgreSQL and MLflow natively (without Docker)
# For Rocky Linux/RHEL/CentOS

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}PostgreSQL + MLflow Native Installation${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Step 1: Install PostgreSQL
echo -e "${BLUE}Step 1: Installing PostgreSQL...${NC}"
if command -v psql &> /dev/null; then
    echo -e "${GREEN}✅ PostgreSQL already installed${NC}"
else
    yum install -y postgresql-server postgresql-contrib
    echo -e "${GREEN}✅ PostgreSQL installed${NC}"
fi
echo ""

# Step 2: Initialize PostgreSQL (if not already initialized)
echo -e "${BLUE}Step 2: Initializing PostgreSQL...${NC}"
if [ ! -d "/var/lib/pgsql/data/base" ]; then
    postgresql-setup --initdb
    echo -e "${GREEN}✅ PostgreSQL initialized${NC}"
else
    echo -e "${GREEN}✅ PostgreSQL already initialized${NC}"
fi
echo ""

# Step 3: Start PostgreSQL
echo -e "${BLUE}Step 3: Starting PostgreSQL...${NC}"
systemctl start postgresql
systemctl enable postgresql
echo -e "${GREEN}✅ PostgreSQL started and enabled${NC}"
echo ""

# Step 4: Create MLflow database and user
echo -e "${BLUE}Step 4: Creating MLflow database...${NC}"
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname = 'mlflow'" | grep -q 1 || \
sudo -u postgres psql <<EOF
CREATE DATABASE mlflow;
CREATE USER mlflow WITH PASSWORD 'mlflow';
GRANT ALL PRIVILEGES ON DATABASE mlflow TO mlflow;
\q
EOF
echo -e "${GREEN}✅ MLflow database created${NC}"
echo ""

# Step 5: Configure PostgreSQL authentication
echo -e "${BLUE}Step 5: Configuring PostgreSQL authentication...${NC}"
PG_HBA="/var/lib/pgsql/data/pg_hba.conf"

# Backup original
cp $PG_HBA ${PG_HBA}.backup

# Add md5 authentication for local connections
if ! grep -q "host.*all.*all.*127.0.0.1/32.*md5" $PG_HBA; then
    echo "host    all             all             127.0.0.1/32            md5" >> $PG_HBA
fi

# Change local authentication to md5
sed -i 's/local.*all.*all.*peer/local   all             all                                     md5/' $PG_HBA

# Restart PostgreSQL
systemctl restart postgresql
echo -e "${GREEN}✅ PostgreSQL configured${NC}"
echo ""

# Step 6: Test PostgreSQL connection
echo -e "${BLUE}Step 6: Testing PostgreSQL connection...${NC}"
PGPASSWORD=mlflow psql -h localhost -U mlflow -d mlflow -c "SELECT version();" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ PostgreSQL connection successful${NC}"
else
    echo -e "${RED}❌ PostgreSQL connection failed${NC}"
    echo -e "${YELLOW}You may need to configure pg_hba.conf manually${NC}"
fi
echo ""

# Step 7: Install Python dependencies
echo -e "${BLUE}Step 7: Installing Python dependencies...${NC}"
echo -e "${YELLOW}Note: Run this as your regular user (not root):${NC}"
echo -e "${YELLOW}  source venv/bin/activate${NC}"
echo -e "${YELLOW}  pip install mlflow psycopg2-binary${NC}"
echo ""

# Step 8: Create MLflow systemd service
echo -e "${BLUE}Step 8: Creating MLflow systemd service...${NC}"
read -p "Enter your username: " USERNAME
read -p "Enter full path to project directory: " PROJECT_DIR
read -p "Enter full path to venv/bin/mlflow: " MLFLOW_BIN

cat > /etc/systemd/system/mlflow.service <<EOF
[Unit]
Description=MLflow Tracking Server
After=network.target postgresql.service

[Service]
Type=simple
User=$USERNAME
WorkingDirectory=$PROJECT_DIR
Environment="PATH=$PROJECT_DIR/venv/bin:/usr/local/bin:/usr/bin"
ExecStart=$MLFLOW_BIN server \\
  --backend-store-uri postgresql://mlflow:mlflow@localhost:5432/mlflow \\
  --default-artifact-root $PROJECT_DIR/mlruns \\
  --host 0.0.0.0 \\
  --port 5000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
echo -e "${GREEN}✅ MLflow service created${NC}"
echo ""

# Summary
echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}✅ Installation Complete!${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps (as your regular user):${NC}"
echo ""
echo -e "1. Install Python dependencies:"
echo -e "   ${BLUE}source venv/bin/activate${NC}"
echo -e "   ${BLUE}pip install mlflow psycopg2-binary${NC}"
echo ""
echo -e "2. Start MLflow service:"
echo -e "   ${BLUE}sudo systemctl start mlflow${NC}"
echo -e "   ${BLUE}sudo systemctl enable mlflow${NC}"
echo ""
echo -e "3. Check MLflow status:"
echo -e "   ${BLUE}sudo systemctl status mlflow${NC}"
echo -e "   ${BLUE}curl http://localhost:5000/health${NC}"
echo ""
echo -e "4. Access MLflow UI:"
echo -e "   ${BLUE}http://localhost:5000${NC}"
echo ""
echo -e "5. Train models:"
echo -e "   ${BLUE}export MLFLOW_TRACKING_URI=http://localhost:5000${NC}"
echo -e "   ${BLUE}python src/models/train.py${NC}"
echo ""

