# 🚨 Model Promotion Not Working - Quick Fix

## The Problem
```bash
$ python scripts/promote-model.py --auto
❌ No models found in registry
```

## The Cause
**You haven't trained any models yet!**

The `mlruns/` directory is empty because no training has been run.

---

## ✅ Quick Fix (2 minutes)

### Step 1: Train Models

```bash
cd ~/Documents/mlops-assignment-1/heart-disease-mlops

# Option A: Automated (recommended)
./scripts/train-and-register.sh

# Option B: Manual
mlflow server --backend-store-uri sqlite:///mlflow.db --host 0.0.0.0 --port 5000 &
export MLFLOW_TRACKING_URI=http://localhost:5000
python scripts/train.py
```

### Step 2: Verify Models Exist

```bash
python scripts/promote-model.py --list

# Should show:
# Model: heart-disease-logistic-regression
# Model: heart-disease-random-forest
```

### Step 3: Promote Best Model

```bash
python scripts/promote-model.py --auto

# Should show:
# ✅ Best model: heart-disease-random-forest (v1)
# ✅ Model promoted successfully!
```

---

## 🔍 Verification

```bash
# Check MLflow is running
lsof -i :5000

# Check models exist
ls -la mlruns/

# Check MLflow UI
open http://localhost:5000
# Go to Models tab → Should see registered models
```

---

## 📋 Complete Workflow

```
1. Train Models          → python scripts/train.py
2. Register in MLflow    → (automatic during training)
3. Promote to Production → python scripts/promote-model.py --auto
4. Build Docker Image    → docker build -t heart-disease-api:latest .
5. Deploy to K8s         → kubectl apply -f deploy/k8s/
```

**You skipped step 1!** That's why promotion fails.

---

## 🎯 One-Command Solution

```bash
# Run complete workflow (train → promote → deploy)
./scripts/complete-ml-workflow.sh
```

---

## ❌ Common Mistakes

| Mistake | Fix |
|---------|-----|
| Trying to promote before training | Run `python scripts/train.py` first |
| MLflow server not running | Start with `mlflow server ...` |
| Wrong directory | `cd ~/Documents/mlops-assignment-1/heart-disease-mlops` |
| Missing dependencies | `pip install -r requirements.txt` |

---

## 📚 Detailed Guide

See: `docs/MODEL-PROMOTION-FIX.md`

---

## ✅ Success Checklist

- [ ] MLflow server running (port 5000)
- [ ] Training completed
- [ ] Models visible in `python scripts/promote-model.py --list`
- [ ] Best model promoted to Production
- [ ] Ready to deploy!

---

**TL;DR:** Run `./scripts/train-and-register.sh` first, then promotion will work! 🎯

