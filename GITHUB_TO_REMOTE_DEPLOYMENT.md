# 🚀 Deploy GitHub-Built Image to Remote Minikube

**Complete guide to deploy the Docker image built in GitHub Actions to your remote Linux machine.**

---

## 🎯 Deployment Options

You have **3 options** to deploy the GitHub-built image to your remote machine:

### **Option 1: Download Artifact & Deploy (Recommended for Assignment)** ⭐
- Download Docker image artifact from GitHub Actions
- Transfer to remote machine
- Load into Minikube and deploy

### **Option 2: Rebuild on Remote Machine (Simplest)**
- Pull latest code on remote machine
- Build Docker image locally
- Deploy to Minikube

### **Option 3: Use Container Registry (Production-Ready)**
- Push image to Docker Hub/GitHub Container Registry
- Pull on remote machine
- Deploy to Minikube

---

## ✅ Option 1: Download Artifact & Deploy (Recommended)

### **Step 1: Download Docker Image from GitHub Actions**

**On your local machine:**

```bash
# Go to GitHub Actions page
open https://github.com/2024aa05820/heart-disease-mlops/actions

# Click on the latest successful workflow run
# Click on "docker-image" artifact to download
# This downloads: docker-image.zip
```

**Or use GitHub CLI:**

```bash
# Install GitHub CLI (if not installed)
brew install gh  # macOS
# or: sudo apt install gh  # Linux

# Login
gh auth login

# Download latest artifact
gh run download --name docker-image --repo 2024aa05820/heart-disease-mlops

# This downloads: docker-image.tar.gz
```

### **Step 2: Transfer to Remote Machine**

```bash
# Using scp
scp docker-image.tar.gz username@remote-server-ip:~/

# Example:
scp docker-image.tar.gz ubuntu@192.168.1.100:~/
```

### **Step 3: Load Image on Remote Machine**

**SSH to remote machine:**

```bash
ssh username@remote-server-ip
```

**Load the Docker image:**

```bash
# Extract and load image
gunzip -c docker-image.tar.gz | docker load

# Verify image loaded
docker images | grep heart-disease-api

# Expected output:
# heart-disease-api   <commit-sha>   <image-id>   <time>   <size>

# Tag as latest
docker tag heart-disease-api:<commit-sha> heart-disease-api:latest

# Load into Minikube
minikube image load heart-disease-api:latest
```

### **Step 4: Deploy to Kubernetes**

```bash
# Navigate to project
cd ~/Documents/mlops-assignment-1/heart-disease-mlops

# Pull latest code (to get K8s manifests)
git pull origin main

# Deploy
kubectl apply -f deploy/k8s/

# Wait for deployment
kubectl wait --for=condition=available --timeout=300s deployment/heart-disease-api

# Verify
kubectl get pods
```

### **Step 5: Start MLflow UI**

```bash
# Start MLflow UI
./scripts/start_mlflow_ui.sh --background
```

### **Step 6: Verify Everything**

```bash
# Get service URL
minikube service heart-disease-api-service --url

# Test health
curl $(minikube service heart-disease-api-service --url)/health

# Check MLflow
curl http://localhost:5001
```

---

## ✅ Option 2: Rebuild on Remote Machine (Simplest)

This is the **easiest** option - just rebuild the image on your remote machine.

### **Complete Steps:**

```bash
# 1. SSH to remote machine
ssh username@remote-server-ip

# 2. Navigate to project
cd ~/Documents/mlops-assignment-1/heart-disease-mlops

# 3. Pull latest code
git pull origin main

# 4. Run quick deploy script
./scripts/remote_quick_deploy.sh
```

**That's it!** ✅ The script will:
- Build Docker image locally
- Load into Minikube
- Deploy to Kubernetes
- Start MLflow UI
- Verify everything

---

## ✅ Option 3: Use Container Registry (Production)

This is the **most professional** approach for production deployments.

### **Step 1: Push to Docker Hub from GitHub Actions**

**Update `.github/workflows/ci.yml`:**

Add Docker Hub credentials to GitHub Secrets:
1. Go to: https://github.com/2024aa05820/heart-disease-mlops/settings/secrets/actions
2. Add secrets:
   - `DOCKER_USERNAME`: Your Docker Hub username
   - `DOCKER_PASSWORD`: Your Docker Hub password/token

**Then update the workflow** (see next section for code).

### **Step 2: Pull on Remote Machine**

```bash
# SSH to remote machine
ssh username@remote-server-ip

# Pull image from Docker Hub
docker pull your-dockerhub-username/heart-disease-api:latest

# Load into Minikube
minikube image load your-dockerhub-username/heart-disease-api:latest

# Update deployment.yaml to use the registry image
# Then deploy
kubectl apply -f deploy/k8s/
```

---

## 🎓 Recommended Approach for Assignment

**Use Option 2 (Rebuild on Remote)** because:
- ✅ Simplest and fastest
- ✅ No need to download/transfer artifacts
- ✅ Always uses latest code
- ✅ One command deployment
- ✅ Perfect for educational purposes

**Use Option 1 (Download Artifact)** if:
- ✅ You want to show you understand CI/CD artifacts
- ✅ You want to use the exact image from GitHub Actions
- ✅ You want to demonstrate production-like workflow

**Use Option 3 (Container Registry)** if:
- ✅ You want bonus points for production-ready setup
- ✅ Your assignment requires container registry
- ✅ You want to show advanced DevOps skills

---

## 📋 Complete Workflow Comparison

| Step | Option 1 (Artifact) | Option 2 (Rebuild) | Option 3 (Registry) |
|------|--------------------|--------------------|---------------------|
| **Download artifact** | ✅ Required | ❌ Not needed | ❌ Not needed |
| **Transfer to remote** | ✅ Required | ❌ Not needed | ❌ Not needed |
| **Build on remote** | ❌ Not needed | ✅ Required | ❌ Not needed |
| **Pull from registry** | ❌ Not needed | ❌ Not needed | ✅ Required |
| **Load to Minikube** | ✅ Required | ✅ Required | ✅ Required |
| **Deploy to K8s** | ✅ Required | ✅ Required | ✅ Required |
| **Complexity** | Medium | Low | High |
| **Time** | ~10 min | ~5 min | ~15 min |
| **Best for** | Learning CI/CD | Quick testing | Production |

---

## 🚀 Quick Commands Reference

### **Option 1: Artifact Download & Deploy**

```bash
# Local machine
gh run download --name docker-image --repo 2024aa05820/heart-disease-mlops
scp docker-image.tar.gz username@remote-ip:~/

# Remote machine
ssh username@remote-ip
gunzip -c docker-image.tar.gz | docker load
docker tag heart-disease-api:<sha> heart-disease-api:latest
minikube image load heart-disease-api:latest
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
git pull origin main
kubectl apply -f deploy/k8s/
./scripts/start_mlflow_ui.sh --background
```

### **Option 2: Rebuild on Remote**

```bash
# Remote machine
ssh username@remote-ip
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
git pull origin main
./scripts/remote_quick_deploy.sh
```

### **Option 3: Container Registry**

```bash
# Remote machine (after setting up registry push in GitHub Actions)
ssh username@remote-ip
docker pull your-username/heart-disease-api:latest
minikube image load your-username/heart-disease-api:latest
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
git pull origin main
kubectl apply -f deploy/k8s/
./scripts/start_mlflow_ui.sh --background
```

---

## 🎯 My Recommendation

**For your assignment, use Option 2 (Rebuild on Remote):**

```bash
# Just run this on your remote machine:
ssh username@remote-ip
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
git pull origin main
./scripts/remote_quick_deploy.sh
```

**Why?**
- ✅ Takes only 5 minutes
- ✅ One command does everything
- ✅ Always uses latest code
- ✅ No manual artifact handling
- ✅ Perfect for demonstration

**The GitHub Actions pipeline still shows:**
- ✅ You can build Docker images in CI/CD
- ✅ You understand the deployment process
- ✅ You have production-ready code

---

## 📸 Screenshots to Take

Regardless of which option you choose, take these screenshots:

1. **GitHub Actions Success** - All jobs passing
2. **Docker Image Artifact** - Show artifact in GitHub Actions
3. **Remote Deployment** - `kubectl get all`
4. **Pods Running** - `kubectl get pods -o wide`
5. **API Health Check** - `curl` response
6. **MLflow UI** - Browser screenshot

---

## ✅ Next Steps

Choose your option and follow the guide:
- **Quick & Easy**: Use Option 2 → See `REMOTE_QUICK_START.md`
- **Learn CI/CD**: Use Option 1 → Follow steps above
- **Production**: Use Option 3 → See next section for registry setup

**Need help?** Check:
- `REMOTE_QUICK_START.md` - 5-minute deployment
- `DEPLOYMENT_COMPLETE_GUIDE.md` - Comprehensive guide
- `REMOTE_DEPLOYMENT_GUIDE.md` - Detailed instructions

