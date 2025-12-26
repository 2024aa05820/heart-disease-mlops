# 🎯 MLflow in Your Assignment - Complete Guide

## 📋 Assignment Requirement

**Task 3: Experiment Tracking [5 marks out of 50]**

> "Integrate MLflow (or a similar tool) for experiment tracking. Log parameters, metrics, artifacts, and plots for all runs."

**This is worth 10% of your total grade!**

---

## 🤔 What is MLflow and Why Do You Need It?

### **What MLflow Does:**
MLflow is an **experiment tracking and model management platform** that automatically records:
- 📊 **Metrics** (accuracy, precision, recall, etc.)
- ⚙️ **Parameters** (hyperparameters like learning rate, max_iter, etc.)
- 📈 **Artifacts** (plots, models, files)
- 🏷️ **Metadata** (timestamps, run IDs, tags)

### **Why It's Critical for MLOps:**
1. **Reproducibility** - Can recreate any experiment exactly
2. **Comparison** - Compare different models side-by-side
3. **Versioning** - Track model evolution over time
4. **Collaboration** - Team members can see all experiments
5. **Production** - Select and deploy the best model

---

## ✅ What Your Project Logs to MLflow

### **For EACH Model (Logistic Regression & Random Forest):**

#### 1. **Parameters** (Hyperparameters)
```python
# Logistic Regression
- max_iter: 1000
- C: 1.0
- solver: 'lbfgs'
- random_state: 42

# Random Forest
- n_estimators: 100
- max_depth: 10
- min_samples_split: 2
- min_samples_leaf: 1
- random_state: 42
```

#### 2. **Metrics** (Performance Scores)
```python
- cv_accuracy_mean: 0.83      # Cross-validation accuracy
- cv_accuracy_std: 0.02       # CV standard deviation
- test_accuracy: 0.85         # Test set accuracy
- precision: 0.87             # Precision score
- recall: 0.82                # Recall score
- f1_score: 0.84              # F1 score
- roc_auc: 0.89               # ROC-AUC score
```

#### 3. **Artifacts** (Files & Plots)
```python
- roc_curve_<model_name>.png           # ROC curve plot
- confusion_matrix_<model_name>.png    # Confusion matrix
- feature_importance_<model_name>.png  # Feature importance (Random Forest only)
- <model_name>/                        # Saved model directory
  ├── MLmodel                          # MLflow model metadata
  ├── model.pkl                        # Serialized model
  ├── conda.yaml                       # Conda environment
  └── requirements.txt                 # Python dependencies
```

---

## 📸 What to Show in Your Report (Screenshots Needed)

### **Screenshot 1: Experiments List**
**What to capture:**
- MLflow UI main page showing "heart-disease-classification" experiment
- Shows 2 runs (one for each model)
- Run names, timestamps, metrics preview

**How to get it:**
```bash
mlflow ui --host 0.0.0.0 --port 5000
# Open: http://<SERVER_IP>:5000
# Take screenshot of main experiments page
```

### **Screenshot 2: Run Details - Logistic Regression**
**What to capture:**
- Parameters section (max_iter, C, solver, etc.)
- Metrics section (all 7 metrics)
- Artifacts section (plots and model)

**How to get it:**
- Click on "Logistic Regression" run
- Scroll to show all sections
- Take full-page screenshot

### **Screenshot 3: Run Details - Random Forest**
**What to capture:**
- Parameters section (n_estimators, max_depth, etc.)
- Metrics section (all 7 metrics)
- Artifacts section (plots and model)

**How to get it:**
- Click on "Random Forest" run
- Scroll to show all sections
- Take full-page screenshot

### **Screenshot 4: Compare Runs**
**What to capture:**
- Side-by-side comparison of both models
- Metrics comparison table
- Parameter differences highlighted

**How to get it:**
- Select both runs (checkboxes)
- Click "Compare" button
- Take screenshot of comparison view

### **Screenshot 5: ROC Curve Artifact**
**What to capture:**
- ROC curve plot for one of the models
- Shows AUC score on the plot

**How to get it:**
- Click on a run
- Click "Artifacts" tab
- Click on "roc_curve_*.png"
- Take screenshot of the plot

### **Screenshot 6: Confusion Matrix Artifact**
**What to capture:**
- Confusion matrix heatmap
- Shows TP, TN, FP, FN values

**How to get it:**
- In Artifacts tab
- Click on "confusion_matrix_*.png"
- Take screenshot

### **Screenshot 7: Feature Importance (Random Forest)**
**What to capture:**
- Bar chart showing feature importance
- Top features highlighted

**How to get it:**
- In Random Forest run
- Artifacts tab
- Click on "feature_importance_random_forest.png"
- Take screenshot

---

## 📝 What to Write in Your Report

### **Section: Experiment Tracking (1-2 pages)**

#### **Introduction:**
```
We integrated MLflow for comprehensive experiment tracking and model 
management. MLflow automatically logs all parameters, metrics, and 
artifacts for each training run, enabling reproducibility and model 
comparison.
```

#### **Implementation:**
```
MLflow Configuration:
- Tracking URI: ./mlruns (local file storage)
- Experiment Name: heart-disease-classification
- Backend: SQLite (default)
- Artifact Store: Local filesystem

For each model training run, we logged:
1. Hyperparameters (model configuration)
2. Performance metrics (7 metrics including ROC-AUC)
3. Visualization artifacts (ROC curves, confusion matrices)
4. Trained model artifacts (for deployment)
```

#### **Results Summary Table:**
```
| Model               | Accuracy | Precision | Recall | F1    | ROC-AUC |
|---------------------|----------|-----------|--------|-------|---------|
| Logistic Regression | 0.83     | 0.85      | 0.80   | 0.82  | 0.87    |
| Random Forest       | 0.86     | 0.88      | 0.84   | 0.86  | 0.91    |
```

#### **Model Comparison:**
```
Using MLflow's comparison feature, we analyzed both models:

Random Forest outperformed Logistic Regression:
- Higher ROC-AUC (0.91 vs 0.87)
- Better accuracy (0.86 vs 0.83)
- Improved recall (0.84 vs 0.80)

Therefore, Random Forest was selected as the production model.
```

#### **Reproducibility:**
```
All experiments are fully reproducible through MLflow:
- Exact parameters logged for each run
- Environment dependencies captured
- Model artifacts versioned and stored
- Can recreate any experiment using run ID
```

#### **Include Screenshots:**
- MLflow experiments list
- Individual run details (both models)
- Comparison view
- Artifact visualizations (ROC, confusion matrix)

---

## 🎥 What to Show in Demo Video

### **MLflow Demo Section (2-3 minutes):**

1. **Start MLflow UI** (10 seconds)
   ```bash
   mlflow ui --host 0.0.0.0 --port 5000
   ```
   Show the command and UI loading

2. **Show Experiments List** (15 seconds)
   - Navigate to experiments page
   - Point out "heart-disease-classification"
   - Show 2 runs listed

3. **Explore Logistic Regression Run** (30 seconds)
   - Click on the run
   - Show Parameters tab
   - Show Metrics tab
   - Show Artifacts tab
   - Click on ROC curve to view

4. **Explore Random Forest Run** (30 seconds)
   - Click on the run
   - Show Parameters tab
   - Show Metrics tab
   - Show feature importance plot

5. **Compare Both Models** (30 seconds)
   - Select both runs
   - Click Compare
   - Show metrics comparison
   - Explain why Random Forest is better

6. **Show Model Artifacts** (20 seconds)
   - Navigate to artifacts
   - Show saved model directory
   - Explain how this is used for deployment

---

## 🎓 Grading Criteria (What Evaluator Looks For)

### **Full Marks (5/5):**
✅ MLflow properly integrated in training code
✅ All parameters logged for both models
✅ All metrics logged (accuracy, precision, recall, F1, ROC-AUC)
✅ Artifacts logged (plots and models)
✅ Multiple runs visible in MLflow UI
✅ Screenshots in report showing all features
✅ Clear explanation of experiment tracking benefits

### **Partial Marks (3-4/5):**
⚠️ MLflow integrated but missing some logs
⚠️ Only basic metrics logged
⚠️ Limited artifacts
⚠️ Screenshots present but incomplete

### **Low Marks (1-2/5):**
❌ MLflow mentioned but not properly used
❌ No screenshots of MLflow UI
❌ Minimal logging

### **Zero Marks (0/5):**
❌ No experiment tracking implemented
❌ No MLflow integration

---

## 🔍 How to Verify Your MLflow Setup

```bash
# 1. Check MLflow runs exist
ls -R mlruns/
# Should show experiment directories with run IDs

# 2. Count runs
find mlruns -name "meta.yaml" | wc -l
# Should show at least 2 (one per model)

# 3. Check artifacts
find mlruns -name "*.png" | wc -l
# Should show 5+ plots

# 4. Verify models saved
find mlruns -name "model.pkl" | wc -l
# Should show 2 (one per model)

# 5. Start UI and verify
mlflow ui --host 0.0.0.0 --port 5000
# Open browser and check all features work
```

---

## 💡 Key Points for Your Report

1. **MLflow enables reproducibility** - Critical for MLOps
2. **Tracks 2 models** - Logistic Regression & Random Forest
3. **Logs 7 metrics per model** - Comprehensive evaluation
4. **Stores 3+ artifacts per model** - Plots and models
5. **Enables comparison** - Selected best model (Random Forest)
6. **Production ready** - Model artifacts used in API deployment

---

## ✅ Checklist Before Submission

- [ ] MLflow UI accessible and working
- [ ] 2 runs visible (Logistic Regression + Random Forest)
- [ ] All parameters logged for both models
- [ ] All 7 metrics logged for both models
- [ ] ROC curves visible in artifacts
- [ ] Confusion matrices visible in artifacts
- [ ] Feature importance visible (Random Forest)
- [ ] Models saved in artifacts
- [ ] 7+ screenshots taken for report
- [ ] Report section written (1-2 pages)
- [ ] Demo video includes MLflow walkthrough (2-3 min)

---

**MLflow is 10% of your grade - make sure it's perfect!** 🎯

