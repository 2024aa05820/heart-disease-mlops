# 🚨 Grafana "No Data" - Quick Fix

## The Problem
✅ Prometheus is collecting metrics (you can see them)  
❌ Grafana dashboard shows "No Data"

## The Solution
**Grafana needs a Prometheus data source configured!**

---

## 🎯 Quick Fix (30 seconds)

### Option 1: Automated Fix

```bash
cd ~/Documents/ml-assign-1/heart-disease-mlops
./scripts/fix-grafana-datasource.sh
```

### Option 2: Manual Fix

1. **Access Grafana**: http://localhost:3000 (admin/admin)

2. **Add Data Source**:
   - Click ⚙️ Configuration → Data Sources
   - Click "Add data source"
   - Select "Prometheus"

3. **Configure**:
   - **Name**: `Prometheus` (exactly this!)
   - **URL**: `http://prometheus:9090` (NOT localhost!)
   - **Access**: Server (default)
   - Click "Save & Test" → Should show ✅

4. **Re-import Dashboard**:
   - Click + → Import
   - Upload `grafana/heart-disease-api-dashboard.json`
   - **Select "Prometheus"** from dropdown
   - Click Import

5. **Generate Metrics**:
   ```bash
   kubectl port-forward service/heart-disease-api-service 8000:80
   # Visit http://localhost:8000/docs
   # Make some predictions
   ```

6. **Refresh Dashboard** → Should see data! 🎉

---

## 🔍 Diagnostics

```bash
# Check everything
./scripts/diagnose-monitoring.sh

# Check Prometheus targets
kubectl port-forward service/prometheus 9090:9090
# Visit: http://localhost:9090/targets
# Should see "heart-disease-api" with state UP

# Check metrics exist
# In Prometheus UI: http://localhost:9090/graph
# Query: predictions_total
```

---

## ❌ Common Mistakes

| Wrong | Right |
|-------|-------|
| URL: `http://localhost:9090` | `http://prometheus:9090` |
| Access: Browser | Server (default) |
| Name: "prometheus" | "Prometheus" |
| No predictions made | Make test predictions first |
| Wrong time range | Last 5-15 minutes |

---

## 📚 Detailed Guide

See: `docs/GRAFANA-NO-DATA-FIX.md`

---

## ✅ Success Checklist

- [ ] Prometheus pod running
- [ ] Grafana pod running  
- [ ] Data source added: `http://prometheus:9090`
- [ ] Data source test: ✅ working
- [ ] Dashboard imported
- [ ] Made test predictions
- [ ] Dashboard shows data! 🎉

---

**Still stuck?** Check logs:

```bash
kubectl logs -l app=grafana
kubectl logs -l app=prometheus
kubectl logs -l app=heart-disease-api
```

