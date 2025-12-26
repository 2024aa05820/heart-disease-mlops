# 🚀 Deployment Options Summary

**Quick reference for deploying your Heart Disease MLOps application to remote Minikube.**

---

## 📊 Three Deployment Methods

### **Method 1: Rebuild on Remote** ⭐ RECOMMENDED

**What it does:**
- Pulls latest code on remote machine
- Builds Docker image locally
- Deploys to Minikube

**Pros:**
- ✅ Simplest (one command)
- ✅ Fastest (5 minutes)
- ✅ Always uses latest code
- ✅ No artifact handling needed

**Cons:**
- ❌ Requires build on remote machine
- ❌ Uses remote machine resources

**When to use:**
- ✅ For assignments/demos
- ✅ Quick testing
- ✅ Development environments

**Command:**
```bash
ssh user@remote
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
git pull origin main
./scripts/remote_quick_deploy.sh
```

---

### **Method 2: GitHub Artifact Download**

**What it does:**
- Downloads Docker image from GitHub Actions
- Transfers to remote machine
- Loads and deploys to Minikube

**Pros:**
- ✅ Uses exact CI/CD built image
- ✅ No build on remote machine
- ✅ Demonstrates artifact workflow

**Cons:**
- ❌ More steps (6 total)
- ❌ Requires artifact download/transfer
- ❌ Artifacts expire after 7 days

**When to use:**
- ✅ To show CI/CD understanding
- ✅ When remote machine is low-powered
- ✅ For reproducible deployments

**Commands:**
```bash
# Local machine
gh run download --name docker-image --repo 2024aa05820/heart-disease-mlops
scp docker-image.tar.gz user@remote:~/

# Remote machine
ssh user@remote
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
./scripts/deploy_github_artifact.sh ~/docker-image.tar.gz
```

---

### **Method 3: Docker Registry (Docker Hub)**

**What it does:**
- Pushes image to Docker Hub from GitHub Actions
- Pulls image on remote machine
- Deploys to Minikube

**Pros:**
- ✅ Most professional/production-like
- ✅ Easy to deploy to multiple machines
- ✅ No artifact expiration
- ✅ Industry standard

**Cons:**
- ❌ Requires Docker Hub account
- ❌ Requires workflow modification
- ❌ Requires GitHub secrets setup
- ❌ Public images (unless paid account)

**When to use:**
- ✅ For production deployments
- ✅ Multiple deployment targets
- ✅ Bonus points in assignment
- ✅ Long-term projects

**Setup (one-time):**
1. Create Docker Hub account
2. Add GitHub secrets (DOCKER_USERNAME, DOCKER_PASSWORD)
3. Update workflow file
4. Push to trigger build

**Deploy:**
```bash
ssh user@remote
docker pull username/heart-disease-api:latest
minikube image load username/heart-disease-api:latest
kubectl apply -f deploy/k8s/
```

---

## 🎯 Quick Decision Guide

**Choose Method 1 if:**
- You want the simplest solution
- You're doing this for an assignment
- You have SSH access to remote machine
- Time is limited

**Choose Method 2 if:**
- You want to demonstrate CI/CD knowledge
- You want to use the exact GitHub-built image
- Your remote machine has limited resources
- You want to show artifact handling

**Choose Method 3 if:**
- You want a production-ready setup
- You're deploying to multiple machines
- You want bonus points for professionalism
- You have time for initial setup

---

## 📚 Documentation Guide

| Document | Purpose | When to Read |
|----------|---------|--------------|
| **STEP_BY_STEP_DEPLOYMENT.md** | Detailed steps for all 3 methods | Start here |
| **REMOTE_QUICK_START.md** | 5-minute quick start (Method 1) | For fastest deployment |
| **GITHUB_TO_REMOTE_DEPLOYMENT.md** | GitHub artifact deployment guide | For Method 2 |
| **DEPLOYMENT_COMPLETE_GUIDE.md** | Comprehensive reference | For troubleshooting |
| **REMOTE_DEPLOYMENT_GUIDE.md** | Detailed Kubernetes guide | For deep understanding |

---

## 🛠️ Available Scripts

| Script | Purpose | Method |
|--------|---------|--------|
| `remote_quick_deploy.sh` | Full automated deployment | Method 1 |
| `deploy_to_minikube.sh` | Deploy to Kubernetes only | Method 1 |
| `deploy_github_artifact.sh` | Deploy GitHub artifact | Method 2 |
| `start_mlflow_ui.sh` | Start/stop MLflow UI | All methods |

---

## ⚡ Quick Commands

### **Method 1: One-Liner**
```bash
ssh user@remote "cd ~/Documents/mlops-assignment-1/heart-disease-mlops && git pull && ./scripts/remote_quick_deploy.sh"
```

### **Method 2: Download & Deploy**
```bash
# Download
gh run download --name docker-image --repo 2024aa05820/heart-disease-mlops

# Transfer
scp docker-image.tar.gz user@remote:~/

# Deploy
ssh user@remote "cd ~/Documents/mlops-assignment-1/heart-disease-mlops && ./scripts/deploy_github_artifact.sh ~/docker-image.tar.gz"
```

### **Method 3: Registry Pull**
```bash
ssh user@remote "docker pull username/heart-disease-api:latest && minikube image load username/heart-disease-api:latest && cd ~/Documents/mlops-assignment-1/heart-disease-mlops && kubectl apply -f deploy/k8s/"
```

---

## 🎓 For Your Assignment

### **Recommended Approach:**

**Use Method 1** for actual deployment:
```bash
./scripts/remote_quick_deploy.sh
```

**But mention in your report:**
> "The project includes a complete CI/CD pipeline that builds Docker images in GitHub Actions. While the pipeline creates deployable artifacts, for this demonstration I used the rebuild method on the target machine for simplicity. The project also supports:
> - Artifact-based deployment from GitHub Actions
> - Container registry deployment (Docker Hub)
> - Production-ready Kubernetes manifests
> 
> In a production environment, we would use a container registry (Docker Hub/ECR/GCR) for image distribution."

### **Screenshots to Include:**

1. **GitHub Actions Pipeline** - All jobs passing
2. **Docker Image Artifact** - Show in GitHub Actions
3. **Deployment Process** - Terminal showing deployment
4. **Kubernetes Resources** - `kubectl get all`
5. **Running Pods** - `kubectl get pods -o wide`
6. **API Health Check** - `curl` response
7. **API Prediction** - Prediction response
8. **MLflow UI** - Experiments and metrics

---

## ✅ Success Checklist

- [ ] ✅ GitHub Actions pipeline passing
- [ ] ✅ Docker image artifact created
- [ ] ✅ Code deployed to remote machine
- [ ] ✅ Minikube running
- [ ] ✅ Kubernetes deployment successful
- [ ] ✅ Pods running (2/2)
- [ ] ✅ Service accessible
- [ ] ✅ Health check passing
- [ ] ✅ Predictions working
- [ ] ✅ MLflow UI accessible
- [ ] ✅ Screenshots captured
- [ ] ✅ Documentation reviewed

---

## 🆘 Troubleshooting

**Issue: GitHub Actions failing**
- Check: `.github/workflows/ci.yml`
- Solution: Review logs in GitHub Actions tab

**Issue: Can't download artifact**
- Check: Artifact exists and not expired (7 days)
- Solution: Trigger new workflow run

**Issue: Image not loading to Minikube**
- Check: `minikube status`
- Solution: `minikube image load heart-disease-api:latest`

**Issue: Pods not starting**
- Check: `kubectl describe pod <pod-name>`
- Solution: `kubectl rollout restart deployment/heart-disease-api`

**Issue: Service not accessible**
- Check: `minikube service heart-disease-api-service --url`
- Solution: Use port-forward or check NodePort

**For detailed troubleshooting:** See `DEPLOYMENT_COMPLETE_GUIDE.md`

---

## 🎉 Final Notes

**All three methods are valid and production-ready!**

- **Method 1** is perfect for learning and quick demos
- **Method 2** shows you understand CI/CD artifacts
- **Method 3** is what you'd use in real production

**Choose based on:**
- Your time constraints
- Assignment requirements
- What you want to demonstrate
- Your comfort level

**Remember:** The goal is to show you can:
- ✅ Build a complete MLOps pipeline
- ✅ Containerize applications
- ✅ Deploy to Kubernetes
- ✅ Track experiments with MLflow
- ✅ Automate with CI/CD

**You've got all the tools - now deploy and succeed!** 🚀

