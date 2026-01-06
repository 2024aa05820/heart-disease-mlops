# 🔍 MLflow Model Cleanup vs. Promotion Issue

## ❓ Question: Will Cleaning Old Models Fix the Promotion Issue?

**Short Answer**: ❌ **No, cleaning old models will NOT fix the RepresentationError.**

---

## 🐛 Understanding the RepresentationError

### What Causes It?

The `RepresentationError` is caused by:

1. **MLflow's internal bug** in file-based storage (mlruns directory)
2. **Metric serialization issue** when transitioning model stages
3. **How MLflow handles Python objects** during stage transitions

### What Does NOT Cause It?

- ❌ Number of model versions
- ❌ Number of registered models
- ❌ Old or archived models
- ❌ Model size or complexity
- ❌ Disk space

---

## 🧹 Model Cleanup: What It Does

### Purpose

Cleanup is useful for:
- ✅ Reducing clutter in MLflow UI
- ✅ Saving disk space
- ✅ Keeping only relevant model versions
- ✅ Improving UI performance

### What It Does NOT Do

- ❌ Fix RepresentationError
- ❌ Fix stage transition issues
- ❌ Improve model promotion success rate

---

## ✅ Actual Solutions to RepresentationError

### Solution 1: Enhanced Promotion Script (Implemented)

The updated `promote-model.py` now tries multiple methods:

```python
# Method 1: Standard API with archive_existing_versions=True
client.transition_model_version_stage(
    name=model_name,
    version=target_version,
    stage="Production",
    archive_existing_versions=True
)

# Method 2: If Method 1 fails, try with archive_existing_versions=False
client.transition_model_version_stage(
    name=model_name,
    version=target_version,
    stage="Production",
    archive_existing_versions=False
)

# Method 3: Manual promotion via MLflow UI (most reliable)
```

### Solution 2: Use MLflow UI (Most Reliable)

The MLflow UI uses a different code path that doesn't trigger the bug:

```bash
# 1. Access MLflow UI
ssh -L 5001:localhost:5001 cloud@YOUR_SERVER_IP

# 2. Open browser: http://localhost:5001
# 3. Navigate to Models → Select model → Change stage
```

### Solution 3: Use Database Backend (Permanent Fix)

Replace file-based storage with PostgreSQL/MySQL:

```bash
# Install PostgreSQL
sudo yum install postgresql-server

# Start MLflow with database
mlflow server \
  --backend-store-uri postgresql://user:pass@localhost/mlflow \
  --default-artifact-root ./mlruns \
  --host 0.0.0.0 \
  --port 5001
```

This usually fixes the RepresentationError permanently.

---

## 🛠️ Using the Cleanup Feature

### When to Use Cleanup

Use cleanup when you want to:
- Remove old experimental versions
- Free up disk space
- Simplify the model registry view
- Keep only recent versions

### How to Use

```bash
# List all models first
python scripts/promote-model.py --list

# Cleanup all models (keeps last 3 versions)
python scripts/promote-model.py --cleanup

# Cleanup specific model (keeps last 5 versions)
python scripts/promote-model.py --cleanup heart-disease-logistic_regression 5

# Cleanup with confirmation
python scripts/promote-model.py --cleanup
# Prompts: ⚠️  Delete old versions of ALL models (keeping last 3)? [y/N]:
```

### What Gets Deleted

- ❌ Old versions (beyond keep_last count)
- ✅ Production versions are ALWAYS kept
- ✅ Recent versions are kept (based on keep_last)

### Example

Before cleanup:
```
📦 heart-disease-logistic_regression
   🏆 Version 5 - Stage: Production
   📌 Version 4 - Stage: None
   📌 Version 3 - Stage: None
   📌 Version 2 - Stage: None
   📌 Version 1 - Stage: None
```

After cleanup (keep_last=2):
```
📦 heart-disease-logistic_regression
   🏆 Version 5 - Stage: Production  ← Kept (Production)
   📌 Version 4 - Stage: None        ← Kept (recent)
   📌 Version 3 - Stage: None        ← Kept (recent)
   🗑️  Version 2 - Deleted
   🗑️  Version 1 - Deleted
```

---

## 📊 Recommended Workflow

### Step 1: Train Models

```bash
# Via Jenkins or manually
python src/models/train.py
```

### Step 2: Promote Best Model

```bash
# Try auto-promotion with enhanced retry logic
python scripts/promote-model.py --auto
```

### Step 3: If Auto-Promotion Fails

```bash
# Use MLflow UI (most reliable)
# Access: http://localhost:5001
# Navigate: Models → Select model → Change stage to Production
```

### Step 4: Cleanup Old Versions (Optional)

```bash
# After successful promotion, cleanup old versions
python scripts/promote-model.py --cleanup
```

---

## 🎯 Summary

| Action | Fixes RepresentationError? | Purpose |
|--------|---------------------------|---------|
| Cleanup old models | ❌ No | Free disk space, reduce clutter |
| Enhanced promotion script | ⚠️ Maybe | Tries multiple methods |
| MLflow UI promotion | ✅ Yes | Uses different code path |
| Database backend | ✅ Yes | Permanent fix |

---

## 💡 Key Takeaways

1. **Cleanup ≠ Fix**: Cleaning models won't fix the RepresentationError
2. **Use MLflow UI**: Most reliable way to promote models
3. **Enhanced script**: Now tries multiple promotion methods
4. **Cleanup is optional**: Only use it to reduce clutter, not to fix bugs
5. **Database backend**: Best long-term solution

---

## 🚀 Next Steps

1. ✅ Pull latest code (enhanced promotion script)
2. ✅ Try auto-promotion: `python scripts/promote-model.py --auto`
3. ✅ If fails, use MLflow UI for promotion
4. ✅ Optionally cleanup old versions
5. ✅ Consider database backend for permanent fix

---

Your models are safe! The RepresentationError is annoying but doesn't affect model quality or deployment. 🎉

