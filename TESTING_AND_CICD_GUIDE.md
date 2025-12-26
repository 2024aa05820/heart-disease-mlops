# 🧪 Testing & CI/CD Complete Guide

## 📋 Assignment Requirements

### **Task 5: CI/CD Pipeline & Automated Testing [8 marks / 50 total = 16%]**

**Requirements:**
- ✅ Write unit tests for data processing and model code (Pytest)
- ✅ Create GitHub Actions pipeline
- ✅ Pipeline includes: Linting, unit testing, model training
- ✅ Artifacts/logging for each workflow run

**This is worth 16% of your grade - CRITICAL!**

---

## 🧪 PART 1: Running Tests Locally

### **Step 1: Activate Virtual Environment**
```bash
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
source .venv/bin/activate
```

### **Step 2: Run All Tests**
```bash
# Run all tests with verbose output
pytest tests/ -v

# Expected output:
# tests/test_api.py::TestHealthEndpoint::test_health_endpoint_returns_200 PASSED
# tests/test_api.py::TestPredictEndpoint::test_predict_endpoint_returns_200 PASSED
# tests/test_data.py::TestDataLoading::test_load_data PASSED
# tests/test_model.py::TestModelTraining::test_model_training PASSED
# ... (more tests)
# ======================== X passed in Y.YYs ========================
```

### **Step 3: Run Tests with Coverage**
```bash
# Run tests with coverage report
pytest tests/ -v --cov=src --cov-report=term --cov-report=html

# This creates:
# 1. Terminal coverage report (shows immediately)
# 2. HTML coverage report in htmlcov/ directory
```

### **Step 4: View Coverage Report**
```bash
# List coverage files
ls -la htmlcov/

# To view in browser (if you have GUI):
# firefox htmlcov/index.html
# Or copy to your local machine to view
```

### **Step 5: Run Specific Test Files**
```bash
# Test only API
pytest tests/test_api.py -v

# Test only data processing
pytest tests/test_data.py -v

# Test only model
pytest tests/test_model.py -v
```

### **Step 6: Run Linting**
```bash
# Check code formatting with black
black --check src/ tests/ scripts/

# Run ruff linter
ruff check src/ tests/ scripts/

# If you want to auto-fix formatting:
black src/ tests/ scripts/
```

---

## 📸 Screenshots for Testing (Take These!)

### **Screenshot 1: Test Execution**
```bash
pytest tests/ -v
# Take screenshot showing all tests PASSED
```

### **Screenshot 2: Coverage Report (Terminal)**
```bash
pytest tests/ -v --cov=src --cov-report=term
# Take screenshot showing coverage percentages
```

### **Screenshot 3: Coverage Report (HTML)**
```bash
# Open htmlcov/index.html in browser
# Take screenshot showing:
# - Overall coverage percentage
# - Coverage by module
```

### **Screenshot 4: Linting Results**
```bash
black --check src/ tests/ scripts/
ruff check src/ tests/ scripts/
# Take screenshot showing "All checks passed" or similar
```

---

## 🔄 PART 2: CI/CD Pipeline (GitHub Actions)

### **What is Already Set Up:**

Your project has a complete CI/CD pipeline in `.github/workflows/ci.yml`

**Pipeline has 5 jobs:**
1. **Lint** - Code quality checks
2. **Test** - Run unit tests
3. **Train** - Train models
4. **Docker** - Build Docker image
5. **Deploy** - Deploy to Kubernetes (placeholder)

### **How to Trigger the Pipeline:**

#### **Method 1: Push to GitHub (Automatic)**
```bash
# Make any change (e.g., update README)
git add .
git commit -m "Trigger CI/CD pipeline"
git push origin main

# Pipeline will run automatically!
```

#### **Method 2: Manual Trigger (if enabled)**
```bash
# Using GitHub CLI (if installed)
gh workflow run ci.yml

# Or trigger from GitHub website:
# Go to: Actions tab → Select workflow → Run workflow
```

### **How to Check Pipeline Status:**

#### **Option 1: GitHub Website**
```
1. Go to: https://github.com/2024aa05820/heart-disease-mlops
2. Click "Actions" tab
3. See all workflow runs
4. Click on a run to see details
```

#### **Option 2: GitHub CLI (if installed)**
```bash
# List recent runs
gh run list --limit 5

# View specific run
gh run view <run-id>

# Watch a run in real-time
gh run watch
```

---

## 📸 Screenshots for CI/CD (Take These!)

### **Screenshot 1: GitHub Actions - Workflow Runs List**
**Where:** GitHub → Actions tab
**What to capture:**
- List of workflow runs
- Status (✅ Success or ❌ Failed)
- Timestamps
- Commit messages

### **Screenshot 2: Successful Pipeline Run - Overview**
**Where:** Click on a successful run
**What to capture:**
- All 5 jobs showing green checkmarks
- Total run time
- Commit info

### **Screenshot 3: Lint Job Details**
**Where:** Click on "Lint Code" job
**What to capture:**
- Ruff linter output
- Black formatter check
- "All checks passed" message

### **Screenshot 4: Test Job Details**
**Where:** Click on "Run Tests" job
**What to capture:**
- pytest output showing tests passed
- Coverage report
- Number of tests run

### **Screenshot 5: Train Job Details**
**Where:** Click on "Train Model" job
**What to capture:**
- Model training output
- Metrics logged
- "Training complete" message

### **Screenshot 6: Docker Job Details**
**Where:** Click on "Build Docker Image" job
**What to capture:**
- Docker build steps
- Image built successfully
- Container test passed

### **Screenshot 7: Artifacts**
**Where:** Scroll down on run page
**What to capture:**
- Artifacts section showing:
  - model-artifacts
  - docker-image
- Download links

---

## 🔧 PART 3: Understanding Your Tests

### **Test Files Overview:**

```
tests/
├── __init__.py
├── test_api.py      # API endpoint tests
├── test_data.py     # Data processing tests
└── test_model.py    # Model training tests
```

### **What Each Test File Does:**

#### **test_api.py** - API Tests
```python
# Tests:
- Health endpoint returns 200
- Root endpoint returns API info
- Predict endpoint accepts valid input
- Predict endpoint returns prediction
- Predict endpoint validates input
- Schema endpoint returns feature schema
- Metrics endpoint returns Prometheus metrics
```

#### **test_data.py** - Data Processing Tests
```python
# Tests:
- Load data from CSV
- Clean data (handle missing values)
- Prepare features and target
- Split data into train/test
- Preprocessing pipeline works
```

#### **test_model.py** - Model Tests
```python
# Tests:
- Logistic Regression trains successfully
- Random Forest trains successfully
- Model makes predictions
- Model evaluation metrics calculated
- Model can be saved and loaded
```

---

## 🎯 PART 4: Complete Testing Workflow

### **Execute This on Your Remote Machine:**

```bash
# 1. Navigate to project
cd ~/Documents/mlops-assignment-1/heart-disease-mlops

# 2. Activate virtual environment
source .venv/bin/activate

# 3. Ensure data is downloaded
python scripts/download_data.py

# 4. Run linting
echo "=== Running Linting ==="
black --check src/ tests/ scripts/
ruff check src/ tests/ scripts/

# 5. Run tests with coverage
echo "=== Running Tests ==="
pytest tests/ -v --cov=src --cov-report=term --cov-report=html

# 6. View results
echo "=== Test Results ==="
echo "Coverage report: htmlcov/index.html"
ls -la htmlcov/

# 7. Take screenshots of all outputs!
```

---

## 🚀 PART 5: Trigger CI/CD Pipeline

### **Step-by-Step:**

```bash
# 1. Make sure you're on main branch
git branch
# Should show: * main

# 2. Pull latest changes
git pull origin main

# 3. Make a small change to trigger pipeline
echo "# CI/CD Test - $(date)" >> .github/workflows/README.md

# 4. Commit and push
git add .
git commit -m "Test: Trigger CI/CD pipeline"
git push origin main

# 5. Check pipeline status
# Go to: https://github.com/2024aa05820/heart-disease-mlops/actions
# You should see a new workflow run starting!

# 6. Wait for pipeline to complete (5-10 minutes)
# Watch the progress in GitHub Actions tab

# 7. Take screenshots when complete!
```

---

## 📊 PART 6: What to Include in Report

### **Section: CI/CD Pipeline & Testing (2-3 pages)**

#### **1. Testing Strategy**
```
We implemented comprehensive unit tests using pytest covering:
- API endpoints (FastAPI application)
- Data processing pipeline
- Model training and evaluation

Total test coverage: XX% (show from coverage report)
```

#### **2. Test Results**
```
All tests passed successfully:
- API tests: X/X passed
- Data tests: X/X passed  
- Model tests: X/X passed
- Total: XX tests passed

Include screenshot of pytest output
```

#### **3. CI/CD Pipeline Architecture**
```
GitHub Actions workflow with 5 stages:

1. Lint (Code Quality)
   - Black formatter check
   - Ruff linter

2. Test (Unit Tests)
   - Run pytest with coverage
   - Upload coverage report

3. Train (Model Training)
   - Download dataset
   - Train models
   - Upload model artifacts

4. Docker (Containerization)
   - Build Docker image
   - Test container
   - Upload image artifact

5. Deploy (Kubernetes)
   - Deployment placeholder
   - Ready for production deployment

Include workflow diagram or screenshot
```

#### **4. Pipeline Results**
```
Latest pipeline run:
- Status: ✅ Success
- Duration: X minutes
- Commit: <commit-hash>
- All jobs passed

Include screenshots of successful run
```

#### **5. Artifacts**
```
Pipeline generates artifacts:
- Model artifacts (trained models)
- Docker image (containerized API)
- Coverage reports
- Test results

Include screenshot of artifacts section
```

---

## ✅ Checklist Before Submission

### **Testing:**
- [ ] All tests pass locally
- [ ] Coverage report generated
- [ ] Linting passes
- [ ] Screenshots taken (4 screenshots)

### **CI/CD:**
- [ ] Pipeline triggered successfully
- [ ] All 5 jobs completed
- [ ] Artifacts generated
- [ ] Screenshots taken (7 screenshots)

### **Report:**
- [ ] Testing section written (1-2 pages)
- [ ] CI/CD section written (1-2 pages)
- [ ] All screenshots included with captions
- [ ] Workflow diagram included

### **Demo Video:**
- [ ] Show running tests locally (1 min)
- [ ] Show GitHub Actions pipeline (2 min)
- [ ] Explain each pipeline stage (1 min)

---

## 🎓 Grading Criteria

### **Full Marks (8/8):**
✅ Comprehensive unit tests (API, data, model)
✅ Tests pass with good coverage (>70%)
✅ GitHub Actions pipeline configured
✅ Pipeline includes all required stages
✅ Pipeline runs successfully
✅ Artifacts generated and stored
✅ Screenshots in report
✅ Clear explanation of CI/CD benefits

### **Partial Marks (5-7/8):**
⚠️ Tests exist but limited coverage
⚠️ Pipeline configured but some jobs fail
⚠️ Limited screenshots

### **Low Marks (1-4/8):**
❌ Minimal tests
❌ Pipeline not working properly
❌ No screenshots

---

## 🆘 Troubleshooting

### **Tests Fail Locally:**
```bash
# Check if data exists
ls -la data/raw/heart.csv

# If missing, download:
python scripts/download_data.py

# Check if models exist (for model tests)
ls -la models/

# If missing, train:
python scripts/train.py
```

### **Pipeline Fails on GitHub:**
```bash
# Check workflow file syntax
cat .github/workflows/ci.yml

# View error logs in GitHub Actions tab
# Click on failed job to see error details
```

### **Coverage Too Low:**
```bash
# Run coverage to see what's missing
pytest tests/ -v --cov=src --cov-report=term-missing

# Shows which lines aren't covered
```

---

## ⏱️ Time Estimates

| Task | Time |
|------|------|
| Run tests locally | 2 min |
| Generate coverage | 2 min |
| Run linting | 1 min |
| Take testing screenshots | 5 min |
| Trigger CI/CD pipeline | 1 min |
| Wait for pipeline | 5-10 min |
| Take CI/CD screenshots | 10 min |
| **Total** | **~25-30 min** |

---

**Next: After testing & CI/CD, you need Docker & Kubernetes!** 🐳☸️

