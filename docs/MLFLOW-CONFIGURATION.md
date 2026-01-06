# MLflow Configuration Guide

## 🎯 Current Configuration

The project now uses **PostgreSQL-backed MLflow** to eliminate YAML RepresenterError issues.

---

## 📁 Configuration Files

### 1. Main Configuration: `src/config/config.yaml`

```yaml
mlflow:
  tracking_uri: "http://localhost:5000"  # PostgreSQL-backed MLflow server
  experiment_name: "heart-disease-classification"
```

**How it works:**
- Training scripts read this config
- Can be overridden by `MLFLOW_TRACKING_URI` environment variable
- Points to MLflow server (not direct PostgreSQL)

### 2. Environment Variables: `.env`

```bash
# MLflow Configuration
MLFLOW_TRACKING_URI=http://localhost:5000

# PostgreSQL Configuration
POSTGRES_USER=mlflow
POSTGRES_PASSWORD=mlflow
POSTGRES_DB=mlflow
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
```

### 3. Docker Compose: `deploy/docker/docker-compose.yml`

```yaml
services:
  postgres:
    image: postgres:14-alpine
    environment:
      POSTGRES_USER: mlflow
      POSTGRES_PASSWORD: mlflow
      POSTGRES_DB: mlflow

  mlflow:
    image: ghcr.io/mlflow/mlflow:v2.9.2
    command: >
      mlflow server
      --backend-store-uri postgresql://mlflow:mlflow@postgres:5432/mlflow
      --default-artifact-root /mlruns
      --host 0.0.0.0
      --port 5000
```

---

## 🔧 Configuration Priority

MLflow tracking URI is determined in this order (highest to lowest priority):

1. **Environment Variable** (highest priority)
   ```bash
   export MLFLOW_TRACKING_URI=http://localhost:5000
   ```

2. **Code Configuration**
   ```python
   mlflow.set_tracking_uri("http://localhost:5000")
   ```

3. **Config File** (lowest priority)
   ```yaml
   mlflow:
     tracking_uri: "http://localhost:5000"
   ```

---

## 🚀 Usage Examples

### Training Models

```python
# src/models/train.py automatically uses config.yaml
# But you can override with environment variable

# Option 1: Use config.yaml (default)
python src/models/train.py

# Option 2: Override with environment variable
export MLFLOW_TRACKING_URI=http://localhost:5000
python src/models/train.py

# Option 3: Override in code
import mlflow
mlflow.set_tracking_uri("http://localhost:5000")
```

### API Usage

```python
# src/api/main.py loads models from local files
# MLflow tracking URI not needed for serving
# Models are already saved to models/ directory
```

### Scripts

```bash
# All scripts respect MLFLOW_TRACKING_URI environment variable

# Promote model
export MLFLOW_TRACKING_URI=http://localhost:5000
python scripts/promote-model.py --auto

# Check MLflow status
python scripts/check_mlflow_status.py
```

---

## 🐳 Docker Configuration

### Local Development

```bash
# Start PostgreSQL + MLflow
docker-compose -f deploy/docker/docker-compose.yml up -d postgres mlflow

# Set tracking URI
export MLFLOW_TRACKING_URI=http://localhost:5000

# Train models
python src/models/train.py
```

### Production Deployment

```bash
# Start all services
docker-compose -f deploy/docker/docker-compose.yml up -d

# Services:
# - PostgreSQL: localhost:5432
# - MLflow: http://localhost:5000
# - API: http://localhost:8000
# - Prometheus: http://localhost:9090
# - Grafana: http://localhost:3000
```

---

## ☸️ Kubernetes Configuration

### ConfigMap for MLflow URI

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mlflow-config
data:
  MLFLOW_TRACKING_URI: "http://mlflow-service:5000"
```

### Deployment with ConfigMap

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: heart-disease-api
spec:
  template:
    spec:
      containers:
      - name: api
        image: heart-disease-api:latest
        env:
        - name: MLFLOW_TRACKING_URI
          valueFrom:
            configMapKeyRef:
              name: mlflow-config
              key: MLFLOW_TRACKING_URI
```

---

## 🔍 Verification

### Check Current Configuration

```bash
# Python
python -c "import mlflow; print(mlflow.get_tracking_uri())"

# Environment
echo $MLFLOW_TRACKING_URI

# Config file
cat src/config/config.yaml | grep tracking_uri
```

### Test Connection

```bash
# HTTP endpoint
curl http://localhost:5000/health

# PostgreSQL
docker exec mlflow-postgres pg_isready -U mlflow

# MLflow experiments
curl http://localhost:5000/api/2.0/mlflow/experiments/list
```

---

## 🛠️ Troubleshooting

### Issue: "Connection refused"

```bash
# Check if MLflow server is running
curl http://localhost:5000/health

# Start MLflow
docker-compose -f deploy/docker/docker-compose.yml up -d mlflow
```

### Issue: "Database connection failed"

```bash
# Check PostgreSQL
docker exec mlflow-postgres pg_isready -U mlflow

# Restart PostgreSQL
docker-compose -f deploy/docker/docker-compose.yml restart postgres
```

### Issue: "Experiments not showing"

```bash
# Check tracking URI
python -c "import mlflow; print(mlflow.get_tracking_uri())"

# Should output: http://localhost:5000
# If not, set environment variable:
export MLFLOW_TRACKING_URI=http://localhost:5000
```

---

## 📚 Related Documentation

- [PostgreSQL MLflow Setup](./POSTGRESQL-MLFLOW-SETUP.md)
- [Migration Guide](./MIGRATION-TO-POSTGRESQL.md)
- [Deployment Summary](./DEPLOYMENT-SUMMARY.md)
- [Quick Reference](./QUICK-REFERENCE.md)

---

## ✅ Best Practices

1. **Always use environment variables in production**
   ```bash
   export MLFLOW_TRACKING_URI=http://mlflow-service:5000
   ```

2. **Use config.yaml for defaults**
   - Good for local development
   - Easy to version control

3. **Never hardcode credentials**
   - Use environment variables
   - Use secrets management in production

4. **Test configuration before training**
   ```bash
   python -c "import mlflow; print(mlflow.get_tracking_uri())"
   ```

5. **Use PostgreSQL backend in production**
   - Eliminates YAML errors
   - Production-ready
   - Scalable

---

**Configuration is now clean and consistent! 🎉**

