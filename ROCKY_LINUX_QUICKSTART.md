# Rocky Linux Quick Start - Heart Disease MLOps

**⚡ Get up and running in 10 minutes!**

---

## 🚀 Option 1: Automated Setup (Recommended)

```bash
# 1. Clone repository
git clone https://github.com/2024aa05820/heart-disease-mlops.git
cd heart-disease-mlops

# 2. Run automated setup (installs everything)
sudo ./scripts/rocky-setup.sh

# 3. Log out and back in (for docker group)
exit
# SSH back in

# 4. Start Minikube
minikube start --driver=docker --cpus=2 --memory=4096

# 5. Deploy application
make deploy

# 6. Get URLs
make urls
```

**Done! 🎉**

---

## 📋 Option 2: Using Makefile Commands

```bash
# Install all prerequisites
make rocky-setup

# Log out and back in
exit

# Start Minikube
make rocky-start

# Check status
make rocky-status

# Deploy application
make deploy

# View URLs
make urls
```

---

## 🔑 Access Jenkins

```bash
# Get Jenkins URL
echo "http://$(hostname -I | awk '{print $1}'):8080"

# Get initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

1. Open Jenkins URL in browser
2. Enter initial password
3. Install suggested plugins
4. Create admin user
5. Add GitHub token (Settings → Credentials)
6. Create pipeline job pointing to your repo

---

## ✅ Verify Installation

```bash
# Check all services
make rocky-status

# Check versions
java -version
docker --version
kubectl version --client
minikube version

# Test docker
docker ps

# Test kubectl
kubectl get nodes
```

---

## 🎯 Deploy & Test

```bash
# Deploy to Kubernetes
make deploy

# Check deployment
make k8s-status

# View logs
make k8s-logs

# Get service URL
minikube service heart-disease-api-service --url

# Test API
curl $(minikube service heart-disease-api-service --url)/health
```

---

## 📊 Access Services

```bash
# Show all URLs
make urls

# Example output:
# API:        http://192.168.49.2:30080
# Swagger:    http://192.168.49.2:30080/docs
# MLflow:     http://192.168.1.100:5001
# Jenkins:    http://192.168.1.100:8080
```

---

## 🐛 Common Issues

### Docker Permission Denied
```bash
sudo usermod -aG docker $USER
exit  # Log out and back in
```

### Minikube Won't Start
```bash
minikube delete
minikube start --driver=docker --cpus=2 --memory=4096
```

### Jenkins Can't Access Docker
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Firewall Blocking
```bash
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=5001/tcp
sudo firewall-cmd --reload
```

---

## 📚 Full Documentation

- **Complete Setup Guide**: [ROCKY_LINUX_SETUP.md](ROCKY_LINUX_SETUP.md)
- **Main README**: [README.md](README.md)
- **Deployment Options**: [DEPLOYMENT_OPTIONS_SUMMARY.md](DEPLOYMENT_OPTIONS_SUMMARY.md)

---

## 🎓 Next Steps

1. ✅ Push code to trigger Jenkins pipeline
2. ✅ Monitor build in Jenkins UI
3. ✅ Check deployment: `make k8s-status`
4. ✅ Test API: `curl <API_URL>/health`
5. ✅ View experiments in MLflow UI

---

**Need Help?** Check the troubleshooting section in [ROCKY_LINUX_SETUP.md](ROCKY_LINUX_SETUP.md)

