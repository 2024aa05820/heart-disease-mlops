# 🚀 Quick Start Guide - Heart Disease MLOps

This is a quick reference for setting up and running the Heart Disease MLOps project on Rocky Linux.

---

## 📋 Prerequisites

- Rocky Linux server with sudo access
- At least 4GB RAM, 2 CPUs
- Internet connection

---

## ⚡ Fast Setup (Skip System Updates)

```bash
# 1. Clone the repository
git clone https://github.com/2024aa05820/heart-disease-mlops.git
cd heart-disease-mlops

# 2. Run setup script (skip updates for faster setup)
sudo ./scripts/rocky-setup.sh --skip-update

# 3. Log out and log back in (for docker group)
exit
# SSH back in

# 4. Start Minikube
minikube start --driver=docker --cpus=2 --memory=4096

# 5. Configure Jenkins to access Minikube
sudo ./scripts/configure-jenkins-minikube.sh

# 6. Access Jenkins
# URL: http://YOUR_SERVER_IP:8080
# Password: sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

## 🐌 Full Setup (With System Updates)

```bash
# Same as above, but use:
sudo ./scripts/rocky-setup.sh --update
```

---

## 🎯 After Setup

### 1. Configure Jenkins

1. Open Jenkins: `http://YOUR_SERVER_IP:8080`
2. Install suggested plugins
3. Create admin user
4. Add GitHub token:
   - Go to: Manage Jenkins → Credentials → Add
   - Kind: Secret text
   - ID: `github-token`
   - Secret: Your GitHub Personal Access Token

### 2. Create Jenkins Pipeline

1. New Item → Pipeline
2. Name: `heart-disease-mlops`
3. Pipeline → Definition: Pipeline script from SCM
4. SCM: Git
5. Repository URL: `https://github.com/2024aa05820/heart-disease-mlops.git`
6. Branch: `*/main`
7. Script Path: `Jenkinsfile`
8. Save

### 3. Run First Build

1. Click "Build Now"
2. Monitor console output
3. All stages should pass ✅

---

## 🌐 Access Services

### Check Service Status

```bash
cd /var/lib/jenkins/workspace/heart-disease-mlops
./scripts/check-all-services.sh
```

### Start MLflow

```bash
./scripts/start-mlflow.sh
```

### Access from Local Machine

```bash
# MLflow (port 5001)
ssh -L 5001:localhost:5001 cloud@YOUR_SERVER_IP
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

## 🔧 Common Commands

```bash
# Check Minikube status
minikube status

# Check Kubernetes pods
kubectl get pods

# Check Jenkins logs
sudo journalctl -u jenkins -f

# Restart Jenkins
sudo systemctl restart jenkins

# Check MLflow process
pgrep -f "mlflow ui"

# View MLflow logs
tail -f logs/mlflow.log

# Deploy monitoring stack
./scripts/setup-monitoring.sh
```

---

## 🐛 Troubleshooting

### Jenkins can't access Minikube

```bash
sudo ./scripts/configure-jenkins-minikube.sh
sudo systemctl restart jenkins
```

### MLflow not running

```bash
./scripts/start-mlflow.sh
```

### Pods not starting

```bash
kubectl get pods
kubectl describe pod POD_NAME
kubectl logs POD_NAME
```

### Port already in use

```bash
# Find process using port
sudo netstat -tlnp | grep PORT_NUMBER

# Kill process
sudo kill PID
```

---

## 📚 Full Documentation

- **Complete Setup**: `ROCKY_LINUX_SETUP.md`
- **Service Access**: `ACCESS-SERVICES.md`
- **MLflow Setup**: `MLFLOW-SETUP-SUMMARY.md`
- **Jenkins Setup**: `JENKINS_SETUP.md`
- **Deployment**: `REMOTE_DEPLOYMENT.md`

---

## 🎯 Quick Reference

| Component | Port | Access |
|-----------|------|--------|
| Jenkins | 8080 | Direct: http://SERVER_IP:8080 |
| MLflow | 5001 | SSH Tunnel: ssh -L 5001:localhost:5001 |
| Grafana | 3000 | Port Forward: kubectl port-forward |
| Prometheus | 9090 | Port Forward: kubectl port-forward |
| API | 8000 | Port Forward: kubectl port-forward |

---

## ⏱️ Estimated Setup Time

- **Fast Setup** (--skip-update): ~10-15 minutes
- **Full Setup** (--update): ~20-30 minutes
- **First Build**: ~5-10 minutes

---

## 💡 Pro Tips

1. **Use tmux/screen** on the server to keep processes running
2. **Keep terminals open** for port forwarding
3. **Check logs** if something fails
4. **Run check-all-services.sh** to verify everything is running
5. **Use --skip-update** for faster setup if system is already updated

---

## 🆘 Need Help?

1. Check the full documentation in the respective MD files
2. Run `./scripts/check-all-services.sh` to diagnose issues
3. Check logs: Jenkins, MLflow, Kubernetes pods
4. Verify Minikube is running: `minikube status`

