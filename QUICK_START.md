# 🚀 Quick Start Guide - MLflow Empty Page Fix

## The Problem
MLflow UI shows empty page = **No experiments logged yet** = **Models not trained yet**

## The Solution (3 Commands)

### On Your Remote Linux Machine:

```bash
# 1. Navigate to project
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
# (or wherever your project is)

# 2. Activate virtual environment
source .venv/bin/activate

# 3. Run the automated setup (ONE COMMAND DOES EVERYTHING!)
bash scripts/setup_mlflow.sh
```

**That's it!** The script will:
- ✅ Download the dataset
- ✅ Train both models (Logistic Regression + Random Forest)
- ✅ Create MLflow experiments
- ✅ Ask if you want to start MLflow UI

---

## Manual Method (If You Prefer Step-by-Step)

```bash
# Step 1: Download dataset
python scripts/download_data.py

# Step 2: Train models (creates MLflow runs)
python scripts/train.py

# Step 3: Check status
python scripts/check_mlflow_status.py

# Step 4: Start MLflow UI
mlflow ui --host 0.0.0.0 --port 5000
```

---

## Accessing MLflow UI

### Option 1: Direct Access (if firewall allows)
```
http://<YOUR_SERVER_IP>:5000
```
Example: `http://192.168.1.100:5000`

### Option 2: SSH Port Forwarding (recommended for security)
**From your local machine:**
```bash
ssh -L 5000:localhost:5000 username@your-server-ip
```
Then open browser: `http://localhost:5000`

---

## What You'll See in MLflow UI

After training completes, you'll see:

### Experiments Tab
- **Experiment Name:** "heart-disease-classification"
- **Number of Runs:** 2 (one per model)

### Each Run Shows
- **Parameters:** Model hyperparameters (C, max_iter, n_estimators, etc.)
- **Metrics:** 
  - Accuracy
  - Precision
  - Recall
  - F1 Score
  - ROC-AUC
  - Cross-validation scores
- **Artifacts:**
  - 📊 ROC Curve (PNG)
  - 📊 Confusion Matrix (PNG)
  - 📊 Feature Importance (PNG - Random Forest only)
  - 💾 Model files

### Compare Models
1. Select both runs (checkboxes)
2. Click "Compare" button
3. See side-by-side comparison

---

## Troubleshooting

### "Command not found: mlflow"
```bash
# Make sure virtual environment is activated
source .venv/bin/activate

# Verify mlflow is installed
pip list | grep mlflow
```

### "Cannot access http://SERVER_IP:5000"
```bash
# Check if firewall is blocking port 5000
sudo firewall-cmd --list-ports

# Add port (Rocky Linux / RHEL)
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --reload

# Or use SSH tunnel instead (see Option 2 above)
```

### "Training takes too long"
- Normal training time: 2-5 minutes
- If stuck, check: `tail -f training.log`

### Still Empty After Training?
```bash
# Run diagnostic script
python scripts/check_mlflow_status.py

# Check if mlruns directory has content
ls -R mlruns/

# Should see experiment directories and run IDs
```

---

## Expected Output During Training

```
Starting model training...
Loading data from data/raw/heart.csv
Data shape: (303, 14)

Training logistic_regression...
Cross-validation scores: [0.82, 0.85, 0.83, 0.84, 0.81]
Mean CV accuracy: 0.83

Training random_forest...
Cross-validation scores: [0.85, 0.87, 0.86, 0.88, 0.84]
Mean CV accuracy: 0.86

✓ Best model: random_forest (accuracy: 0.86)
✓ Models saved to: models/
✓ MLflow runs logged
```

---

## Next Steps After MLflow Works

1. **Take Screenshots** for your report:
   - MLflow experiments list
   - Individual run details
   - Metrics comparison
   - Artifacts (plots)

2. **Test the API:**
   ```bash
   make serve
   # In another terminal:
   curl http://localhost:8000/health
   ```

3. **Build Docker:**
   ```bash
   make docker-build
   make docker-run
   ```

4. **Write Report** - You now have MLflow screenshots!

---

## Time Estimates

| Task | Time |
|------|------|
| Download dataset | 10-30 seconds |
| Train models | 2-5 minutes |
| Start MLflow UI | 5 seconds |
| **Total** | **~5 minutes** |

---

## Need More Help?

- **Detailed Guide:** `MLFLOW_SETUP_GUIDE.md`
- **Status Checker:** `python scripts/check_mlflow_status.py`
- **Full README:** `README.md`

---

## Summary

**The empty MLflow UI is normal before training!**

Just run:
```bash
bash scripts/setup_mlflow.sh
```

Then access: `http://<SERVER_IP>:5000`

**Done!** 🎉

