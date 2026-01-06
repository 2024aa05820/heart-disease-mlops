# 📊 Monitoring Stack Troubleshooting Summary

## 🎯 Your Issue: Grafana Shows "No Data"

### What You Reported
- ✅ Prometheus is collecting metrics (you showed the raw metrics)
- ✅ Metrics like `prometheus_tsdb_*` and `promhttp_*` are visible
- ❌ Grafana dashboard shows "No Data" in all panels

### Root Cause
**Grafana doesn't have a Prometheus data source configured.**

The dashboard JSON expects a data source named "Prometheus" pointing to `http://prometheus:9090`, but this wasn't set up when you imported the dashboard.

---

## ✅ Solutions Provided

### 1. Automated Fix Script
**File**: `scripts/fix-grafana-datasource.sh`

**What it does**:
- Checks Prometheus and Grafana are running
- Configures Prometheus data source via Grafana API
- Sets correct URL: `http://prometheus:9090`
- Makes it the default data source
- Tests the connection

**Usage**:
```bash
./scripts/fix-grafana-datasource.sh
```

### 2. Diagnostic Script
**File**: `scripts/diagnose-monitoring.sh`

**What it checks**:
- ✅ Prometheus pod status
- ✅ Grafana pod status
- ✅ API pod status and annotations
- ✅ Prometheus targets
- ✅ Metrics availability
- ✅ Provides actionable next steps

**Usage**:
```bash
./scripts/diagnose-monitoring.sh
```

### 3. Comprehensive Documentation
**File**: `docs/GRAFANA-NO-DATA-FIX.md`

**Covers**:
- Root cause explanation
- Automated fix instructions
- Manual fix step-by-step
- Troubleshooting for each component
- Common mistakes
- Complete workflow
- Success checklist

### 4. Quick Reference
**File**: `GRAFANA-QUICK-FIX.md`

**Provides**:
- 30-second quick fix
- Common mistakes table
- Diagnostics commands
- Success checklist

---

## 🔧 How to Fix (Choose One)

### Option A: Automated (Recommended)

```bash
# 1. Run the fix script
./scripts/fix-grafana-datasource.sh

# 2. Access Grafana
# http://localhost:3000 (admin/admin)

# 3. Verify data source
# Configuration → Data Sources → Prometheus
# Should show green checkmark

# 4. Import dashboard
# + icon → Import → Upload grafana/heart-disease-api-dashboard.json
# Select "Prometheus" → Import

# 5. Make predictions
kubectl port-forward service/heart-disease-api-service 8000:80
# Visit http://localhost:8000/docs

# 6. View dashboard - should show data!
```

### Option B: Manual

```bash
# 1. Access Grafana
kubectl port-forward service/grafana 3000:3000
# http://localhost:3000 (admin/admin)

# 2. Add Prometheus data source
# Configuration → Data Sources → Add data source → Prometheus
# Name: Prometheus
# URL: http://prometheus:9090
# Save & Test

# 3. Import dashboard
# + icon → Import → Upload JSON
# Select "Prometheus" data source

# 4. Make predictions to generate metrics

# 5. View dashboard
```

---

## 🎓 Key Learnings

### Why "No Data"?

1. **Prometheus collects metrics** from your API pods
2. **Grafana visualizes metrics** from Prometheus
3. **Grafana needs to know WHERE Prometheus is** → Data source configuration
4. **Without data source**, Grafana doesn't know where to get data

### Architecture

```
API Pods (port 8000)
    ↓ /metrics endpoint
Prometheus (scrapes every 15s)
    ↓ stores metrics
Grafana (queries Prometheus)
    ↓ needs data source config!
Dashboard (visualizes data)
```

### Critical Settings

| Setting | Value | Why |
|---------|-------|-----|
| Data source name | `Prometheus` | Dashboard JSON expects this exact name |
| URL | `http://prometheus:9090` | Kubernetes service name (in-cluster) |
| Access | Server (default) | Grafana server accesses Prometheus |
| NOT localhost | ❌ `http://localhost:9090` | Grafana pod can't reach localhost |

---

## 🔍 Verification Steps

### 1. Check Prometheus is Scraping

```bash
kubectl port-forward service/prometheus 9090:9090
# Visit: http://localhost:9090/targets
# Should see: heart-disease-api (1/1 up)
```

### 2. Check Metrics Exist

```bash
# In Prometheus UI: http://localhost:9090/graph
# Query: predictions_total
# Should see: results with values
```

### 3. Check Grafana Data Source

```bash
# In Grafana: http://localhost:3000
# Configuration → Data Sources → Prometheus
# Click "Save & Test"
# Should see: ✅ "Data source is working"
```

### 4. Check Dashboard

```bash
# In Grafana: http://localhost:3000
# Dashboards → Heart Disease API Dashboard
# Should see: data in panels (after making predictions)
```

---

## 📋 Troubleshooting Checklist

Run through this checklist:

```bash
# 1. Monitoring stack deployed?
kubectl get pods -l app=prometheus
kubectl get pods -l app=grafana
# Both should be Running

# 2. API pods running?
kubectl get pods -l app=heart-disease-api
# Should see 2 pods Running

# 3. Prometheus scraping API?
kubectl port-forward service/prometheus 9090:9090
# Visit http://localhost:9090/targets
# Should see heart-disease-api with state UP

# 4. Metrics exist?
# In Prometheus UI: http://localhost:9090/graph
# Query: predictions_total
# Should see results

# 5. Grafana data source configured?
# In Grafana: http://localhost:3000
# Configuration → Data Sources
# Should see "Prometheus" with green checkmark

# 6. Made predictions?
kubectl port-forward service/heart-disease-api-service 8000:80
# Visit http://localhost:8000/docs
# Make some predictions

# 7. Dashboard imported?
# In Grafana: Dashboards
# Should see "Heart Disease API Dashboard"

# 8. Time range correct?
# In dashboard, top right
# Should be "Last 5 minutes" or "Last 15 minutes"
```

---

## 🚀 Next Steps

1. **Pull latest code** (includes all fixes):
   ```bash
   git pull origin main
   ```

2. **Run diagnostics**:
   ```bash
   ./scripts/diagnose-monitoring.sh
   ```

3. **Fix data source**:
   ```bash
   ./scripts/fix-grafana-datasource.sh
   ```

4. **Import dashboard** (if not already done)

5. **Make predictions** to generate metrics

6. **View dashboard** → Should see data! 🎉

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| `GRAFANA-QUICK-FIX.md` | 30-second quick reference |
| `docs/GRAFANA-NO-DATA-FIX.md` | Comprehensive troubleshooting guide |
| `docs/MONITORING-ARCHITECTURE.md` | Architecture and design |
| `grafana/README.md` | Dashboard import instructions |
| `scripts/fix-grafana-datasource.sh` | Automated fix script |
| `scripts/diagnose-monitoring.sh` | Diagnostic script |

---

## ✅ Success Criteria

You'll know it's working when:

1. ✅ `./scripts/diagnose-monitoring.sh` shows all green checkmarks
2. ✅ Prometheus UI shows heart-disease-api target as UP
3. ✅ Grafana data source test shows "working"
4. ✅ Dashboard panels show data (after making predictions)
5. ✅ Metrics update in real-time (5s refresh)

---

**Your monitoring stack is now fully documented and fixable!** 🎉

