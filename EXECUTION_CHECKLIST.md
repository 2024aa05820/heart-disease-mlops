# 📋 Complete Execution Checklist - MLOps Assignment

**Execute these commands on your remote Linux machine in order.**

---

## ✅ PHASE 1: Initial Setup & Verification (2 minutes)

### 1.1 Navigate to Project Directory
```bash
# Replace with your actual path
cd ~/Documents/mlops-assignment-1/heart-disease-mlops

# Verify you're in the right place
pwd
ls -la
# Should see: README.md, requirements.txt, src/, scripts/, etc.
```

### 1.2 Pull Latest Changes from GitHub
```bash
git pull origin main
# Should show: Already up to date OR download new files
```

### 1.3 Check Python Version
```bash
python3 --version
# Required: Python 3.11 or higher
```

### 1.4 Check Current Status
```bash
# Run diagnostic script
python3 scripts/check_mlflow_status.py
# This will tell you what's missing
```

**✅ CHECKPOINT:** You should see project structure verified

---

## ✅ PHASE 2: Environment Setup (1 minute)

### 2.1 Activate Virtual Environment
```bash
# If .venv exists
source .venv/bin/activate

# If not, create it first
python3 -m venv .venv
source .venv/bin/activate
```

### 2.2 Verify Virtual Environment
```bash
which python
# Should show: /path/to/heart-disease-mlops/.venv/bin/python

which pip
# Should show: /path/to/heart-disease-mlops/.venv/bin/pip
```

### 2.3 Install/Update Dependencies
```bash
pip install --upgrade pip
pip install -r requirements.txt
# Wait for installation to complete (1-2 minutes)
```

### 2.4 Verify Key Packages
```bash
pip list | grep -E "mlflow|fastapi|scikit-learn|pandas"
# Should show all packages installed
```

**✅ CHECKPOINT:** Virtual environment activated, all packages installed

---

## ✅ PHASE 3: Data Download & Model Training (5-7 minutes)

### 3.1 OPTION A: Automated Setup (Recommended)
```bash
# One command does everything!
bash scripts/setup_mlflow.sh

# This will:
# - Download dataset
# - Train both models
# - Create MLflow experiments
# - Ask if you want to start MLflow UI
```

### 3.2 OPTION B: Manual Step-by-Step

#### Step 1: Download Dataset
```bash
python scripts/download_data.py

# Expected output:
# Downloading Heart Disease dataset from UCI...
# ✓ Dataset saved to: data/raw/heart.csv
# ✓ Columns: 14
# ✓ Rows: 303
```

#### Step 2: Verify Dataset
```bash
ls -lh data/raw/
# Should show: heart.csv (~10-15 KB)

head -5 data/raw/heart.csv
# Should show CSV with headers and data
```

#### Step 3: Train Models
```bash
python scripts/train.py

# Expected output (takes 2-5 minutes):
# Starting model training...
# Loading data from data/raw/heart.csv
# Training logistic_regression...
# Training random_forest...
# ✓ Best model: random_forest
# ✓ Models saved to: models/
```

#### Step 4: Verify Training Completed
```bash
# Check if models were saved
ls -lh models/
# Should show: .pkl or .joblib files

# Check if MLflow runs were created
ls -R mlruns/
# Should show experiment directories with run IDs

# Run diagnostic again
python scripts/check_mlflow_status.py
# Should show: ✓ MLflow experiments created
```

**✅ CHECKPOINT:** Dataset downloaded, models trained, MLflow runs created

---

## ✅ PHASE 4: MLflow UI (Ongoing)

### 4.1 Start MLflow UI
```bash
# Start in background or separate terminal
mlflow ui --host 0.0.0.0 --port 5000

# Expected output:
# [INFO] Starting gunicorn
# [INFO] Listening at: http://0.0.0.0:5000
```

### 4.2 Access MLflow UI

**Option A: Direct Access (if firewall allows)**
```
Open browser: http://<YOUR_SERVER_IP>:5000
```

**Option B: SSH Port Forwarding (from your local machine)**
```bash
# On your LOCAL machine (not the server):
ssh -L 5000:localhost:5000 username@server-ip

# Then open browser on local machine:
http://localhost:5000
```

### 4.3 Verify MLflow UI Shows Data
- ✅ Should see experiment: "heart-disease-classification"
- ✅ Should see 2 runs (Logistic Regression + Random Forest)
- ✅ Click on runs to see metrics, parameters, artifacts

### 4.4 Take Screenshots (CRITICAL for Report!)
**Take screenshots of:**
1. Experiments list page
2. Logistic Regression run details (metrics, parameters)
3. Random Forest run details (metrics, parameters)
4. Compare runs page (select both, click Compare)
5. ROC curve artifact
6. Confusion matrix artifact
7. Feature importance plot (Random Forest)

**Save screenshots to:**
```bash
# Create screenshots directory if needed
mkdir -p reports/screenshots/mlflow
# Then save your browser screenshots there
```

**✅ CHECKPOINT:** MLflow UI accessible, screenshots taken

---

## ✅ PHASE 5: API Testing (5 minutes)

### 5.1 Start API Server (New Terminal)
```bash
# Open new terminal, navigate to project
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
source .venv/bin/activate

# Start API
uvicorn src.api.app:app --host 0.0.0.0 --port 8000 --reload

# Expected output:
# INFO: Uvicorn running on http://0.0.0.0:8000
```

### 5.2 Test API Endpoints (Another Terminal)
```bash
# Health check
curl http://localhost:8000/health

# Expected: {"status": "healthy", ...}

# API info
curl http://localhost:8000/

# Get schema
curl http://localhost:8000/schema

# Make prediction
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "age": 63, "sex": 1, "cp": 3, "trestbps": 145,
    "chol": 233, "fbs": 1, "restecg": 0, "thalach": 150,
    "exang": 0, "oldpeak": 2.3, "slope": 0, "ca": 0, "thal": 1
  }'

# Expected: {"prediction": 1, "probability": 0.XX, ...}

# Check metrics
curl http://localhost:8000/metrics
```

### 5.3 Access Swagger UI
```
Open browser: http://<SERVER_IP>:8000/docs
```

### 5.4 Take Screenshots
**Take screenshots of:**
1. Swagger UI main page
2. /health endpoint response
3. /predict endpoint with sample input
4. /predict endpoint response
5. /metrics endpoint (Prometheus metrics)

**✅ CHECKPOINT:** API working, all endpoints tested, screenshots taken

---

## ✅ PHASE 6: Docker Build & Test (10 minutes)

### 6.1 Stop API Server (if running)
```bash
# In the terminal running uvicorn, press Ctrl+C
```

### 6.2 Build Docker Image
```bash
docker build -t heart-disease-api:latest .

# Expected output (takes 3-5 minutes):
# Step 1/X : FROM python:3.11-slim
# ...
# Successfully built <image-id>
# Successfully tagged heart-disease-api:latest
```

### 6.3 Verify Image Built
```bash
docker images | grep heart-disease-api
# Should show: heart-disease-api  latest  <image-id>  <size>
```

### 6.4 Run Docker Container
```bash
docker run -d --name heart-api -p 8000:8000 heart-disease-api:latest

# Check if running
docker ps
# Should show container running on port 8000
```

### 6.5 Test Dockerized API
```bash
# Wait 10 seconds for container to start
sleep 10

# Test health endpoint
curl http://localhost:8000/health

# Test prediction
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "age": 63, "sex": 1, "cp": 3, "trestbps": 145,
    "chol": 233, "fbs": 1, "restecg": 0, "thalach": 150,
    "exang": 0, "oldpeak": 2.3, "slope": 0, "ca": 0, "thal": 1
  }'
```

### 6.6 Check Docker Logs
```bash
docker logs heart-api
# Should show: INFO: Uvicorn running...
```

### 6.7 Take Screenshots
**Take screenshots of:**
1. `docker build` command output (successful build)
2. `docker images` output
3. `docker ps` output (running container)
4. `docker logs` output
5. API response from dockerized container

### 6.8 Stop Container (when done testing)
```bash
docker stop heart-api
docker rm heart-api
```

**✅ CHECKPOINT:** Docker image built, container tested, screenshots taken

---

## ✅ PHASE 7: Kubernetes Deployment (15 minutes) - OPTIONAL

### 7.1 Check if Minikube is Installed
```bash
minikube version
# If not installed, see README.md for installation instructions
```

### 7.2 Start Minikube
```bash
minikube start

# Expected output:
# 😄  minikube v1.x.x on Rocky Linux
# ✨  Using the docker driver
# 🏄  Done! kubectl is now configured
```

### 7.3 Load Docker Image into Minikube
```bash
minikube image load heart-disease-api:latest

# Verify
minikube image ls | grep heart-disease-api
```

### 7.4 Deploy to Kubernetes
```bash
kubectl apply -f deploy/k8s/

# Expected output:
# deployment.apps/heart-disease-api created
# service/heart-disease-api-service created
# horizontalpodautoscaler.autoscaling/heart-disease-api-hpa created
```

### 7.5 Check Deployment Status
```bash
# Check pods
kubectl get pods
# Wait until STATUS shows "Running"

# Check services
kubectl get services

# Check deployments
kubectl get deployments
```

### 7.6 Access the API
```bash
# Port forward to access locally
kubectl port-forward service/heart-disease-api-service 8000:80

# In another terminal, test:
curl http://localhost:8000/health
```

### 7.7 Take Screenshots
**Take screenshots of:**
1. `minikube start` output
2. `kubectl get pods` output
3. `kubectl get services` output
4. `kubectl get deployments` output
5. `kubectl describe pod <pod-name>` output
6. API response through K8s service

### 7.8 Cleanup (when done)
```bash
kubectl delete -f deploy/k8s/
minikube stop
```

**✅ CHECKPOINT:** Kubernetes deployment successful, screenshots taken

---

## ✅ PHASE 8: Testing & CI/CD Verification (5 minutes)

### 8.1 Run Unit Tests
```bash
# Make sure virtual environment is activated
source .venv/bin/activate

# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ -v --cov=src --cov-report=html --cov-report=term

# Expected: All tests should pass
```

### 8.2 View Coverage Report
```bash
# Open coverage report
# The HTML report is in: htmlcov/index.html
ls -la htmlcov/
```

### 8.3 Run Linting
```bash
# Check code formatting
black --check src/ tests/ scripts/

# Run linter
ruff check src/ tests/ scripts/
```

### 8.4 Check GitHub Actions
```bash
# View recent workflow runs (if gh CLI installed)
gh workflow list
gh run list --limit 5

# Or visit in browser:
# https://github.com/2024aa05820/heart-disease-mlops/actions
```

### 8.5 Take Screenshots
**Take screenshots of:**
1. `pytest` output (all tests passing)
2. Coverage report (terminal output)
3. Coverage HTML report (open htmlcov/index.html in browser)
4. GitHub Actions workflow runs (from GitHub website)
5. Successful CI/CD pipeline run details

**✅ CHECKPOINT:** All tests passing, CI/CD verified, screenshots taken

---

## ✅ PHASE 9: Documentation & Screenshots Organization (10 minutes)

### 9.1 Organize Screenshots
```bash
# Create organized screenshot directories
mkdir -p reports/screenshots/{mlflow,api,docker,kubernetes,cicd,testing}

# Move/copy your screenshots to appropriate folders:
# - reports/screenshots/mlflow/ - MLflow UI screenshots
# - reports/screenshots/api/ - API testing screenshots
# - reports/screenshots/docker/ - Docker build/run screenshots
# - reports/screenshots/kubernetes/ - K8s deployment screenshots
# - reports/screenshots/cicd/ - GitHub Actions screenshots
# - reports/screenshots/testing/ - Test results screenshots
```

### 9.2 Generate EDA Visualizations
```bash
# Open Jupyter notebook
jupyter notebook notebooks/01_eda.ipynb

# Run all cells to generate visualizations
# Export key plots as PNG files to reports/screenshots/eda/
```

### 9.3 Create Architecture Diagram
```bash
# The README already has a text-based architecture diagram
# For the report, you can:
# 1. Use draw.io or Lucidchart to create a visual diagram
# 2. Or screenshot the README architecture section
```

### 9.4 Verify All Screenshots Collected
```bash
# List all screenshots
find reports/screenshots -type f -name "*.png" -o -name "*.jpg"

# Count screenshots
find reports/screenshots -type f \( -name "*.png" -o -name "*.jpg" \) | wc -l
# Should have 20+ screenshots
```

**✅ CHECKPOINT:** All screenshots organized and ready for report

---

## ✅ PHASE 10: Final Verification (5 minutes)

### 10.1 Run Complete Status Check
```bash
python scripts/check_mlflow_status.py
# Should show all green checkmarks
```

### 10.2 Verify All Components
```bash
# Check data
ls -lh data/raw/heart.csv

# Check models
ls -lh models/

# Check MLflow runs
ls -R mlruns/ | head -20

# Check screenshots
ls -R reports/screenshots/

# Check tests pass
pytest tests/ -v --tb=short
```

### 10.3 Create Summary Document
```bash
# List what you've completed
cat > reports/COMPLETION_STATUS.txt << 'EOF'
MLOps Assignment - Completion Status
====================================

✅ Data downloaded: data/raw/heart.csv
✅ Models trained: Logistic Regression, Random Forest
✅ MLflow experiments: 2 runs logged
✅ API tested: All endpoints working
✅ Docker image: Built and tested
✅ Kubernetes: Deployed and verified
✅ Tests: All passing with coverage
✅ Screenshots: 20+ screenshots collected
✅ CI/CD: GitHub Actions pipeline verified

Next Steps:
- [ ] Write 10-page report (doc/docx)
- [ ] Record demo video (5-10 minutes)
- [ ] Final review and submission
EOF

cat reports/COMPLETION_STATUS.txt
```

**✅ CHECKPOINT:** All technical components complete!

---

## 📝 CRITICAL MISSING DELIVERABLES

### ⚠️ You Still Need To Complete:

#### 1. **10-Page Report (doc/docx)** - CRITICAL
Create a Word document with these sections:
- Introduction & Objectives
- Dataset Description & EDA (include plots)
- Feature Engineering & Preprocessing
- Model Development & Selection
- Experiment Tracking (MLflow screenshots)
- Model Packaging & Reproducibility
- CI/CD Pipeline (GitHub Actions screenshots)
- Containerization (Docker screenshots)
- Deployment (Kubernetes screenshots)
- Monitoring & Logging
- Challenges & Solutions
- Conclusion & Future Work

#### 2. **Demo Video (5-10 minutes)** - CRITICAL
Record a video showing:
- Project structure walkthrough
- Running training script
- MLflow UI demonstration
- API testing (Swagger UI)
- Docker build and run
- Kubernetes deployment
- Monitoring dashboard

**Tools for recording:**
- Linux: `recordmydesktop`, `SimpleScreenRecorder`, `OBS Studio`
- Or use Zoom/Teams to record your screen

#### 3. **Update README.md**
```bash
# Replace placeholders
sed -i 's/YOUR_USERNAME/2024aa05820/g' README.md
sed -i 's/\[Your Name\]/Chandrababu Yelamuri/g' README.md

# Commit changes
git add README.md
git commit -m "Update README with author information"
git push origin main
```

---

## 🎯 QUICK COMMAND SUMMARY (Copy-Paste Ready)

```bash
# Complete setup in one go
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
source .venv/bin/activate
bash scripts/setup_mlflow.sh

# In separate terminals:
# Terminal 1: MLflow UI
mlflow ui --host 0.0.0.0 --port 5000

# Terminal 2: API Server
uvicorn src.api.app:app --host 0.0.0.0 --port 8000

# Terminal 3: Testing
pytest tests/ -v --cov=src
docker build -t heart-disease-api:latest .
docker run -d --name heart-api -p 8000:8000 heart-disease-api:latest
```

---

## ⏱️ TIME ESTIMATES

| Phase | Time Required |
|-------|---------------|
| Setup & Verification | 2 min |
| Environment Setup | 1 min |
| Data & Training | 5-7 min |
| MLflow UI | 2 min |
| API Testing | 5 min |
| Docker | 10 min |
| Kubernetes | 15 min |
| Testing & CI/CD | 5 min |
| Screenshots | 10 min |
| **Total Technical Work** | **~55 min** |
| **Report Writing** | **4-5 hours** |
| **Video Recording** | **1 hour** |
| **GRAND TOTAL** | **~7 hours** |

---

## 📞 NEED HELP?

- **MLflow Issues:** See `MLFLOW_SETUP_GUIDE.md`
- **Quick Reference:** See `QUICK_START.md`
- **Status Check:** Run `python scripts/check_mlflow_status.py`

---

**Good luck with your assignment! 🚀**

