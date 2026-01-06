# Migration Guide: FileStore to PostgreSQL Backend

## 🎯 Why Migrate?

### Problems with FileStore (mlruns/)
- ❌ **YAML RepresenterError**: Non-serializable data causes crashes
- ❌ **Stage transitions fail**: Model promotion doesn't work reliably
- ❌ **Not production-ready**: File-based storage has limitations
- ❌ **Concurrent access issues**: Multiple processes can corrupt data

### Benefits of PostgreSQL
- ✅ **No YAML errors**: SQL database handles all data types
- ✅ **Reliable stage transitions**: Model promotion works perfectly
- ✅ **Production-ready**: Used by real companies
- ✅ **Scalable**: Handles thousands of experiments
- ✅ **Safe concurrent access**: ACID compliance

---

## 🔄 Migration Steps

### Step 1: Backup Existing Data (Optional)

If you have important experiments in `mlruns/`:

```bash
# Backup mlruns directory
tar -czf mlruns-backup-$(date +%Y%m%d).tar.gz mlruns/

# Or copy to safe location
cp -r mlruns mlruns-backup
```

### Step 2: Update Configuration

The configuration has been updated automatically:

**Before** (`src/config/config.yaml`):
```yaml
mlflow:
  tracking_uri: "mlruns"  # FileStore
  experiment_name: "heart-disease-classification"
```

**After** (`src/config/config.yaml`):
```yaml
mlflow:
  tracking_uri: "http://localhost:5000"  # PostgreSQL-backed server
  experiment_name: "heart-disease-classification"
```

### Step 3: Start PostgreSQL + MLflow

```bash
# Use the new setup script
./scripts/setup-postgresql-mlflow.sh
```

This will:
1. Start PostgreSQL container
2. Start MLflow server with PostgreSQL backend
3. Verify both services are healthy

### Step 4: Retrain Models

```bash
# Set tracking URI
export MLFLOW_TRACKING_URI=http://localhost:5000

# Train models (they will be logged to PostgreSQL)
python src/models/train.py
```

### Step 5: Verify Migration

```bash
# Check MLflow UI
open http://localhost:5000

# You should see:
# - New experiments in PostgreSQL
# - Models registered successfully
# - No YAML errors!
```

---

## 📝 Updated Scripts

### Deprecated Scripts (Still work but show warnings)

These scripts now show deprecation warnings:

1. **`scripts/setup_mlflow.sh`**
   - Old: Started FileStore-based MLflow
   - Now: Redirects to PostgreSQL setup

2. **`scripts/start-mlflow.sh`**
   - Old: Started FileStore MLflow UI
   - Now: Shows deprecation warning

3. **`scripts/start_mlflow_ui.sh`**
   - Old: Started FileStore MLflow UI
   - Now: Shows deprecation warning

### New Recommended Scripts

Use these instead:

1. **`scripts/setup-postgresql-mlflow.sh`** ⭐
   - Starts PostgreSQL + MLflow
   - Verifies health
   - Shows access URLs

2. **Docker Compose** ⭐
   ```bash
   docker-compose -f deploy/docker/docker-compose.yml up -d
   ```

---

## 🔧 Environment Variables

### Old Way (FileStore)
```bash
# No environment variable needed
# MLflow used local mlruns/ directory
```

### New Way (PostgreSQL)
```bash
# Option 1: Use HTTP endpoint (recommended)
export MLFLOW_TRACKING_URI=http://localhost:5000

# Option 2: Direct PostgreSQL connection (advanced)
export MLFLOW_TRACKING_URI=postgresql://mlflow:mlflow@localhost:5432/mlflow
```

---

## 🐳 Docker Compose Changes

The `docker-compose.yml` now includes:

```yaml
services:
  postgres:
    image: postgres:14-alpine
    environment:
      POSTGRES_USER: mlflow
      POSTGRES_PASSWORD: mlflow
      POSTGRES_DB: mlflow
    ports:
      - "5432:5432"

  mlflow:
    image: ghcr.io/mlflow/mlflow:v2.9.2
    command: >
      mlflow server
      --backend-store-uri postgresql://mlflow:mlflow@postgres:5432/mlflow
      --default-artifact-root /mlruns
      --host 0.0.0.0
      --port 5000
    ports:
      - "5000:5000"
    depends_on:
      - postgres
```

---

## 🧪 Testing the Migration

### Test 1: Train Models
```bash
export MLFLOW_TRACKING_URI=http://localhost:5000
python src/models/train.py
```

**Expected**: No YAML errors, models logged successfully

### Test 2: Check MLflow UI
```bash
open http://localhost:5000
```

**Expected**: See experiments and registered models

### Test 3: Promote Model
```bash
python scripts/promote-model.py --auto
```

**Expected**: Model promoted without errors

### Test 4: API Prediction
```bash
docker-compose -f deploy/docker/docker-compose.yml up -d api

curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"age":63,"sex":1,"cp":3,"trestbps":145,"chol":233,"fbs":1,"restecg":0,"thalach":150,"exang":0,"oldpeak":2.3,"slope":0,"ca":0,"thal":1}'
```

**Expected**: Successful prediction

---

## 🔍 Troubleshooting

### Issue: "Connection refused" to PostgreSQL

```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# Start PostgreSQL
docker-compose -f deploy/docker/docker-compose.yml up -d postgres

# Check logs
docker logs mlflow-postgres
```

### Issue: MLflow can't connect to PostgreSQL

```bash
# Verify PostgreSQL is ready
docker exec mlflow-postgres pg_isready -U mlflow

# Restart MLflow
docker-compose -f deploy/docker/docker-compose.yml restart mlflow
```

### Issue: Old mlruns/ data not visible

This is expected! PostgreSQL is a fresh start. Your old data is still in `mlruns/` backup.

To view old experiments:
```bash
# Temporarily start FileStore MLflow on different port
mlflow ui --backend-store-uri mlruns/ --port 5001
```

---

## 📊 Comparison

| Feature | FileStore (Old) | PostgreSQL (New) |
|---------|----------------|------------------|
| YAML Errors | ❌ Common | ✅ Never |
| Stage Transitions | ❌ Unreliable | ✅ Perfect |
| Production Ready | ❌ No | ✅ Yes |
| Concurrent Access | ❌ Risky | ✅ Safe |
| Scalability | ❌ Limited | ✅ Excellent |
| Setup Complexity | ✅ Simple | ⚠️ Moderate |

---

## ✅ Migration Checklist

- [ ] Backup existing `mlruns/` directory (if needed)
- [ ] Start PostgreSQL + MLflow: `./scripts/setup-postgresql-mlflow.sh`
- [ ] Update environment: `export MLFLOW_TRACKING_URI=http://localhost:5000`
- [ ] Retrain models: `python src/models/train.py`
- [ ] Verify in MLflow UI: `http://localhost:5000`
- [ ] Test model promotion: `python scripts/promote-model.py --auto`
- [ ] Test API: `docker-compose -f deploy/docker/docker-compose.yml up -d api`
- [ ] Update CI/CD (already done in Jenkinsfile)

---

**Migration Complete! 🎉**

You're now using a production-ready PostgreSQL backend with no YAML errors!

