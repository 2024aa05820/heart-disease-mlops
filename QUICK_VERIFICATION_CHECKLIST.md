# ✅ Quick Verification Checklist

## 🚀 Before Submitting Assignment

Use this checklist to verify everything is working correctly.

---

## 1️⃣ **GitHub Actions CI/CD** ✅

### **Check Pipeline Status:**

```
https://github.com/2024aa05820/heart-disease-mlops/actions
```

### **Expected Results:**

| Job | Status | Details |
|-----|--------|---------|
| **Lint Code** | ✅ | Black + Ruff checks pass |
| **Run Tests** | ✅ | 23/23 tests pass |
| **Train Model** | ✅ | Models train successfully |
| **Build Docker** | ✅ | Image builds successfully |

**Screenshot this page for your assignment!** 📸

---

## 2️⃣ **Local Code Quality Checks** ✅

### **Run These Commands:**

```bash
# Navigate to project
cd ~/path/to/heart-disease-mlops

# Check Black formatting
black --check src/ tests/ scripts/

# Expected output:
# ✅ All done! ✨ 🍰 ✨
# ✅ 16 files would be left unchanged.

# Run all tests
pytest tests/ -v

# Expected output:
# ✅ ======================== 23 passed in 3.45s ========================
```

---

## 3️⃣ **MLflow Tracking** ✅

### **Check MLflow UI:**

```bash
# Start MLflow UI
mlflow ui --port 5001

# Open in browser:
http://localhost:5001
```

### **Expected:**
- ✅ Experiments visible
- ✅ Multiple runs logged
- ✅ Metrics tracked (accuracy, precision, recall, F1)
- ✅ Models registered

**Screenshot the MLflow UI for your assignment!** 📸

---

## 4️⃣ **API Testing** ✅

### **Start API Server:**

```bash
# Terminal 1: Start API
uvicorn src.api.app:app --reload --port 8000

# Terminal 2: Test health endpoint
curl http://localhost:8000/health

# Expected output:
# {"status":"healthy","model_loaded":true}

# Test prediction endpoint
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "age": 63,
    "sex": 1,
    "cp": 3,
    "trestbps": 145,
    "chol": 233,
    "fbs": 1,
    "restecg": 0,
    "thalach": 150,
    "exang": 0,
    "oldpeak": 2.3,
    "slope": 0,
    "ca": 0,
    "thal": 1
  }'

# Expected output:
# {"prediction":1,"probability":0.85,"risk_level":"high"}
```

**Screenshot the API response for your assignment!** 📸

---

## 5️⃣ **Docker Build** ✅

### **Build and Run Docker Container:**

```bash
# Build Docker image
docker build -t heart-disease-api .

# Expected output:
# ✅ Successfully built <image_id>
# ✅ Successfully tagged heart-disease-api:latest

# Run container
docker run -p 8000:8000 heart-disease-api

# Test in another terminal
curl http://localhost:8000/health
```

**Screenshot successful Docker build for your assignment!** 📸

---

## 6️⃣ **Git Repository Status** ✅

### **Check Git Status:**

```bash
# Check current status
git status

# Expected output:
# On branch main
# Your branch is up to date with 'origin/main'.
# nothing to commit, working tree clean

# Check recent commits
git log --oneline -5

# Expected output:
# 8012f48 Format: Apply black formatting to all Python files
# d057f75 Fix: Remove unused pandas import in test_model.py
# 41f3017 Fix: Resolve all linting errors (unused imports, f-strings, E402)
# b390ee1 Fix: Increase sample data size for stratified split tests
# ...
```

---

## 7️⃣ **Documentation Check** ✅

### **Verify All Documentation Exists:**

```bash
ls -la *.md

# Expected files:
# ✅ README.md
# ✅ SETUP.md
# ✅ HYBRID_WORKFLOW_GUIDE.md
# ✅ TESTING_AND_CICD_GUIDE.md
# ✅ TEST_FIX_SUMMARY.md
# ✅ LINTING_FIX_SUMMARY.md
# ✅ CODE_QUALITY_FINAL_SUMMARY.md
# ✅ QUICK_VERIFICATION_CHECKLIST.md (this file)
```

---

## 8️⃣ **Assignment Submission Checklist** 📋

### **Before Submitting:**

- [ ] ✅ GitHub Actions pipeline is green
- [ ] ✅ All 23 tests passing
- [ ] ✅ Black formatting applied
- [ ] ✅ Ruff linting passes (0 errors)
- [ ] ✅ MLflow experiments visible
- [ ] ✅ API endpoints working
- [ ] ✅ Docker image builds successfully
- [ ] ✅ README.md is complete
- [ ] ✅ All documentation files present
- [ ] ✅ Screenshots taken for submission

---

## 📸 **Screenshots to Include in Assignment:**

1. **GitHub Actions Pipeline** - All jobs passing ✅
2. **MLflow UI** - Experiments and runs visible ✅
3. **API Response** - Successful prediction ✅
4. **Docker Build** - Successful build output ✅
5. **Test Results** - All 23 tests passing ✅

---

## 🎯 **Quick Command Reference:**

```bash
# Run all tests
pytest tests/ -v

# Check formatting
black --check src/ tests/ scripts/

# Start MLflow UI
mlflow ui --port 5001

# Start API server
uvicorn src.api.app:app --reload --port 8000

# Build Docker image
docker build -t heart-disease-api .

# Run Docker container
docker run -p 8000:8000 heart-disease-api

# Check Git status
git status

# View recent commits
git log --oneline -5
```

---

## ✅ **Final Verification:**

**Run this one-liner to check everything:**

```bash
echo "=== Code Quality ===" && \
black --check src/ tests/ scripts/ && \
echo "=== Tests ===" && \
pytest tests/ -v && \
echo "=== Git Status ===" && \
git status && \
echo "=== All Checks Complete! ==="
```

**Expected output:**
```
=== Code Quality ===
✅ All done! ✨ 🍰 ✨
✅ 16 files would be left unchanged.

=== Tests ===
✅ ======================== 23 passed in 3.45s ========================

=== Git Status ===
On branch main
Your branch is up to date with 'origin/main'.
nothing to commit, working tree clean

=== All Checks Complete! ===
```

---

## 🎉 **You're Ready to Submit!**

**If all checks pass, your assignment is:**
- ✅ Production-ready
- ✅ Professionally formatted
- ✅ Fully tested
- ✅ CI/CD enabled
- ✅ Ready for full marks!

**Good luck!** 🚀

