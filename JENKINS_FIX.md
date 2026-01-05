# Jenkins Pipeline Fix - No Local Setup Needed

## The Problem
Your Docker container health check is failing because the `models/` directory is empty.

## The Solution
The Jenkinsfile already has a "Train Models" stage that should create the models automatically. I've enhanced it to:
- ✅ Show detailed output during training
- ✅ Stop the pipeline if training fails
- ✅ Verify models exist before building Docker image
- ✅ Show container logs when debugging

## What to Do Now

### Step 1: Commit and Push Changes
```bash
git add Jenkinsfile scripts/debug_docker.sh DOCKER_DEBUG_GUIDE.md JENKINS_FIX.md
git commit -m "Fix: Enhanced Jenkinsfile with better model verification and debugging"
git push origin main
```

### Step 2: Trigger Jenkins Build
- Go to your Jenkins dashboard
- Click on your pipeline job
- Click "Build Now"

### Step 3: Monitor the Build
Watch the console output carefully. You should see:

#### ✅ **Train Models Stage** (NEW - Enhanced Output)
```
🤖 Training ML models...
📂 Current directory: /var/lib/jenkins/workspace/...
📂 Models directory before training:
total 0
drwxr-xr-x 2 jenkins jenkins 4096 ... .
-rw-r--r-- 1 jenkins jenkins    0 ... .gitkeep

🚀 Starting model training...
[Training output...]

📂 Models directory after training:
total 12345
-rw-r--r-- 1 jenkins jenkins 6789 ... best_model.joblib
-rw-r--r-- 1 jenkins jenkins 5678 ... preprocessing_pipeline.joblib

✅ Model files verified:
-rw-r--r-- 1 jenkins jenkins 6.7M ... best_model.joblib
-rw-r--r-- 1 jenkins jenkins 5.5M ... preprocessing_pipeline.joblib
```

#### ✅ **Build Docker Image Stage** (NEW - Model Verification)
```
🐳 Building Docker image...
🔍 Verifying model files before Docker build...
✅ Model files verified:
-rw-r--r-- 1 jenkins jenkins 6.7M ... best_model.joblib
-rw-r--r-- 1 jenkins jenkins 5.5M ... preprocessing_pipeline.joblib

📦 Docker images:
heart-disease-api   20   ...   1.24GB

🔍 Verifying models are in Docker image...
total 12M
-rw-r--r-- 1 appuser appuser 6.7M ... best_model.joblib
-rw-r--r-- 1 appuser appuser 5.5M ... preprocessing_pipeline.joblib
```

#### ✅ **Test Docker Image Stage** (NEW - Better Logging)
```
🧪 Testing Docker image...
🚀 Starting container test-api-20...
📊 Container status:
test-api-20   Up 2 seconds   0.0.0.0:8001->8000/tcp

⏳ Waiting 5 seconds for initial startup...
📋 Initial container logs:
INFO:     Started server process [1]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000

✅ Container is running

🏥 Testing health endpoint...
Attempt 1/5...
HTTP Status Code: 200
Response body:
{"status":"healthy","model_loaded":true,"timestamp":"..."}

✅ Health check passed!
```

## If Training Fails

If you see an error in the "Train Models" stage, check:

### Common Issue 1: Dataset Not Downloaded
**Error:** `FileNotFoundError: data/heart.csv not found`
**Solution:** The "Download Dataset" stage should run before training. Check if it succeeded.

### Common Issue 2: Missing Dependencies
**Error:** `ModuleNotFoundError: No module named 'sklearn'`
**Solution:** Check the "Setup Python Environment" stage succeeded.

### Common Issue 3: Insufficient Memory
**Error:** `MemoryError` or training hangs
**Solution:** Your Jenkins server might need more RAM. Try reducing the dataset size or model complexity.

## Manual Fix (If Needed)

If the automatic training still doesn't work, you can manually train on the Jenkins server:

```bash
# SSH to Jenkins server
ssh your-user@jenkins-server

# Find the workspace
cd /var/lib/jenkins/workspace/heart-disease-mlops
# OR
cd /home/jenkins/workspace/heart-disease-mlops

# Activate virtual environment
source venv/bin/activate

# Download data (if needed)
python scripts/download_data.py

# Train models
python scripts/train.py

# Verify
ls -lh models/*.joblib

# Trigger a new build in Jenkins
```

## Verification Checklist

After the build completes, verify:
- [ ] "Train Models" stage shows model files created
- [ ] "Build Docker Image" stage shows models verified
- [ ] "Build Docker Image" stage shows models in Docker image
- [ ] "Test Docker Image" stage shows container running
- [ ] "Test Docker Image" stage shows health check passed
- [ ] No errors in console output

## Next Steps After Success

Once the pipeline passes:
1. ✅ Models are trained and saved
2. ✅ Docker image contains models
3. ✅ Container starts successfully
4. ✅ Health check passes
5. ✅ Ready for deployment to Kubernetes!

## Still Having Issues?

If the build still fails:
1. Copy the **full console output** from Jenkins
2. Look for the **first error** (not the last one)
3. Check which **stage** failed
4. Share the error message for more specific help

The enhanced Jenkinsfile will now give you much better error messages to help diagnose the issue!

