# Heart Disease Prediction - MLOps Project

[![CI/CD Pipeline](https://github.com/2024aa05820/heart-disease-mlops/actions/workflows/ci.yml/badge.svg)](https://github.com/2024aa05820/heart-disease-mlops/actions/workflows/ci.yml)

A production-ready machine learning solution for predicting heart disease risk, built with modern MLOps best practices.

## 🚀 Quick Start

### Rocky Linux (Recommended for Production)

**Deploy in 10 minutes:**

```bash
# Clone and setup
git clone https://github.com/2024aa05820/heart-disease-mlops.git
cd heart-disease-mlops

# Automated installation (Java, Docker, k8s, Jenkins)
sudo ./scripts/rocky-setup.sh

# Log out and back in, then:
make rocky-start
make deploy
make urls
```

**📖 Full Guide:** [ROCKY_LINUX_QUICKSTART.md](ROCKY_LINUX_QUICKSTART.md) | [ROCKY_LINUX_SETUP.md](ROCKY_LINUX_SETUP.md)

### Other Deployment Options

```bash
# SSH to your remote machine
ssh username@your-remote-server-ip

# Navigate to project
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
git pull origin main

# Deploy everything (builds, deploys, starts MLflow)
./scripts/remote_quick_deploy.sh
```

**See:** [DEPLOYMENT_OPTIONS_SUMMARY.md](DEPLOYMENT_OPTIONS_SUMMARY.md) for all deployment methods.

## 📋 Project Overview

This project implements an end-to-end ML pipeline for heart disease classification:
- **Dataset**: UCI Heart Disease Dataset (303 samples, 14 features)
- **Models**: Logistic Regression & Random Forest classifiers
- **Tracking**: MLflow for experiment tracking
- **API**: FastAPI-based REST API
- **Deployment**: Docker + Kubernetes

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         CI/CD Pipeline (GitHub Actions)                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │   Lint   │→ │   Test   │→ │  Train   │→ │  Docker  │→ │  Deploy  │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                     ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                            Kubernetes Cluster                            │
│  ┌───────────────┐    ┌───────────────────────────────────────────┐    │
│  │   Ingress/LB  │ →  │  Heart Disease API (FastAPI)              │    │
│  └───────────────┘    │  - /health     Health check               │    │
│                       │  - /predict    Make predictions           │    │
│                       │  - /metrics    Prometheus metrics         │    │
│                       └───────────────────────────────────────────┘    │
│                                          ↓                              │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                    Monitoring (Prometheus + Grafana)              │ │
│  └───────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
heart-disease-mlops/
├── .github/workflows/      # CI/CD pipeline
│   └── ci.yml
├── data/
│   ├── raw/               # Raw dataset
│   └── processed/         # Processed data
├── deploy/
│   └── k8s/               # Kubernetes manifests
│       ├── deployment.yaml
│       ├── service.yaml
│       └── ingress.yaml
├── models/                # Saved model artifacts
├── mlruns/                # MLflow tracking
├── notebooks/             # Jupyter notebooks
│   └── 01_eda.ipynb
├── reports/               # Documentation & screenshots
│   └── screenshots/
├── scripts/               # Utility scripts
│   ├── download_data.py
│   └── train.py
├── src/
│   ├── api/              # FastAPI application
│   │   └── app.py
│   ├── config/           # Configuration
│   │   └── config.yaml
│   ├── data/             # Data processing
│   │   └── pipeline.py
│   └── models/           # ML models
│       ├── train.py
│       └── predict.py
├── tests/                 # Unit tests
│   ├── test_api.py
│   ├── test_data.py
│   └── test_model.py
├── Dockerfile
├── Makefile
├── requirements.txt
└── README.md
```

## 🚀 Quick Start

### Prerequisites
- Python 3.11+
- Docker
- Minikube (for Kubernetes deployment)
- MLflow (for experiment tracking)

### 🎯 Five Deployment Options

**Choose your deployment method:**

1. **Rebuild on Remote** ⭐ RECOMMENDED - Simplest, 5 minutes
2. **GitHub Artifact** - Use CI/CD built image
3. **Docker Registry** - Production-ready with Docker Hub
4. **Jenkins CI/CD** 🚀 - Full automation (build + deploy)
5. **Hybrid (GitHub + Jenkins)** 🔥 NEW - Best of both worlds!

**See:** [DEPLOYMENT_SOLUTION_SUMMARY.md](DEPLOYMENT_SOLUTION_SUMMARY.md) for detailed comparison.

**Quick Deploy (Method 1):**
```bash
ssh user@remote
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
git pull origin main
./scripts/remote_quick_deploy.sh
```

### Initial Setup (Rocky Linux / RHEL / CentOS)

#### Step 1: Check Python Version & Install Dependencies

Run these commands on your Linux box:

```bash
# Check Python version (need 3.11+)
python3 --version

# If Python 3.11 is not installed, install it:
sudo dnf install python3.11 python3.11-pip python3.11-devel -y

# Install make if not present
sudo dnf install make -y

# Install git if not present (you likely have it since you cloned)
sudo dnf install git -y
```

#### Step 2: Navigate to Project & Setup Virtual Environment

```bash
# Go to project directory
cd ~/Documents/mlops-assignment-1/heart-disease-mlops

# Create virtual environment
python3 -m venv .venv

# Activate virtual environment
source .venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install dependencies
pip install -r requirements.txt
```

**Or use the Makefile shortcut:**

```bash
make init
source .venv/bin/activate
```

#### Alternative: Using Conda (Recommended for ML Projects)

```bash
# Create conda environment
make init-conda

# Activate conda environment
conda activate heart-mlops

# Install dependencies
make install
```

### 1. Setup Environment (After Initial Setup)

```bash
# Clone repository (if not already done)
git clone https://github.com/YOUR_USERNAME/heart-disease-mlops.git
cd heart-disease-mlops

# Create virtual environment
make init

# Activate virtual environment
source .venv/bin/activate
```

### 2. Download Dataset

```bash
make download
# or
python scripts/download_data.py
```

### 3. Train Models

```bash
make train
# or
python scripts/train.py
```

### 4. Run API Locally

```bash
make serve
# or
uvicorn src.api.app:app --host 0.0.0.0 --port 8000 --reload
```

### 5. Test API

```bash
# Health check
curl http://localhost:8000/health

# Make prediction
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "age": 63, "sex": 1, "cp": 3, "trestbps": 145,
    "chol": 233, "fbs": 1, "restecg": 0, "thalach": 150,
    "exang": 0, "oldpeak": 2.3, "slope": 0, "ca": 0, "thal": 1
  }'
```

## 🐳 Docker

### Build & Run

```bash
# Build image
make docker-build

# Run container
make docker-run

# Or manually
docker build -t heart-disease-api:latest .
docker run -p 8000:8000 heart-disease-api:latest
```

## ☸️ Kubernetes Deployment

### Installing kubectl on Rocky Linux / RHEL / CentOS

```bash
# Install kubectl
# Method 1: Using dnf/yum (if available in repos)
sudo dnf install -y kubectl

# Method 2: Manual installation (recommended)
# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Make it executable
chmod +x kubectl

# Move to PATH
sudo mv kubectl /usr/local/bin/

# Verify installation
kubectl version --client
```

### Installing Minikube on Rocky Linux

```bash
# Download Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Install Minikube
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Verify installation
minikube version

# Install Docker (required for Minikube)
sudo dnf install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Log out and log back in for group changes to take effect
# Or run: newgrp docker
```

### Using Minikube

```bash
# Start Minikube
minikube start

# Load Docker image into Minikube
minikube image load heart-disease-api:latest

# Deploy (use kubectl directly if installed)
kubectl apply -f deploy/k8s/

# If kubectl is not installed separately, use minikube kubectl with -- separator:
# minikube kubectl -- apply -f deploy/k8s/

# Check status
kubectl get pods
kubectl get services

# Access API (port-forward)
kubectl port-forward service/heart-disease-api-service 8000:80
```

**Note:** If you don't have `kubectl` installed separately, you can use `minikube kubectl` with the `--` separator:
```bash
minikube kubectl -- apply -f deploy/k8s/
minikube kubectl -- get pods
minikube kubectl -- get services
```

### Alternative: Using Docker Desktop Kubernetes (if available)

If you have Docker Desktop with Kubernetes enabled:

```bash
# Enable Kubernetes in Docker Desktop settings
# Then deploy directly:
kubectl apply -f deploy/k8s/
```

## 🧪 Testing

```bash
# Run all tests
make test

# Run with coverage
pytest tests/ -v --cov=src --cov-report=html

# Run specific test file
pytest tests/test_api.py -v
```

## 📊 MLflow Experiment Tracking

### View Experiments

After training models, view experiments in MLflow UI:

```bash
# Start MLflow UI
mlflow ui --backend-store-uri mlruns

# Or use Makefile shortcut
make mlflow-ui

# Open browser: http://localhost:5000
# Or if accessing remotely: http://0.0.0.0:5000
```

### Troubleshooting Empty MLflow UI

If MLflow UI shows an empty page, it means **no experiments have been logged yet**.

**SOLUTION: Use the automated setup script:**

```bash
# One-command fix (downloads data + trains models + verifies)
bash scripts/setup_mlflow.sh

# Or manually:
python scripts/download_data.py  # Step 1: Download dataset
python scripts/train.py          # Step 2: Train models (creates MLflow runs)
python scripts/check_mlflow_status.py  # Step 3: Verify everything worked
```

**Then start MLflow UI:**
```bash
mlflow ui --host 0.0.0.0 --port 5000
```

**Access from browser:**
- Local: `http://localhost:5000`
- Remote: `http://YOUR_SERVER_IP:5000`
- SSH tunnel: `ssh -L 5000:localhost:5000 user@server` then `http://localhost:5000`

**Detailed troubleshooting guide:** See `MLFLOW_SETUP_GUIDE.md`

### What You'll See After Training

Once models are trained, MLflow UI will show:
- **Experiments**: "heart-disease-classification"
- **Runs**: One for each model (Logistic Regression, Random Forest)
- **Metrics**: Accuracy, Precision, Recall, F1, ROC-AUC
- **Parameters**: Model hyperparameters
- **Artifacts**: ROC curves, confusion matrices, feature importance plots

## 🤖 Jenkins CI/CD (Automated Deployment)

### Overview

Jenkins provides **fully automated deployment** with GitHub webhooks:
- ✅ Push code to GitHub → Jenkins automatically builds and deploys
- ✅ No manual intervention needed
- ✅ Production-like CI/CD pipeline
- ✅ Free and open-source

### Quick Setup

**1. Install Jenkins:**
```bash
sudo dnf install java-17-openjdk jenkins -y
sudo systemctl start jenkins
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
# Access: http://remote-ip:8080
```

**2. Configure:**
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

**3. Create Pipeline Job:**
- Repository: `https://github.com/2024aa05820/heart-disease-mlops.git`
- Script Path: `Jenkinsfile`
- Build Triggers: ✅ GitHub hook trigger

**4. Add GitHub Webhook:**
- URL: `http://remote-ip:8080/github-webhook/`

**5. Push code → Jenkins auto-deploys! 🚀**

**See:** [JENKINS_SETUP_GUIDE.md](JENKINS_SETUP_GUIDE.md) for complete instructions.

### 🔥 Hybrid: GitHub Actions + Jenkins

**Best of both worlds - GitHub builds, Jenkins deploys!**

**How it works:**
1. Push code → GitHub Actions builds Docker image
2. Jenkins downloads artifact from GitHub
3. Jenkins deploys to Minikube

**Benefits:**
- ✅ Fast cloud builds (GitHub runners)
- ✅ Controlled deployment (your server)
- ✅ Free (GitHub's CI/CD minutes)
- ✅ Production-like pattern

**Quick Setup:**
```bash
# Install jq
sudo dnf install jq -y

# Add GitHub token to Jenkins (ID: github-token)
# Create pipeline with Script Path: Jenkinsfile.hybrid
# Push code → Auto-deploy! 🚀
```

**See:** [JENKINS_HYBRID_DEPLOYMENT.md](JENKINS_HYBRID_DEPLOYMENT.md) for complete guide.

## 📈 API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | API information |
| `/health` | GET | Health check |
| `/predict` | POST | Make prediction |
| `/metrics` | GET | Prometheus metrics |
| `/schema` | GET | Feature schema |
| `/docs` | GET | Swagger documentation |

## 🔧 Configuration

Edit `src/config/config.yaml` to customize:
- Data paths
- Model hyperparameters
- MLflow settings
- API configuration

## 📋 Feature Description

| Feature | Description | Type | Range |
|---------|-------------|------|-------|
| age | Age in years | int | 0-120 |
| sex | Sex (1=male, 0=female) | int | 0-1 |
| cp | Chest pain type | int | 0-3 |
| trestbps | Resting blood pressure (mm Hg) | int | 50-250 |
| chol | Serum cholesterol (mg/dl) | int | 100-600 |
| fbs | Fasting blood sugar > 120 mg/dl | int | 0-1 |
| restecg | Resting ECG results | int | 0-2 |
| thalach | Maximum heart rate achieved | int | 50-250 |
| exang | Exercise induced angina | int | 0-1 |
| oldpeak | ST depression | float | 0-10 |
| slope | Slope of peak ST segment | int | 0-2 |
| ca | Major vessels colored by fluoroscopy | int | 0-4 |
| thal | Thalassemia | int | 0-3 |

## 📚 Deployment Documentation

### Quick Reference Guides

| Document | Purpose | Use When |
|----------|---------|----------|
| **[README.md](README.md)** | Main project documentation | Overview and getting started |
| **[DEPLOYMENT_SOLUTION_SUMMARY.md](DEPLOYMENT_SOLUTION_SUMMARY.md)** | Overview of all 5 deployment methods | Start here - choose your method |
| **[GITHUB_TO_REMOTE_DEPLOYMENT.md](GITHUB_TO_REMOTE_DEPLOYMENT.md)** | GitHub artifact deployment | Using CI/CD built images |
| **[JENKINS_SETUP_GUIDE.md](JENKINS_SETUP_GUIDE.md)** | Jenkins CI/CD setup | Full automation with Jenkins |
| **[JENKINS_HYBRID_DEPLOYMENT.md](JENKINS_HYBRID_DEPLOYMENT.md)** | Hybrid GitHub + Jenkins | Best of both worlds! |
| **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** | Quick command reference | Fast lookup of commands |

### Available Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `scripts/remote_quick_deploy.sh` | Full automated deployment | `./scripts/remote_quick_deploy.sh` |
| `scripts/deploy_to_minikube.sh` | Deploy to Kubernetes | `./scripts/deploy_to_minikube.sh` |
| `scripts/deploy_github_artifact.sh` | Deploy GitHub artifact | `./scripts/deploy_github_artifact.sh ~/docker-image.tar.gz` |
| `scripts/download_github_artifact.sh` | Download GitHub artifact | `./scripts/download_github_artifact.sh` |
| `scripts/jenkins_deploy.sh` | Jenkins deployment helper | `./scripts/jenkins_deploy.sh latest` |
| `scripts/start_mlflow_ui.sh` | Manage MLflow UI | `./scripts/start_mlflow_ui.sh --background` |

### Deployment Methods Comparison

| Method | Time | Complexity | Best For |
|--------|------|------------|----------|
| **Rebuild on Remote** | 5 min | ⭐ Easy | Assignments, quick testing |
| **GitHub Artifact** | 10 min | ⭐⭐ Medium | Learning CI/CD, reproducibility |
| **Docker Registry** | 15 min | ⭐⭐⭐ Advanced | Production, multiple targets |

## 📄 License

This project is for educational purposes (BITS Pilani MLOps Assignment).

## 👤 Author

- **Name**: [Your Name]
- **Course**: MLOps (S1-25_AIMLCZG523)
- **Institution**: BITS Pilani

