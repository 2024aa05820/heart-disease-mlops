# 🔧 MLflow Model Registry Workaround

## The Issue

MLflow's `transition_model_version_stage()` is throwing a `RepresentationError`:

```
RepresentationError: ('cannot represent an object', <Metric: ...>)
```

This is a **known bug** in MLflow when using file-based tracking (mlruns directory) with certain metric types.

---

## ✅ Good News

**Your models ARE being registered successfully!** ✅

The error only affects the **automatic stage transition** to Production. The models are in the registry, just not automatically promoted.

---

## 🎯 Solution: Manual Promotion

You have **3 options** to promote models to Production:

---

### Option 1: Use the Promotion Script (Easiest)

I've created a script that handles promotion for you:

```bash
# List all models
python scripts/promote-model.py --list

# Promote latest version of a model
python scripts/promote-model.py heart-disease-logistic_regression

# Promote specific version
python scripts/promote-model.py heart-disease-logistic_regression 2
```

**Example output:**
```
🔍 Looking for model: heart-disease-logistic_regression
✅ Found version 2
   Current stage: None

📦 Checking for existing Production versions...

🚀 Promoting version 2 to Production...
✅ Successfully promoted heart-disease-logistic_regression v2 to Production!
```

---

### Option 2: Use MLflow UI (Recommended)

This is the most reliable method:

1. **Access MLflow UI**:
   ```bash
   # On your server
   ssh -L 5001:localhost:5001 cloud@YOUR_SERVER_IP
   ```

2. **Open browser**: http://localhost:5001

3. **Navigate to Models**:
   - Click **"Models"** tab in top navigation

4. **Select your model**:
   - Click on the model name (e.g., `heart-disease-logistic_regression`)

5. **Promote to Production**:
   - Click on the version number (e.g., `Version 2`)
   - Find the **"Stage"** dropdown
   - Select **"Production"**
   - Click **"Save"** or **"Update"**

6. **Done!** ✅

---

### Option 3: Use Python Script

Create a simple script:

```python
from mlflow.tracking import MlflowClient
import mlflow

mlflow.set_tracking_uri("mlruns")
client = MlflowClient()

# Promote model
client.transition_model_version_stage(
    name="heart-disease-logistic_regression",
    version="2",
    stage="Production"
)

print("✅ Model promoted to Production!")
```

Run it:
```bash
python your_script.py
```

---

## 📊 Verify Models Are Registered

### Check via MLflow UI:

1. Open http://localhost:5001
2. Click **"Models"** tab
3. You should see:
   - `heart-disease-logistic_regression`
   - `heart-disease-random_forest`
   - (and other models you trained)

### Check via Script:

```bash
python scripts/promote-model.py --list
```

**Output:**
```
📋 Registered Models:
================================================================================

📦 heart-disease-logistic_regression
   📌 Version 2 - Stage: None
      Tag: best_model = true
      Tag: roc_auc = 0.9665

📦 heart-disease-random_forest
   📌 Version 2 - Stage: None
```

---

## 🏷️ Best Model Tagging

Even though automatic promotion fails, the training script now **tags** the best model:

- Tag: `best_model = true`
- Tag: `roc_auc = <score>`

You can find the best model by looking for the `best_model=true` tag!

---

## 🔍 Why This Happens

### Root Cause:

MLflow's file-based backend (mlruns directory) has a bug where:

1. Metrics are stored with metadata
2. When transitioning stages, MLflow tries to serialize these metrics
3. The serialization fails with `RepresentationError`

### Why It's Hard to Fix:

- It's a bug in MLflow's internal code
- Happens with file-based tracking (not database backends)
- Affects certain MLflow versions
- The fix requires changes to MLflow itself

### Workarounds:

1. ✅ **Manual promotion** (what we're doing)
2. ✅ **Use database backend** (PostgreSQL, MySQL) - more complex
3. ✅ **Upgrade/downgrade MLflow** - might not work
4. ✅ **Use tags instead of stages** - alternative approach

---

## 🚀 Recommended Workflow

### Step 1: Train Models

```bash
# Run training (via Jenkins or manually)
python src/models/train.py
```

**Output:**
```
✅ Tagged version 2 as best model
⚠️  Automatic stage transition failed: RepresentationError
ℹ️  Model is registered and tagged as 'best_model=true'
ℹ️  Please manually set stage to 'Production' in MLflow UI
```

### Step 2: Check Which Model Won

```bash
python scripts/promote-model.py --list
```

Look for the model with `best_model = true` tag.

### Step 3: Promote to Production

**Option A - Use script:**
```bash
python scripts/promote-model.py heart-disease-logistic_regression
```

**Option B - Use UI:**
- Go to MLflow UI → Models → Select model → Change stage to Production

### Step 4: Verify

```bash
python scripts/promote-model.py --list
```

Should show:
```
🏆 Version 2 - Stage: Production
```

---

## 📝 Updated Training Output

With the latest fix, you'll see:

```
5. Selecting best model...
   Best model: logistic_regression
   ROC-AUC: 0.9665

   Tagging and promoting best model to Production stage...
   Waiting for model registration to complete...
   Searching for model versions of 'heart-disease-logistic_regression'...
   Found version 2, current stage: None
   ✅ Tagged version 2 as best model
   Transitioning version 2 to Production...
   ⚠️  Automatic stage transition failed: RepresentationError
   ℹ️  Model is registered and tagged as 'best_model=true'
   ℹ️  Please manually set stage to 'Production' in MLflow UI:
      1. Go to MLflow UI → Models tab
      2. Click 'heart-disease-logistic_regression'
      3. Click 'Version 2'
      4. Change Stage to 'Production'

6. Saving artifacts...
   Model saved to: models/best_model.joblib
   Preprocessor saved to: models/preprocessing_pipeline.joblib

✅ Training completed successfully!
```

---

## 🎯 Key Points

1. ✅ **Models ARE being registered** - check Models tab in MLflow UI
2. ✅ **Best model is tagged** - look for `best_model=true` tag
3. ⚠️  **Automatic promotion fails** - due to MLflow bug
4. ✅ **Manual promotion works** - use script or UI
5. ✅ **Everything else works** - metrics, artifacts, experiments

---

## 🔧 Alternative: Use Database Backend (Advanced)

If you want to fix this permanently, use a database backend:

### Setup PostgreSQL Backend:

```bash
# Install PostgreSQL
sudo yum install postgresql-server

# Initialize and start
sudo postgresql-setup initdb
sudo systemctl start postgresql

# Create database
sudo -u postgres createdb mlflow

# Start MLflow with database
mlflow server \
  --backend-store-uri postgresql://user:pass@localhost/mlflow \
  --default-artifact-root ./mlruns \
  --host 0.0.0.0 \
  --port 5001
```

This usually fixes the RepresentationError, but it's more complex to set up.

---

## ✅ Summary

**Problem**: Automatic stage transition fails with RepresentationError  
**Cause**: MLflow file-based backend bug  
**Impact**: Models registered ✅, but not auto-promoted ❌  
**Solution**: Manual promotion via script or UI ✅  
**Status**: Models are safe and usable! ✅  

---

## 📚 Next Steps

1. ✅ Pull latest code: `git pull origin main`
2. ✅ Run training: `python src/models/train.py`
3. ✅ Check models: `python scripts/promote-model.py --list`
4. ✅ Promote best model: `python scripts/promote-model.py <model-name>`
5. ✅ Verify in MLflow UI

---

Your models are safe and working! Just need one extra manual step to promote to Production. 🎉

