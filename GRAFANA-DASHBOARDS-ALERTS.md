# Grafana Dashboards and Alerts Configuration

This guide explains how to set up Grafana dashboards and Prometheus alerts for the Heart Disease MLOps project.

## 📊 Dashboards

### 1. Heart Disease API - Comprehensive Monitoring

**Location**: `grafana/comprehensive-dashboard.json`

**Panels**:
- **Total Predictions**: Cumulative count of all predictions
- **Predictions/sec**: Current prediction rate (gauge)
- **P95 Prediction Latency**: 95th percentile latency
- **Error Rate %**: Percentage of 5xx errors
- **Prediction Rate Over Time**: Time series of predictions by result
- **Predictions Distribution**: Pie chart of disease vs no-disease
- **Prediction Latency Percentiles**: P50, P95, P99 latency over time
- **Request Rate by Status Code**: HTTP status code breakdown
- **Request Rate by Endpoint**: Traffic per endpoint
- **API Health Status**: Service up/down indicator
- **Request Rate by HTTP Method**: GET vs POST breakdown
- **Heart Disease Detection Rate**: Percentage of positive predictions

### 2. Heart Disease API Monitoring (Basic)

**Location**: `grafana/heart-disease-api-dashboard.json`

A simpler dashboard with core metrics.

## 🚨 Alert Rules

**Location**: `deploy/k8s/prometheus-alerts.yaml`

### API Performance Alerts

1. **High Error Rate (Warning)**
   - Condition: Error rate > 5% for 5 minutes
   - Severity: Warning
   - Description: Monitors 5xx error percentage

2. **Critical Error Rate**
   - Condition: Error rate > 10% for 2 minutes
   - Severity: Critical
   - Description: Immediate attention required

3. **High Prediction Latency (Warning)**
   - Condition: P95 latency > 1.0s for 5 minutes
   - Severity: Warning
   - Description: Performance degradation

4. **Critical Prediction Latency**
   - Condition: P95 latency > 2.0s for 2 minutes
   - Severity: Critical
   - Description: Severe performance issue

5. **API Service Down**
   - Condition: Service unavailable for 1 minute
   - Severity: Critical
   - Description: Complete service outage

6. **Low Request Rate**
   - Condition: Request rate < 0.1 req/s for 10 minutes
   - Severity: Warning
   - Description: Unusual traffic drop

7. **High Prediction Failure Rate**
   - Condition: Prediction failures > 5% for 5 minutes
   - Severity: Warning
   - Description: Model prediction errors

### Kubernetes Resource Alerts

8. **Pod Crash Looping**
   - Condition: Pod restarts detected
   - Severity: Warning
   - Description: Pod instability

9. **High Memory Usage**
   - Condition: Memory usage > 80% for 5 minutes
   - Severity: Warning
   - Description: Resource pressure

10. **High CPU Usage**
    - Condition: CPU usage > 80% for 5 minutes
    - Severity: Warning
    - Description: Resource pressure

## 🚀 Setup Instructions

### Automated Setup (Recommended)

```bash
# Deploy monitoring stack (if not already deployed)
kubectl apply -f deploy/k8s/monitoring.yaml
kubectl apply -f deploy/k8s/prometheus-alerts.yaml

# Wait for services to be ready
kubectl wait --for=condition=ready pod -l app=grafana --timeout=120s
kubectl wait --for=condition=ready pod -l app=prometheus --timeout=120s

# Run setup script
./scripts/setup-grafana-dashboards.sh
```

### Manual Setup

#### 1. Deploy Alert Rules

```bash
kubectl apply -f deploy/k8s/prometheus-alerts.yaml
kubectl rollout restart deployment/prometheus
```

#### 2. Access Grafana

```bash
# Port forward Grafana
kubectl port-forward service/grafana 3000:3000
```

Visit: http://localhost:3000
- Username: `admin`
- Password: `admin`

#### 3. Configure Prometheus Datasource

1. Go to **Configuration → Data Sources**
2. Click **Add data source**
3. Select **Prometheus**
4. URL: `http://prometheus:9090`
5. Click **Save & Test**

#### 4. Import Dashboards

1. Go to **Dashboards → Import**
2. Upload `grafana/comprehensive-dashboard.json`
3. Select **Prometheus** as datasource
4. Click **Import**

Repeat for `grafana/heart-disease-api-dashboard.json`

#### 5. View Alerts

1. Go to **Alerting → Alert Rules**
2. You should see all configured alerts
3. Alerts will trigger based on conditions

## 📈 Metrics Exposed by API

The API exposes the following Prometheus metrics:

- `predictions_total{result}` - Total predictions counter
- `prediction_latency_seconds` - Prediction latency histogram
- `request_count_total{method, endpoint, status}` - Request counter

### Example Queries

```promql
# Total predictions
sum(predictions_total)

# Prediction rate
sum(rate(predictions_total[5m]))

# P95 latency
histogram_quantile(0.95, sum(rate(prediction_latency_seconds_bucket[5m])) by (le))

# Error rate
sum(rate(request_count_total{status=~"5.."}[5m])) / sum(rate(request_count_total[5m])) * 100
```

## 🔧 Troubleshooting

### Dashboards Show "No Data"

1. **Check Prometheus is scraping**:
   ```bash
   kubectl port-forward service/prometheus 9090:9090
   # Visit http://localhost:9090/targets
   ```

2. **Verify API metrics endpoint**:
   ```bash
   kubectl port-forward service/heart-disease-api-service 8000:80
   curl http://localhost:8000/metrics
   ```

3. **Check datasource configuration**:
   - Grafana → Configuration → Data Sources
   - Test connection to Prometheus

### Alerts Not Firing

1. **Check Prometheus alert rules**:
   ```bash
   kubectl exec -it deployment/prometheus -- cat /etc/prometheus/alerts/alerts.yml
   ```

2. **View Prometheus alerts**:
   ```bash
   kubectl port-forward service/prometheus 9090:9090
   # Visit http://localhost:9090/alerts
   ```

3. **Check alert evaluation**:
   - Prometheus → Alerts tab
   - Verify rules are loaded and evaluated

### Grafana Connection Issues

1. **Check Grafana pod logs**:
   ```bash
   kubectl logs -l app=grafana
   ```

2. **Verify service is running**:
   ```bash
   kubectl get pods -l app=grafana
   kubectl get service grafana
   ```

## 📚 Additional Resources

- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Alerting](https://prometheus.io/docs/alerting/latest/overview/)
- [PromQL Query Language](https://prometheus.io/docs/prometheus/latest/querying/basics/)

## 🎯 Next Steps

1. ✅ Dashboards imported
2. ✅ Alerts configured
3. ⏭️  Set up alert notifications (email, Slack, etc.)
4. ⏭️  Customize dashboards for your needs
5. ⏭️  Add custom metrics if needed

---

**Need Help?** Check the troubleshooting section or review the Grafana/Prometheus logs.

