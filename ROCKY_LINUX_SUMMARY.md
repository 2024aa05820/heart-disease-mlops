# Rocky Linux Deployment Summary

## 📦 What's Been Updated

Your Heart Disease MLOps project now has **complete Rocky Linux support** with automated setup and deployment.

### New Files Created

1. **`ROCKY_LINUX_SETUP.md`** - Complete step-by-step installation guide
2. **`ROCKY_LINUX_QUICKSTART.md`** - Quick reference for fast deployment
3. **`scripts/rocky-setup.sh`** - Automated installation script
4. **`ROCKY_LINUX_SUMMARY.md`** - This file

### Updated Files

1. **`Makefile`** - Added Rocky Linux specific commands
2. **`README.md`** - Added Rocky Linux quick start section

---

## 🎯 What Gets Installed

The automated setup installs and configures:

| Component | Version | Purpose |
|-----------|---------|---------|
| **Java** | 17 | Jenkins requirement |
| **Docker** | Latest | Container runtime |
| **kubectl** | Latest | Kubernetes CLI |
| **Minikube** | Latest | Local Kubernetes cluster |
| **Jenkins** | Latest LTS | CI/CD automation |
| **Python** | 3.11+ | ML/API runtime |
| **Git** | Latest | Version control |

---

## 🚀 Quick Commands Reference

### Installation
```bash
# Automated setup (one command)
sudo ./scripts/rocky-setup.sh

# Or using Makefile
make rocky-setup
```

### Starting Services
```bash
# Start Minikube
make rocky-start

# Check status
make rocky-status

# Show all URLs
make urls
```

### Deployment
```bash
# Deploy to Kubernetes
make deploy

# Check deployment
make k8s-status

# View logs
make k8s-logs

# Restart deployment
make k8s-restart
```

### Development
```bash
# Setup Python environment
make init-conda  # or make init

# Download data
make download

# Train models
make train

# Run tests
make test

# Start MLflow UI
make mlflow-ui
```

---

## 📊 Service URLs

After deployment, access services at:

```bash
# Get all URLs
make urls

# Example output:
API:        http://192.168.49.2:30080
Swagger:    http://192.168.49.2:30080/docs
MLflow:     http://192.168.1.100:5001
Jenkins:    http://192.168.1.100:8080
```

---

## 🔧 Jenkins Pipeline

The Jenkinsfile is already configured to:

1. ✅ Checkout code from GitHub
2. ✅ Setup Python environment
3. ✅ Run linting and tests
4. ✅ Download dataset
5. ✅ Train ML models
6. ✅ Build Docker image
7. ✅ Test Docker container
8. ✅ Load image to Minikube
9. ✅ Deploy to Kubernetes
10. ✅ Start MLflow UI

**Trigger:** Automatically runs on push to GitHub

---

## 📁 Project Structure

```
heart-disease-mlops/
├── ROCKY_LINUX_SETUP.md          # Complete setup guide
├── ROCKY_LINUX_QUICKSTART.md     # Quick reference
├── ROCKY_LINUX_SUMMARY.md        # This file
├── scripts/
│   └── rocky-setup.sh            # Automated installer
├── Makefile                       # Build commands (updated)
├── README.md                      # Main docs (updated)
├── Jenkinsfile                    # CI/CD pipeline
├── deploy/k8s/                    # Kubernetes manifests
├── src/                           # Application code
└── tests/                         # Unit tests
```

---

## ✅ Verification Checklist

After installation, verify:

- [ ] Java 17 installed: `java -version`
- [ ] Docker running: `docker ps`
- [ ] kubectl working: `kubectl version --client`
- [ ] Minikube running: `minikube status`
- [ ] Jenkins accessible: `http://<IP>:8080`
- [ ] User in docker group: `groups | grep docker`

---

## 🐛 Common Issues & Solutions

### 1. Docker Permission Denied
```bash
sudo usermod -aG docker $USER
exit  # Log out and back in
```

### 2. Minikube Won't Start
```bash
minikube delete
minikube start --driver=docker --cpus=2 --memory=4096
```

### 3. Jenkins Can't Access Docker
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### 4. Firewall Blocking Ports
```bash
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=5001/tcp
sudo firewall-cmd --reload
```

### 5. Pods Not Starting
```bash
# Check pod status
kubectl get pods -o wide

# View pod logs
kubectl logs <pod-name>

# Describe pod
kubectl describe pod <pod-name>
```

---

## 🎓 Workflow

### First Time Setup
1. Run `sudo ./scripts/rocky-setup.sh`
2. Log out and back in
3. Run `make rocky-start`
4. Configure Jenkins (add GitHub token)
5. Create Jenkins pipeline job
6. Push code to trigger build

### Daily Development
1. Make code changes
2. Push to GitHub
3. Jenkins automatically builds and deploys
4. Check deployment: `make k8s-status`
5. Test API: `curl <API_URL>/health`
6. View experiments in MLflow

---

## 📚 Documentation

- **Quick Start**: [ROCKY_LINUX_QUICKSTART.md](ROCKY_LINUX_QUICKSTART.md)
- **Full Setup**: [ROCKY_LINUX_SETUP.md](ROCKY_LINUX_SETUP.md)
- **Main README**: [README.md](README.md)
- **Deployment Options**: [DEPLOYMENT_OPTIONS_SUMMARY.md](DEPLOYMENT_OPTIONS_SUMMARY.md)

---

## 🎯 Next Steps

1. ✅ Review the setup guide: `ROCKY_LINUX_SETUP.md`
2. ✅ Run automated setup: `sudo ./scripts/rocky-setup.sh`
3. ✅ Configure Jenkins with GitHub token
4. ✅ Create Jenkins pipeline job
5. ✅ Push code to trigger first build
6. ✅ Monitor deployment and test API

---

**Ready to deploy? Start with:** [ROCKY_LINUX_QUICKSTART.md](ROCKY_LINUX_QUICKSTART.md)

