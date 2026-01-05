# Rocky Linux Deployment Checklist

Use this checklist to ensure a successful deployment of the Heart Disease MLOps project on Rocky Linux.

---

## 📋 Pre-Installation Checklist

- [ ] Rocky Linux 8.x or 9.x installed
- [ ] Root/sudo access available
- [ ] Internet connection active
- [ ] At least 4GB RAM available
- [ ] At least 20GB disk space available
- [ ] Ports 8080, 5001, 30080 available

---

## 🚀 Installation Checklist

### Step 1: Clone Repository
- [ ] Repository cloned: `git clone https://github.com/2024aa05820/heart-disease-mlops.git`
- [ ] Changed to project directory: `cd heart-disease-mlops`

### Step 2: Run Automated Setup
- [ ] Executed: `sudo ./scripts/rocky-setup.sh`
- [ ] Installation completed without errors
- [ ] All components installed successfully

### Step 3: Post-Installation
- [ ] Logged out and back in (for docker group)
- [ ] Verified docker access: `docker ps` (no permission error)
- [ ] Verified Java: `java -version` (shows 17.x.x)
- [ ] Verified kubectl: `kubectl version --client`
- [ ] Verified Minikube: `minikube version`

---

## ☸️ Minikube Setup Checklist

- [ ] Started Minikube: `minikube start --driver=docker --cpus=2 --memory=4096`
- [ ] Minikube running: `minikube status` (shows "Running")
- [ ] kubectl connected: `kubectl get nodes` (shows 1 node Ready)
- [ ] Minikube IP obtained: `minikube ip`

---

## 🔧 Jenkins Configuration Checklist

### Initial Setup
- [ ] Jenkins accessible at: `http://<SERVER_IP>:8080`
- [ ] Initial admin password retrieved: `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
- [ ] Unlocked Jenkins with password
- [ ] Installed suggested plugins
- [ ] Created admin user account
- [ ] Saved Jenkins URL

### GitHub Integration
- [ ] Generated GitHub personal access token
  - [ ] Scopes: `repo`, `workflow`
- [ ] Added token to Jenkins credentials
  - [ ] ID: `github-token`
  - [ ] Type: Secret text

### Pipeline Job
- [ ] Created new Pipeline job: `heart-disease-mlops`
- [ ] Configured SCM:
  - [ ] Type: Git
  - [ ] URL: `https://github.com/2024aa05820/heart-disease-mlops.git`
  - [ ] Branch: `*/main`
  - [ ] Script Path: `Jenkinsfile`
- [ ] Enabled Poll SCM: `H/2 * * * *`
- [ ] Saved job configuration

---

## 🐳 Docker Verification Checklist

- [ ] Docker service running: `sudo systemctl status docker`
- [ ] Docker version: `docker --version`
- [ ] User in docker group: `groups | grep docker`
- [ ] Can run docker without sudo: `docker ps`
- [ ] Jenkins in docker group: `sudo groups jenkins | grep docker`

---

## 🔥 Firewall Configuration Checklist

- [ ] Firewall running: `sudo firewall-cmd --state`
- [ ] Port 8080 open: `sudo firewall-cmd --list-ports | grep 8080`
- [ ] Port 5001 open: `sudo firewall-cmd --list-ports | grep 5001`
- [ ] Firewall reloaded: `sudo firewall-cmd --reload`

---

## 📦 Application Deployment Checklist

### Build & Deploy
- [ ] Triggered Jenkins build (push to GitHub or manual)
- [ ] Build completed successfully
- [ ] Docker image built
- [ ] Image loaded to Minikube
- [ ] Kubernetes manifests applied
- [ ] Deployment created

### Verification
- [ ] Pods running: `kubectl get pods` (shows Running status)
- [ ] Service created: `kubectl get services`
- [ ] Service URL obtained: `minikube service heart-disease-api-service --url`
- [ ] Health check passed: `curl <SERVICE_URL>/health`

---

## 🧪 Testing Checklist

### API Testing
- [ ] Health endpoint: `curl <API_URL>/health`
  - [ ] Returns: `{"status": "healthy"}`
- [ ] Docs endpoint: `curl <API_URL>/docs`
  - [ ] Returns Swagger UI
- [ ] Predict endpoint: `curl -X POST <API_URL>/predict -H "Content-Type: application/json" -d '{...}'`
  - [ ] Returns prediction

### MLflow Testing
- [ ] MLflow UI accessible: `http://<SERVER_IP>:5001`
- [ ] Experiments visible
- [ ] Models logged
- [ ] Metrics displayed

### Jenkins Testing
- [ ] Jenkins UI accessible: `http://<SERVER_IP>:8080`
- [ ] Pipeline job visible
- [ ] Build history shows successful builds
- [ ] Console output shows no errors

---

## 📊 Monitoring Checklist

- [ ] Can view pod logs: `kubectl logs -f <pod-name>`
- [ ] Can view Jenkins logs: `sudo journalctl -u jenkins -f`
- [ ] Can view Docker logs: `docker logs <container-id>`
- [ ] MLflow tracking experiments
- [ ] Prometheus metrics available (if configured)

---

## 🔄 CI/CD Pipeline Checklist

- [ ] Code pushed to GitHub
- [ ] Jenkins detected change (within 2 minutes)
- [ ] Pipeline started automatically
- [ ] All stages passed:
  - [ ] Checkout
  - [ ] Setup Python
  - [ ] Lint
  - [ ] Test
  - [ ] Download Dataset
  - [ ] Train Models
  - [ ] Build Docker
  - [ ] Test Docker
  - [ ] Load to Minikube
  - [ ] Deploy to K8s
  - [ ] Start MLflow
- [ ] Deployment successful
- [ ] API accessible

---

## 🎯 Final Verification Checklist

### All Services Running
- [ ] Docker: `sudo systemctl status docker`
- [ ] Jenkins: `sudo systemctl status jenkins`
- [ ] Minikube: `minikube status`
- [ ] Kubernetes pods: `kubectl get pods`

### All URLs Accessible
- [ ] API: `http://<MINIKUBE_IP>:30080`
- [ ] Swagger: `http://<MINIKUBE_IP>:30080/docs`
- [ ] MLflow: `http://<SERVER_IP>:5001`
- [ ] Jenkins: `http://<SERVER_IP>:8080`

### Functionality Working
- [ ] Can make predictions via API
- [ ] Can view experiments in MLflow
- [ ] Can trigger builds in Jenkins
- [ ] Can view pod logs
- [ ] Can restart deployment

---

## 📚 Documentation Review Checklist

- [ ] Read: [ROCKY_LINUX_QUICKSTART.md](ROCKY_LINUX_QUICKSTART.md)
- [ ] Read: [ROCKY_LINUX_SETUP.md](ROCKY_LINUX_SETUP.md)
- [ ] Read: [ROCKY_LINUX_SUMMARY.md](ROCKY_LINUX_SUMMARY.md)
- [ ] Read: [ROCKY_LINUX_ARCHITECTURE.md](ROCKY_LINUX_ARCHITECTURE.md)
- [ ] Reviewed: [README.md](README.md)
- [ ] Reviewed: [Makefile](Makefile)

---

## ✅ Success Criteria

All of the following should be true:

- ✅ All services running without errors
- ✅ API responding to health checks
- ✅ Predictions working correctly
- ✅ MLflow tracking experiments
- ✅ Jenkins pipeline executing successfully
- ✅ Kubernetes pods in Running state
- ✅ No firewall blocking issues
- ✅ All URLs accessible

---

## 🐛 Troubleshooting Reference

If any item fails, refer to:
- [ROCKY_LINUX_SETUP.md](ROCKY_LINUX_SETUP.md) - Troubleshooting section
- [ROCKY_LINUX_SUMMARY.md](ROCKY_LINUX_SUMMARY.md) - Common issues

---

**Status:** [ ] Complete | [ ] In Progress | [ ] Not Started

**Date:** _______________

**Notes:**
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

