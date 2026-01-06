# Heart Disease MLOps - Complete Deployment Summary

## 🎯 Overview

This document provides a complete overview of the MLOps infrastructure for the Heart Disease Prediction project, including PostgreSQL-backed MLflow, Docker deployment, Kubernetes orchestration, and monitoring.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     MLOps Infrastructure                     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │  PostgreSQL  │◄───│    MLflow    │◄───│   Training   │  │
│  │   Database   │    │    Server    │    │   Pipeline   │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│         │                    │                               │
│         │                    ▼                               │
│         │            ┌──────────────┐                        │
│         │            │  Model       │                        │
│         │            │  Registry    │                        │
│         │            └──────────────┘                        │
│         │                    │                               │
│         ▼                    ▼                               │
│  ┌──────────────────────────────────┐                       │
│  │      FastAPI Application         │                       │
│  │  (Heart Disease Prediction API)  │                       │
│  └──────────────────────────────────┘                       │
│         │                    │                               │
│         ▼                    ▼                               │
│  ┌──────────────┐    ┌──────────────┐                       │
│  │  Prometheus  │    │   Grafana    │                       │
│  │  (Metrics)   │    │ (Dashboard)  │                       │
│  └──────────────┘    └──────────────┘                       │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Components

### 1. PostgreSQL Database
- **Purpose**: Backend store for MLflow experiments and model registry
- **Why**: Eliminates YAML RepresenterError issues with FileStore
- **Port**: 5432
- **Credentials**: mlflow/mlflow
- **Location**: `deploy/docker/docker-compose.yml`

### 2. MLflow Server
- **Purpose**: Experiment tracking and model registry
- **Backend**: PostgreSQL (production-ready)
- **Artifact Store**: Local filesystem (`./mlruns`)
- **Port**: 5000
- **UI**: http://localhost:5000
- **Location**: `deploy/docker/docker-compose.yml`

### 3. FastAPI Application
- **Purpose**: Serve predictions via REST API
- **Features**:
  - Health check endpoint
  - Prediction endpoint
  - Prometheus metrics
  - Swagger documentation
- **Port**: 8000
- **Docs**: http://localhost:8000/docs
- **Location**: `src/api/main.py`

### 4. Prometheus
- **Purpose**: Metrics collection and monitoring
- **Scrapes**: API metrics, MLflow metrics
- **Port**: 9090
- **UI**: http://localhost:9090
- **Config**: `deploy/monitoring/prometheus.yml`

### 5. Grafana
- **Purpose**: Visualization and dashboards
- **Datasource**: Prometheus
- **Port**: 3000
- **Login**: admin/admin
- **Config**: `deploy/monitoring/grafana-datasources.yml`

---

## 🚀 Quick Start

### Option 1: Full Stack (Recommended)

```bash
# Start all services
docker-compose -f deploy/docker/docker-compose.yml up -d

# Check status
docker-compose -f deploy/docker/docker-compose.yml ps

# View logs
docker-compose -f deploy/docker/docker-compose.yml logs -f
```

### Option 2: Step-by-Step

```bash
# 1. Start PostgreSQL + MLflow
./scripts/setup-postgresql-mlflow.sh

# 2. Train models
export MLFLOW_TRACKING_URI=http://localhost:5000
python src/models/train.py

# 3. Start API
docker-compose -f deploy/docker/docker-compose.yml up -d api

# 4. Start monitoring
docker-compose -f deploy/docker/docker-compose.yml up -d prometheus grafana
```

---

## 🔧 Configuration Files

| File | Purpose |
|------|---------|
| `deploy/docker/docker-compose.yml` | All services orchestration |
| `deploy/docker/Dockerfile` | API container image |
| `deploy/k8s/deployment.yaml` | Kubernetes deployment |
| `deploy/k8s/service.yaml` | Kubernetes service |
| `deploy/monitoring/prometheus.yml` | Prometheus configuration |
| `deploy/monitoring/grafana-datasources.yml` | Grafana datasource |
| `.env.example` | Environment variables template |
| `Jenkinsfile` | CI/CD pipeline |

---

## 📊 CI/CD Pipeline (Jenkins)

### Pipeline Stages

1. **Checkout**: Clone repository
2. **Setup Environment**: Create Python venv, install dependencies
3. **Lint Code**: Run ruff and black
4. **Run Tests**: Execute pytest with coverage
5. **Download Dataset**: Fetch training data
6. **Start MLflow with PostgreSQL**: Launch backend services
7. **Train Models**: Train with PostgreSQL-backed MLflow
8. **Promote Best Model**: Auto-promote to production
9. **Build Docker Image**: Create API container
10. **Test Docker Image**: Verify container health
11. **Load Image to Minikube**: Prepare for K8s deployment
12. **Deploy to Kubernetes**: Apply manifests
13. **Verify Deployment**: Test deployed API

### Key Features

- ✅ **No YAML errors**: Uses PostgreSQL backend
- ✅ **Automatic model promotion**: Best model auto-promoted
- ✅ **Health checks**: Verifies all services
- ✅ **Rollback support**: Kubernetes rollout management
- ✅ **Cleanup**: Automatic resource cleanup

---

## 🌐 Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| MLflow UI | http://localhost:5000 | - |
| API Docs | http://localhost:8000/docs | - |
| API Health | http://localhost:8000/health | - |
| API Metrics | http://localhost:8000/metrics | - |
| Prometheus | http://localhost:9090 | - |
| Grafana | http://localhost:3000 | admin/admin |
| PostgreSQL | localhost:5432 | mlflow/mlflow |

---

## 🧪 Testing

### Test API Locally

```bash
# Health check
curl http://localhost:8000/health

# Make prediction
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "age": 63,
    "sex": 1,
    "cp": 3,
    "trestbps": 145,
    "chol": 233,
    "fbs": 1,
    "restecg": 0,
    "thalach": 150,
    "exang": 0,
    "oldpeak": 2.3,
    "slope": 0,
    "ca": 0,
    "thal": 1
  }'
```

### Test Kubernetes Deployment

```bash
# Port forward to service
kubectl port-forward service/heart-disease-api-service 8000:80

# Test health
curl http://localhost:8000/health

# Test prediction
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"age":63,"sex":1,"cp":3,"trestbps":145,"chol":233,"fbs":1,"restecg":0,"thalach":150,"exang":0,"oldpeak":2.3,"slope":0,"ca":0,"thal":1}'
```

---

## 📚 Documentation

- [PostgreSQL MLflow Setup](./POSTGRESQL-MLFLOW-SETUP.md)
- [Docker Deployment](../deploy/docker/README.md)
- [Kubernetes Deployment](../deploy/k8s/README.md)
- [API Documentation](http://localhost:8000/docs)

---

## 🔍 Troubleshooting

### PostgreSQL Issues

```bash
# Check PostgreSQL logs
docker logs mlflow-postgres

# Test connection
docker exec mlflow-postgres pg_isready -U mlflow

# Connect to database
docker exec -it mlflow-postgres psql -U mlflow -d mlflow
```

### MLflow Issues

```bash
# Check MLflow logs
docker logs mlflow-server

# Test health
curl http://localhost:5000/health

# Check experiments
curl http://localhost:5000/api/2.0/mlflow/experiments/list
```

### API Issues

```bash
# Check API logs
docker logs heart-disease-api

# Test health
curl http://localhost:8000/health

# Check metrics
curl http://localhost:8000/metrics
```

---

## ✅ Benefits of This Setup

| Feature | Benefit |
|---------|---------|
| PostgreSQL Backend | No YAML RepresenterError |
| Docker Compose | Easy local development |
| Kubernetes | Production-ready orchestration |
| Prometheus + Grafana | Complete monitoring |
| Jenkins Pipeline | Automated CI/CD |
| Model Registry | Version control for models |
| FastAPI | Modern, fast API framework |
| Health Checks | Reliable deployments |

---

## 🎓 Learning Resources

- [MLflow Documentation](https://mlflow.org/docs/latest/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

---

**Last Updated**: 2026-01-06

