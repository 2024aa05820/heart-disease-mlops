# 🚀 Remote Minikube Deployment - Quick Start

**5-Minute Deployment Guide** for deploying to your remote Linux machine with Minikube.

---

## 📋 Prerequisites

✅ Remote Linux machine with:
- Minikube installed and running
- kubectl installed
- Docker installed
- SSH access configured

---

## 🎯 Option 1: Automated Deployment (Recommended)

### **Step 1: SSH to Remote Machine**

```bash
# Replace with your details
ssh username@your-remote-server-ip

# Example:
ssh ubuntu@192.168.1.100
```

### **Step 2: Clone/Update Repository**

```bash
# Navigate to workspace
cd ~/Documents/mlops-assignment-1

# Clone (first time)
git clone https://github.com/2024aa05820/heart-disease-mlops.git
cd heart-disease-mlops

# OR pull latest changes (if already cloned)
cd heart-disease-mlops
git pull origin main
```

### **Step 3: Run Quick Deploy Script**

```bash
# Make script executable
chmod +x scripts/remote_quick_deploy.sh

# Run deployment
./scripts/remote_quick_deploy.sh
```

**That's it!** The script will:
- ✅ Build Docker image
- ✅ Deploy to Minikube
- ✅ Start MLflow UI
- ✅ Verify everything works

---

## 🎯 Option 2: Manual Step-by-Step

### **Step 1: SSH to Remote Machine**

```bash
ssh username@your-remote-server-ip
```

### **Step 2: Navigate to Project**

```bash
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
git pull origin main
```

### **Step 3: Build Docker Image**

```bash
# Build image
docker build -t heart-disease-api:latest .

# Load into Minikube
minikube image load heart-disease-api:latest
```

### **Step 4: Deploy to Kubernetes**

```bash
# Deploy all resources
kubectl apply -f deploy/k8s/

# Wait for deployment
kubectl wait --for=condition=available --timeout=300s deployment/heart-disease-api
```

### **Step 5: Start MLflow UI**

```bash
# Start in background
nohup mlflow ui --host 0.0.0.0 --port 5001 > mlflow.log 2>&1 &
```

### **Step 6: Verify Deployment**

```bash
# Get service URL
minikube service heart-disease-api-service --url

# Test health endpoint
curl $(minikube service heart-disease-api-service --url)/health
```

---

## 🌐 Access from Your Local Machine

### **Option A: SSH Tunnel (Recommended)**

**On your local machine**, run:

```bash
# Create SSH tunnel for both API and MLflow
ssh -L 5001:localhost:5001 -L 8000:$(minikube ip):30080 username@remote-server-ip

# Example:
ssh -L 5001:localhost:5001 -L 8000:192.168.49.2:30080 ubuntu@192.168.1.100
```

**Then access:**
- **API**: http://localhost:8000/health
- **MLflow UI**: http://localhost:5001

### **Option B: Direct Access (if firewall allows)**

**Get remote server IP:**
```bash
# On remote machine
hostname -I | awk '{print $1}'
```

**Access:**
- **API**: http://remote-ip:30080/health
- **MLflow UI**: http://remote-ip:5001

---

## 🧪 Test the Deployment

### **1. Health Check**

```bash
# Get service URL
SERVICE_URL=$(minikube service heart-disease-api-service --url)

# Test health
curl $SERVICE_URL/health
```

**Expected output:**
```json
{
  "status": "healthy",
  "model_loaded": true
}
```

### **2. Make a Prediction**

```bash
curl -X POST $SERVICE_URL/predict \
  -H "Content-Type: application/json" \
  -d '{
    "age": 63,
    "sex": 1,
    "cp": 3,
    "trestbps": 145,
    "chol": 233,
    "fbs": 1,
    "restecg": 0,
    "thalach": 150,
    "exang": 0,
    "oldpeak": 2.3,
    "slope": 0,
    "ca": 0,
    "thal": 1
  }'
```

**Expected output:**
```json
{
  "prediction": 1,
  "probability": 0.85,
  "risk_level": "high"
}
```

### **3. Check MLflow UI**

**Access:** http://localhost:5001 (via SSH tunnel)

You should see:
- ✅ Experiments listed
- ✅ Multiple runs
- ✅ Metrics (accuracy, precision, recall, F1)
- ✅ Registered models

---

## 📊 Monitoring Commands

### **Check Kubernetes Resources**

```bash
# View all resources
kubectl get all

# View pods
kubectl get pods

# View services
kubectl get services

# View pod logs
kubectl logs -f <pod-name>
```

### **Check MLflow Status**

```bash
# Check if MLflow is running
ps aux | grep mlflow

# View MLflow logs
tail -f mlflow.log

# Stop MLflow
pkill -f mlflow
```

---

## 🛠️ Troubleshooting

### **Issue: Pods not starting**

```bash
# Check pod status
kubectl get pods

# Describe pod
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Solution: Reload image
minikube image load heart-disease-api:latest
kubectl rollout restart deployment/heart-disease-api
```

### **Issue: Service not accessible**

```bash
# Get service URL
minikube service heart-disease-api-service --url

# Or use port-forward
kubectl port-forward service/heart-disease-api-service 8000:80
```

### **Issue: MLflow UI not accessible**

```bash
# Check if running
ps aux | grep mlflow

# Restart MLflow
pkill -f mlflow
nohup mlflow ui --host 0.0.0.0 --port 5001 > mlflow.log 2>&1 &

# Check logs
tail -f mlflow.log
```

---

## 🧹 Cleanup

### **Stop Everything**

```bash
# Delete Kubernetes resources
kubectl delete -f deploy/k8s/

# Stop MLflow
pkill -f mlflow

# (Optional) Stop Minikube
minikube stop
```

---

## 📸 Screenshots for Assignment

### **1. Kubernetes Deployment**
```bash
kubectl get all
```

### **2. Pod Status**
```bash
kubectl get pods -o wide
```

### **3. API Health Check**
```bash
curl $(minikube service heart-disease-api-service --url)/health
```

### **4. API Prediction**
```bash
curl -X POST $(minikube service heart-disease-api-service --url)/predict \
  -H "Content-Type: application/json" \
  -d '{"age":63,"sex":1,"cp":3,"trestbps":145,"chol":233,"fbs":1,"restecg":0,"thalach":150,"exang":0,"oldpeak":2.3,"slope":0,"ca":0,"thal":1}'
```

### **5. MLflow UI**
- Access: http://localhost:5001
- Screenshot experiments page

---

## ✅ Success Checklist

- [ ] ✅ Docker image built
- [ ] ✅ Image loaded into Minikube
- [ ] ✅ Kubernetes deployment successful
- [ ] ✅ Pods running (2/2)
- [ ] ✅ Service accessible
- [ ] ✅ Health check passing
- [ ] ✅ Predictions working
- [ ] ✅ MLflow UI accessible
- [ ] ✅ Screenshots taken

---

## 🎉 You're Done!

**Your MLOps application is now:**
- ✅ Running on Kubernetes (Minikube)
- ✅ Accessible via API
- ✅ Tracked with MLflow
- ✅ Production-ready

**Need help?** Check `REMOTE_DEPLOYMENT_GUIDE.md` for detailed instructions.

