# ⚡ Quick Access Guide

## 🚀 One-Time Setup

```bash
# 1. Deploy monitoring stack (Prometheus + Grafana)
./scripts/setup-monitoring.sh
```

---

## 🌐 Access All Services (Copy & Paste)

**Open 4 terminals and run these commands:**

### Terminal 1: MLflow UI
```bash
ssh -L 5001:localhost:5001 cloud@192.168.1.100
```
Then visit: **http://localhost:5001**

### Terminal 2: Grafana
```bash
kubectl port-forward service/grafana 3000:3000
```
Then visit: **http://localhost:3000** (admin/admin)

### Terminal 3: Prometheus
```bash
kubectl port-forward service/prometheus 9090:9090
```
Then visit: **http://localhost:9090**

### Terminal 4: API
```bash
kubectl port-forward service/heart-disease-api-service 8000:80
```
Then visit: **http://localhost:8000/docs**

---

## 📊 Quick Links

| Service | URL | Credentials |
|---------|-----|-------------|
| 📊 MLflow | http://localhost:5001 | - |
| 📈 Grafana | http://localhost:3000 | admin/admin |
| 🔍 Prometheus | http://localhost:9090 | - |
| 🚀 API Docs | http://localhost:8000/docs | - |
| 📊 API Metrics | http://localhost:8000/metrics | - |

---

## 🧪 Test API

```bash
# Health check
curl http://localhost:8000/health

# Make prediction
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"age":63,"sex":1,"cp":3,"trestbps":145,"chol":233,"fbs":1,"restecg":0,"thalach":150,"exang":0,"oldpeak":2.3,"slope":0,"ca":0,"thal":1}'
```

---

## 🔧 Troubleshooting

```bash
# Check if services are running
kubectl get pods -l app=heart-disease-api
kubectl get pods -l app=grafana
kubectl get pods -l app=prometheus

# Restart if needed
kubectl rollout restart deployment/heart-disease-api
kubectl rollout restart deployment/grafana
kubectl rollout restart deployment/prometheus
```

---

**For detailed instructions, see [ACCESS_SERVICES.md](ACCESS_SERVICES.md)**

