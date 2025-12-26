# 🚀 Complete Deployment Guide - Heart Disease MLOps

**Everything you need to deploy to your remote Linux machine with Minikube + MLflow**

---

## 📚 Table of Contents

1. [Quick Start (5 minutes)](#quick-start)
2. [Detailed Deployment](#detailed-deployment)
3. [Access from Local Machine](#access-from-local-machine)
4. [Testing & Verification](#testing--verification)
5. [Troubleshooting](#troubleshooting)
6. [Screenshots for Assignment](#screenshots-for-assignment)

---

## 🎯 Quick Start

### **On Remote Linux Machine:**

```bash
# 1. SSH to remote machine
ssh username@your-remote-server-ip

# 2. Navigate to project
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
git pull origin main

# 3. Run automated deployment
chmod +x scripts/remote_quick_deploy.sh
./scripts/remote_quick_deploy.sh
```

**Done!** ✅ Your application is now running on Kubernetes with MLflow UI.

---

## 📖 Detailed Deployment

### **Step 1: Prepare Remote Machine**

```bash
# SSH to remote machine
ssh username@your-remote-server-ip

# Verify Minikube is running
minikube status

# If not running, start it
minikube start --driver=docker --cpus=4 --memory=8192

# Verify kubectl
kubectl version --client
kubectl cluster-info
```

### **Step 2: Get Latest Code**

```bash
# Navigate to workspace
cd ~/Documents/mlops-assignment-1

# Clone repository (first time)
git clone https://github.com/2024aa05820/heart-disease-mlops.git
cd heart-disease-mlops

# OR pull latest changes (if already cloned)
cd heart-disease-mlops
git pull origin main
```

### **Step 3: Build & Deploy**

**Option A: Automated (Recommended)**

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run quick deploy
./scripts/remote_quick_deploy.sh
```

**Option B: Step-by-Step**

```bash
# Build and deploy to Kubernetes
./scripts/deploy_to_minikube.sh

# Start MLflow UI
./scripts/start_mlflow_ui.sh --background
```

**Option C: Manual**

```bash
# Build Docker image
docker build -t heart-disease-api:latest .

# Load into Minikube
minikube image load heart-disease-api:latest

# Deploy to Kubernetes
kubectl apply -f deploy/k8s/

# Wait for deployment
kubectl wait --for=condition=available --timeout=300s deployment/heart-disease-api

# Start MLflow UI
nohup mlflow ui --host 0.0.0.0 --port 5001 > mlflow.log 2>&1 &
```

### **Step 4: Verify Deployment**

```bash
# Check pods
kubectl get pods

# Expected output:
# NAME                                 READY   STATUS    RESTARTS   AGE
# heart-disease-api-xxxxxxxxxx-xxxxx   1/1     Running   0          1m
# heart-disease-api-xxxxxxxxxx-xxxxx   1/1     Running   0          1m

# Get service URL
minikube service heart-disease-api-service --url

# Test health endpoint
curl $(minikube service heart-disease-api-service --url)/health

# Expected output:
# {"status":"healthy","model_loaded":true}
```

---

## 🌐 Access from Local Machine

### **Method 1: SSH Tunnel (Recommended)**

**On your local machine:**

```bash
# Get remote server IP (run this on remote machine first)
hostname -I | awk '{print $1}'

# Get Minikube IP (run this on remote machine first)
minikube ip

# Create SSH tunnel from local machine
ssh -L 5001:localhost:5001 -L 8000:<minikube-ip>:30080 username@remote-server-ip

# Example:
ssh -L 5001:localhost:5001 -L 8000:192.168.49.2:30080 ubuntu@192.168.1.100
```

**Then access on your local machine:**
- **API**: http://localhost:8000/health
- **MLflow UI**: http://localhost:5001

### **Method 2: Direct Access (if firewall allows)**

**On remote machine, get IPs:**

```bash
# Get remote server IP
hostname -I | awk '{print $1}'

# Get NodePort
kubectl get service heart-disease-api-service -o jsonpath='{.spec.ports[0].nodePort}'
```

**Access from anywhere:**
- **API**: http://remote-server-ip:nodeport/health
- **MLflow UI**: http://remote-server-ip:5001

---

## 🧪 Testing & Verification

### **1. Health Check**

```bash
SERVICE_URL=$(minikube service heart-disease-api-service --url)
curl $SERVICE_URL/health
```

**Expected:**
```json
{"status":"healthy","model_loaded":true}
```

### **2. Make Prediction**

```bash
curl -X POST $SERVICE_URL/predict \
  -H "Content-Type: application/json" \
  -d '{
    "age": 63, "sex": 1, "cp": 3, "trestbps": 145,
    "chol": 233, "fbs": 1, "restecg": 0, "thalach": 150,
    "exang": 0, "oldpeak": 2.3, "slope": 0, "ca": 0, "thal": 1
  }'
```

**Expected:**
```json
{"prediction":1,"probability":0.85,"risk_level":"high"}
```

### **3. Check Kubernetes Resources**

```bash
# All resources
kubectl get all

# Pods
kubectl get pods -o wide

# Services
kubectl get services

# Deployments
kubectl get deployments

# Pod logs
kubectl logs -f <pod-name>
```

### **4. Check MLflow UI**

```bash
# Check if running
ps aux | grep mlflow

# View logs
tail -f mlflow.log

# Access UI
# Via SSH tunnel: http://localhost:5001
# Direct: http://remote-ip:5001
```

---

## 🛠️ Troubleshooting

### **Pods Not Starting**

```bash
# Check pod status
kubectl get pods

# Describe pod
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Common fix: Reload image
minikube image load heart-disease-api:latest
kubectl rollout restart deployment/heart-disease-api
```

### **Service Not Accessible**

```bash
# Get service URL
minikube service heart-disease-api-service --url

# Or use port-forward
kubectl port-forward service/heart-disease-api-service 8000:80

# Then access: http://localhost:8000
```

### **MLflow UI Not Accessible**

```bash
# Check if running
ps aux | grep mlflow

# Check logs
tail -f mlflow.log

# Restart
pkill -f mlflow
./scripts/start_mlflow_ui.sh --background

# Or manually
nohup mlflow ui --host 0.0.0.0 --port 5001 > mlflow.log 2>&1 &
```

### **Image Not Found in Minikube**

```bash
# Load image into Minikube
minikube image load heart-disease-api:latest

# Verify
minikube image ls | grep heart-disease-api

# Restart deployment
kubectl rollout restart deployment/heart-disease-api
```

---

## 📸 Screenshots for Assignment

### **1. Kubernetes Deployment Status**

```bash
kubectl get all
```

Screenshot showing:
- ✅ Deployment: 2/2 ready
- ✅ Pods: 2 running
- ✅ Services: LoadBalancer + ClusterIP
- ✅ HPA: Configured

### **2. Pod Details**

```bash
kubectl get pods -o wide
```

Screenshot showing:
- ✅ Pod names
- ✅ Status: Running
- ✅ Node assignment
- ✅ IP addresses

### **3. API Health Check**

```bash
curl $(minikube service heart-disease-api-service --url)/health | python3 -m json.tool
```

Screenshot showing:
- ✅ JSON response
- ✅ Status: healthy
- ✅ Model loaded: true

### **4. API Prediction**

```bash
curl -X POST $(minikube service heart-disease-api-service --url)/predict \
  -H "Content-Type: application/json" \
  -d '{"age":63,"sex":1,"cp":3,"trestbps":145,"chol":233,"fbs":1,"restecg":0,"thalach":150,"exang":0,"oldpeak":2.3,"slope":0,"ca":0,"thal":1}' \
  | python3 -m json.tool
```

Screenshot showing:
- ✅ Prediction result
- ✅ Probability
- ✅ Risk level

### **5. MLflow UI**

Access: http://localhost:5001 (via SSH tunnel)

Screenshot showing:
- ✅ Experiments list
- ✅ Multiple runs
- ✅ Metrics (accuracy, precision, recall, F1)
- ✅ Model artifacts

### **6. Pod Logs**

```bash
kubectl logs <pod-name> | tail -20
```

Screenshot showing:
- ✅ Application startup
- ✅ Model loading
- ✅ API server running

---

## 🧹 Cleanup

```bash
# Delete Kubernetes resources
kubectl delete -f deploy/k8s/

# Stop MLflow
./scripts/start_mlflow_ui.sh --stop

# (Optional) Stop Minikube
minikube stop
```

---

## 📋 Useful Commands Reference

```bash
# Deployment
./scripts/remote_quick_deploy.sh              # Full automated deployment
./scripts/deploy_to_minikube.sh               # Deploy to K8s only
./scripts/deploy_to_minikube.sh --clean       # Clean and redeploy
./scripts/start_mlflow_ui.sh --background     # Start MLflow UI
./scripts/start_mlflow_ui.sh --status         # Check MLflow status
./scripts/start_mlflow_ui.sh --stop           # Stop MLflow UI

# Kubernetes
kubectl get all                                # View all resources
kubectl get pods                               # View pods
kubectl get services                           # View services
kubectl logs -f <pod-name>                     # Follow pod logs
kubectl describe pod <pod-name>                # Pod details
kubectl rollout restart deployment/heart-disease-api  # Restart deployment
kubectl delete -f deploy/k8s/                  # Delete all resources

# Minikube
minikube status                                # Check status
minikube service heart-disease-api-service --url  # Get service URL
minikube ip                                    # Get Minikube IP
minikube image load heart-disease-api:latest  # Load image
minikube image ls                              # List images

# Testing
curl $(minikube service heart-disease-api-service --url)/health  # Health check
```

---

## ✅ Success Checklist

- [ ] ✅ Minikube running
- [ ] ✅ Docker image built
- [ ] ✅ Image loaded into Minikube
- [ ] ✅ Kubernetes deployment successful
- [ ] ✅ Pods running (2/2)
- [ ] ✅ Service accessible
- [ ] ✅ Health check passing
- [ ] ✅ Predictions working
- [ ] ✅ MLflow UI running
- [ ] ✅ MLflow UI accessible
- [ ] ✅ Screenshots taken

---

## 🎉 You're Done!

Your Heart Disease MLOps application is now:
- ✅ Running on Kubernetes (Minikube)
- ✅ Accessible via REST API
- ✅ Tracked with MLflow
- ✅ Production-ready
- ✅ Ready for assignment submission

**Need more help?** Check:
- `REMOTE_QUICK_START.md` - Quick 5-minute guide
- `REMOTE_DEPLOYMENT_GUIDE.md` - Detailed step-by-step guide

