# MLflow Empty Page - Complete Fix Guide

## Problem
MLflow UI shows an empty page because **no experiments have been logged yet**. You need to train the models first.

## Solution: Step-by-Step Instructions

### Step 1: Verify Your Environment

```bash
# SSH into your remote Linux machine
# Navigate to project directory
cd ~/Documents/mlops-assignment-1/heart-disease-mlops

# OR wherever your project is located
cd /path/to/heart-disease-mlops

# Activate virtual environment
source .venv/bin/activate

# Verify Python and packages
python --version  # Should be 3.11+
pip list | grep mlflow  # Should show mlflow>=2.10.0
```

### Step 2: Download the Dataset

```bash
# Run the download script
python scripts/download_data.py

# You should see output like:
# Downloading Heart Disease dataset from UCI...
# ✓ Dataset saved to: data/raw/heart.csv
# ✓ Columns: 14
# ✓ Rows: 303
```

**Verify the data was downloaded:**
```bash
ls -lh data/raw/
# Should show: heart.csv (around 10-15 KB)

# Check first few lines
head -5 data/raw/heart.csv
```

### Step 3: Train the Models (This Creates MLflow Experiments!)

```bash
# Run training script
python scripts/train.py

# This will:
# 1. Load and preprocess data
# 2. Train Logistic Regression model
# 3. Train Random Forest model
# 4. Log everything to MLflow
# 5. Save models to models/ directory

# Expected output:
# Starting model training...
# Training logistic_regression...
# Training random_forest...
# ✓ Best model: random_forest (accuracy: 0.XX)
```

**Training takes 2-5 minutes.** You'll see progress messages.

### Step 4: Verify MLflow Runs Were Created

```bash
# Check if mlruns directory exists
ls -la mlruns/

# You should see directories like:
# drwxr-xr-x  0/  (experiment ID 0)
# drwxr-xr-x  1/  (experiment ID 1 - your experiments)

# Check experiment contents
ls -la mlruns/1/

# Should show run directories with random IDs like:
# drwxr-xr-x  abc123def456.../
# drwxr-xr-x  xyz789ghi012.../

# Verify artifacts were saved
find mlruns/ -name "*.png" | head -5
# Should show ROC curves, confusion matrices, etc.
```

### Step 5: Start MLflow UI

```bash
# Start MLflow UI (accessible from remote machine)
mlflow ui --host 0.0.0.0 --port 5000 --backend-store-uri mlruns

# You should see:
# [INFO] Starting gunicorn 20.1.0
# [INFO] Listening at: http://0.0.0.0:5000
```

**Important:** Use `--host 0.0.0.0` to make it accessible from your local machine!

### Step 6: Access MLflow UI

**From your local machine's browser:**

```
http://<REMOTE_MACHINE_IP>:5000
```

Replace `<REMOTE_MACHINE_IP>` with your college server's IP address.

**Example:**
- If server IP is `192.168.1.100`: http://192.168.1.100:5000
- If using hostname: http://mlops-server.college.edu:5000

### Step 7: What You Should See in MLflow UI

Once training is complete, MLflow UI will show:

1. **Experiments Tab:**
   - Experiment name: "heart-disease-classification"
   - 2 runs (one for each model)

2. **For Each Run:**
   - **Parameters:** max_iter, C, n_estimators, etc.
   - **Metrics:** accuracy, precision, recall, f1_score, roc_auc
   - **Artifacts:** 
     - ROC curve (PNG)
     - Confusion matrix (PNG)
     - Feature importance (PNG for Random Forest)
     - Model files

3. **Compare Runs:**
   - Click both runs
   - Click "Compare" button
   - See side-by-side metrics comparison

---

## Troubleshooting

### Issue 1: "ModuleNotFoundError" when running train.py

```bash
# Make sure you're in the project root
pwd  # Should end with: heart-disease-mlops

# Activate virtual environment
source .venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt
```

### Issue 2: "FileNotFoundError: data/raw/heart.csv"

```bash
# Download the dataset first!
python scripts/download_data.py

# Verify it exists
ls -lh data/raw/heart.csv
```

### Issue 3: MLflow UI still empty after training

```bash
# Check if mlruns directory has content
ls -R mlruns/

# If empty, training didn't complete successfully
# Check for errors in training output

# Re-run training with verbose output
python scripts/train.py 2>&1 | tee training.log
```

### Issue 4: Cannot access MLflow UI from local machine

```bash
# Check if port 5000 is open on firewall
sudo firewall-cmd --list-ports  # RHEL/Rocky Linux

# Add port if needed
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --reload

# Or use SSH port forwarding from your local machine:
ssh -L 5000:localhost:5000 user@remote-server

# Then access: http://localhost:5000
```

---

## Quick Commands Summary

```bash
# Complete workflow
cd heart-disease-mlops
source .venv/bin/activate
python scripts/download_data.py
python scripts/train.py
mlflow ui --host 0.0.0.0 --port 5000

# Access from browser: http://<SERVER_IP>:5000
```

---

## Expected Timeline

- Download data: 10-30 seconds
- Train models: 2-5 minutes
- MLflow UI startup: 5 seconds
- Total: ~5-10 minutes

---

## Next Steps After MLflow Works

1. ✅ Take screenshots of MLflow UI for your report
2. ✅ Test the API locally
3. ✅ Build Docker image
4. ✅ Deploy to Kubernetes
5. ✅ Write the 10-page report

