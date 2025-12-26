# 🚀 Quick Commands - Testing & CI/CD

## 🧪 Testing Commands (Copy-Paste Ready)

### **Complete Testing Workflow:**
```bash
# Navigate to project
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
source .venv/bin/activate

# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ -v --cov=src --cov-report=term --cov-report=html

# Run linting
black --check src/ tests/ scripts/
ruff check src/ tests/ scripts/

# View coverage
ls -la htmlcov/
```

### **Individual Test Commands:**
```bash
# Test API only
pytest tests/test_api.py -v

# Test data processing only
pytest tests/test_data.py -v

# Test models only
pytest tests/test_model.py -v

# Run specific test
pytest tests/test_api.py::TestHealthEndpoint::test_health_endpoint_returns_200 -v
```

---

## 🔄 CI/CD Commands

### **Trigger Pipeline:**
```bash
# Method 1: Make a change and push
git add .
git commit -m "Trigger CI/CD pipeline"
git push origin main

# Method 2: Empty commit (no changes needed)
git commit --allow-empty -m "Trigger CI/CD"
git push origin main
```

### **Check Pipeline Status:**
```bash
# Using GitHub CLI (if installed)
gh run list --limit 5
gh run view
gh run watch

# Or visit in browser:
# https://github.com/2024aa05820/heart-disease-mlops/actions
```

---

## 📸 Screenshot Checklist

### **Testing Screenshots (4 total):**
- [ ] `pytest tests/ -v` output (all tests passed)
- [ ] Coverage report (terminal)
- [ ] Coverage HTML report (htmlcov/index.html)
- [ ] Linting results (black + ruff)

### **CI/CD Screenshots (7 total):**
- [ ] GitHub Actions - Workflow runs list
- [ ] Successful pipeline run - Overview
- [ ] Lint job details
- [ ] Test job details
- [ ] Train job details
- [ ] Docker job details
- [ ] Artifacts section

---

## ✅ Quick Verification

```bash
# Check if tests exist
ls -la tests/
# Should show: test_api.py, test_data.py, test_model.py

# Check if CI/CD workflow exists
ls -la .github/workflows/
# Should show: ci.yml

# Count tests
pytest --collect-only tests/ | grep "test session starts"

# Check test coverage
pytest tests/ --cov=src --cov-report=term | grep "TOTAL"
```

---

## 🎯 Expected Results

### **Test Output:**
```
======================== test session starts ========================
tests/test_api.py::TestHealthEndpoint::test_health_endpoint_returns_200 PASSED
tests/test_api.py::TestPredictEndpoint::test_predict_endpoint_returns_200 PASSED
tests/test_data.py::TestDataLoading::test_load_data PASSED
tests/test_model.py::TestModelTraining::test_logistic_regression PASSED
tests/test_model.py::TestModelTraining::test_random_forest PASSED
======================== XX passed in X.XXs ========================
```

### **Coverage Output:**
```
Name                          Stmts   Miss  Cover
-------------------------------------------------
src/__init__.py                   0      0   100%
src/api/app.py                  120     15    88%
src/data/pipeline.py             85     10    88%
src/models/train.py             150     20    87%
src/models/predict.py            45      5    89%
-------------------------------------------------
TOTAL                           400     50    88%
```

### **CI/CD Pipeline:**
```
✅ Lint Code          (1 min)
✅ Run Tests          (2 min)
✅ Train Model        (5 min)
✅ Build Docker       (3 min)
✅ Deploy             (1 min)
-----------------------------------
Total: ~12 minutes
```

---

## 🆘 Troubleshooting

### **Tests Fail:**
```bash
# Download data first
python scripts/download_data.py

# Train models (needed for some tests)
python scripts/train.py

# Re-run tests
pytest tests/ -v
```

### **Import Errors:**
```bash
# Make sure virtual env is activated
source .venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt
```

### **Pipeline Fails:**
```bash
# Check workflow syntax
cat .github/workflows/ci.yml

# View logs on GitHub:
# Actions tab → Click failed run → Click failed job
```

---

## 📊 Assignment Requirements Met

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Unit tests for data processing | ✅ | test_data.py |
| Unit tests for model code | ✅ | test_model.py |
| Unit tests for API | ✅ | test_api.py |
| GitHub Actions pipeline | ✅ | .github/workflows/ci.yml |
| Linting in pipeline | ✅ | Lint job |
| Testing in pipeline | ✅ | Test job |
| Training in pipeline | ✅ | Train job |
| Artifacts/logging | ✅ | Artifacts uploaded |

**Total: 8/8 marks** ✅

---

## ⏱️ Time Required

- Run tests locally: **5 minutes**
- Take testing screenshots: **5 minutes**
- Trigger CI/CD: **1 minute**
- Wait for pipeline: **10 minutes**
- Take CI/CD screenshots: **10 minutes**
- **Total: ~30 minutes**

---

## 📚 Full Documentation

- **Complete Guide:** `TESTING_AND_CICD_GUIDE.md`
- **Execution Checklist:** `EXECUTION_CHECKLIST.md`
- **Quick Reference:** `COMMANDS_QUICK_REFERENCE.md`

