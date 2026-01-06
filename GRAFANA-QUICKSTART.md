# 🚀 Grafana Quick Start - 5 Minutes to Dashboard

Get your Grafana dashboard up and running in 5 minutes!

---

## ⚡ Super Quick Setup (3 Commands)

```bash
# 1. Deploy monitoring stack
./scripts/setup-monitoring.sh

# 2. Access Grafana (in new terminal)
kubectl port-forward service/grafana 3000:3000

# 3. Open browser
# http://localhost:3000
# Login: admin/admin
```

---

## 📊 Import Pre-Built Dashboard

### Step 1: Login to Grafana
- URL: **http://localhost:3000**
- Username: `admin`
- Password: `admin`
- (Change password when prompted, or skip)

### Step 2: Add Prometheus Data Source
1. Click **⚙️ Configuration** (gear icon) → **Data Sources**
2. Click **Add data source**
3. Select **Prometheus**
4. Enter URL: `http://prometheus:9090`
5. Click **Save & Test** ✅

### Step 3: Import Dashboard
1. Click **+ icon** → **Import**
2. Click **Upload JSON file**
3. Select: `grafana/heart-disease-api-dashboard.json`
4. Click **Load**
5. Select **Prometheus** from dropdown
6. Click **Import**

### Step 4: Generate Some Data
```bash
# In another terminal, port-forward the API
kubectl port-forward service/heart-disease-api-service 8000:80

# Make a test prediction
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

### Step 5: Watch the Dashboard! 🎉
- Dashboard auto-refreshes every 5 seconds
- Make more predictions to see live updates

---

## 📈 What You'll See

### Dashboard Panels:

```
┌─────────────────────────────────────────────────────────────────┐
│  Total Predictions  │  Predictions/sec  │  Avg Latency  │  Error Rate  │
│        42           │      2.5 req/s    │    0.15s      │     0%       │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────┬──────────────────────────────┐
│  Predictions Over Time           │  Predictions by Result       │
│                                  │                              │
│  [Time series graph showing      │  [Pie chart showing:         │
│   predictions by result]         │   - Disease: 45%             │
│                                  │   - No Disease: 55%]         │
└──────────────────────────────────┴──────────────────────────────┘
```

---

## 🎯 Key Metrics Explained

| Metric | What It Shows | Good Value |
|--------|---------------|------------|
| **Total Predictions** | Total predictions made | Any number |
| **Predictions/sec** | Current request rate | < 5 req/s (green) |
| **Avg Latency** | Time to make prediction | < 0.5s (green) |
| **Error Rate** | % of failed requests | < 1% (green) |

---

## 🔧 Troubleshooting

### "No Data" in Dashboard?

**Check 1**: Is Prometheus connected?
```bash
# In Grafana: Configuration → Data Sources → Prometheus
# Click "Save & Test" - should see green checkmark
```

**Check 2**: Is API running?
```bash
kubectl get pods | grep heart-disease-api
# Should show: Running
```

**Check 3**: Are metrics being collected?
```bash
# Port-forward Prometheus
kubectl port-forward service/prometheus 9090:9090

# Open: http://localhost:9090
# Query: predictions_total
# Should show data
```

**Check 4**: Make some predictions!
```bash
# API needs requests to generate metrics
# Use the curl command above
```

---

## 📚 Full Documentation

For detailed guides, see:
- **GRAFANA-SETUP-GUIDE.md** - Complete setup guide with PromQL queries
- **grafana/README.md** - Dashboard customization and advanced features
- **ACCESS_SERVICES.md** - How to access all services

---

## 🎨 Customize Your Dashboard

### Change Time Range
- Click time picker (top right)
- Select: Last 5m, 15m, 1h, 6h, 24h

### Add More Panels
1. Click **Add panel** (top right)
2. Select **Add new panel**
3. Choose metric from Prometheus
4. Select visualization type
5. Click **Apply**

### Useful Queries to Add:

**Request Rate by Endpoint:**
```promql
sum by (endpoint) (rate(request_count_total[5m]))
```

**95th Percentile Latency:**
```promql
histogram_quantile(0.95, rate(prediction_latency_seconds_bucket[5m]))
```

**HTTP Status Codes:**
```promql
sum by (status) (rate(request_count_total[5m]))
```

---

## 🚨 Set Up Alerts (Optional)

### Example: High Error Rate Alert

1. Edit **Error Rate** panel
2. Click **Alert** tab
3. Create alert rule:
   - **Condition**: Error rate > 5%
   - **For**: 5 minutes
4. Add notification channel (email, Slack, etc.)
5. Save

---

## ✅ Quick Checklist

- [ ] Monitoring stack deployed (`./scripts/setup-monitoring.sh`)
- [ ] Grafana accessible (http://localhost:3000)
- [ ] Logged in (admin/admin)
- [ ] Prometheus data source added
- [ ] Dashboard imported
- [ ] Made test predictions
- [ ] Dashboard showing data
- [ ] Auto-refresh working (5s)

---

## 🎯 Next Steps

1. ✅ **Explore the dashboard** - Click on panels to see details
2. ✅ **Make more predictions** - Watch metrics update in real-time
3. ✅ **Customize panels** - Add your own queries and visualizations
4. ✅ **Set up alerts** - Get notified of issues
5. ✅ **Share with team** - Export and share dashboard JSON

---

## 💡 Pro Tips

1. **Use Variables**: Create dashboard variables for filtering
2. **Set Thresholds**: Color-code metrics (green/yellow/red)
3. **Add Annotations**: Mark deployments on graphs
4. **Create Folders**: Organize multiple dashboards
5. **Export Regularly**: Save dashboard JSON to version control

---

## 🌐 Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://localhost:3000 | admin/admin |
| **Prometheus** | http://localhost:9090 | None |
| **API** | http://localhost:8000 | None |
| **API Docs** | http://localhost:8000/docs | None |

---

## 🎉 You're All Set!

Your monitoring dashboard is ready! 

- Make predictions → See metrics update in real-time
- Monitor performance → Identify bottlenecks
- Track errors → Get alerted to issues
- Analyze trends → Make data-driven decisions

Happy monitoring! 📊✨

