# 🚨 Model Promotion Not Working - Complete Fix

## 🐛 The Problem

You're running `python scripts/promote-model.py --auto` but getting:
```
❌ No models found in registry
```

---

## 🎯 Root Cause

**You haven't trained any models yet!**

The promotion script can't find models because:
1. ❌ No training has been run
2. ❌ `mlruns/` directory is empty
3. ❌ No models registered in MLflow
4. ❌ Nothing to promote

**The workflow is:**
```
Train Models → Register in MLflow → Promote to Production → Deploy
     ↑
   YOU ARE HERE (skipped this step!)
```

---

## ✅ Complete Solution

### Step 1: Train Models First

**Option A: Automated Script (Recommended)**

```bash
cd ~/Documents/mlops-assignment-1/heart-disease-mlops

# Train and register models
./scripts/train-and-register.sh
```

**Option B: Manual Training**

```bash
# 1. Start MLflow server
mlflow server \
    --backend-store-uri sqlite:///mlflow.db \
    --default-artifact-root ./mlruns \
    --host 0.0.0.0 \
    --port 5000 &

# 2. Wait for server to start
sleep 5

# 3. Set tracking URI
export MLFLOW_TRACKING_URI=http://localhost:5000

# 4. Run training
python scripts/train.py

# 5. Verify models are registered
python scripts/promote-model.py --list
```

### Step 2: Promote Model

After training completes:

```bash
# Automatic promotion (promotes best model by ROC-AUC)
python scripts/promote-model.py --auto

# OR manual promotion
python scripts/promote-model.py --list
python scripts/promote-model.py --model heart-disease-random-forest --version 1
```

### Step 3: Verify Promotion

```bash
# Check model status
python scripts/promote-model.py --list

# Should show:
# Model: heart-disease-random-forest
#   Version 1: Production ✅
```

---

## 🔍 Verification Steps

### 1. Check if MLflow Server is Running

```bash
# Check if port 5000 is in use
lsof -i :5000

# Should show mlflow process
# If not, start it:
mlflow server --backend-store-uri sqlite:///mlflow.db --host 0.0.0.0 --port 5000 &
```

### 2. Check if Models Exist

```bash
# Check mlruns directory
ls -la mlruns/

# Should show experiment directories (0, 1, 2, etc.)
# If empty, no training has been run!

# Check models directory
ls -la mlruns/models/

# Should show registered models
```

### 3. Check MLflow UI

```bash
# Access MLflow UI
# http://localhost:5000

# Check:
# - Experiments tab: Should show runs
# - Models tab: Should show registered models
```

### 4. Check Training Logs

```bash
# If training failed, check logs
cat /tmp/mlflow.log

# Or run training with verbose output
python scripts/train.py
```

---

## 🛠️ Troubleshooting

### Issue 1: "No models found in registry"

**Cause:** No training has been run

**Fix:**
```bash
# Run training first!
./scripts/train-and-register.sh

# OR
python scripts/train.py
```

### Issue 2: "MLflow server not running"

**Cause:** MLflow tracking server is not started

**Fix:**
```bash
# Start MLflow server
mlflow server \
    --backend-store-uri sqlite:///mlflow.db \
    --default-artifact-root ./mlruns \
    --host 0.0.0.0 \
    --port 5000 &

# Verify it's running
lsof -i :5000
```

### Issue 3: "Training fails with import errors"

**Cause:** Missing dependencies

**Fix:**
```bash
# Install dependencies
pip install -r requirements.txt

# Verify installation
python -c "import mlflow, sklearn, pandas, numpy"
```

### Issue 4: "Model registered but promotion fails"

**Cause:** Stage transition not supported in filesystem backend

**Fix:**
```bash
# Manual promotion in MLflow UI:
# 1. Visit http://localhost:5000
# 2. Go to Models tab
# 3. Click on the model
# 4. Click on version
# 5. Change Stage to "Production"

# OR use tags instead:
python scripts/promote-model.py --auto
# This tags the model as "best_model=true"
```

### Issue 5: "Pydantic warning about model_name"

**Cause:** Pydantic namespace conflict (harmless warning)

**Fix:** This is just a warning, not an error. You can ignore it or fix it:

```python
# In the code that defines the model
class Config:
    protected_namespaces = ()
```

---

## 📋 Complete Workflow

### First Time Setup

```bash
# 1. Clone repository
cd ~/Documents/mlops-assignment-1/heart-disease-mlops

# 2. Install dependencies
pip install -r requirements.txt

# 3. Download data (if needed)
python scripts/download_data.py

# 4. Start MLflow server
mlflow server --backend-store-uri sqlite:///mlflow.db --host 0.0.0.0 --port 5000 &

# 5. Train models
python scripts/train.py

# 6. Promote best model
python scripts/promote-model.py --auto

# 7. Build Docker image
docker build -t heart-disease-api:latest .

# 8. Deploy to Kubernetes
kubectl apply -f deploy/k8s/
```

### Subsequent Runs

```bash
# Just run the complete workflow
./scripts/complete-ml-workflow.sh
```

---

## 🎓 Understanding the Workflow

### 1. Training Phase
- Trains multiple models (Logistic Regression, Random Forest)
- Logs metrics to MLflow (accuracy, precision, recall, ROC-AUC)
- Registers models in MLflow Model Registry
- Saves artifacts (model files, preprocessor, plots)

### 2. Promotion Phase
- Finds best model by ROC-AUC score
- Tags model as "best_model=true"
- Transitions model to "Production" stage
- Makes model available for deployment

### 3. Deployment Phase
- Builds Docker image with Production model
- Deploys to Kubernetes
- Exposes API endpoint
- Monitors with Prometheus/Grafana

---

## ✅ Success Checklist

- [ ] MLflow server running on port 5000
- [ ] Training completed successfully
- [ ] Models visible in MLflow UI (Models tab)
- [ ] `python scripts/promote-model.py --list` shows models
- [ ] Best model promoted to Production
- [ ] Docker image built with latest model
- [ ] Deployed to Kubernetes
- [ ] API accessible and working

---

## 📊 Expected Output

### After Training

```bash
$ python scripts/promote-model.py --list

📋 Registered Models:
================================================================================

Model: heart-disease-logistic-regression
  Latest Version: 1
  Stage: None
  ROC-AUC: 0.8234

Model: heart-disease-random-forest
  Latest Version: 1
  Stage: None
  ROC-AUC: 0.8756
```

### After Promotion

```bash
$ python scripts/promote-model.py --auto

🔍 Searching for best model...
✅ Best model: heart-disease-random-forest (v1)
   ROC-AUC: 0.8756
🚀 Promoting to Production...
✅ Model promoted successfully!
```

---

## 🚀 Quick Commands

```bash
# Train models
./scripts/train-and-register.sh

# List models
python scripts/promote-model.py --list

# Auto-promote best model
python scripts/promote-model.py --auto

# Complete workflow
./scripts/complete-ml-workflow.sh

# Check MLflow UI
open http://localhost:5000
```

---

**Remember:** You MUST train models before you can promote them! 🎯

