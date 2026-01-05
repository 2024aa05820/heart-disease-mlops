# 🌐 How to Access All Services

This guide shows you how to access MLflow, Grafana, Prometheus, and the API from your local machine.

---

## 📊 Available Services

| Service | Purpose | Default Port |
|---------|---------|--------------|
| **MLflow UI** | Experiment tracking & model registry | 5001 |
| **Grafana** | Metrics visualization & dashboards | 3000 |
| **Prometheus** | Metrics collection & storage | 9090 |
| **FastAPI** | Heart Disease Prediction API | 8000 |

---

## 🚀 Quick Start

### 1️⃣ Deploy Monitoring Stack (First Time Only)

```bash
# Deploy Prometheus and Grafana to Kubernetes
./scripts/setup-monitoring.sh
```

This will deploy:
- ✅ Prometheus (metrics collection)
- ✅ Grafana (visualization)
- ✅ Auto-configured to scrape API metrics

---

## 🔌 Access Methods

### Method 1: SSH Port Forwarding (Recommended for MLflow)

**Access MLflow UI from your local machine:**

```bash
# Forward MLflow port from Jenkins server to your local machine
ssh -L 5001:localhost:5001 cloud@192.168.1.100

# Keep this terminal open, then visit:
# http://localhost:5001
```

---

### Method 2: kubectl Port Forwarding (Recommended for K8s services)

**Access Grafana:**
```bash
kubectl port-forward service/grafana 3000:3000

# Visit: http://localhost:3000
# Login: admin/admin
```

**Access Prometheus:**
```bash
kubectl port-forward service/prometheus 9090:9090

# Visit: http://localhost:9090
```

**Access API:**
```bash
kubectl port-forward service/heart-disease-api-service 8000:80

# Visit: http://localhost:8000/docs (Swagger UI)
# Visit: http://localhost:8000/metrics (Prometheus metrics)
```

---

### Method 3: Minikube Service (If using Minikube locally)

```bash
# Get service URLs
minikube service heart-disease-api-service --url
minikube service prometheus --url
minikube service grafana --url
```

---

## 📊 Setting Up Grafana Dashboard

### Step 1: Access Grafana
```bash
kubectl port-forward service/grafana 3000:3000
```
Visit: http://localhost:3000

### Step 2: Login
- Username: `admin`
- Password: `admin`
- (You'll be prompted to change password)

### Step 3: Add Prometheus Data Source
1. Click **⚙️ Configuration** → **Data Sources**
2. Click **Add data source**
3. Select **Prometheus**
4. Configure:
   - **Name**: Prometheus
   - **URL**: `http://prometheus:9090`
   - **Access**: Server (default)
5. Click **Save & Test**

### Step 4: Create Dashboard
1. Click **+** → **Dashboard** → **Add new panel**
2. Use these queries to visualize API metrics:

**Request Rate:**
```promql
rate(http_requests_total[5m])
```

**Request Duration:**
```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

**Prediction Count:**
```promql
predictions_total
```

---

## 🧪 Testing the API

### Health Check
```bash
curl http://localhost:8000/health
```

### Make a Prediction
```bash
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
```

### View Metrics
```bash
curl http://localhost:8000/metrics
```

---

## 🔍 Troubleshooting

### MLflow UI not accessible
```bash
# Check if MLflow is running on Jenkins server
ssh cloud@192.168.1.100 "pgrep -f 'mlflow ui'"

# If not running, start it
ssh cloud@192.168.1.100 "cd /var/lib/jenkins/workspace/heart-disease-mlops && nohup mlflow ui --host 0.0.0.0 --port 5001 > mlflow.log 2>&1 &"
```

### Grafana/Prometheus not running
```bash
# Check pod status
kubectl get pods -l app=grafana
kubectl get pods -l app=prometheus

# Redeploy if needed
kubectl delete -f deploy/k8s/monitoring.yaml
kubectl apply -f deploy/k8s/monitoring.yaml
```

### Port forwarding disconnects
```bash
# Use autossh for persistent SSH tunnels
autossh -M 0 -L 5001:localhost:5001 cloud@192.168.1.100

# Or use kubectl with --address to bind to all interfaces
kubectl port-forward --address 0.0.0.0 service/grafana 3000:3000
```

---

## 📝 Summary

**From your local machine, run these commands in separate terminals:**

```bash
# Terminal 1: MLflow
ssh -L 5001:localhost:5001 cloud@192.168.1.100

# Terminal 2: Grafana
kubectl port-forward service/grafana 3000:3000

# Terminal 3: Prometheus
kubectl port-forward service/prometheus 9090:9090

# Terminal 4: API
kubectl port-forward service/heart-disease-api-service 8000:80
```

**Then visit:**
- 📊 MLflow: http://localhost:5001
- 📈 Grafana: http://localhost:3000 (admin/admin)
- 🔍 Prometheus: http://localhost:9090
- 🚀 API Docs: http://localhost:8000/docs
- 📊 API Metrics: http://localhost:8000/metrics

---

**Need help?** Check the logs:
```bash
# API logs
kubectl logs -f -l app=heart-disease-api

# Grafana logs
kubectl logs -f -l app=grafana

# Prometheus logs
kubectl logs -f -l app=prometheus
```

