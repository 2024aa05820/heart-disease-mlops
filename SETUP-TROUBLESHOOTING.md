# Setup Script Troubleshooting Guide

## 🐛 Common Issues and Solutions

### Issue 1: Script Stuck at "Updating system packages"

**Symptoms:**
- Script shows "📦 Updating system packages..." and hangs
- No output for several minutes
- Terminal appears frozen

**Causes:**
- `yum update` can take 10-30 minutes on first run
- Large number of packages to update
- Slow internet connection
- Output redirected to `/dev/null` so you can't see progress

**Solutions:**

#### Option 1: Use the FAST setup script (Recommended)
```bash
# Kill the stuck script
Ctrl+C

# Use the fast version that skips system update
chmod +x setup-project-fast.sh
sudo ./setup-project-fast.sh
```

#### Option 2: Wait it out
- The script IS working, just slowly
- Can take 10-30 minutes on first run
- Be patient and let it complete

#### Option 3: Update system manually first
```bash
# Kill the stuck script
Ctrl+C

# Update system manually (you'll see progress)
sudo yum update -y

# Then run the fast setup
sudo ./setup-project-fast.sh
```

#### Option 4: Skip system update entirely
```bash
# Kill the stuck script
Ctrl+C

# Edit the script to skip update
sudo vi setup-project.sh

# Comment out line 101:
# yum update -y --skip-broken 2>&1 | grep -E "^(Complete|Error|Nothing)" || echo "Updating..."

# Save and run
sudo ./setup-project.sh
```

---

### Issue 2: PostgreSQL Connection Failed

**Symptoms:**
- "❌ PostgreSQL connection failed"
- Script falls back to SQLite

**Solutions:**

#### Check PostgreSQL status
```bash
sudo systemctl status postgresql
```

#### Test connection manually
```bash
PGPASSWORD=mlflow psql -h localhost -U mlflow -d mlflow
```

#### Check authentication config
```bash
sudo cat /var/lib/pgsql/data/pg_hba.conf | grep -v "^#"
```

#### Restart PostgreSQL
```bash
sudo systemctl restart postgresql
sleep 2
PGPASSWORD=mlflow psql -h localhost -U mlflow -d mlflow -c "SELECT 1;"
```

---

### Issue 3: Python Dependencies Installation Slow

**Symptoms:**
- Stuck at "Installing project dependencies"
- Takes more than 5 minutes

**Solutions:**

#### Check if it's actually working
```bash
# In another terminal
ps aux | grep pip
```

#### Use verbose mode
```bash
# Kill the script
Ctrl+C

# Install manually to see progress
source venv/bin/activate
pip install -r requirements.txt
```

---

### Issue 4: MLflow Server Won't Start

**Symptoms:**
- "❌ MLflow server failed to start"

**Solutions:**

#### Check logs
```bash
sudo journalctl -u mlflow -n 50
```

#### Check if port is in use
```bash
sudo lsof -i :5000
```

#### Try starting manually
```bash
source venv/bin/activate
mlflow server \
  --backend-store-uri sqlite:///mlflow.db \
  --default-artifact-root ./mlruns \
  --host 0.0.0.0 \
  --port 5000
```

---

### Issue 5: Model Training Failed

**Symptoms:**
- "❌ Model training failed"

**Solutions:**

#### Check if MLflow is accessible
```bash
curl http://localhost:5000/health
```

#### Check if dataset exists
```bash
ls -lh data/raw/heart.csv
```

#### Train manually
```bash
source venv/bin/activate
export MLFLOW_TRACKING_URI=http://localhost:5000
python src/models/train.py
```

---

## 🚀 Recommended Setup Approach

### For First-Time Setup (Slow but Complete)
```bash
# 1. Update system first (see progress)
sudo yum update -y

# 2. Then run fast setup
sudo ./setup-project-fast.sh
```

### For Quick Setup (Skip Updates)
```bash
# Just run the fast version
sudo ./setup-project-fast.sh
```

### For SQLite (Simplest)
```bash
# Use SQLite backend (no PostgreSQL)
sudo ./setup-project-fast.sh --sqlite
```

---

## 📊 Setup Scripts Comparison

| Script | System Update | Speed | Best For |
|--------|---------------|-------|----------|
| `setup-project.sh` | Yes | Slow (15-30 min) | Fresh systems |
| `setup-project-fast.sh` | No | Fast (5-10 min) | Updated systems |
| `setup-project-fast.sh --sqlite` | No | Fastest (3-5 min) | Development |

---

## 🔍 Debugging Commands

### Check what's running
```bash
ps aux | grep -E "(yum|python|pip)"
```

### Monitor system resources
```bash
top
# or
htop
```

### Check disk space
```bash
df -h
```

### Check internet connection
```bash
ping -c 3 google.com
curl -I https://pypi.org
```

### View all logs
```bash
# MLflow logs
sudo journalctl -u mlflow -f

# System logs
sudo tail -f /var/log/messages
```

---

## ✅ Quick Fix Summary

**Script stuck?**
→ Use `setup-project-fast.sh` instead

**PostgreSQL issues?**
→ Use `--sqlite` flag

**Dependencies slow?**
→ Install manually first: `pip install -r requirements.txt`

**MLflow won't start?**
→ Check logs: `sudo journalctl -u mlflow -n 50`

**Still stuck?**
→ Run steps manually (see docs/COMPLETE-SETUP-GUIDE.md)

---

## 📞 Getting Help

If you're still stuck:

1. Check logs: `sudo journalctl -u mlflow -n 100`
2. Check what's running: `ps aux | grep -E "(yum|python|pip)"`
3. Try the fast setup: `sudo ./setup-project-fast.sh --sqlite`
4. Run steps manually following docs/COMPLETE-SETUP-GUIDE.md

