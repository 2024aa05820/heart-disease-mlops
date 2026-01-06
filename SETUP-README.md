# 🚀 Heart Disease MLOps - One-Command Setup

## Quick Start

### For PostgreSQL (Production)
```bash
sudo ./setup-project.sh
```

### For SQLite (Development)
```bash
sudo ./setup-project.sh --sqlite
```

---

## What Gets Installed

| Component | Description |
|-----------|-------------|
| **Python 3.9** | Runtime environment |
| **PostgreSQL** | Database backend (or SQLite) |
| **MLflow** | Experiment tracking server |
| **Models** | Pre-trained ML models |
| **API** | FastAPI service (ready to start) |

---

## After Setup

### 1. Access MLflow UI
```bash
# Local
http://localhost:5000

# Remote (SSH tunnel from your machine)
ssh -L 5000:localhost:5000 user@server-ip
# Then visit: http://localhost:5000
```

### 2. Check Status
```bash
./check-status.sh
```

### 3. Start API
```bash
./start-api.sh
```

### 4. View Logs
```bash
sudo journalctl -u mlflow -f
```

---

## Common Commands

```bash
# Restart MLflow
sudo systemctl restart mlflow

# Stop all services
./stop-services.sh

# Train models again
source venv/bin/activate
export MLFLOW_TRACKING_URI=http://localhost:5000
python src/models/train.py

# Test API
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"age": 63, "sex": 1, "cp": 3, "trestbps": 145, ...}'
```

---

## Troubleshooting

### MLflow not accessible?
```bash
sudo systemctl status mlflow
sudo journalctl -u mlflow -n 50
```

### PostgreSQL issues?
```bash
sudo systemctl status postgresql
PGPASSWORD=mlflow psql -h localhost -U mlflow -d mlflow
```

### Firewall blocking?
```bash
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --reload
```

---

## Documentation

- **Complete Guide**: [docs/COMPLETE-SETUP-GUIDE.md](docs/COMPLETE-SETUP-GUIDE.md)
- **PostgreSQL Setup**: [docs/POSTGRESQL-MLFLOW-SETUP.md](docs/POSTGRESQL-MLFLOW-SETUP.md)
- **Quick Reference**: [docs/QUICK-REFERENCE.md](docs/QUICK-REFERENCE.md)

---

## Requirements

- Rocky Linux / RHEL / CentOS 8+
- 2GB RAM minimum (4GB recommended)
- 5GB disk space
- Root/sudo access
- Internet connection

---

**Setup Time:** ~10-15 minutes

**Questions?** Check [docs/COMPLETE-SETUP-GUIDE.md](docs/COMPLETE-SETUP-GUIDE.md)

