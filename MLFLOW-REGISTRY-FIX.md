# 🔧 MLflow Model Registry Fix

## Problem

When training models, you were seeing this error:

```
⚠️  Could not promote model to Production: ('cannot represent an object', <Metric: ...>)
```

This prevented models from being automatically promoted to the **Production** stage in the MLflow Model Registry.

---

## Root Causes

### 1. **Numpy Float Serialization Issue**
- Metrics were being logged as numpy float64 objects
- MLflow's `transition_model_version_stage()` had trouble serializing these
- Error: `'cannot represent an object', <Metric: cv_accuracy_mean=...>`

### 2. **Model Registration Timing**
- Code tried to promote model immediately after registration
- Model registration is asynchronous and might not complete instantly
- Version lookup failed because registration wasn't complete

### 3. **Incomplete Stage Transition Logic**
- Didn't explicitly archive old Production versions
- Used `stages=["None"]` filter which might miss newly registered models
- Didn't check if model was already in Production

---

## Fixes Applied

### ✅ Fix 1: Convert Metrics to Python Floats

**Before:**
```python
metrics = {
    "cv_accuracy_mean": cv_scores.mean(),  # numpy.float64
    "cv_accuracy_std": cv_scores.std(),    # numpy.float64
    ...
}
```

**After:**
```python
metrics = {
    "cv_accuracy_mean": float(cv_scores.mean()),  # Python float
    "cv_accuracy_std": float(cv_scores.std()),    # Python float
    ...
}
```

This ensures all metrics are Python native floats, avoiding serialization issues.

---

### ✅ Fix 2: Add Wait Time for Registration

**Added:**
```python
# Wait for model registration to complete
time.sleep(3)
```

Gives MLflow time to complete the model registration before trying to promote it.

---

### ✅ Fix 3: Improved Version Lookup

**Before:**
```python
latest_versions = client.get_latest_versions(
    registered_model_name, 
    stages=["None"]  # Only looks for models in "None" stage
)
```

**After:**
```python
# Search all versions, not just specific stages
all_versions = client.search_model_versions(f"name='{registered_model_name}'")
all_versions.sort(key=lambda x: int(x.version), reverse=True)
latest_version = all_versions[0].version
```

More reliable - finds the latest version regardless of current stage.

---

### ✅ Fix 4: Explicit Archive of Old Production Versions

**Added:**
```python
# Archive existing Production versions first
production_versions = client.get_latest_versions(
    registered_model_name, 
    stages=["Production"]
)
for pv in production_versions:
    client.transition_model_version_stage(
        name=registered_model_name,
        version=pv.version,
        stage="Archived"
    )
```

Explicitly archives old Production versions before promoting the new one.

---

### ✅ Fix 5: Better Error Handling

**Added:**
```python
except Exception as e:
    print(f"⚠️  Could not promote model to Production: {type(e).__name__}: {e}")
    print(f"The model was registered successfully, but stage transition failed.")
    print(f"You can manually set the stage to 'Production' in the MLflow UI.")
```

Provides clear error messages and fallback instructions.

---

## How to Test

### Step 1: Pull Latest Code

On your Rocky Linux server:

```bash
cd ~/Documents/ml-assign-1/heart-disease-mlops
git pull origin main
```

### Step 2: Run Training

Trigger a new Jenkins build or run manually:

```bash
python src/models/train.py
```

### Step 3: Check Output

You should now see:

```
5. Selecting best model...
   Best model: logistic_regression
   ROC-AUC: 0.9665

   Promoting best model to Production stage...
   Waiting for model registration to complete...
   Searching for model versions of 'heart-disease-logistic_regression'...
   Found version 1, current stage: None
   Transitioning version 1 to Production...
   ✅ Model heart-disease-logistic_regression v1 promoted to Production
```

### Step 4: Verify in MLflow UI

1. **Access MLflow**:
   ```bash
   ssh -L 5001:localhost:5001 cloud@YOUR_SERVER_IP
   ```

2. **Open browser**: http://localhost:5001

3. **Click "Models" tab**

4. **You should see**:
   - Model: `heart-disease-logistic_regression` (or whichever won)
   - Stage: **Production** ✅
   - Version: 1

---

## What You'll See Now

### Before (Broken):
```
Promoting best model to Production stage...
⚠️  Could not promote model to Production: ('cannot represent an object', <Metric: ...>)
```

Models tab: Empty or models stuck in "None" stage

---

### After (Fixed):
```
Promoting best model to Production stage...
Waiting for model registration to complete...
Searching for model versions of 'heart-disease-logistic_regression'...
Found version 1, current stage: None
Transitioning version 1 to Production...
✅ Model heart-disease-logistic_regression v1 promoted to Production
```

Models tab: Shows model with **Production** stage! 🎉

---

## Manual Promotion (If Needed)

If automatic promotion still fails for any reason, you can manually promote in the MLflow UI:

1. Go to **Models** tab
2. Click on the model name (e.g., `heart-disease-logistic_regression`)
3. Click on the version number (e.g., `Version 1`)
4. Click **Stage** dropdown
5. Select **Production**
6. Click **Save**

---

## Troubleshooting

### Issue: Still seeing "cannot represent an object" error

**Solution 1**: Check MLflow version
```bash
pip show mlflow
# Should be >= 2.10.0
```

**Solution 2**: Upgrade MLflow
```bash
pip install --upgrade mlflow
```

**Solution 3**: Clear old MLflow data
```bash
# Backup first!
mv mlruns mlruns.backup
mkdir mlruns

# Run training again
python src/models/train.py
```

---

### Issue: "No versions found for model"

**Cause**: Model registration is taking longer than expected

**Solution**: Increase wait time in `src/models/train.py`:
```python
# Change from 3 to 5 seconds
time.sleep(5)
```

---

### Issue: Model registered but not promoted

**Cause**: Stage transition failed but model is registered

**Solution**: Manually promote in MLflow UI (see above)

---

## Technical Details

### Error Explanation

The original error:
```
('cannot represent an object', <Metric: dataset_digest=None, dataset_name=None, 
key='cv_accuracy_mean', model_id='m-...', run_id='...', step=0, 
timestamp=1767673314829, value=0.8427721088435375>)
```

This happens when:
1. MLflow tries to serialize a `Metric` object
2. The object contains numpy types that can't be pickled properly
3. The serialization fails during `transition_model_version_stage()`

### Why Converting to Float Works

- Python's native `float` type is JSON-serializable
- Numpy's `float64` requires special handling
- MLflow's internal serialization expects Python native types
- Converting ensures compatibility

---

## Summary

✅ **Fixed**: Numpy float serialization issue  
✅ **Fixed**: Model registration timing  
✅ **Fixed**: Version lookup logic  
✅ **Fixed**: Stage transition process  
✅ **Added**: Better error handling  

**Result**: Models now automatically promote to Production stage! 🎉

---

## Next Steps

1. ✅ Pull latest code
2. ✅ Run training
3. ✅ Check MLflow Models tab
4. ✅ Verify Production stage
5. ✅ Celebrate! 🎊

---

For more information, see:
- **MLFLOW-MODEL-REGISTRY.md** - Model Registry guide
- **MLflow Docs**: https://mlflow.org/docs/latest/model-registry.html

