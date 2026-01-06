# 📊 Grafana Dashboards

This directory contains pre-built Grafana dashboards for monitoring the Heart Disease API.

---

## 📁 Available Dashboards

### 1. Heart Disease API Monitoring (`heart-disease-api-dashboard.json`)

Complete monitoring dashboard with:
- **Total Predictions** - Total number of predictions made
- **Predictions/sec** - Current prediction rate
- **Average Latency** - Average prediction time
- **Error Rate** - Percentage of failed requests
- **Predictions Over Time** - Time series of predictions by result
- **Predictions by Result** - Pie chart showing distribution

---

## 🚀 How to Import Dashboard

### Method 1: Using Grafana UI (Recommended)

1. **Access Grafana**:
   ```bash
   kubectl port-forward service/grafana 3000:3000
   ```
   Open: http://localhost:3000

2. **Login**:
   - Username: `admin`
   - Password: `admin`

3. **Import Dashboard**:
   - Click **+ icon** in left sidebar
   - Click **Import**
   - Click **Upload JSON file**
   - Select `grafana/heart-disease-api-dashboard.json`
   - Click **Load**

4. **Select Data Source**:
   - Select **Prometheus** from dropdown
   - Click **Import**

5. **Done!** 🎉
   - Your dashboard is now ready
   - It will auto-refresh every 5 seconds

---

### Method 2: Copy-Paste JSON

1. **Open the JSON file**:
   ```bash
   cat grafana/heart-disease-api-dashboard.json
   ```

2. **Copy the entire content**

3. **In Grafana**:
   - Click **+ icon** → **Import**
   - Paste JSON in the text area
   - Click **Load**
   - Select **Prometheus** data source
   - Click **Import**

---

## 🔧 Prerequisites

Before importing, make sure:

1. ✅ **Monitoring stack is deployed**:
   ```bash
   ./scripts/setup-monitoring.sh
   ```

2. ✅ **Prometheus data source is configured**:
   - Go to Configuration → Data Sources
   - Add Prometheus with URL: `http://prometheus:9090`

3. ✅ **API is running and generating metrics**:
   ```bash
   kubectl get pods | grep heart-disease-api
   ```

4. ✅ **Make some predictions** to generate data:
   ```bash
   kubectl port-forward service/heart-disease-api-service 8000:80
   
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

---

## 📊 Dashboard Panels Explained

### Row 1: Key Metrics (Stats & Gauges)

1. **Total Predictions**
   - Query: `sum(predictions_total)`
   - Shows: Total number of predictions since startup
   - Type: Stat panel

2. **Predictions/sec**
   - Query: `sum(rate(predictions_total[5m]))`
   - Shows: Current prediction rate (requests per second)
   - Type: Gauge (0-10 range)
   - Thresholds: Green (0-5), Yellow (5-8), Red (8+)

3. **Avg Prediction Latency**
   - Query: `rate(prediction_latency_seconds_sum[5m]) / rate(prediction_latency_seconds_count[5m])`
   - Shows: Average time to make a prediction
   - Type: Stat panel
   - Unit: Seconds
   - Thresholds: Green (<0.5s), Yellow (0.5-1s), Red (>1s)

4. **Error Rate**
   - Query: `sum(rate(request_count_total{status=~"5.."}[5m])) / sum(rate(request_count_total[5m])) * 100`
   - Shows: Percentage of failed requests (5xx errors)
   - Type: Gauge (0-100%)
   - Thresholds: Green (<1%), Yellow (1-5%), Red (>5%)

### Row 2: Prediction Analysis

5. **Predictions Over Time**
   - Query: `sum by (result) (rate(predictions_total[5m]))`
   - Shows: Time series of predictions split by result (disease/no disease)
   - Type: Time series graph
   - Legend: Shows each result type

6. **Predictions by Result**
   - Query: `sum by (result) (predictions_total)`
   - Shows: Distribution of predictions (pie chart)
   - Type: Pie chart
   - Useful for: Understanding prediction distribution

---

## 🎨 Customizing the Dashboard

### Change Time Range

- Click time picker in top right
- Select: Last 5m, 15m, 1h, 6h, 24h, etc.
- Or set custom range

### Change Refresh Rate

- Click refresh dropdown (top right)
- Select: 5s, 10s, 30s, 1m, etc.
- Or disable auto-refresh

### Edit Panels

1. Click panel title
2. Click **Edit**
3. Modify:
   - Query
   - Visualization type
   - Thresholds
   - Colors
   - Units
4. Click **Apply**

### Add New Panels

1. Click **Add panel** icon (top right)
2. Click **Add new panel**
3. Configure query and visualization
4. Click **Apply**

---

## 📈 Additional Queries You Can Add

### Request Rate by Endpoint
```promql
sum by (endpoint) (rate(request_count_total[5m]))
```

### 95th Percentile Latency
```promql
histogram_quantile(0.95, rate(prediction_latency_seconds_bucket[5m]))
```

### Requests by HTTP Status
```promql
sum by (status) (rate(request_count_total[5m]))
```

### Successful Predictions Rate
```promql
sum(rate(predictions_total{result="disease"}[5m])) + sum(rate(predictions_total{result="no_disease"}[5m]))
```

---

## 🚨 Setting Up Alerts

### Example: High Error Rate Alert

1. **Edit Error Rate panel**
2. Click **Alert** tab
3. **Create alert rule**:
   - Name: High Error Rate
   - Condition: WHEN avg() IS ABOVE 5
   - For: 5m
4. **Add notification**:
   - Configure notification channel first (email, Slack, etc.)
5. **Save**

---

## 💾 Exporting Dashboards

### Export as JSON

1. Click **Dashboard settings** (gear icon)
2. Click **JSON Model**
3. Copy JSON
4. Save to file

### Share Dashboard

1. Click **Share** icon (top right)
2. Options:
   - **Link**: Share URL
   - **Snapshot**: Create public snapshot
   - **Export**: Download JSON

---

## 🔍 Troubleshooting

### Dashboard Shows "No Data"

1. **Check Prometheus connection**:
   - Configuration → Data Sources → Prometheus
   - Click "Save & Test"

2. **Verify metrics exist**:
   - Go to Prometheus UI: http://localhost:9090
   - Run query: `predictions_total`
   - Should show data

3. **Make some predictions**:
   - API needs to receive requests to generate metrics
   - Use the curl command above

### Panels Show Errors

1. **Check PromQL syntax**:
   - Edit panel
   - Check query for typos

2. **Verify metric names**:
   - Go to Prometheus → Graph
   - Type metric name to autocomplete

---

## 📚 Resources

- **Grafana Docs**: https://grafana.com/docs/
- **PromQL Guide**: https://prometheus.io/docs/prometheus/latest/querying/basics/
- **Dashboard Best Practices**: https://grafana.com/docs/grafana/latest/best-practices/

---

## ✅ Quick Checklist

- [ ] Monitoring stack deployed
- [ ] Grafana accessible at http://localhost:3000
- [ ] Prometheus data source configured
- [ ] Dashboard imported
- [ ] API is running
- [ ] Made test predictions
- [ ] Dashboard showing data
- [ ] Auto-refresh enabled

---

Enjoy your monitoring dashboard! 📊🎉

