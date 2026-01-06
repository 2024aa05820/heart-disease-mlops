# 🎛️ Service Management Guide

Quick reference for managing all MLOps services.

---

## 🚀 One-Command Service Management

### Start All Services

```bash
./scripts/start-all-services.sh
```

**What it does:**
1. ✅ Checks and starts Docker
2. ✅ Starts Minikube cluster (2 CPUs, 4GB RAM)
3. ✅ Starts Jenkins service
4. ✅ Configures Jenkins to access Minikube
5. ✅ Starts MLflow UI on port 5001
6. ✅ Optionally deploys monitoring stack (Grafana + Prometheus)

**Output:**
- Colored status messages
- Service health checks
- Comprehensive summary
- Access instructions

---

### Stop All Services

```bash
./scripts/stop-all-services.sh
```

**What it does:**
1. 🛑 Stops MLflow UI
2. 🛑 Optionally stops Jenkins (asks for confirmation)
3. 🛑 Stops Minikube cluster
4. 🛑 Optionally stops Docker (asks for confirmation)

**Interactive:**
- Prompts before stopping Jenkins
- Prompts before stopping Docker
- Shows final status of all services

---

## 🔍 Service Status Checking

### Check All Services

```bash
./scripts/check-all-services.sh
```

Shows status of:
- Docker
- Minikube
- Jenkins
- MLflow
- Kubernetes pods
- Monitoring stack

---

### Verify Docker Access

```bash
./scripts/verify-docker-access.sh
```

Checks:
- Docker group membership
- Docker socket permissions
- Docker command access
- Provides fix instructions if needed

---

## 🎯 Individual Service Management

### Docker

```bash
# Start
sudo systemctl start docker

# Stop
sudo systemctl stop docker

# Restart
sudo systemctl restart docker

# Status
sudo systemctl status docker

# Test access
docker ps
```

---

### Minikube

```bash
# Start (with specific resources)
minikube start --driver=docker --cpus=2 --memory=4096

# Stop
minikube stop

# Delete (removes cluster)
minikube delete

# Status
minikube status

# Dashboard
minikube dashboard
```

---

### Jenkins

```bash
# Start
sudo systemctl start jenkins

# Stop
sudo systemctl stop jenkins

# Restart
sudo systemctl restart jenkins

# Status
sudo systemctl status jenkins

# Logs (follow)
sudo journalctl -u jenkins -f

# Logs (last 100 lines)
sudo journalctl -u jenkins -n 100

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

### MLflow

```bash
# Start
./scripts/start-mlflow.sh

# Start (simple version)
./start-mlflow-simple.sh

# Stop
pkill -f "mlflow ui"

# Check if running
pgrep -f "mlflow ui"

# View logs
tail -f logs/mlflow.log

# View logs (follow)
tail -f /var/lib/jenkins/workspace/heart-disease-mlops/logs/mlflow.log
```

---

### Monitoring Stack (Grafana + Prometheus)

```bash
# Deploy
./scripts/setup-monitoring.sh

# Check pods
kubectl get pods

# Check services
kubectl get services

# Port forward Grafana
kubectl port-forward service/grafana 3000:3000

# Port forward Prometheus
kubectl port-forward service/prometheus 9090:9090

# Delete monitoring stack
kubectl delete -f k8s/monitoring/
```

---

## 🔧 Troubleshooting Commands

### Docker Issues

```bash
# Check Docker daemon
sudo systemctl status docker

# Check Docker socket
ls -l /var/run/docker.sock

# Check group membership
groups

# Add user to docker group
sudo usermod -aG docker $USER

# Activate docker group (current session)
newgrp docker
```

---

### Minikube Issues

```bash
# Check status
minikube status

# View logs
minikube logs

# SSH into Minikube
minikube ssh

# Check Minikube IP
minikube ip

# Reset Minikube
minikube delete
minikube start --driver=docker --cpus=2 --memory=4096
```

---

### Jenkins Issues

```bash
# Check if Jenkins can access Docker
sudo -u jenkins docker ps

# Check if Jenkins can access kubectl
sudo -u jenkins kubectl get nodes

# Reconfigure Jenkins for Minikube
sudo ./scripts/configure-jenkins-minikube.sh

# Restart Jenkins
sudo systemctl restart jenkins
```

---

### MLflow Issues

```bash
# Check if running
pgrep -f "mlflow ui"

# Check port
netstat -tlnp | grep 5001

# Kill MLflow
pkill -f "mlflow ui"

# Check logs
tail -f logs/mlflow.log

# Reinstall MLflow
sudo ./scripts/fix-mlflow-install.sh
```

---

### Kubernetes Issues

```bash
# Check all pods
kubectl get pods

# Describe pod
kubectl describe pod POD_NAME

# View pod logs
kubectl logs POD_NAME

# Delete pod (will restart)
kubectl delete pod POD_NAME

# Check services
kubectl get services

# Check deployments
kubectl get deployments
```

---

## 📊 Service Access URLs

| Service | Port | Access Method | URL |
|---------|------|---------------|-----|
| Jenkins | 8080 | Direct | http://SERVER_IP:8080 |
| MLflow | 5001 | SSH Tunnel | ssh -L 5001:localhost:5001 cloud@SERVER_IP |
| Grafana | 3000 | Port Forward | kubectl port-forward service/grafana 3000:3000 |
| Prometheus | 9090 | Port Forward | kubectl port-forward service/prometheus 9090:9090 |
| API | 8000 | Port Forward | kubectl port-forward service/heart-disease-api-service 8000:80 |

---

## 🔄 Common Workflows

### Daily Startup

```bash
# Start all services
./scripts/start-all-services.sh

# Check status
./scripts/check-all-services.sh
```

---

### Daily Shutdown

```bash
# Stop all services
./scripts/stop-all-services.sh
```

---

### After System Reboot

```bash
# Everything needs to be restarted
./scripts/start-all-services.sh
```

---

### Debugging a Failed Build

```bash
# Check Jenkins logs
sudo journalctl -u jenkins -f

# Check Minikube
minikube status
kubectl get pods

# Check MLflow
pgrep -f "mlflow ui"
tail -f logs/mlflow.log

# Check all services
./scripts/check-all-services.sh
```

---

## 📚 Related Documentation

- **Quick Start**: `QUICK-START.md`
- **Full Setup**: `ROCKY_LINUX_SETUP.md`
- **Service Access**: `ACCESS-SERVICES.md`
- **MLflow Setup**: `MLFLOW-SETUP-SUMMARY.md`
- **Fix Docker Issues**: `FIX-REQUESTS-ERROR.md`

---

## 💡 Pro Tips

1. **Use tmux/screen** to keep services running in background
2. **Check logs first** when troubleshooting
3. **Restart services** in order: Docker → Minikube → Jenkins → MLflow
4. **Use start-all-services.sh** after system reboot
5. **Keep terminals open** for port forwarding (Grafana, Prometheus)

---

## 🆘 Quick Help

```bash
# Everything broken? Start fresh:
./scripts/stop-all-services.sh
./scripts/start-all-services.sh

# Docker permission issues?
./scripts/verify-docker-access.sh

# MLflow not working?
sudo ./scripts/fix-mlflow-install.sh

# Jenkins can't access Minikube?
sudo ./scripts/configure-jenkins-minikube.sh
```

