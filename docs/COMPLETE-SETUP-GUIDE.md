# Complete Project Setup Guide - Rocky Linux

## 🎯 Overview

This guide provides a **single-command setup** for the entire Heart Disease MLOps project on Rocky Linux / RHEL / CentOS.

The setup script (`setup-project.sh`) automates everything:
- ✅ System dependencies installation
- ✅ PostgreSQL or SQLite database setup
- ✅ Python environment configuration
- ✅ MLflow tracking server deployment
- ✅ Dataset download
- ✅ Model training
- ✅ Service configuration

---

## 🚀 Quick Start

### Option 1: PostgreSQL Backend (Recommended for Production)

```bash
# Clone the repository
git clone https://github.com/2024aa05820/heart-disease-mlops.git
cd heart-disease-mlops

# Make script executable
chmod +x setup-project.sh

# Run setup (requires sudo)
sudo ./setup-project.sh
```

### Option 2: SQLite Backend (Simpler, for Development)

```bash
# Clone the repository
git clone https://github.com/2024aa05820/heart-disease-mlops.git
cd heart-disease-mlops

# Make script executable
chmod +x setup-project.sh

# Run setup with SQLite
sudo ./setup-project.sh --sqlite
```

---

## 📋 What the Script Does

### Step 1: System Dependencies
- Updates system packages
- Installs Development Tools
- Installs Python 3.9
- Installs Git and build tools
- Installs required system libraries

### Step 2: Database Setup

**PostgreSQL Mode:**
- Installs PostgreSQL server
- Initializes database
- Creates `mlflow` database and user
- Configures authentication
- Tests connection

**SQLite Mode:**
- Creates SQLite database file
- No additional installation needed

### Step 3: Python Environment
- Creates virtual environment
- Upgrades pip
- Installs all project dependencies
- Installs MLflow and database drivers

### Step 4: Dataset Download
- Downloads heart disease dataset
- Saves to `data/raw/heart.csv`

### Step 5: MLflow Server
- Creates systemd service
- Starts MLflow tracking server
- Enables auto-start on boot
- Configures backend storage

### Step 6: Environment Configuration
- Creates `.env` file
- Updates `config.yaml`
- Sets MLflow tracking URI

### Step 7: Model Training
- Trains multiple ML models
- Logs experiments to MLflow
- Saves best model
- Registers model in MLflow

### Step 8: Verification
- Checks MLflow server health
- Verifies model files
- Tests database connection

### Step 9: Firewall (Optional)
- Opens MLflow port (5000)
- Opens API port (8000)

### Step 10: Helper Scripts
- Creates `start-api.sh`
- Creates `stop-services.sh`
- Creates `check-status.sh`

---

## 🔧 Requirements

### System Requirements
- **OS**: Rocky Linux 8/9, RHEL 8/9, CentOS 8/9
- **RAM**: Minimum 2GB (4GB recommended)
- **Disk**: Minimum 5GB free space
- **User**: Root or sudo access

### Network Requirements
- Internet connection for package downloads
- Ports 5000 (MLflow) and 8000 (API) available

---

## 📊 After Installation

### Access MLflow UI

**Local Access:**
```bash
# Open in browser
http://localhost:5000
```

**Remote Access (SSH Tunnel):**
```bash
# From your local machine
ssh -L 5000:localhost:5000 user@server-ip

# Then visit
http://localhost:5000
```

### Check Status

```bash
# Use the helper script
./check-status.sh

# Or manually
sudo systemctl status mlflow
curl http://localhost:5000/health
```

### View Logs

```bash
# MLflow logs
sudo journalctl -u mlflow -f

# Or check service logs
sudo journalctl -u mlflow -n 100
```

### Start API

```bash
# Use the helper script
./start-api.sh

# Or manually
source venv/bin/activate
export MLFLOW_TRACKING_URI=http://localhost:5000
uvicorn src.api.main:app --host 0.0.0.0 --port 8000
```

### Train Models Again

```bash
source venv/bin/activate
export MLFLOW_TRACKING_URI=http://localhost:5000
python src/models/train.py
```

---

## 🗂️ Directory Structure After Setup

```
heart-disease-mlops/
├── venv/                          # Python virtual environment
├── data/
│   └── raw/
│       └── heart.csv              # Downloaded dataset
├── models/
│   ├── best_model.joblib          # Trained model
│   └── preprocessing_pipeline.joblib
├── mlruns/                        # MLflow artifacts
├── mlflow.db                      # SQLite database (if using SQLite)
├── .env                           # Environment variables
├── setup-project.sh               # This setup script
├── start-api.sh                   # Helper: Start API
├── stop-services.sh               # Helper: Stop services
└── check-status.sh                # Helper: Check status
```

---

## 🔍 Troubleshooting

### MLflow Server Not Starting

```bash
# Check logs
sudo journalctl -u mlflow -n 50

# Check if port is in use
sudo lsof -i :5000

# Restart service
sudo systemctl restart mlflow
```

### PostgreSQL Connection Failed

```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Test connection
PGPASSWORD=mlflow psql -h localhost -U mlflow -d mlflow

# Check authentication config
sudo cat /var/lib/pgsql/data/pg_hba.conf
```

### Model Training Failed

```bash
# Check if MLflow is accessible
curl http://localhost:5000/health

# Check if dataset exists
ls -lh data/raw/heart.csv

# Try training manually
source venv/bin/activate
export MLFLOW_TRACKING_URI=http://localhost:5000
python src/models/train.py
```

### Firewall Blocking Access

```bash
# Check firewall status
sudo firewall-cmd --list-all

# Add ports
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --reload
```

---

## 🔄 Uninstall / Cleanup

```bash
# Stop services
sudo systemctl stop mlflow
sudo systemctl disable mlflow

# Remove systemd service
sudo rm /etc/systemd/system/mlflow.service
sudo systemctl daemon-reload

# Remove PostgreSQL (if installed)
sudo systemctl stop postgresql
sudo yum remove -y postgresql-server postgresql-contrib

# Remove project directory
cd ..
rm -rf heart-disease-mlops
```

---

## 📚 Additional Resources

- [PostgreSQL MLflow Setup](./POSTGRESQL-MLFLOW-SETUP.md)
- [Quick Reference](./QUICK-REFERENCE.md)
- [Deployment Summary](./DEPLOYMENT-SUMMARY.md)
- [MLflow Configuration](./MLFLOW-CONFIGURATION.md)

---

## ✅ Success Indicators

After successful setup, you should see:

1. ✅ MLflow UI accessible at http://localhost:5000
2. ✅ Experiments visible in MLflow UI
3. ✅ Models registered in MLflow
4. ✅ Model files in `models/` directory
5. ✅ MLflow service running: `sudo systemctl status mlflow`
6. ✅ No errors in logs: `sudo journalctl -u mlflow -n 50`

---

**Setup Time:** Approximately 10-15 minutes (depending on internet speed)

**One command to rule them all!** 🚀

