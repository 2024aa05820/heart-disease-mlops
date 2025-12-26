# 📋 Step-by-Step Deployment Guide

**Choose your deployment method and follow the exact steps.**

---

## 🎯 Which Method Should You Use?

### **Method 1: Rebuild on Remote (RECOMMENDED)** ⭐

**Best for:**
- ✅ Quick deployment (5 minutes)
- ✅ Educational/assignment purposes
- ✅ You have access to remote machine
- ✅ You want simplicity

**Steps:** Only 3 commands!

### **Method 2: Download GitHub Artifact**

**Best for:**
- ✅ Using exact CI/CD built image
- ✅ Demonstrating artifact handling
- ✅ Learning production workflows

**Steps:** 6 steps total

### **Method 3: Docker Registry (Advanced)**

**Best for:**
- ✅ Production deployments
- ✅ Bonus points in assignment
- ✅ Multiple deployment targets

**Steps:** Setup required, then 4 steps

---

## ⭐ Method 1: Rebuild on Remote (RECOMMENDED)

### **Prerequisites:**
- Remote Linux machine with Minikube running
- SSH access to remote machine
- Git installed on remote machine

### **Step 1: SSH to Remote Machine**

```bash
ssh username@your-remote-server-ip
```

**Example:**
```bash
ssh ubuntu@192.168.1.100
```

### **Step 2: Navigate to Project Directory**

```bash
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
```

**If project doesn't exist, clone it:**
```bash
cd ~/Documents/mlops-assignment-1
git clone https://github.com/2024aa05820/heart-disease-mlops.git
cd heart-disease-mlops
```

### **Step 3: Pull Latest Code**

```bash
git pull origin main
```

### **Step 4: Run Deployment Script**

```bash
chmod +x scripts/remote_quick_deploy.sh
./scripts/remote_quick_deploy.sh
```

### **Step 5: Verify Deployment**

```bash
# Check pods
kubectl get pods

# Get service URL
minikube service heart-disease-api-service --url

# Test health
curl $(minikube service heart-disease-api-service --url)/health
```

### **Step 6: Access from Local Machine (Optional)**

**On your local machine:**

```bash
# Get Minikube IP from remote machine first
# On remote: minikube ip
# Example output: 192.168.49.2

# Create SSH tunnel
ssh -L 5001:localhost:5001 -L 8000:192.168.49.2:30080 username@remote-ip
```

**Then access:**
- API: http://localhost:8000/health
- MLflow: http://localhost:5001

### **✅ Done!**

---

## 📦 Method 2: Download GitHub Artifact

### **Prerequisites:**
- GitHub CLI installed (`gh`) OR manual download
- SSH access to remote machine
- Minikube running on remote machine

### **Step 1: Download Artifact (Local Machine)**

**Option A: Using GitHub CLI (Recommended)**

```bash
# Install GitHub CLI (if not installed)
# macOS: brew install gh
# Linux: sudo apt install gh

# Login to GitHub
gh auth login

# Download latest artifact
gh run download --name docker-image --repo 2024aa05820/heart-disease-mlops

# This creates: docker-image.tar.gz
```

**Option B: Manual Download**

1. Go to: https://github.com/2024aa05820/heart-disease-mlops/actions
2. Click on latest successful workflow run
3. Scroll down to "Artifacts"
4. Click "docker-image" to download
5. Extract the zip file to get `docker-image.tar.gz`

### **Step 2: Transfer to Remote Machine**

```bash
# Using scp
scp docker-image.tar.gz username@remote-server-ip:~/

# Example:
scp docker-image.tar.gz ubuntu@192.168.1.100:~/
```

### **Step 3: SSH to Remote Machine**

```bash
ssh username@remote-server-ip
```

### **Step 4: Navigate to Project**

```bash
cd ~/Documents/mlops-assignment-1/heart-disease-mlops

# Pull latest code (for K8s manifests)
git pull origin main
```

### **Step 5: Deploy Using Script**

```bash
# Make script executable
chmod +x scripts/deploy_github_artifact.sh

# Run deployment
./scripts/deploy_github_artifact.sh ~/docker-image.tar.gz
```

**The script will:**
- ✅ Load Docker image
- ✅ Tag as latest
- ✅ Load into Minikube
- ✅ Deploy to Kubernetes
- ✅ Verify deployment

### **Step 6: Start MLflow UI**

```bash
./scripts/start_mlflow_ui.sh --background
```

### **Step 7: Verify Everything**

```bash
# Check deployment
kubectl get all

# Test API
curl $(minikube service heart-disease-api-service --url)/health

# Check MLflow
curl http://localhost:5001
```

### **✅ Done!**

---

## 🐳 Method 3: Docker Registry (Advanced)

### **Prerequisites:**
- Docker Hub account
- GitHub repository access
- SSH access to remote machine

### **Part A: Setup (One-time)**

#### **Step 1: Create Docker Hub Account**

1. Go to: https://hub.docker.com/signup
2. Create account
3. Create access token:
   - Settings → Security → New Access Token
   - Name: "GitHub Actions"
   - Copy the token

#### **Step 2: Add GitHub Secrets**

1. Go to: https://github.com/2024aa05820/heart-disease-mlops/settings/secrets/actions
2. Click "New repository secret"
3. Add two secrets:
   - Name: `DOCKER_USERNAME`, Value: your Docker Hub username
   - Name: `DOCKER_PASSWORD`, Value: your Docker Hub token

#### **Step 3: Update Workflow**

```bash
# On your local machine
cd ~/Documents/mlops-assignment-1/heart-disease-mlops

# Backup current workflow
cp .github/workflows/ci.yml .github/workflows/ci.yml.backup

# Copy example workflow
cp .github/workflows/ci-with-registry.yml.example .github/workflows/ci.yml

# Edit the workflow
# Change line 16: DOCKER_REGISTRY: your-dockerhub-username
```

#### **Step 4: Commit and Push**

```bash
git add .github/workflows/ci.yml
git commit -m "Add Docker Hub push to CI/CD"
git push origin main
```

#### **Step 5: Wait for GitHub Actions**

- Go to: https://github.com/2024aa05820/heart-disease-mlops/actions
- Wait for workflow to complete
- Verify image pushed to Docker Hub

### **Part B: Deploy (Every time)**

#### **Step 1: SSH to Remote Machine**

```bash
ssh username@remote-server-ip
```

#### **Step 2: Pull Image from Docker Hub**

```bash
# Pull latest image
docker pull your-dockerhub-username/heart-disease-api:latest
```

#### **Step 3: Load into Minikube**

```bash
# Load image
minikube image load your-dockerhub-username/heart-disease-api:latest

# Verify
minikube image ls | grep heart-disease-api
```

#### **Step 4: Update Deployment Manifest**

```bash
cd ~/Documents/mlops-assignment-1/heart-disease-mlops

# Edit deployment.yaml
# Change image line to: your-dockerhub-username/heart-disease-api:latest
```

#### **Step 5: Deploy to Kubernetes**

```bash
kubectl apply -f deploy/k8s/

# Wait for deployment
kubectl wait --for=condition=available --timeout=300s deployment/heart-disease-api
```

#### **Step 6: Start MLflow UI**

```bash
./scripts/start_mlflow_ui.sh --background
```

#### **Step 7: Verify**

```bash
kubectl get all
curl $(minikube service heart-disease-api-service --url)/health
```

### **✅ Done!**

---

## 📊 Comparison Table

| Feature | Method 1 (Rebuild) | Method 2 (Artifact) | Method 3 (Registry) |
|---------|-------------------|---------------------|---------------------|
| **Setup Time** | 0 min | 0 min | 15 min (one-time) |
| **Deploy Time** | 5 min | 10 min | 5 min |
| **Complexity** | ⭐ Easy | ⭐⭐ Medium | ⭐⭐⭐ Advanced |
| **Commands** | 3 | 6 | 4 (after setup) |
| **Best For** | Quick testing | Learning CI/CD | Production |
| **Requires** | Git access | GitHub CLI | Docker Hub account |

---

## 🎓 My Recommendation for Assignment

**Use Method 1 (Rebuild on Remote)**

**Why?**
- ✅ Fastest (5 minutes)
- ✅ Simplest (3 commands)
- ✅ Always works
- ✅ Perfect for demonstration

**Your GitHub Actions still shows:**
- ✅ Complete CI/CD pipeline
- ✅ Docker image building
- ✅ Artifact creation
- ✅ Professional workflow

**You can mention in your report:**
> "While the CI/CD pipeline builds and saves Docker images as artifacts, for this demonstration I rebuilt the image on the target machine for simplicity. In a production environment, we would use a container registry (Docker Hub/ECR/GCR) to distribute images."

---

## ✅ Quick Reference

### **Method 1: One Command**
```bash
ssh user@remote && cd ~/Documents/mlops-assignment-1/heart-disease-mlops && git pull && ./scripts/remote_quick_deploy.sh
```

### **Method 2: Download & Deploy**
```bash
# Local
gh run download --name docker-image --repo 2024aa05820/heart-disease-mlops
scp docker-image.tar.gz user@remote:~/

# Remote
ssh user@remote
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
./scripts/deploy_github_artifact.sh ~/docker-image.tar.gz
```

### **Method 3: Registry Pull**
```bash
# Remote
ssh user@remote
docker pull username/heart-disease-api:latest
minikube image load username/heart-disease-api:latest
kubectl apply -f deploy/k8s/
```

---

## 🆘 Need Help?

Check these guides:
- **Quick Start**: `REMOTE_QUICK_START.md`
- **Complete Guide**: `DEPLOYMENT_COMPLETE_GUIDE.md`
- **GitHub Artifact**: `GITHUB_TO_REMOTE_DEPLOYMENT.md`
- **Troubleshooting**: `DEPLOYMENT_COMPLETE_GUIDE.md` (Troubleshooting section)

