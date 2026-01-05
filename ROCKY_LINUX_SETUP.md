# Rocky Linux Setup Guide - Heart Disease MLOps

Complete setup guide for deploying the Heart Disease MLOps project on Rocky Linux.

## 📋 Prerequisites

| Component | Version | Purpose |
|-----------|---------|---------|
| **Rocky Linux** | 8.x or 9.x | Operating System |
| **Java** | 17 | Jenkins requirement |
| **Docker** | 24.x+ | Containerization |
| **kubectl** | Latest | Kubernetes CLI |
| **Minikube** | Latest | Local Kubernetes |
| **Jenkins** | Latest LTS | CI/CD Server |
| **Python** | 3.11+ | ML/API runtime |

## 🚀 Quick Start (Automated)

```bash
# Clone the repository
git clone https://github.com/2024aa05820/heart-disease-mlops.git
cd heart-disease-mlops

# Run automated setup (installs everything)
sudo ./scripts/rocky-setup.sh

# After installation, log out and back in for docker group
exit
# SSH back in

# Start Minikube
minikube start --driver=docker --cpus=2 --memory=4096

# Access Jenkins
echo "Jenkins: http://$(hostname -I | awk '{print $1}'):8080"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

## 📝 Manual Step-by-Step Installation

### Step 1: Update System

```bash
sudo dnf update -y
sudo dnf install -y epel-release
```

### Step 2: Install Java 17

```bash
# Install Java 17
sudo dnf install -y java-17-openjdk java-17-openjdk-devel

# Verify
java -version
# Expected: openjdk version "17.x.x"
```

### Step 3: Install Docker

```bash
# Install yum-utils
sudo dnf install -y yum-utils

# Add Docker repository
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group
sudo usermod -aG docker $USER

# Verify
docker --version
# Expected: Docker version 24.x.x

# IMPORTANT: Log out and back in for group to take effect
```

### Step 4: Install kubectl

```bash
# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Clean up
rm -f kubectl

# Verify
kubectl version --client
```

### Step 5: Install Minikube

```bash
# Download Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Install
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Clean up
rm -f minikube-linux-amd64

# Verify
minikube version

# Start Minikube (after logging back in for docker group)
minikube start --driver=docker --cpus=2 --memory=4096

# Verify
minikube status
```

### Step 6: Install Jenkins

```bash
# Add Jenkins repository
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Jenkins
sudo dnf install -y jenkins

# Add jenkins to docker group
sudo usermod -aG docker jenkins

# Start Jenkins
sudo systemctl daemon-reload
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Get initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Get server IP
hostname -I | awk '{print $1}'
# Access Jenkins at: http://<IP>:8080
```

### Step 7: Install Additional Tools

```bash
# Install tools
sudo dnf install -y git curl wget jq unzip python3 python3-pip

# Verify
git --version
python3 --version
```

### Step 8: Configure Firewall

```bash
# Open Jenkins port
sudo firewall-cmd --permanent --add-port=8080/tcp

# Open MLflow port
sudo firewall-cmd --permanent --add-port=5001/tcp

# Reload firewall
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --list-ports
```

---

## 🔧 Jenkins Configuration

### 1. Initial Setup

1. Open: `http://<YOUR_SERVER_IP>:8080`
2. Enter initial admin password from Step 6
3. Click **"Install suggested plugins"**
4. Create admin user
5. Save and finish

### 2. Add GitHub Token

1. Generate token at: https://github.com/settings/tokens
   - Scopes: `repo`, `workflow`
2. In Jenkins: **Manage Jenkins** → **Credentials** → **Global** → **Add Credentials**
   - Kind: `Secret text`
   - Secret: `<your-github-token>`
   - ID: `github-token`
   - Description: `GitHub Token`

### 3. Create Pipeline Job

1. Click **"New Item"**
2. Name: `heart-disease-mlops`
3. Type: **Pipeline**
4. Configure:
   - **Build Triggers**: ✅ Poll SCM
   - **Schedule**: `H/2 * * * *` (checks every 2 minutes)
   - **Pipeline**:
     - Definition: `Pipeline script from SCM`
     - SCM: `Git`
     - Repository URL: `https://github.com/2024aa05820/heart-disease-mlops.git`
     - Branch: `*/main`
     - Script Path: `Jenkinsfile`
5. Click **Save**

---

## ✅ Verification

```bash
# Check all services
sudo systemctl status docker
sudo systemctl status jenkins
minikube status

# Check versions
java -version
docker --version
kubectl version --client
minikube version

# Test docker access
docker ps

# Test kubectl
kubectl get nodes
```

---

## 🎯 Deploy the Application

```bash
# Clone repository
git clone https://github.com/2024aa05820/heart-disease-mlops.git
cd heart-disease-mlops

# Deploy using Makefile
make deploy

# Or manually
kubectl apply -f deploy/k8s/

# Check deployment
kubectl get pods
kubectl get services

# Get service URL
minikube service heart-disease-api-service --url

# Test API
curl $(minikube service heart-disease-api-service --url)/health
```

---

## 🐛 Troubleshooting

### Docker Permission Denied

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in
exit
```

### Minikube Won't Start

```bash
# Delete and recreate
minikube delete
minikube start --driver=docker --cpus=2 --memory=4096
```

### Jenkins Can't Access Docker

```bash
# Add jenkins to docker group
sudo usermod -aG docker jenkins

# Restart Jenkins
sudo systemctl restart jenkins
```

### Firewall Blocking Ports

```bash
# Check firewall status
sudo firewall-cmd --list-all

# Open required ports
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=5001/tcp
sudo firewall-cmd --reload
```

---

## 📊 Access URLs

After successful deployment:

```bash
# Get all URLs
MINIKUBE_IP=$(minikube ip)
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "API:     http://${MINIKUBE_IP}:30080"
echo "Swagger: http://${MINIKUBE_IP}:30080/docs"
echo "MLflow:  http://${SERVER_IP}:5001"
echo "Jenkins: http://${SERVER_IP}:8080"
```

---

## 🎓 Next Steps

1. ✅ Push code to trigger pipeline
2. ✅ Monitor build in Jenkins
3. ✅ Check deployment in Kubernetes
4. ✅ Test API endpoints
5. ✅ View experiments in MLflow

---

**Need Help?** Check the main [README.md](README.md) or [Troubleshooting Guide](TROUBLESHOOTING.md)

