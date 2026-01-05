# 🚀 How to Access All Services

This guide shows you how to access MLflow, Grafana, Prometheus, and the API from your local machine.

## 📋 Prerequisites

- SSH access to the Jenkins server (cloud@172.31.127.73)
- kubectl configured to access the Kubernetes cluster
- Services running on the Jenkins server

---

## 🔍 Step 1: Check Service Status

**On the Jenkins server**, run:

```bash
cd /var/lib/jenkins/workspace/heart-disease-mlops
chmod +x scripts/check-all-services.sh
./scripts/check-all-services.sh
```

This will show you which services are running and which need to be started.

---

## 🚀 Step 2: Start Missing Services

### Start MLflow (if not running)

**On the Jenkins server**:

```bash
cd /var/lib/jenkins/workspace/heart-disease-mlops
chmod +x scripts/start-mlflow.sh
./scripts/start-mlflow.sh
```

### Deploy Monitoring Stack (if Grafana/Prometheus not running)

**On the Jenkins server**:

```bash
cd /var/lib/jenkins/workspace/heart-disease-mlops
chmod +x scripts/setup-monitoring.sh
./scripts/setup-monitoring.sh
```

Wait for pods to be ready:

```bash
kubectl get pods -w
```

Press Ctrl+C when all pods show `Running` status.

---

## 🌐 Step 3: Access Services from Your Local Machine

### 1️⃣ MLflow UI (Port 5001)

**From your LOCAL machine**:

```bash
ssh -L 5001:localhost:5001 cloud@172.31.127.73
```

Keep this terminal open and visit: **http://localhost:5001**

### 2️⃣ Grafana (Port 3000)

**From your LOCAL machine** (requires kubectl configured):

```bash
kubectl port-forward service/grafana 3000:3000
```

Keep this terminal open and visit: **http://localhost:3000**

- **Username**: admin
- **Password**: admin (you'll be prompted to change it)

### 3️⃣ Prometheus (Port 9090)

**From your LOCAL machine** (requires kubectl configured):

```bash
kubectl port-forward service/prometheus 9090:9090
```

Keep this terminal open and visit: **http://localhost:9090**

### 4️⃣ Heart Disease API (Port 8000)

**From your LOCAL machine** (requires kubectl configured):

```bash
kubectl port-forward service/heart-disease-api-service 8000:80
```

Keep this terminal open and visit: **http://localhost:8000/docs**

---

## 🔧 Troubleshooting

### MLflow not accessible

1. Check if MLflow is running on the server:
   ```bash
   ssh cloud@172.31.127.73 "pgrep -f 'mlflow ui'"
   ```

2. If not running, start it:
   ```bash
   ssh cloud@172.31.127.73 "cd /var/lib/jenkins/workspace/heart-disease-mlops && ./scripts/start-mlflow.sh"
   ```

3. Check the logs:
   ```bash
   ssh cloud@172.31.127.73 "tail -f /var/lib/jenkins/workspace/heart-disease-mlops/mlflow.log"
   ```

### Grafana/Prometheus not accessible

1. Check if pods are running:
   ```bash
   kubectl get pods
   ```

2. If pods are not running, deploy monitoring:
   ```bash
   ssh cloud@172.31.127.73 "cd /var/lib/jenkins/workspace/heart-disease-mlops && ./scripts/setup-monitoring.sh"
   ```

3. Check pod logs:
   ```bash
   kubectl logs -l app=grafana
   kubectl logs -l app=prometheus
   ```

### Port forwarding fails

1. Make sure kubectl is configured:
   ```bash
   kubectl cluster-info
   ```

2. Check if the service exists:
   ```bash
   kubectl get services
   ```

3. Try a different local port:
   ```bash
   kubectl port-forward service/grafana 3001:3000
   ```

---

## 📊 Quick Reference

| Service | Local Port | Command |
|---------|-----------|---------|
| MLflow | 5001 | `ssh -L 5001:localhost:5001 cloud@172.31.127.73` |
| Grafana | 3000 | `kubectl port-forward service/grafana 3000:3000` |
| Prometheus | 9090 | `kubectl port-forward service/prometheus 9090:9090` |
| API | 8000 | `kubectl port-forward service/heart-disease-api-service 8000:80` |

---

## 💡 Tips

1. **Keep terminals open**: Each port-forward command needs to keep running in its own terminal
2. **Use tmux/screen**: On the server, use tmux or screen to keep MLflow running even after you disconnect
3. **Check firewall**: Make sure your local firewall allows the port forwarding
4. **Multiple services**: You can run all port-forwards simultaneously in different terminals

---

## 🎯 All-in-One Access Script

Save this as `access-all.sh` on your LOCAL machine:

```bash
#!/bin/bash

# Open multiple terminals for port forwarding
# Requires: gnome-terminal, xterm, or iTerm2

echo "🚀 Starting all port forwards..."

# MLflow (SSH tunnel)
gnome-terminal -- bash -c "ssh -L 5001:localhost:5001 cloud@172.31.127.73; exec bash" &

# Grafana
gnome-terminal -- bash -c "kubectl port-forward service/grafana 3000:3000; exec bash" &

# Prometheus  
gnome-terminal -- bash -c "kubectl port-forward service/prometheus 9090:9090; exec bash" &

# API
gnome-terminal -- bash -c "kubectl port-forward service/heart-disease-api-service 8000:80; exec bash" &

echo "✅ All terminals opened!"
echo ""
echo "Visit:"
echo "  MLflow:     http://localhost:5001"
echo "  Grafana:    http://localhost:3000"
echo "  Prometheus: http://localhost:9090"
echo "  API:        http://localhost:8000/docs"
```

Make it executable: `chmod +x access-all.sh`

