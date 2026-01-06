# Prediction Traffic Generation Scripts

Scripts to generate prediction traffic for testing and monitoring the Heart Disease API.

## 📋 Available Scripts

### 1. `generate-prediction-traffic.sh` (Full Featured)

Comprehensive script with detailed logging, error handling, and statistics.

**Features:**
- ✅ Generates random but realistic patient data
- ✅ Configurable request count (default: 500)
- ✅ Configurable interval between requests (default: 1 second)
- ✅ Success/error tracking
- ✅ Summary statistics
- ✅ Can be stopped with Ctrl+C
- ✅ API connectivity check
- ✅ Optional response logging

**Usage:**
```bash
# Basic usage (500 requests, 1 second interval)
./scripts/generate-prediction-traffic.sh

# Custom API URL
API_URL=http://localhost:8000 ./scripts/generate-prediction-traffic.sh

# Custom request count and interval
MAX_REQUESTS=1000 REQUEST_INTERVAL=0.5 ./scripts/generate-prediction-traffic.sh

# Enable response logging
LOG_RESPONSES=true ./scripts/generate-prediction-traffic.sh

# For Kubernetes (port-forward first)
kubectl port-forward service/heart-disease-api-service 8000:80 &
API_URL=http://localhost:8000 ./scripts/generate-prediction-traffic.sh
```

**Environment Variables:**
- `API_URL` - API endpoint URL (default: `http://localhost:8000`)
- `MAX_REQUESTS` - Maximum number of requests (default: `500`)
- `REQUEST_INTERVAL` - Seconds between requests (default: `1`)
- `LOG_RESPONSES` - Log full responses (default: `false`)

---

### 2. `generate-traffic-simple.sh` (Quick & Simple)

Lightweight one-liner version for quick testing.

**Usage:**
```bash
# Basic usage
./scripts/generate-traffic-simple.sh

# Custom parameters
./scripts/generate-traffic-simple.sh http://localhost:8000 1000 0.5
# Arguments: [API_URL] [COUNT] [INTERVAL]
```

---

## 🚀 Quick Start

### Local Development

```bash
# Start API locally (if not running)
python -m uvicorn src.api.app:app --host 0.0.0.0 --port 8000

# In another terminal, generate traffic
./scripts/generate-prediction-traffic.sh
```

### Kubernetes Deployment

```bash
# Port-forward to API service
kubectl port-forward service/heart-disease-api-service 8000:80

# In another terminal, generate traffic
API_URL=http://localhost:8000 ./scripts/generate-prediction-traffic.sh
```

### Remote Server

```bash
# Set API URL to remote server
API_URL=http://your-server:8000 ./scripts/generate-prediction-traffic.sh
```

---

## 📊 Example Output

```
=========================================
🚀 Prediction Traffic Generator
=========================================

ℹ️  API URL: http://localhost:8000
ℹ️  Max Requests: 500
ℹ️  Interval: 1s
ℹ️  Log Responses: false

⚠️  Press Ctrl+C to stop early

ℹ️  Testing API connectivity...
✅ API is reachable

ℹ️  Starting traffic generation...

[500/500] ✅ Success: 500 | ❌ Errors: 0

=========================================
📊 Traffic Generation Summary
=========================================
Total Requests:  500
Successful:      500
Errors:          0
Success Rate:    100%
=========================================

ℹ️  Duration: 500s
ℹ️  Average Rate: 1.00 requests/sec
```

---

## 🎯 Use Cases

### 1. **Load Testing**
```bash
# High load: 1000 requests with 0.1s interval
MAX_REQUESTS=1000 REQUEST_INTERVAL=0.1 ./scripts/generate-prediction-traffic.sh
```

### 2. **Monitoring Dashboard Population**
```bash
# Generate steady traffic for Grafana dashboards
MAX_REQUESTS=500 REQUEST_INTERVAL=1 ./scripts/generate-prediction-traffic.sh
```

### 3. **Stress Testing**
```bash
# Rapid fire requests
MAX_REQUESTS=10000 REQUEST_INTERVAL=0.01 ./scripts/generate-prediction-traffic.sh
```

### 4. **Continuous Monitoring**
```bash
# Run indefinitely (stop with Ctrl+C)
MAX_REQUESTS=999999 REQUEST_INTERVAL=1 ./scripts/generate-prediction-traffic.sh
```

---

## 🔍 Monitoring Results

After running the script, check your monitoring dashboards:

1. **Grafana Dashboard**
   - Total Predictions should increase
   - Predictions/sec should show activity
   - Request Rate by Endpoint should show `/predict` traffic

2. **Prometheus**
   ```bash
   kubectl port-forward service/prometheus 9090:9090
   # Visit http://localhost:9090
   # Query: sum(predictions_total)
   ```

3. **API Logs**
   ```bash
   kubectl logs -l app=heart-disease-api -f
   ```

---

## 🛠️ Troubleshooting

### API Not Reachable

```bash
# Check if API is running
curl http://localhost:8000/health

# For Kubernetes
kubectl get pods -l app=heart-disease-api
kubectl port-forward service/heart-disease-api-service 8000:80
```

### High Error Rate

- Check API logs for errors
- Verify API has enough resources
- Check network connectivity
- Verify API is not rate-limited

### Script Too Slow

- Reduce `REQUEST_INTERVAL` (e.g., `0.5` or `0.1`)
- Run multiple instances in parallel
- Use the simple script for faster execution

---

## 📝 Notes

- The script generates **realistic** patient data within valid ranges
- Each request uses **random** parameters to simulate real-world usage
- The script is **interruptible** - press Ctrl+C to stop early
- Statistics are shown on completion or interruption
- All requests are logged for monitoring in Prometheus/Grafana

---

## 🔗 Related

- [Monitoring Architecture](../docs/MONITORING-ARCHITECTURE.md)
- [Grafana Dashboards](../grafana/README.md)
- [API Documentation](../README.md#api-endpoints)

