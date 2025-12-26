# 🚀 Quick Reference Card

**One-page reference for deploying Heart Disease MLOps to remote Minikube.**

---

## ⚡ Fastest Deployment (5 Minutes)

```bash
# 1. SSH to remote machine
ssh username@remote-server-ip

# 2. Navigate and pull latest code
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
git pull origin main

# 3. Deploy everything
./scripts/remote_quick_deploy.sh

# ✅ Done! API and MLflow are running
```

---

## 🎯 Four Deployment Methods

| Method | Time | Commands | Best For |
|--------|------|----------|----------|
| **1. Rebuild** ⭐ | 5 min | 3 | Quick/Assignment |
| **2. Artifact** | 10 min | 6 | CI/CD Learning |
| **3. Registry** | 15 min | 4 | Production |
| **4. Jenkins** 🚀 | Auto | 0 | Automated CI/CD |

---

## 📋 Essential Commands

### **Deployment**
```bash
# Full automated deployment
./scripts/remote_quick_deploy.sh

# Deploy to Kubernetes only
./scripts/deploy_to_minikube.sh

# Deploy GitHub artifact
./scripts/deploy_github_artifact.sh ~/docker-image.tar.gz

# Clean and redeploy
./scripts/deploy_to_minikube.sh --clean
```

### **MLflow UI**
```bash
# Start in background
./scripts/start_mlflow_ui.sh --background

# Start in foreground
./scripts/start_mlflow_ui.sh

# Check status
./scripts/start_mlflow_ui.sh --status

# Stop MLflow
./scripts/start_mlflow_ui.sh --stop
```

### **Kubernetes**
```bash
# View all resources
kubectl get all

# View pods
kubectl get pods

# View pod logs
kubectl logs -f <pod-name>

# Restart deployment
kubectl rollout restart deployment/heart-disease-api

# Delete all resources
kubectl delete -f deploy/k8s/
```

### **Testing**
```bash
# Get service URL
minikube service heart-disease-api-service --url

# Health check
curl $(minikube service heart-disease-api-service --url)/health

# Make prediction
curl -X POST $(minikube service heart-disease-api-service --url)/predict \
  -H "Content-Type: application/json" \
  -d '{"age":63,"sex":1,"cp":3,"trestbps":145,"chol":233,"fbs":1,"restecg":0,"thalach":150,"exang":0,"oldpeak":2.3,"slope":0,"ca":0,"thal":1}'
```

### **Minikube**
```bash
# Check status
minikube status

# Get IP
minikube ip

# Load Docker image
minikube image load heart-disease-api:latest

# List images
minikube image ls | grep heart-disease
```

### **Jenkins CI/CD**
```bash
# Install Jenkins (one-time)
sudo dnf install java-17-openjdk jenkins -y
sudo systemctl start jenkins

# Access Jenkins
http://remote-ip:8080

# Get initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Add jenkins to docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

# Manual trigger (if needed)
# Go to Jenkins → Job → Build Now

# Automatic trigger
# Push to GitHub → Webhook → Jenkins builds & deploys
```

---

## 🌐 Access from Local Machine

### **SSH Tunnel (Recommended)**
```bash
# On local machine (replace IPs)
ssh -L 5001:localhost:5001 -L 8000:192.168.49.2:30080 user@remote-ip

# Then access:
# API: http://localhost:8000
# MLflow: http://localhost:5001
```

### **Direct Access**
```bash
# Get remote IP (on remote machine)
hostname -I | awk '{print $1}'

# Access:
# API: http://remote-ip:30080
# MLflow: http://remote-ip:5001
```

---

## 🧪 Quick Tests

### **1. Health Check**
```bash
curl $(minikube service heart-disease-api-service --url)/health
# Expected: {"status":"healthy","model_loaded":true}
```

### **2. Prediction**
```bash
SERVICE_URL=$(minikube service heart-disease-api-service --url)
curl -X POST $SERVICE_URL/predict \
  -H "Content-Type: application/json" \
  -d '{"age":63,"sex":1,"cp":3,"trestbps":145,"chol":233,"fbs":1,"restecg":0,"thalach":150,"exang":0,"oldpeak":2.3,"slope":0,"ca":0,"thal":1}'
# Expected: {"prediction":1,"probability":0.85,"risk_level":"high"}
```

### **3. Check Pods**
```bash
kubectl get pods
# Expected: 2 pods running
```

### **4. Check MLflow**
```bash
curl http://localhost:5001
# Expected: HTML response
```

---

## 🛠️ Troubleshooting

| Issue | Check | Fix |
|-------|-------|-----|
| Pods not starting | `kubectl describe pod <name>` | `minikube image load heart-disease-api:latest` |
| Service not accessible | `minikube service list` | `minikube service heart-disease-api-service --url` |
| MLflow not running | `ps aux \| grep mlflow` | `./scripts/start_mlflow_ui.sh --background` |
| Image not found | `minikube image ls` | Rebuild or reload image |

---

## 📸 Screenshots Checklist

- [ ] GitHub Actions - All jobs passing
- [ ] Docker artifact in GitHub Actions
- [ ] `kubectl get all` - All resources
- [ ] `kubectl get pods -o wide` - Pod details
- [ ] Health check response
- [ ] Prediction response
- [ ] MLflow UI - Experiments page
- [ ] MLflow UI - Metrics comparison

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| **README.md** | Main project documentation |
| **DEPLOYMENT_SOLUTION_SUMMARY.md** | Deployment overview |
| **GITHUB_TO_REMOTE_DEPLOYMENT.md** | GitHub artifact guide |
| **JENKINS_SETUP_GUIDE.md** | Jenkins CI/CD setup |
| **QUICK_REFERENCE.md** | This quick reference |

---

## ✅ Success Checklist

- [ ] Minikube running
- [ ] Code pulled from GitHub
- [ ] Docker image built/loaded
- [ ] Kubernetes deployment successful
- [ ] 2 pods running
- [ ] Service accessible
- [ ] Health check passing
- [ ] Predictions working
- [ ] MLflow UI accessible
- [ ] Screenshots captured

---

## 🎯 One-Liner Deployments

### **Method 1: Rebuild on Remote**
```bash
ssh user@remote "cd ~/Documents/mlops-assignment-1/heart-disease-mlops && git pull && ./scripts/remote_quick_deploy.sh"
```

### **Method 2: GitHub Artifact**
```bash
# Local: Download and transfer
gh run download --name docker-image --repo 2024aa05820/heart-disease-mlops && scp docker-image.tar.gz user@remote:~/

# Remote: Deploy
ssh user@remote "cd ~/Documents/mlops-assignment-1/heart-disease-mlops && ./scripts/deploy_github_artifact.sh ~/docker-image.tar.gz"
```

### **Method 3: Docker Registry**
```bash
ssh user@remote "docker pull username/heart-disease-api:latest && minikube image load username/heart-disease-api:latest && cd ~/Documents/mlops-assignment-1/heart-disease-mlops && kubectl apply -f deploy/k8s/"
```

### **Method 4: Jenkins (Automated)**
```bash
# One-time setup (see JENKINS_SETUP_GUIDE.md)
# 1. Install Jenkins
# 2. Configure GitHub webhook
# 3. Create pipeline job

# Then just push code:
git push origin main
# Jenkins automatically builds and deploys! 🚀
```

---

## 🎉 You're Ready!

**Everything you need is here. Choose your method and deploy!**

**Need help?** Check the detailed guides in the documentation section.

**Good luck with your assignment!** 🚀

