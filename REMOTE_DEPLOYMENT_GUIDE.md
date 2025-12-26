# 🚀 Remote Minikube Deployment Guide

Complete guide to deploy Heart Disease MLOps application to your remote Linux machine with Minikube and MLflow UI.

---

## 📋 Prerequisites

### **On Remote Linux Machine:**
- ✅ Minikube installed and running
- ✅ kubectl installed
- ✅ Docker installed
- ✅ Git installed
- ✅ Python 3.11+ installed
- ✅ SSH access configured

---

## 🎯 Deployment Overview

```
Local Machine → Push to GitHub → Remote Machine → Minikube Cluster
                                      ↓
                                  MLflow UI (Port 5001)
                                  API Service (Port 30080)
```

---

## 📦 Step 1: Prepare Remote Machine

### **SSH to Remote Machine:**

```bash
# Replace with your remote machine details
ssh username@your-remote-server-ip

# Example:
# ssh ubuntu@192.168.1.100
```

### **Verify Minikube is Running:**

```bash
# Check Minikube status
minikube status

# Expected output:
# minikube
# type: Control Plane
# host: Running
# kubelet: Running
# apiserver: Running
# kubeconfig: Configured

# If not running, start it:
minikube start --driver=docker --cpus=4 --memory=8192
```

### **Verify kubectl:**

```bash
# Check kubectl
kubectl version --client

# Check cluster info
kubectl cluster-info

# Expected output:
# Kubernetes control plane is running at https://...
```

---

## 📥 Step 2: Clone Repository on Remote Machine

```bash
# Navigate to your workspace
cd ~/Documents/mlops-assignment-1

# Clone the repository (if not already cloned)
git clone https://github.com/2024aa05820/heart-disease-mlops.git

# Or pull latest changes if already cloned
cd heart-disease-mlops
git pull origin main
```

---

## 🐳 Step 3: Build Docker Image

```bash
# Navigate to project directory
cd ~/Documents/mlops-assignment-1/heart-disease-mlops

# Build Docker image
docker build -t heart-disease-api:latest .

# Verify image was built
docker images | grep heart-disease-api

# Expected output:
# heart-disease-api   latest   <image-id>   <time>   <size>
```

### **Load Image into Minikube:**

```bash
# Load the Docker image into Minikube
minikube image load heart-disease-api:latest

# Verify image is in Minikube
minikube image ls | grep heart-disease-api

# Expected output:
# docker.io/library/heart-disease-api:latest
```

---

## ☸️ Step 4: Deploy to Kubernetes

### **Deploy Application:**

```bash
# Apply all Kubernetes manifests
kubectl apply -f deploy/k8s/

# Expected output:
# deployment.apps/heart-disease-api created
# horizontalpodautoscaler.autoscaling/heart-disease-api-hpa created
# service/heart-disease-api-service created
# service/heart-disease-api-internal created
# ingress.networking.k8s.io/heart-disease-api-ingress created
# configmap/heart-disease-api-config created
```

### **Verify Deployment:**

```bash
# Check deployments
kubectl get deployments

# Expected output:
# NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
# heart-disease-api    2/2     2            2           30s

# Check pods
kubectl get pods

# Expected output:
# NAME                                 READY   STATUS    RESTARTS   AGE
# heart-disease-api-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
# heart-disease-api-xxxxxxxxxx-xxxxx   1/1     Running   0          30s

# Check services
kubectl get services

# Expected output:
# NAME                          TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
# heart-disease-api-service     LoadBalancer   10.96.xxx.xxx   <pending>     80:30080/TCP   30s
# heart-disease-api-internal    ClusterIP      10.96.xxx.xxx   <none>        8000/TCP       30s
```

---

## 🌐 Step 5: Access the API

### **Option A: Using Minikube Service (Recommended for Minikube):**

```bash
# Get the service URL
minikube service heart-disease-api-service --url

# Expected output:
# http://192.168.49.2:30080

# Test the API
curl $(minikube service heart-disease-api-service --url)/health

# Expected output:
# {"status":"healthy","model_loaded":true}
```

### **Option B: Using Port Forwarding:**

```bash
# Forward port 8000 to local machine
kubectl port-forward service/heart-disease-api-service 8000:80

# In another terminal, test:
curl http://localhost:8000/health
```

### **Option C: Using NodePort (Access from Outside):**

```bash
# Get Minikube IP
minikube ip

# Get NodePort
kubectl get service heart-disease-api-service -o jsonpath='{.spec.ports[0].nodePort}'

# Access from your local machine:
# http://<minikube-ip>:<nodeport>
# Example: http://192.168.49.2:30080
```

---

## 🧪 Step 6: Test the Deployment

### **Test Health Endpoint:**

```bash
# Get service URL
SERVICE_URL=$(minikube service heart-disease-api-service --url)

# Test health
curl $SERVICE_URL/health

# Expected output:
# {"status":"healthy","model_loaded":true}
```

### **Test Prediction Endpoint:**

```bash
# Make a prediction
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

# Expected output:
# {"prediction":1,"probability":0.85,"risk_level":"high"}
```

---

## 📊 Step 7: Set Up MLflow UI

### **Install MLflow (if not already installed):**

```bash
# Install MLflow
pip install mlflow

# Or use the project's requirements
pip install -r requirements.txt
```

### **Start MLflow UI:**

```bash
# Navigate to project directory
cd ~/Documents/mlops-assignment-1/heart-disease-mlops

# Start MLflow UI (runs in background)
nohup mlflow ui --host 0.0.0.0 --port 5001 > mlflow.log 2>&1 &

# Check if it's running
ps aux | grep mlflow

# Check logs
tail -f mlflow.log
```

### **Access MLflow UI:**

**From Remote Machine:**
```bash
# Open browser on remote machine
firefox http://localhost:5001
# or
google-chrome http://localhost:5001
```

**From Your Local Machine (SSH Tunnel):**
```bash
# On your local machine, create SSH tunnel
ssh -L 5001:localhost:5001 username@your-remote-server-ip

# Then open browser on local machine:
# http://localhost:5001
```

---

## 🔍 Step 8: Monitor and Verify

### **Check Pod Logs:**

```bash
# Get pod name
POD_NAME=$(kubectl get pods -l app=heart-disease-api -o jsonpath='{.items[0].metadata.name}')

# View logs
kubectl logs $POD_NAME

# Follow logs
kubectl logs -f $POD_NAME
```

### **Check Pod Status:**

```bash
# Describe pod
kubectl describe pod $POD_NAME

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

### **Check Resource Usage:**

```bash
# Check pod resource usage
kubectl top pods

# Check node resource usage
kubectl top nodes
```

---

## 📸 Step 9: Take Screenshots for Assignment

### **1. Kubernetes Deployment:**
```bash
kubectl get all
```

### **2. Pod Status:**
```bash
kubectl get pods -o wide
```

### **3. Service Status:**
```bash
kubectl get services
minikube service heart-disease-api-service --url
```

### **4. API Response:**
```bash
curl $(minikube service heart-disease-api-service --url)/health
```

### **5. MLflow UI:**
- Open browser: `http://localhost:5001`
- Screenshot the experiments page

---

## 🛠️ Troubleshooting

### **Pods Not Starting:**

```bash
# Check pod status
kubectl get pods

# Describe pod to see errors
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Common issues:
# 1. Image not found → Run: minikube image load heart-disease-api:latest
# 2. Resource limits → Reduce replicas or increase Minikube resources
```

### **Service Not Accessible:**

```bash
# Check service
kubectl get service heart-disease-api-service

# For Minikube, use:
minikube service heart-disease-api-service --url

# Or use port-forward:
kubectl port-forward service/heart-disease-api-service 8000:80
```

### **MLflow UI Not Accessible:**

```bash
# Check if MLflow is running
ps aux | grep mlflow

# Check logs
tail -f mlflow.log

# Restart MLflow
pkill -f mlflow
nohup mlflow ui --host 0.0.0.0 --port 5001 > mlflow.log 2>&1 &
```

---

**Continue to REMOTE_DEPLOYMENT_GUIDE_PART2.md for automation scripts...**

