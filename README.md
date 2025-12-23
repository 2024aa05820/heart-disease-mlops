# Heart Disease Prediction - MLOps Project

[![CI/CD Pipeline](https://github.com/YOUR_USERNAME/heart-disease-mlops/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/heart-disease-mlops/actions/workflows/ci.yml)

A production-ready machine learning solution for predicting heart disease risk, built with modern MLOps best practices.

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
- (Optional) Minikube or Kubernetes cluster

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

# Deploy
kubectl apply -f deploy/k8s/

# Check status
kubectl get pods
kubectl get services

# Access API (port-forward)
kubectl port-forward service/heart-disease-api-service 8000:80
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

After training, view experiments:

```bash
# Start MLflow UI
mlflow ui --backend-store-uri mlruns

# Open browser: http://localhost:5000
```

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

## 📄 License

This project is for educational purposes (BITS Pilani MLOps Assignment).

## 👤 Author

- **Name**: [Your Name]
- **Course**: MLOps (S1-25_AIMLCZG523)
- **Institution**: BITS Pilani

