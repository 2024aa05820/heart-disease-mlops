# MLflow with PostgreSQL Backend Setup

## 🎯 Why PostgreSQL Instead of FileStore?

### The Problem with FileStore (mlruns/)
- **YAML RepresenterError**: FileStore writes metadata as YAML files
- Non-serializable data (numpy types, booleans, complex objects) causes crashes
- Stage transitions are particularly problematic
- Not production-ready

### The Solution: PostgreSQL Backend
- ✅ **No YAML issues**: Uses SQL database instead of YAML files
- ✅ **Production-ready**: Used by real companies in production
- ✅ **Scalable**: Handles thousands of experiments
- ✅ **Reliable**: ACID compliance, transactions
- ✅ **Stage transitions work perfectly**: No serialization issues

---

## 🚀 Quick Start

### Option 1: Using Docker Compose (Recommended)

```bash
# Start PostgreSQL + MLflow + API + Monitoring
docker-compose -f deploy/docker/docker-compose.yml up -d

# Check services
docker-compose -f deploy/docker/docker-compose.yml ps

# View logs
docker-compose -f deploy/docker/docker-compose.yml logs -f mlflow

# Stop services
docker-compose -f deploy/docker/docker-compose.yml down
```

**Services Started:**
- PostgreSQL: `localhost:5432`
- MLflow UI: `http://localhost:5000`
- API: `http://localhost:8000`
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3000` (admin/admin)

### Option 2: Manual Setup

```bash
# 1. Start PostgreSQL
docker run -d \
  --name mlflow-postgres \
  -e POSTGRES_USER=mlflow \
  -e POSTGRES_PASSWORD=mlflow \
  -e POSTGRES_DB=mlflow \
  -p 5432:5432 \
  postgres:14-alpine

# 2. Start MLflow Server
mlflow server \
  --backend-store-uri postgresql://mlflow:mlflow@localhost:5432/mlflow \
  --default-artifact-root ./mlruns \
  --host 0.0.0.0 \
  --port 5000
```

---

## 📊 Training Models with PostgreSQL Backend

```bash
# Set tracking URI
export MLFLOW_TRACKING_URI=http://localhost:5000

# Train models
python src/models/train.py

# Or use the old script
python scripts/train.py
```

**What happens:**
1. Models are trained with different hyperparameters
2. Experiments are logged to PostgreSQL (not YAML files!)
3. Best model is automatically registered
4. Model is aliased as "champion" (no stage transition issues!)
5. Model files saved to `models/` directory

---

## 🔧 Configuration

### Environment Variables

Create `.env` file from `.env.example`:

```bash
cp .env.example .env
```

Edit `.env`:
```bash
# MLflow with PostgreSQL
MLFLOW_TRACKING_URI=postgresql://mlflow:mlflow@localhost:5432/mlflow

# Or use HTTP endpoint
MLFLOW_TRACKING_URI=http://localhost:5000
```

### Docker Compose Configuration

See `deploy/docker/docker-compose.yml` for full configuration.

Key settings:
- PostgreSQL user/password: `mlflow/mlflow`
- MLflow backend: PostgreSQL
- Artifact storage: Local filesystem (`./mlruns`)

---

## 📈 Accessing Services

### MLflow UI
```bash
# Open in browser
open http://localhost:5000

# Or via SSH tunnel from local machine
ssh -L 5000:localhost:5000 user@server
# Then visit http://localhost:5000
```

### API Documentation
```bash
# Swagger UI
open http://localhost:8000/docs

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

### Prometheus Metrics
```bash
open http://localhost:9090
```

### Grafana Dashboards
```bash
open http://localhost:3000
# Login: admin/admin
```

---

## 🧪 Testing

### Test PostgreSQL Connection
```bash
docker exec -it mlflow-postgres psql -U mlflow -d mlflow -c "\dt"
```

### Test MLflow Server
```bash
curl http://localhost:5000/health
```

### Test API
```bash
# Health check
curl http://localhost:8000/health

# Metrics
curl http://localhost:8000/metrics
```

---

## 🔍 Troubleshooting

### PostgreSQL not starting
```bash
# Check logs
docker logs mlflow-postgres

# Restart
docker restart mlflow-postgres
```

### MLflow can't connect to PostgreSQL
```bash
# Check if PostgreSQL is ready
docker exec mlflow-postgres pg_isready -U mlflow

# Check connection string
echo $MLFLOW_TRACKING_URI
```

### Port already in use
```bash
# Find process using port 5000
lsof -i :5000

# Kill process
kill -9 <PID>
```

---

## 📚 Additional Resources

- [MLflow Documentation](https://mlflow.org/docs/latest/tracking.html#backend-stores)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

---

## ✅ Benefits Summary

| Feature | FileStore | PostgreSQL |
|---------|-----------|------------|
| YAML RepresenterError | ❌ Common | ✅ Never |
| Stage Transitions | ❌ Problematic | ✅ Works perfectly |
| Production Ready | ❌ No | ✅ Yes |
| Scalability | ❌ Limited | ✅ Excellent |
| Concurrent Access | ❌ Issues | ✅ Safe |
| Backup/Restore | ❌ Manual | ✅ Built-in |

**Recommendation:** Always use PostgreSQL backend for production MLflow deployments!

