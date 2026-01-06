# 📊 Grafana Setup Guide - Connect to Prometheus & Build Dashboards

Complete guide to set up Grafana, connect it to Prometheus, and create monitoring dashboards for the Heart Disease API.

---

## 🚀 Quick Start (3 Steps)

### Step 1: Deploy Monitoring Stack

```bash
# Deploy Prometheus and Grafana to Kubernetes
./scripts/setup-monitoring.sh
```

### Step 2: Access Grafana

```bash
# Port forward Grafana to your local machine
kubectl port-forward service/grafana 3000:3000
```

Then open: **http://localhost:3000**

### Step 3: Login

- **Username**: `admin`
- **Password**: `admin`
- (You'll be prompted to change password on first login)

---

## 📡 Connect Grafana to Prometheus

### Method 1: Using the Web UI (Recommended)

1. **Login to Grafana** at http://localhost:3000

2. **Add Data Source**:
   - Click the **⚙️ gear icon** (Configuration) in the left sidebar
   - Click **Data Sources**
   - Click **Add data source**

3. **Select Prometheus**:
   - Click on **Prometheus** from the list

4. **Configure Connection**:
   ```
   Name: Prometheus
   URL: http://prometheus:9090
   Access: Server (default)
   ```
   
   **Important**: Use `http://prometheus:9090` (not `localhost`) because Grafana runs inside Kubernetes and needs to use the service name.

5. **Save & Test**:
   - Scroll down and click **Save & Test**
   - You should see: ✅ "Data source is working"

---

### Method 2: Using Configuration File (Advanced)

Create a datasource provisioning file (already done in the setup):

```yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
```

---

## 📊 Build Your First Dashboard

### Option A: Import Pre-built Dashboard (Fastest)

I'll create a pre-built dashboard for you. See the next section.

### Option B: Create Dashboard Manually

1. **Create New Dashboard**:
   - Click **+ icon** in left sidebar
   - Click **Dashboard**
   - Click **Add new panel**

2. **Configure Panel**:
   - **Data Source**: Select "Prometheus"
   - **Metric**: Enter a PromQL query (see examples below)
   - **Panel Title**: Give it a descriptive name
   - **Visualization**: Choose chart type (Time series, Gauge, Stat, etc.)

3. **Save Dashboard**:
   - Click **Save** (disk icon) in top right
   - Give it a name: "Heart Disease API Monitoring"
   - Click **Save**

---

## 📈 Useful PromQL Queries

### 1. Total Predictions

```promql
# Total predictions made
sum(predictions_total)
```

### 2. Predictions by Result

```promql
# Predictions by result (disease/no disease)
sum by (result) (predictions_total)
```

### 3. Prediction Rate (per second)

```promql
# Rate of predictions per second
rate(predictions_total[5m])
```

### 4. Average Prediction Latency

```promql
# Average prediction time in seconds
rate(prediction_latency_seconds_sum[5m]) / rate(prediction_latency_seconds_count[5m])
```

### 5. 95th Percentile Latency

```promql
# 95th percentile of prediction latency
histogram_quantile(0.95, rate(prediction_latency_seconds_bucket[5m]))
```

### 6. Request Count by Endpoint

```promql
# Total requests by endpoint
sum by (endpoint) (request_count_total)
```

### 7. Request Rate by Status Code

```promql
# Request rate by HTTP status code
sum by (status) (rate(request_count_total[5m]))
```

### 8. Error Rate

```promql
# Percentage of 5xx errors
sum(rate(request_count_total{status=~"5.."}[5m])) / sum(rate(request_count_total[5m])) * 100
```

---

## 🎨 Dashboard Layout Suggestions

### Row 1: Overview
- **Total Predictions** (Stat panel)
- **Predictions/sec** (Gauge panel)
- **Average Latency** (Stat panel)
- **Error Rate** (Gauge panel)

### Row 2: Predictions
- **Predictions Over Time** (Time series)
- **Predictions by Result** (Pie chart)

### Row 3: Performance
- **Prediction Latency** (Time series)
- **Latency Distribution** (Heatmap)

### Row 4: Requests
- **Request Rate by Endpoint** (Time series)
- **HTTP Status Codes** (Bar chart)

---

## 🔧 Step-by-Step: Create a Complete Dashboard

I'll create a JSON dashboard file you can import. Continue reading...

---

## 📝 Dashboard Best Practices

1. **Use Time Ranges**: Set appropriate time ranges (Last 1h, Last 24h, etc.)
2. **Add Variables**: Create variables for filtering (e.g., by endpoint)
3. **Set Refresh Rate**: Auto-refresh every 5s or 10s
4. **Use Thresholds**: Set color thresholds for alerts (green/yellow/red)
5. **Add Descriptions**: Add panel descriptions for clarity
6. **Organize Rows**: Group related panels in rows

---

## 🎯 Common Dashboard Panels

### Panel 1: Total Predictions (Stat)
```
Query: sum(predictions_total)
Visualization: Stat
Title: Total Predictions
```

### Panel 2: Prediction Rate (Gauge)
```
Query: sum(rate(predictions_total[5m]))
Visualization: Gauge
Title: Predictions/sec
Min: 0
Max: 10
Thresholds: 0 (green), 5 (yellow), 8 (red)
```

### Panel 3: Average Latency (Time Series)
```
Query: rate(prediction_latency_seconds_sum[5m]) / rate(prediction_latency_seconds_count[5m])
Visualization: Time series
Title: Average Prediction Latency
Unit: seconds (s)
```

### Panel 4: Predictions by Result (Pie Chart)
```
Query: sum by (result) (predictions_total)
Visualization: Pie chart
Title: Predictions by Result
Legend: {{result}}
```

---

## 🚨 Setting Up Alerts

### Create Alert Rule:

1. **Edit Panel** → **Alert** tab
2. **Create Alert Rule**
3. **Condition**: 
   ```
   WHEN avg() OF query(A, 5m, now) IS ABOVE 1
   ```
4. **Notifications**: Configure notification channel (email, Slack, etc.)

### Example Alert: High Error Rate

```
Alert Name: High Error Rate
Condition: Error rate > 5%
Query: sum(rate(request_count_total{status=~"5.."}[5m])) / sum(rate(request_count_total[5m])) * 100
Threshold: 5
```

---

## 🔍 Troubleshooting

### Grafana Can't Connect to Prometheus

**Problem**: "Data source is not working"

**Solutions**:
1. Check Prometheus is running:
   ```bash
   kubectl get pods | grep prometheus
   ```

2. Verify Prometheus service:
   ```bash
   kubectl get service prometheus
   ```

3. Test Prometheus from within cluster:
   ```bash
   kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://prometheus:9090/api/v1/query?query=up
   ```

4. Check Prometheus URL in Grafana:
   - Must be `http://prometheus:9090` (service name)
   - NOT `http://localhost:9090`

---

### No Metrics Showing

**Problem**: Queries return no data

**Solutions**:
1. Check if API is running:
   ```bash
   kubectl get pods | grep heart-disease-api
   ```

2. Verify API has metrics endpoint:
   ```bash
   kubectl port-forward service/heart-disease-api-service 8000:80
   curl http://localhost:8000/metrics
   ```

3. Check Prometheus is scraping:
   - Go to Prometheus UI: http://localhost:9090
   - Status → Targets
   - Look for `heart-disease-api` job

4. Make some predictions to generate metrics:
   ```bash
   curl -X POST http://localhost:8000/predict \
     -H "Content-Type: application/json" \
     -d '{"age": 63, "sex": 1, "cp": 3, ...}'
   ```

---

## 📚 Next Steps

1. ✅ Connect Grafana to Prometheus
2. ✅ Import pre-built dashboard (see next file)
3. ✅ Customize panels
4. ✅ Set up alerts
5. ✅ Share dashboard with team

---

## 🔗 Useful Links

- **Grafana Docs**: https://grafana.com/docs/
- **PromQL Guide**: https://prometheus.io/docs/prometheus/latest/querying/basics/
- **Dashboard Examples**: https://grafana.com/grafana/dashboards/

---

## 💡 Pro Tips

1. **Use Variables**: Create dashboard variables for dynamic filtering
2. **Template Queries**: Use `label_values()` for dropdown options
3. **Annotations**: Mark deployments and incidents on graphs
4. **Folders**: Organize dashboards in folders
5. **Snapshots**: Share dashboard snapshots with team
6. **Export**: Export dashboards as JSON for version control

---

Continue to the next file for a pre-built dashboard JSON you can import!

