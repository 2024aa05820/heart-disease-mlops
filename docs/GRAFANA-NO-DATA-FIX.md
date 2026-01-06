# 🔧 Grafana "No Data" Issue - Complete Fix Guide

## 🐛 The Problem

You imported the Grafana dashboard from JSON, but all panels show **"No Data"** even though Prometheus is collecting metrics.

---

## 🎯 Root Cause

The dashboard expects a Prometheus data source named **"Prometheus"**, but it's not configured in Grafana.

**What's happening:**
1. ✅ Prometheus IS scraping metrics from your API
2. ✅ Metrics ARE available (you can see them in Prometheus)
3. ❌ Grafana doesn't know WHERE to get the data from
4. ❌ The data source is missing or misconfigured

---

## ✅ Quick Fix (Automated)

### Option 1: Run the Fix Script

```bash
# On your Rocky Linux server
cd ~/Documents/ml-assign-1/heart-disease-mlops

# Run the automated fix
./scripts/fix-grafana-datasource.sh
```

This script will:
- ✅ Check if Grafana and Prometheus are running
- ✅ Configure Prometheus data source in Grafana
- ✅ Set correct URL: `http://prometheus:9090`
- ✅ Make it the default data source
- ✅ Test the connection

---

## 🛠️ Manual Fix (Step-by-Step)

### Step 1: Access Grafana

```bash
# Port-forward to Grafana
kubectl port-forward service/grafana 3000:3000
```

Open browser: **http://localhost:3000**

Login:
- Username: `admin`
- Password: `admin`

### Step 2: Add Prometheus Data Source

1. Click **⚙️ Configuration** (gear icon) in left sidebar
2. Click **Data Sources**
3. Click **Add data source**
4. Select **Prometheus**

### Step 3: Configure Data Source

**Important settings:**

| Field | Value | Notes |
|-------|-------|-------|
| **Name** | `Prometheus` | Must be exactly "Prometheus" |
| **URL** | `http://prometheus:9090` | In-cluster service name |
| **Access** | `Server (default)` | Grafana accesses Prometheus |
| **Scrape interval** | `15s` | Optional |
| **HTTP Method** | `POST` | Optional |

### Step 4: Test Connection

1. Scroll down
2. Click **Save & Test**
3. Should see: ✅ **"Data source is working"**

If you see an error, check:
- Prometheus service is running: `kubectl get svc prometheus`
- URL is correct: `http://prometheus:9090` (not `http://localhost:9090`)

### Step 5: Re-import Dashboard

1. Click **+ icon** → **Import**
2. Upload `grafana/heart-disease-api-dashboard.json`
3. **Select "Prometheus" from dropdown** ← IMPORTANT!
4. Click **Import**

---

## 🔍 Troubleshooting

### Issue 1: "Data source is not working"

**Symptoms:** Red error when clicking "Save & Test"

**Causes:**
- Prometheus service not running
- Wrong URL
- Network issue

**Fix:**

```bash
# Check Prometheus is running
kubectl get pods -l app=prometheus
kubectl get svc prometheus

# Check Prometheus is accessible
kubectl port-forward service/prometheus 9090:9090
# Visit http://localhost:9090 - should see Prometheus UI

# Check Prometheus has targets
# In Prometheus UI: Status → Targets
# Should see "heart-disease-api" with state "UP"
```

### Issue 2: Dashboard still shows "No Data"

**Symptoms:** Data source works, but dashboard panels are empty

**Possible causes:**

#### A. No metrics generated yet

**Fix:** Make some predictions to generate metrics

```bash
# Port-forward to API
kubectl port-forward service/heart-disease-api-service 8000:80

# Visit http://localhost:8000/docs
# Make some predictions using the Swagger UI
```

#### B. Wrong time range

**Fix:** Adjust time range in Grafana

1. Click **time picker** (top right)
2. Select **Last 5 minutes** or **Last 15 minutes**
3. Click **Apply**

#### C. Metrics not being scraped

**Fix:** Check Prometheus targets

```bash
# Port-forward to Prometheus
kubectl port-forward service/prometheus 9090:9090

# Visit http://localhost:9090/targets
# Look for "heart-disease-api" job
# State should be "UP"
```

If state is "DOWN":
- Check API pods are running: `kubectl get pods -l app=heart-disease-api`
- Check pod annotations: `kubectl get pod <pod-name> -o yaml | grep prometheus`
- Should see:
  ```yaml
  prometheus.io/scrape: "true"
  prometheus.io/port: "8000"
  prometheus.io/path: "/metrics"
  ```

#### D. Wrong metric names

**Fix:** Verify metrics exist in Prometheus

```bash
# In Prometheus UI (http://localhost:9090)
# Go to Graph tab
# Try these queries:

predictions_total
prediction_duration_seconds_count
http_requests_total
```

If metrics don't exist:
- API might not be generating metrics
- Check API logs: `kubectl logs -l app=heart-disease-api`

---

## 📊 Verify Everything is Working

### 1. Check Prometheus Targets

```bash
kubectl port-forward service/prometheus 9090:9090
# Visit: http://localhost:9090/targets
```

Should see:
```
heart-disease-api (1/1 up)
```

### 2. Check Metrics in Prometheus

```bash
# In Prometheus UI: http://localhost:9090/graph
# Run query: predictions_total
```

Should see results with values.

### 3. Check Grafana Data Source

```bash
# In Grafana: http://localhost:3000
# Configuration → Data Sources → Prometheus
# Click "Save & Test"
```

Should see: ✅ "Data source is working"

### 4. Check Dashboard

```bash
# In Grafana: http://localhost:3000
# Dashboards → Heart Disease API Dashboard
```

Should see data in panels (after making predictions).

---

## 🎯 Common Mistakes

| Mistake | Correct Value |
|---------|---------------|
| ❌ URL: `http://localhost:9090` | ✅ `http://prometheus:9090` |
| ❌ URL: `http://prometheus.default.svc.cluster.local:9090` | ✅ `http://prometheus:9090` |
| ❌ Access: Browser | ✅ Server (default) |
| ❌ Data source name: "prometheus" | ✅ "Prometheus" (capital P) |
| ❌ Looking at wrong time range | ✅ Last 5-15 minutes |
| ❌ No predictions made yet | ✅ Make test predictions first |

---

## 🚀 Complete Workflow

```bash
# 1. Deploy monitoring stack
kubectl apply -f deploy/k8s/monitoring.yaml

# 2. Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=grafana
kubectl wait --for=condition=ready pod -l app=prometheus

# 3. Configure Grafana data source (automated)
./scripts/fix-grafana-datasource.sh

# OR configure manually:
# - Access Grafana: http://localhost:3000
# - Add Prometheus data source
# - URL: http://prometheus:9090

# 4. Import dashboard
# - Upload grafana/heart-disease-api-dashboard.json
# - Select "Prometheus" data source

# 5. Generate metrics
kubectl port-forward service/heart-disease-api-service 8000:80
# Visit http://localhost:8000/docs
# Make predictions

# 6. View dashboard
# - Refresh Grafana dashboard
# - Should see data!
```

---

## ✅ Success Checklist

- [ ] Prometheus pod is running
- [ ] Grafana pod is running
- [ ] Prometheus data source added in Grafana
- [ ] Data source URL is `http://prometheus:9090`
- [ ] Data source test shows "working"
- [ ] Dashboard imported
- [ ] Dashboard uses "Prometheus" data source
- [ ] Made test predictions
- [ ] Time range is recent (last 5-15 min)
- [ ] Dashboard shows data! 🎉

---

Your dashboard should now show data! If you still have issues, check the logs:

```bash
# Grafana logs
kubectl logs -l app=grafana

# Prometheus logs
kubectl logs -l app=prometheus

# API logs
kubectl logs -l app=heart-disease-api
```

