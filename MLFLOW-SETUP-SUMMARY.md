# MLflow and Monitoring Services Setup Summary

## 🎯 What Was Done

This document summarizes all the changes made to integrate MLflow and monitoring services into the Heart Disease MLOps project.

---

## 📦 Files Created/Modified

### New Files Created:

1. **`ACCESS-SERVICES.md`** - Comprehensive guide for accessing all services
   - MLflow UI access instructions
   - Grafana access instructions
   - Prometheus access instructions
   - API access instructions
   - Troubleshooting guide

2. **`scripts/check-all-services.sh`** - Service status checker
   - Checks if MLflow is running
   - Checks Kubernetes services (Grafana, Prometheus, API)
   - Shows access instructions for each service
   - Provides quick fix commands

3. **`scripts/start-mlflow.sh`** - MLflow startup script
   - Starts MLflow UI on port 5001
   - Creates necessary directories (mlruns, logs)
   - Handles errors gracefully
   - Shows access instructions

4. **`start-mlflow-simple.sh`** - Simplified MLflow starter
   - Minimal version for quick startup
   - Works from any directory
   - Easy to use

### Modified Files:

1. **`scripts/rocky-setup.sh`** - Updated with MLflow installation
   - Added MLflow and ML libraries installation
   - Added firewall rules for ports 3000, 5001, 9090
   - Created MLflow directories
   - Added service access instructions
   - Updated troubleshooting section

---

## 🚀 What Gets Installed

### On Rocky Linux Server:

```bash
# Python packages
pip3 install mlflow scikit-learn pandas numpy matplotlib seaborn

# Firewall ports opened
- 8080 (Jenkins)
- 5001 (MLflow)
- 3000 (Grafana)
- 9090 (Prometheus)

# Directories created
/var/lib/jenkins/workspace/heart-disease-mlops/mlruns
/var/lib/jenkins/workspace/heart-disease-mlops/logs
```

---

## 🌐 Service Access Guide

### From the Jenkins Server:

```bash
# Check all services
./scripts/check-all-services.sh

# Start MLflow
./scripts/start-mlflow.sh

# Deploy monitoring (Grafana + Prometheus)
./scripts/setup-monitoring.sh
```

### From Your Local Machine:

```bash
# MLflow (port 5001)
ssh -L 5001:localhost:5001 cloud@172.31.127.73
# Visit: http://localhost:5001

# Grafana (port 3000)
kubectl port-forward service/grafana 3000:3000
# Visit: http://localhost:3000 (admin/admin)

# Prometheus (port 9090)
kubectl port-forward service/prometheus 9090:9090
# Visit: http://localhost:9090

# API (port 8000)
kubectl port-forward service/heart-disease-api-service 8000:80
# Visit: http://localhost:8000/docs
```

---

## 🔧 How It Works

### MLflow Integration:

1. **Training Stage**: Models are trained and logged to MLflow
   - Experiments tracked in `mlruns/` directory
   - Metrics, parameters, and artifacts saved
   - Model registry updated

2. **MLflow UI**: Provides visualization
   - Compare experiments
   - View metrics and parameters
   - Download model artifacts
   - Track model versions

3. **Access**: Via SSH tunnel from local machine
   - Secure access through SSH
   - No direct internet exposure
   - Port forwarding to localhost

### Monitoring Stack:

1. **Prometheus**: Collects metrics from API
   - Scrapes `/metrics` endpoint
   - Stores time-series data
   - Provides query interface

2. **Grafana**: Visualizes metrics
   - Pre-configured dashboards
   - Real-time monitoring
   - Alerting capabilities

3. **Access**: Via kubectl port-forward
   - Requires kubectl configured
   - Direct access to Kubernetes services
   - No external exposure

---

## 📋 Quick Reference

| Service | Port | Access Method | URL |
|---------|------|---------------|-----|
| Jenkins | 8080 | Direct | http://SERVER_IP:8080 |
| MLflow | 5001 | SSH Tunnel | http://localhost:5001 |
| Grafana | 3000 | Port Forward | http://localhost:3000 |
| Prometheus | 9090 | Port Forward | http://localhost:9090 |
| API | 8000 | Port Forward | http://localhost:8000/docs |

---

## 🐛 Common Issues Fixed

### Issue 1: MLflow Permission Denied
**Problem**: `mlflow.log: Permission denied`

**Solution**: 
- Updated script to use current directory
- Create logs directory with proper permissions
- Use `$PWD` instead of hardcoded paths

### Issue 2: Services Not Accessible
**Problem**: Grafana on 3000, Prometheus on 9090, but MLflow not found

**Solution**:
- MLflow needs to be started manually on server
- Use `./scripts/start-mlflow.sh` to start it
- Access via SSH tunnel, not direct connection

### Issue 3: Confusion About Access Methods
**Problem**: Different services use different access methods

**Solution**:
- Created comprehensive `ACCESS-SERVICES.md` guide
- Added `check-all-services.sh` to show current status
- Clear instructions for each service

---

## ✅ Verification Steps

After running the updated `rocky-setup.sh`:

```bash
# 1. Verify MLflow is installed
mlflow --version

# 2. Check firewall rules
sudo firewall-cmd --list-ports

# 3. Verify directories exist
ls -la /var/lib/jenkins/workspace/heart-disease-mlops/

# 4. Start MLflow
./scripts/start-mlflow.sh

# 5. Check all services
./scripts/check-all-services.sh
```

---

## 📚 Documentation

- **Full Setup Guide**: `ROCKY_LINUX_SETUP.md`
- **Service Access**: `ACCESS-SERVICES.md`
- **Jenkins Setup**: `JENKINS_SETUP.md`
- **Deployment Guide**: `REMOTE_DEPLOYMENT.md`

---

## 🎓 Next Steps

1. Run the updated `rocky-setup.sh` on the server
2. Start MLflow using the provided scripts
3. Deploy monitoring stack
4. Access services from your local machine
5. Monitor your ML pipeline!

