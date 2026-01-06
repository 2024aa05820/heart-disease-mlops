# Heart Disease MLOps - Quick Reference

## 🚀 Common Commands

### Start Services

```bash
# Start everything
docker-compose -f deploy/docker/docker-compose.yml up -d

# Start specific services
docker-compose -f deploy/docker/docker-compose.yml up -d postgres mlflow
docker-compose -f deploy/docker/docker-compose.yml up -d api
docker-compose -f deploy/docker/docker-compose.yml up -d prometheus grafana

# Use setup script (PostgreSQL + MLflow only)
./scripts/setup-postgresql-mlflow.sh
```

### Stop Services

```bash
# Stop all services
docker-compose -f deploy/docker/docker-compose.yml down

# Stop specific services
docker-compose -f deploy/docker/docker-compose.yml stop api
docker-compose -f deploy/docker/docker-compose.yml stop prometheus grafana
```

### View Logs

```bash
# All services
docker-compose -f deploy/docker/docker-compose.yml logs -f

# Specific service
docker-compose -f deploy/docker/docker-compose.yml logs -f mlflow
docker-compose -f deploy/docker/docker-compose.yml logs -f api
docker-compose -f deploy/docker/docker-compose.yml logs -f postgres
```

### Check Status

```bash
# Docker Compose services
docker-compose -f deploy/docker/docker-compose.yml ps

# Individual containers
docker ps | grep mlflow
docker ps | grep postgres
docker ps | grep heart-disease
```

---

## 🤖 Model Training

### Train Models

```bash
# Set MLflow tracking URI
export MLFLOW_TRACKING_URI=http://localhost:5000

# Train using new script
python src/models/train.py

# Or use old script
python scripts/train.py
```

### Promote Models

```bash
# Auto-promote best model
python scripts/promote-model.py --auto

# List all models
python scripts/promote-model.py --list

# Promote specific model
python scripts/promote-model.py <model-name>
```

---

## 🌐 API Testing

### Health Check

```bash
curl http://localhost:8000/health
```

### Make Prediction

```bash
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

### View Metrics

```bash
curl http://localhost:8000/metrics
```

### API Documentation

```bash
# Open Swagger UI
open http://localhost:8000/docs

# Open ReDoc
open http://localhost:8000/redoc
```

---

## ☸️ Kubernetes

### Deploy

```bash
# Apply all manifests
kubectl apply -f deploy/k8s/

# Or apply individually
kubectl apply -f deploy/k8s/deployment.yaml
kubectl apply -f deploy/k8s/service.yaml
```

### Check Status

```bash
# Get pods
kubectl get pods -l app=heart-disease-api

# Get deployments
kubectl get deployments

# Get services
kubectl get services

# Describe pod
kubectl describe pod <pod-name>
```

### View Logs

```bash
# Get pod name
POD_NAME=$(kubectl get pods -l app=heart-disease-api -o jsonpath='{.items[0].metadata.name}')

# View logs
kubectl logs $POD_NAME

# Follow logs
kubectl logs -f $POD_NAME
```

### Port Forward

```bash
# Forward service port
kubectl port-forward service/heart-disease-api-service 8000:80

# Forward pod port
kubectl port-forward $POD_NAME 8000:8000
```

### Update Deployment

```bash
# Restart deployment
kubectl rollout restart deployment/heart-disease-api

# Check rollout status
kubectl rollout status deployment/heart-disease-api

# Rollback
kubectl rollout undo deployment/heart-disease-api
```

### Delete Resources

```bash
# Delete all resources
kubectl delete -f deploy/k8s/

# Delete specific resources
kubectl delete deployment heart-disease-api
kubectl delete service heart-disease-api-service
```

---

## 🗄️ Database

### PostgreSQL

```bash
# Connect to database
docker exec -it mlflow-postgres psql -U mlflow -d mlflow

# Check if ready
docker exec mlflow-postgres pg_isready -U mlflow

# List tables
docker exec -it mlflow-postgres psql -U mlflow -d mlflow -c "\dt"

# Backup database
docker exec mlflow-postgres pg_dump -U mlflow mlflow > backup.sql

# Restore database
docker exec -i mlflow-postgres psql -U mlflow mlflow < backup.sql
```

---

## 📊 Monitoring

### Prometheus

```bash
# Open UI
open http://localhost:9090

# Query metrics
curl 'http://localhost:9090/api/v1/query?query=up'
```

### Grafana

```bash
# Open UI
open http://localhost:3000

# Login: admin/admin
```

---

## 🐳 Docker

### Build Image

```bash
# Build API image
docker build -t heart-disease-api:latest .

# Build with tag
docker build -t heart-disease-api:v1.0 .
```

### Run Container

```bash
# Run API container
docker run -d -p 8000:8000 --name api heart-disease-api:latest

# Run with environment variables
docker run -d -p 8000:8000 \
  -e MLFLOW_TRACKING_URI=http://localhost:5000 \
  --name api heart-disease-api:latest
```

### Manage Containers

```bash
# Stop container
docker stop api

# Start container
docker start api

# Remove container
docker rm api

# View logs
docker logs api
docker logs -f api
```

### Clean Up

```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove all unused resources
docker system prune -a
```

---

## 🧪 Testing

### Run Tests

```bash
# All tests
pytest tests/ -v

# With coverage
pytest tests/ -v --cov=src --cov-report=html

# Specific test file
pytest tests/test_api.py -v

# Specific test
pytest tests/test_api.py::test_health_check -v
```

### Linting

```bash
# Run ruff
ruff check src/ tests/

# Run black
black --check src/ tests/

# Auto-fix with black
black src/ tests/
```

---

## 🔧 Environment

### Setup

```bash
# Create virtual environment
python3 -m venv venv

# Activate
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Create .env file
cp .env.example .env
```

### Environment Variables

```bash
# Set MLflow tracking URI
export MLFLOW_TRACKING_URI=http://localhost:5000

# Set API host/port
export API_HOST=0.0.0.0
export API_PORT=8000

# Load from .env file
export $(cat .env | xargs)
```

---

## 📝 Useful Aliases

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# Docker Compose
alias dc='docker-compose -f deploy/docker/docker-compose.yml'
alias dcup='docker-compose -f deploy/docker/docker-compose.yml up -d'
alias dcdown='docker-compose -f deploy/docker/docker-compose.yml down'
alias dclogs='docker-compose -f deploy/docker/docker-compose.yml logs -f'
alias dcps='docker-compose -f deploy/docker/docker-compose.yml ps'

# Kubernetes
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias klogs='kubectl logs -f'

# MLflow
alias mlflow-ui='open http://localhost:5000'
alias api-docs='open http://localhost:8000/docs'
```

---

**Quick Links:**
- [Full Documentation](./DEPLOYMENT-SUMMARY.md)
- [PostgreSQL Setup](./POSTGRESQL-MLFLOW-SETUP.md)
- [API Docs](http://localhost:8000/docs)
- [MLflow UI](http://localhost:5000)

