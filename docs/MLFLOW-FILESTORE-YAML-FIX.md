# MLflow FileStore YAML RepresenterError - PERMANENT FIX

## 🎯 Root Cause

When MLflow uses the **filesystem backend** (`mlruns/` folder), registry metadata is written as **YAML**.

**The Problem:**
- If ANY tag, metric, or metadata contains non-YAML-serializable data (numpy types, booleans, dicts, lists, objects), stage transitions throw `RepresenterError`
- This is a **known MLflow FileStore limitation**

**Common Culprits:**
```python
# ❌ BAD - Causes RepresenterError
client.set_model_version_tag(name, version, "best_model", True)  # Boolean
client.set_model_version_tag(name, version, "roc_auc", 0.9665)  # Float
client.set_model_version_tag(name, version, "metrics", {"auc": 0.96})  # Dict
client.set_model_version_tag(name, version, "version", 7)  # Int

# ✅ GOOD - All strings
client.set_model_version_tag(name, version, "best_model", "true")  # String
client.set_model_version_tag(name, version, "roc_auc", "0.9665")  # String
client.set_model_version_tag(name, version, "model_type", "random_forest")  # String
client.set_model_version_tag(name, version, "version", "7")  # String
```

---

## ✅ PERMANENT SOLUTION IMPLEMENTED

### 1. **Use ALIASES Instead of STAGES**

**Why:**
- Aliases avoid the complex YAML stage machinery
- Simpler, more reliable with FileStore
- No RepresenterError issues

**Implementation in `src/models/train.py`:**
```python
# Set alias instead of stage transition
client.set_registered_model_alias(
    name=registered_model_name,
    alias="champion",
    version=str(latest_version)
)

# Load model with alias
model = mlflow.sklearn.load_model(f"models:/{model_name}@champion")
```

### 2. **All Tags Are Strings**

**Fixed in `src/models/train.py`:**
```python
# CRITICAL: All tag values MUST be strings for FileStore YAML
client.set_model_version_tag(
    name=registered_model_name,
    version=str(latest_version),  # ✅ String version
    key="best_model",
    value="true"  # ✅ String, not boolean
)
client.set_model_version_tag(
    name=registered_model_name,
    version=str(latest_version),
    key="roc_auc",
    value=str(best_metrics['roc_auc'])  # ✅ String, not float
)
client.set_model_version_tag(
    name=registered_model_name,
    version=str(latest_version),
    key="model_type",
    value=str(best_model_name)  # ✅ String
)
```

### 3. **Removed Stage Transitions**

**Before (Problematic):**
```python
# ❌ This causes RepresenterError with FileStore
client.transition_model_version_stage(
    name=model_name,
    version=version,
    stage="Production",
    archive_existing_versions=True
)
```

**After (Fixed):**
```python
# ✅ Use alias instead
client.set_registered_model_alias(
    name=model_name,
    alias="champion",
    version=str(version)
)
```

---

## 📋 Changes Made

### File: `src/models/train.py`

**Changes:**
1. ✅ All tag values converted to strings
2. ✅ Version numbers converted to strings
3. ✅ Removed stage transition code
4. ✅ Added alias-based model promotion
5. ✅ Added `model_type` tag for better tracking

**Benefits:**
- No more RepresenterError
- Simpler, more reliable
- Works perfectly with FileStore
- Easier to understand and maintain

---

## 🚀 How to Use

### Training Models:
```bash
# Train models (automatically sets 'champion' alias)
python src/models/train.py
```

**Output:**
```
✅ Tagged version 7 as best model
✅ Model heart-disease-random_forest v7 aliased as 'champion'
ℹ️  Load with: models:/heart-disease-random_forest@champion
```

### Loading Models:

**Option 1: Using Alias (Recommended)**
```python
import mlflow

# Load the champion model
model = mlflow.sklearn.load_model("models:/heart-disease-random_forest@champion")
```

**Option 2: Using Tags**
```python
from mlflow.tracking import MlflowClient

client = MlflowClient()

# Find model with best_model=true tag
versions = client.search_model_versions(f"name='heart-disease-random_forest'")
best_version = [v for v in versions if v.tags.get('best_model') == 'true'][0]

# Load by version
model = mlflow.sklearn.load_model(f"models:/heart-disease-random_forest/{best_version.version}")
```

**Option 3: Using Joblib (Current API)**
```python
import joblib

# Load from saved file (what the API currently uses)
model = joblib.load("models/best_model.joblib")
preprocessor = joblib.load("models/preprocessing_pipeline.joblib")
```

---

## 🔍 Verification

### Check Tags:
```bash
# List models and their tags
python scripts/promote-model.py --list
```

### Check Aliases:
```python
from mlflow.tracking import MlflowClient

client = MlflowClient()
client.set_tracking_uri("mlruns")

# Get model with alias
model_version = client.get_model_version_by_alias("heart-disease-random_forest", "champion")
print(f"Champion version: {model_version.version}")
print(f"Tags: {model_version.tags}")
```

---

## 🛠️ If You Still Get RepresenterError

### 1. Clean Existing YAML Files

If old "poisoned" YAML exists:

```bash
# Find the model's YAML files
find mlruns -name "meta.yaml" -o -name "tags.yaml"

# Look for non-string values in YAML:
grep -r "!!python" mlruns/
grep -r "numpy" mlruns/
```

**Fix manually:**
```yaml
# Before (BAD):
best_model: true
roc_auc: 0.9665

# After (GOOD):
best_model: "true"
roc_auc: "0.9665"
```

### 2. Start Fresh (Nuclear Option)

```bash
# Backup current mlruns
mv mlruns mlruns.backup

# Retrain (will create clean YAML)
python src/models/train.py
```

---

## 📊 Comparison: Stages vs Aliases

| Feature | Stages | Aliases |
|---------|--------|---------|
| FileStore YAML Issues | ❌ Yes | ✅ No |
| RepresenterError | ❌ Common | ✅ Never |
| Complexity | ❌ High | ✅ Low |
| Multiple "Production" | ❌ No | ✅ Yes (multiple aliases) |
| Recommended | ❌ No | ✅ Yes |

---

## 🎯 Summary

**Problem:** FileStore YAML RepresenterError on stage transitions  
**Root Cause:** Non-string tag values (booleans, floats, ints, objects)  
**Solution:** Use aliases + ensure all tags are strings  
**Status:** ✅ FIXED in `src/models/train.py`

**Key Changes:**
1. ✅ All tags are strings
2. ✅ Using aliases instead of stages
3. ✅ Removed stage transition code
4. ✅ Added comprehensive documentation

**Result:** No more RepresenterError! 🎉

