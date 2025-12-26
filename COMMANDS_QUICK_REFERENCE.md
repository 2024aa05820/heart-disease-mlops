# 🚀 Quick Command Reference - Copy & Paste

## 📍 STEP 1: Initial Setup (2 min)
```bash
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
git pull origin main
source .venv/bin/activate
python scripts/check_mlflow_status.py
```

## 📍 STEP 2: Complete Automated Setup (5 min)
```bash
bash scripts/setup_mlflow.sh
```
**This does everything: downloads data, trains models, creates MLflow runs!**

---

## 🔧 Manual Commands (If Needed)

### Download Data
```bash
python scripts/download_data.py
```

### Train Models
```bash
python scripts/train.py
```

### Check Status
```bash
python scripts/check_mlflow_status.py
```

---

## 🌐 Start Services (3 Terminals)

### Terminal 1: MLflow UI
```bash
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
source .venv/bin/activate
mlflow ui --host 0.0.0.0 --port 5000
```
**Access:** `http://<SERVER_IP>:5000`

### Terminal 2: API Server
```bash
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
source .venv/bin/activate
uvicorn src.api.app:app --host 0.0.0.0 --port 8000
```
**Access:** `http://<SERVER_IP>:8000/docs`

### Terminal 3: Testing Commands
```bash
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
source .venv/bin/activate

# Test API
curl http://localhost:8000/health
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"age":63,"sex":1,"cp":3,"trestbps":145,"chol":233,"fbs":1,"restecg":0,"thalach":150,"exang":0,"oldpeak":2.3,"slope":0,"ca":0,"thal":1}'
```

---

## 🐳 Docker Commands

```bash
# Build image
docker build -t heart-disease-api:latest .

# Run container
docker run -d --name heart-api -p 8000:8000 heart-disease-api:latest

# Check logs
docker logs heart-api

# Test
curl http://localhost:8000/health

# Stop & remove
docker stop heart-api
docker rm heart-api
```

---

## ☸️ Kubernetes Commands (Optional)

```bash
# Start minikube
minikube start

# Load image
minikube image load heart-disease-api:latest

# Deploy
kubectl apply -f deploy/k8s/

# Check status
kubectl get pods
kubectl get services

# Port forward
kubectl port-forward service/heart-disease-api-service 8000:80

# Cleanup
kubectl delete -f deploy/k8s/
minikube stop
```

---

## 🧪 Testing Commands

```bash
# Run tests
pytest tests/ -v

# With coverage
pytest tests/ -v --cov=src --cov-report=html

# Linting
black --check src/ tests/ scripts/
ruff check src/ tests/ scripts/
```

---

## 📸 Screenshot Checklist

### MLflow UI (http://SERVER_IP:5000)
- [ ] Experiments list
- [ ] Logistic Regression run details
- [ ] Random Forest run details
- [ ] Compare runs page
- [ ] ROC curve artifact
- [ ] Confusion matrix artifact
- [ ] Feature importance plot

### API (http://SERVER_IP:8000/docs)
- [ ] Swagger UI main page
- [ ] /health endpoint
- [ ] /predict endpoint with input
- [ ] /predict response
- [ ] /metrics endpoint

### Docker
- [ ] `docker build` output
- [ ] `docker images` output
- [ ] `docker ps` output
- [ ] `docker logs` output

### Kubernetes (if deployed)
- [ ] `kubectl get pods`
- [ ] `kubectl get services`
- [ ] `kubectl describe pod`

### Testing
- [ ] `pytest` output
- [ ] Coverage report

### GitHub Actions
- [ ] Workflow runs page
- [ ] Successful pipeline run

---

## 📁 Save Screenshots To:
```bash
mkdir -p reports/screenshots/{mlflow,api,docker,kubernetes,cicd,testing}
```

---

## ⚠️ CRITICAL: Still Need To Do

1. **Write 10-page report (doc/docx)**
   - Use screenshots you collected
   - See `EXECUTION_CHECKLIST.md` for report structure

2. **Record demo video (5-10 min)**
   - Show end-to-end pipeline
   - Use OBS Studio or SimpleScreenRecorder

3. **Update README**
   ```bash
   sed -i 's/YOUR_USERNAME/2024aa05820/g' README.md
   sed -i 's/\[Your Name\]/Chandrababu Yelamuri/g' README.md
   git add README.md
   git commit -m "Update author info"
   git push origin main
   ```

---

## 🆘 Troubleshooting

**MLflow UI empty?**
```bash
python scripts/check_mlflow_status.py
bash scripts/setup_mlflow.sh
```

**Can't access from browser?**
```bash
# SSH tunnel from local machine:
ssh -L 5000:localhost:5000 user@server-ip
ssh -L 8000:localhost:8000 user@server-ip
```

**Virtual env issues?**
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

---

## ⏱️ Time Estimates

- Setup & Training: **5-7 minutes**
- API Testing: **5 minutes**
- Docker: **10 minutes**
- Kubernetes: **15 minutes**
- Screenshots: **10 minutes**
- **Report Writing: 4-5 hours**
- **Video Recording: 1 hour**

---

## 📚 Full Documentation

- **Complete Guide:** `EXECUTION_CHECKLIST.md`
- **MLflow Help:** `MLFLOW_SETUP_GUIDE.md`
- **Quick Start:** `QUICK_START.md`
- **Main README:** `README.md`

---

**All files pushed to:** https://github.com/2024aa05820/heart-disease-mlops

