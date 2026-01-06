# 🏆 Model Promotion Workflow

This document explains how model promotion works in the CI/CD pipeline and how to manually promote models.

---

## 📋 Overview

After training, the best model is automatically:
1. ✅ **Registered** in MLflow Model Registry
2. ✅ **Tagged** with `best_model=true` and `roc_auc=<score>`
3. 🤖 **Auto-promoted** to Production stage (via Jenkins pipeline)

---

## 🔄 Automated Promotion (Jenkins Pipeline)

### How It Works

The Jenkins pipeline includes a **"Promote Best Model"** stage that:

1. Lists all registered models
2. Finds the model tagged with `best_model=true`
3. Automatically promotes it to Production stage
4. Shows the final model registry status

### Pipeline Flow

```
Train Models
    ↓
Promote Best Model (NEW!)
    ↓
Build Docker Image
    ↓
Deploy to Kubernetes
```

### What You'll See

```bash
========================================
📊 MLflow Model Registry - Before Promotion
========================================

📋 Registered Models:
📦 heart-disease-logistic_regression
   📌 Version 2 - Stage: None
      Tag: best_model = true
      Tag: roc_auc = 0.9665

========================================
🏆 Auto-Promoting Best Model
========================================

🔍 Searching for best model...
✅ Found best model: heart-disease-logistic_regression v2 (ROC-AUC: 0.9665)
🔍 Looking for model: heart-disease-logistic_regression
✅ Found version 2
   Current stage: None

🚀 Promoting version 2 to Production...
✅ Successfully promoted heart-disease-logistic_regression v2 to Production!

========================================
📊 MLflow Model Registry - After Promotion
========================================

📦 heart-disease-logistic_regression
   🏆 Version 2 - Stage: Production
      Tag: best_model = true
      Tag: roc_auc = 0.9665
```

---

## 🛠️ Manual Promotion

If auto-promotion fails or you want to promote manually:

### Option 1: Auto-Promote Best Model

```bash
# Automatically find and promote the best model
python scripts/promote-model.py --auto
```

### Option 2: Promote Specific Model

```bash
# Promote latest version
python scripts/promote-model.py heart-disease-logistic_regression

# Promote specific version
python scripts/promote-model.py heart-disease-logistic_regression 2
```

### Option 3: Use MLflow UI

1. Access MLflow UI: http://localhost:5001
2. Click **"Models"** tab
3. Click your model name
4. Click the version number
5. Change **"Stage"** dropdown to **"Production"**
6. Click **"Save"**

---

## 📊 Check Model Status

### List All Models

```bash
python scripts/promote-model.py --list
```

**Output:**
```
📋 Registered Models:
================================================================================

📦 heart-disease-logistic_regression
   🏆 Version 2 - Stage: Production
      Tag: best_model = true
      Tag: roc_auc = 0.9665

📦 heart-disease-random_forest
   📌 Version 1 - Stage: None
      Tag: roc_auc = 0.9512
```

---

## 🔍 How Best Model is Selected

The training script (`src/models/train.py`) automatically:

1. Trains multiple models (Logistic Regression, Random Forest, etc.)
2. Compares them using ROC-AUC score
3. Selects the best performing model
4. Tags it with:
   - `best_model = true`
   - `roc_auc = <score>`
5. Attempts to promote to Production (may fail due to MLflow bug)

---

## ⚠️ Known Issue: RepresentationError

**Issue**: MLflow's automatic stage transition sometimes fails with `RepresentationError`

**Impact**: Models are registered ✅ and tagged ✅, but auto-promotion may fail ❌

**Solution**: The Jenkins pipeline now handles this automatically using the promotion script!

**Fallback**: If pipeline promotion fails, manually run:
```bash
python scripts/promote-model.py --auto
```

See [MLFLOW-WORKAROUND.md](../MLFLOW-WORKAROUND.md) for details.

---

## 🚀 Complete Workflow

### Via Jenkins (Recommended)

1. **Trigger Jenkins build** (manual or via webhook)
2. **Pipeline runs**:
   - Downloads data
   - Trains models
   - **Auto-promotes best model** ✨
   - Builds Docker image
   - Deploys to Kubernetes
3. **Check results** in Jenkins console output
4. **Verify** in MLflow UI

### Manual Training + Promotion

```bash
# 1. Train models
python src/models/train.py

# 2. Check which model won
python scripts/promote-model.py --list

# 3. Auto-promote best model
python scripts/promote-model.py --auto

# 4. Verify
python scripts/promote-model.py --list
```

---

## 📁 Related Files

- **Jenkinsfile** - Pipeline with auto-promotion stage
- **scripts/promote-model.py** - Promotion script
- **src/models/train.py** - Training script with tagging
- **MLFLOW-WORKAROUND.md** - Detailed workaround guide

---

## 💡 Tips

1. **Always check the Jenkins console output** to see which model was promoted
2. **Use `--list` frequently** to check model registry status
3. **Use `--auto`** to let the script find and promote the best model
4. **Check MLflow UI** for detailed model information and metrics
5. **If promotion fails**, the pipeline continues - you can promote manually later

---

## ✅ Summary

- ✅ **Automated promotion** in Jenkins pipeline
- ✅ **Manual promotion** via script or UI
- ✅ **Best model tagging** for easy identification
- ✅ **Fallback options** if auto-promotion fails
- ✅ **Clear visibility** in pipeline output

Your models are automatically promoted to Production! 🎉

