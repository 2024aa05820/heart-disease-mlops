# 🔄 Hybrid Deployment: GitHub Actions + Jenkins

**Best of both worlds: GitHub Actions builds, Jenkins deploys!**

---

## 🎯 Overview

This hybrid approach combines:
- ✅ **GitHub Actions** - Builds Docker image in the cloud (free CI/CD minutes)
- ✅ **Jenkins** - Downloads artifact and deploys to your remote Minikube
- ✅ **Automated** - Webhook triggers Jenkins when GitHub Actions completes

### **Why This Approach?**

**Benefits:**
- 🚀 **Fast builds** - GitHub Actions has powerful cloud runners
- 💰 **Free** - Uses GitHub's free CI/CD minutes
- 🎯 **Controlled deployment** - Jenkins on your infrastructure
- 🔒 **Secure** - No need to expose Minikube to internet
- 📊 **Best practices** - Separation of build and deployment
- 🏢 **Production-like** - Common in enterprise environments

**Perfect for:**
- Remote Linux machines without powerful build resources
- Learning modern CI/CD patterns
- Assignments requiring both GitHub Actions and Jenkins
- Production-like deployment workflows

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        GitHub Actions (Cloud)                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │   Lint   │→ │   Test   │→ │  Train   │→ │  Docker  │        │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘        │
│                                                    ↓             │
│                                            ┌──────────────┐      │
│                                            │   Artifact   │      │
│                                            │ (Docker img) │      │
│                                            └──────────────┘      │
└─────────────────────────────────────────────────────────────────┘
                                                    ↓
                                            GitHub Webhook
                                                    ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Jenkins (Remote Linux)                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Download   │→ │  Load Image  │→ │    Deploy    │          │
│  │   Artifact   │  │  to Minikube │  │  to K8s      │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                                                    ↓
┌─────────────────────────────────────────────────────────────────┐
│                      Minikube Cluster                            │
│                   Heart Disease API Running                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📋 Prerequisites

**On Remote Linux Machine:**
- ✅ Jenkins installed and running
- ✅ Docker installed
- ✅ Minikube running
- ✅ kubectl configured
- ✅ jq installed (for JSON parsing)

**On GitHub:**
- ✅ GitHub Actions workflow enabled
- ✅ Repository with CI/CD pipeline

**Credentials:**
- ✅ GitHub Personal Access Token (with `repo` and `workflow` scopes)

---

## 🚀 Setup Instructions

### **Step 1: Install jq (JSON Parser)**

```bash
# Rocky Linux / RHEL / CentOS
sudo dnf install jq -y

# Ubuntu / Debian
sudo apt install jq -y

# Verify
jq --version
```

### **Step 2: Create GitHub Personal Access Token**

1. Go to: https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Select scopes:
   - ✅ `repo` (all)
   - ✅ `workflow`
4. Generate and copy the token
5. **Save it securely!**

### **Step 3: Add GitHub Token to Jenkins**

1. Go to: Jenkins → Manage Jenkins → Credentials → System → Global credentials
2. Click "Add Credentials"
3. Select "Secret text"
4. Enter:
   - **Secret:** Your GitHub Personal Access Token
   - **ID:** `github-token`
   - **Description:** GitHub API Token
5. Click "Create"

### **Step 4: Create Hybrid Jenkins Pipeline**

1. **Go to Jenkins Dashboard**
2. **Click "New Item"**
3. **Enter name:** `heart-disease-hybrid-pipeline`
4. **Select:** "Pipeline"
5. **Click OK**

**Configure:**

**General:**
- ✅ GitHub project: `https://github.com/2024aa05820/heart-disease-mlops/`

**Build Triggers:**
- ✅ GitHub hook trigger for GITScm polling
- ✅ Build after other projects are built (optional)

**Pipeline:**
- Definition: "Pipeline script from SCM"
- SCM: Git
- Repository URL: `https://github.com/2024aa05820/heart-disease-mlops.git`
- Credentials: Select your GitHub credentials
- Branch: `*/main`
- **Script Path:** `Jenkinsfile.hybrid` ⭐ (Important!)

**Click "Save"**

### **Step 5: Configure GitHub Webhook (Optional)**

If you want Jenkins to auto-trigger when GitHub Actions completes:

1. Go to: https://github.com/2024aa05820/heart-disease-mlops/settings/hooks
2. Click "Add webhook"
3. Configure:
   - Payload URL: `http://your-remote-ip:8080/github-webhook/`
   - Content type: `application/json`
   - Events: Select "Workflow runs" (in addition to "Push")
4. Click "Add webhook"

---

## 🎮 Usage

### **Automatic Workflow:**

```bash
# 1. Make changes and push to GitHub
git add .
git commit -m "Update: My changes"
git push origin main

# 2. GitHub Actions automatically:
#    - Runs tests
#    - Trains models
#    - Builds Docker image
#    - Uploads artifact

# 3. Jenkins automatically (via webhook):
#    - Downloads artifact from GitHub
#    - Loads image to Minikube
#    - Deploys to Kubernetes
#    - Verifies deployment

# ✅ Done! Your app is deployed!
```

### **Manual Trigger:**

```bash
# Trigger Jenkins manually
# Go to: http://remote-ip:8080/job/heart-disease-hybrid-pipeline/
# Click "Build Now"
```

### **Manual Download (for testing):**

```bash
# Set GitHub token
export GITHUB_TOKEN='your-token-here'

# Download latest artifact
./scripts/download_github_artifact.sh

# Deploy manually
./scripts/deploy_github_artifact.sh docker-image.tar.gz
```

---

## 📊 Pipeline Stages

The hybrid pipeline (`Jenkinsfile.hybrid`) includes:

1. **Checkout** - Pull code from GitHub
2. **Get Latest Run** - Find latest successful GitHub Actions run
3. **Download Artifact** - Download Docker image from GitHub
4. **Load Docker Image** - Load image into local Docker
5. **Load to Minikube** - Import image to Kubernetes
6. **Deploy** - Apply Kubernetes manifests
7. **Verify** - Check deployment health
8. **Start MLflow** - Launch experiment tracking UI

---

## 🔍 Monitoring

### **GitHub Actions:**
- URL: https://github.com/2024aa05820/heart-disease-mlops/actions
- Check build status
- View workflow logs
- Download artifacts manually

### **Jenkins:**
- URL: `http://remote-ip:8080`
- View deployment status
- Check console output
- Monitor build history

### **Kubernetes:**
```bash
# Check pods
kubectl get pods

# Get service URL
minikube service heart-disease-api-service --url

# Test API
curl $(minikube service heart-disease-api-service --url)/health
```

---

## 🛠️ Troubleshooting

### **Issue: Jenkins can't download artifact**

**Check:**
```bash
# Verify GitHub token
echo $GITHUB_TOKEN

# Test API access
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/2024aa05820/heart-disease-mlops/actions/runs
```

**Fix:**
- Verify token has correct scopes (`repo`, `workflow`)
- Check token is added to Jenkins credentials
- Ensure token hasn't expired

### **Issue: jq command not found**

```bash
# Install jq
sudo dnf install jq -y  # Rocky Linux
sudo apt install jq -y  # Ubuntu
```

### **Issue: No artifacts found**

**Check:**
- GitHub Actions workflow completed successfully
- Artifact was uploaded (check GitHub Actions logs)
- Artifact name matches (`docker-image`)

### **Issue: Download fails with 404**

**Possible causes:**
- Artifact expired (GitHub keeps artifacts for 90 days)
- Wrong repository name
- Token doesn't have access to repository

---

## ✅ Advantages of Hybrid Approach

| Aspect | Hybrid | Full Jenkins | Full GitHub Actions |
|--------|--------|--------------|---------------------|
| **Build Speed** | ✅ Fast (cloud) | ❌ Slow (local) | ✅ Fast (cloud) |
| **Deployment Control** | ✅ Full | ✅ Full | ❌ Limited |
| **Cost** | ✅ Free | ✅ Free | ⚠️ Minutes limit |
| **Security** | ✅ High | ✅ High | ⚠️ Needs secrets |
| **Learning Value** | ✅✅ Best | ✅ Good | ✅ Good |
| **Production-like** | ✅✅ Yes | ✅ Yes | ❌ No |

---

## 📚 Related Documentation

- **[JENKINS_SETUP_GUIDE.md](JENKINS_SETUP_GUIDE.md)** - Jenkins installation
- **[GITHUB_TO_REMOTE_DEPLOYMENT.md](GITHUB_TO_REMOTE_DEPLOYMENT.md)** - GitHub artifact deployment
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Quick commands

---

## 🎉 Success!

**You now have a production-like CI/CD pipeline:**
- ✅ GitHub Actions builds in the cloud
- ✅ Jenkins deploys to your infrastructure
- ✅ Fully automated with webhooks
- ✅ Best practices for enterprise environments

**This is exactly how many companies do CI/CD!** 🚀

