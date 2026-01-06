# 📦 MLflow Model Registry Guide

## 🎯 What Changed

Previously, models were only logged to MLflow **runs** but not registered to the **Model Registry**. Now they are automatically registered!

---

## ✅ What You'll See Now

### Before (What you had):
- ✅ Experiments tab: Shows runs with metrics
- ❌ Models tab: Empty (no registered models)

### After (What you'll get):
- ✅ Experiments tab: Shows runs with metrics
- ✅ **Models tab: Shows all registered models!**
- ✅ Best model automatically promoted to **Production** stage
- ✅ Model signatures and input examples
- ✅ Version history for each model

---

## 🚀 How to See the Models

### Step 1: Pull the Latest Code

On your Rocky Linux server:

```bash
cd ~/Documents/ml-assign-1/heart-disease-mlops
git pull origin main
```

### Step 2: Run a New Build in Jenkins

1. Go to Jenkins: `http://YOUR_SERVER_IP:8080`
2. Click on your pipeline: `heart-disease-mlops`
3. Click **"Build Now"**
4. Wait for the build to complete

### Step 3: Check MLflow Models Tab

1. Access MLflow UI (from your local machine):
   ```bash
   ssh -L 5001:localhost:5001 cloud@YOUR_SERVER_IP
   ```

2. Open browser: `http://localhost:5001`

3. Click on **"Models"** tab (top navigation)

4. You should now see models like:
   - `heart-disease-logistic_regression`
   - `heart-disease-random_forest`
   - `heart-disease-gradient_boosting`
   - `heart-disease-svm`
   - `heart-disease-xgboost`

5. The best model will have **"Production"** stage tag

---

## 📊 What Gets Registered

For each model trained, the following is registered:

### Model Artifacts:
- ✅ Trained model (pickle/joblib)
- ✅ Model signature (input/output schema)
- ✅ Input example (sample data)
- ✅ Model metadata

### Model Information:
- **Name**: `heart-disease-{model_name}`
  - Example: `heart-disease-random_forest`
- **Version**: Auto-incremented (1, 2, 3, ...)
- **Stage**: 
  - Best model → **Production**
  - Other models → **None**
- **Metrics**: Accuracy, ROC-AUC, Precision, Recall, F1

---

## 🏆 Best Model Selection

The system automatically:

1. **Trains all models** (Logistic Regression, Random Forest, etc.)
2. **Compares ROC-AUC scores**
3. **Selects the best model**
4. **Promotes it to Production stage**
5. **Archives previous Production versions**

---

## 🔍 Model Registry Features

### In the Models Tab:

1. **View all registered models**
   - Click on a model name to see details

2. **See version history**
   - Each training run creates a new version
   - Compare versions side-by-side

3. **Check model stage**
   - **Production**: Currently deployed model
   - **Staging**: Models being tested
   - **Archived**: Old versions
   - **None**: Newly registered models

4. **View model signature**
   - Input schema (feature names and types)
   - Output schema (prediction format)

5. **Download models**
   - Download any version for local testing

---

## 📈 Example: What You'll See

### Models Tab:

```
┌─────────────────────────────────────────────────────────┐
│ Models                                                   │
├─────────────────────────────────────────────────────────┤
│                                                          │
│ heart-disease-random_forest          [Production]       │
│   Latest Version: 1                                     │
│   Created: 2024-01-06                                   │
│                                                          │
│ heart-disease-gradient_boosting      [None]             │
│   Latest Version: 1                                     │
│   Created: 2024-01-06                                   │
│                                                          │
│ heart-disease-logistic_regression    [None]             │
│   Latest Version: 1                                     │
│   Created: 2024-01-06                                   │
│                                                          │
│ heart-disease-svm                    [None]             │
│   Latest Version: 1                                     │
│   Created: 2024-01-06                                   │
│                                                          │
│ heart-disease-xgboost                [None]             │
│   Latest Version: 1                                     │
│   Created: 2024-01-06                                   │
└─────────────────────────────────────────────────────────┘
```

---

## 🔄 Model Lifecycle

### Typical Workflow:

1. **Training** → Model registered with stage "None"
2. **Evaluation** → Best model promoted to "Production"
3. **Deployment** → Load model from "Production" stage
4. **Retraining** → New version created, old version archived

### Stage Transitions:

```
None → Staging → Production → Archived
```

---

## 💻 Using Models Programmatically

### Load Production Model:

```python
import mlflow

# Load the production version of the best model
model_name = "heart-disease-random_forest"
model_uri = f"models:/{model_name}/Production"

model = mlflow.sklearn.load_model(model_uri)

# Make predictions
predictions = model.predict(X_test)
```

### Load Specific Version:

```python
# Load version 2 of a specific model
model_uri = f"models:/{model_name}/2"
model = mlflow.sklearn.load_model(model_uri)
```

---

## 🎯 Benefits of Model Registry

1. **Version Control**: Track all model versions
2. **Stage Management**: Clear production vs staging models
3. **Reproducibility**: Recreate any model version
4. **Collaboration**: Team can see all models
5. **Deployment**: Easy to deploy production models
6. **Rollback**: Quickly revert to previous versions
7. **Comparison**: Compare model performance across versions

---

## 🔧 Troubleshooting

### Models Still Not Showing?

1. **Check if build succeeded:**
   ```bash
   # Check Jenkins build logs
   ```

2. **Check MLflow logs:**
   ```bash
   tail -f logs/mlflow.log
   ```

3. **Verify MLflow is running:**
   ```bash
   pgrep -f "mlflow ui"
   ```

4. **Check mlruns directory:**
   ```bash
   ls -la mlruns/
   ```

### Clear Old Data (if needed):

```bash
# Backup first!
mv mlruns mlruns.backup

# Create fresh directory
mkdir mlruns

# Run a new build
```

---

## 📚 Related Documentation

- **MLflow Model Registry**: https://mlflow.org/docs/latest/model-registry.html
- **MLflow Models**: https://mlflow.org/docs/latest/models.html
- **Model Signatures**: https://mlflow.org/docs/latest/models.html#model-signature

---

## ✅ Summary

**Before:**
- Models logged to runs only
- No model registry
- No version management
- No production stage

**After:**
- ✅ Models registered to Model Registry
- ✅ Automatic versioning
- ✅ Best model promoted to Production
- ✅ Model signatures and examples
- ✅ Easy deployment and rollback

---

## 🎯 Next Steps

1. Pull the latest code
2. Run a new Jenkins build
3. Check the Models tab in MLflow
4. See your registered models!
5. Click on the Production model to see details

Enjoy your Model Registry! 🚀

