# ⚡ Hybrid Setup - Quick Commands

## 🖥️ LOCAL MACHINE (Mac) - Copy-Paste Ready

### **Push Code to GitHub:**
```bash
cd /Users/chandrababu.y/self/bits/assignments/mlops/heart-disease-mlops
git add .
git commit -m "Update: testing and CI/CD"
git push origin main
```

### **SSH to Remote Server:**
```bash
# Replace with your actual server details
ssh username@your-remote-server-ip

# Example:
# ssh ubuntu@192.168.1.100
```

---

## 🖥️ REMOTE SERVER (Linux) - Copy-Paste Ready

### **Pull Latest Code:**
```bash
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
git pull origin main
source .venv/bin/activate
```

### **Run Tests:**
```bash
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
source .venv/bin/activate
pytest tests/ -v --cov=src --cov-report=term --cov-report=html
```

### **Run Training:**
```bash
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
source .venv/bin/activate
python scripts/train.py
```

### **Start MLflow UI:**
```bash
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
source .venv/bin/activate
mlflow ui --host 0.0.0.0 --port 5000
```

### **Start FastAPI:**
```bash
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
source .venv/bin/activate
uvicorn src.api.app:app --host 0.0.0.0 --port 8000 --reload
```

---

## 🌐 BROWSER (Local Mac) - URLs to Open

### **Access Remote Services:**
```
# Replace <REMOTE_IP> with your server IP

# MLflow UI
http://<REMOTE_IP>:5000

# FastAPI
http://<REMOTE_IP>:8000

# API Documentation
http://<REMOTE_IP>:8000/docs

# GitHub Actions
https://github.com/2024aa05820/heart-disease-mlops/actions
```

---

## 🔄 Complete Workflow (Copy-Paste in Order)

### **1. LOCAL: Push Code**
```bash
cd /Users/chandrababu.y/self/bits/assignments/mlops/heart-disease-mlops
git add .
git commit -m "Trigger CI/CD and testing"
git push origin main
```

### **2. REMOTE: Pull and Test**
```bash
ssh username@remote-server
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
git pull origin main
source .venv/bin/activate
pytest tests/ -v --cov=src --cov-report=term --cov-report=html
```

### **3. REMOTE: Start MLflow (in tmux)**
```bash
# On remote server
tmux new -s mlflow
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
source .venv/bin/activate
mlflow ui --host 0.0.0.0 --port 5000

# Detach: Ctrl+b, then d
# Reattach later: tmux attach -t mlflow
```

### **4. LOCAL: Open Browser**
```bash
# Open these URLs in your Mac browser:
# http://<REMOTE_IP>:5000  (MLflow)
# https://github.com/2024aa05820/heart-disease-mlops/actions  (CI/CD)
```

---

## 📸 Screenshot Checklist

### **From Remote Terminal (4 screenshots):**
```bash
# SSH to remote and run these, screenshot each:

# 1. Test output
pytest tests/ -v

# 2. Coverage report
pytest tests/ -v --cov=src --cov-report=term

# 3. Training output
python scripts/train.py

# 4. MLflow UI starting
mlflow ui --host 0.0.0.0 --port 5000
```

### **From Local Browser (14 screenshots):**
```
# MLflow UI (7 screenshots)
http://<REMOTE_IP>:5000
- Experiments list
- Logistic Regression run details
- Random Forest run details
- Compare runs
- ROC curve artifact
- Confusion matrix artifact
- Feature importance artifact

# GitHub Actions (7 screenshots)
https://github.com/2024aa05820/heart-disease-mlops/actions
- Workflow runs list
- Successful run overview
- Lint job details
- Test job details
- Train job details
- Docker job details
- Artifacts section
```

---

## 🛠️ Useful tmux Commands

### **Manage Long-Running Processes:**
```bash
# Create new session
tmux new -s mlflow

# List sessions
tmux ls

# Attach to session
tmux attach -t mlflow

# Detach from session
# Press: Ctrl+b, then d

# Kill session
tmux kill-session -t mlflow

# Create multiple windows in session
# Ctrl+b, then c (create)
# Ctrl+b, then n (next)
# Ctrl+b, then p (previous)
```

---

## 🔐 SSH Tunneling (if ports blocked)

### **Access Remote Services via SSH Tunnel:**
```bash
# From local Mac, create tunnel
ssh -L 5000:localhost:5000 -L 8000:localhost:8000 user@remote-server

# Then access in browser:
http://localhost:5000  # MLflow
http://localhost:8000  # API
```

---

## ⚡ One-Command Execution

### **LOCAL: Complete Push Workflow**
```bash
cd /Users/chandrababu.y/self/bits/assignments/mlops/heart-disease-mlops && \
git add . && \
git commit -m "Update: $(date '+%Y-%m-%d %H:%M')" && \
git push origin main && \
echo "✅ Pushed to GitHub - CI/CD triggered!"
```

### **REMOTE: Complete Test Workflow**
```bash
cd ~/Documents/mlops-assignment-1/heart-disease-mlops && \
git pull origin main && \
source .venv/bin/activate && \
pytest tests/ -v --cov=src --cov-report=term --cov-report=html && \
echo "✅ Tests complete!"
```

### **REMOTE: Complete Training Workflow**
```bash
cd ~/Documents/mlops-assignment-1/heart-disease-mlops && \
source .venv/bin/activate && \
python scripts/download_data.py && \
python scripts/train.py && \
echo "✅ Training complete!"
```

### **REMOTE: Start All Services**
```bash
# Terminal 1: MLflow
tmux new -s mlflow
cd ~/Documents/mlops-assignment-1/heart-disease-mlops && \
source .venv/bin/activate && \
mlflow ui --host 0.0.0.0 --port 5000

# Terminal 2: API
tmux new -s api
cd ~/Documents/mlops-assignment-1/heart-disease-mlops && \
source .venv/bin/activate && \
uvicorn src.api.app:app --host 0.0.0.0 --port 8000 --reload
```

---

## 🆘 Quick Troubleshooting

### **Can't SSH:**
```bash
# Check SSH service on remote
ssh -v user@remote-server

# Use SSH key
ssh -i ~/.ssh/id_rsa user@remote-server
```

### **Can't Access Ports:**
```bash
# On remote server, check if running
netstat -tulpn | grep 5000
netstat -tulpn | grep 8000

# Open firewall
sudo ufw allow 5000
sudo ufw allow 8000

# Or use SSH tunnel (from local)
ssh -L 5000:localhost:5000 user@remote-server
```

### **Git Pull Fails:**
```bash
# On remote server
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
git stash
git pull origin main
git stash pop
```

### **Virtual Environment Issues:**
```bash
# On remote server
cd ~/Documents/mlops-assignment-1/heart-disease-mlops

# Recreate venv
rm -rf .venv
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

---

## 📋 Daily Workflow Checklist

### **Morning Routine:**
- [ ] LOCAL: `git pull origin main`
- [ ] REMOTE: SSH and `git pull origin main`
- [ ] REMOTE: Check services running (`tmux ls`)

### **Development Cycle:**
- [ ] LOCAL: Edit code
- [ ] LOCAL: `git push origin main`
- [ ] REMOTE: `git pull origin main`
- [ ] REMOTE: Test changes
- [ ] BROWSER: Verify in MLflow/API

### **Before Submission:**
- [ ] All tests passing
- [ ] MLflow UI accessible
- [ ] API running
- [ ] CI/CD pipeline successful
- [ ] All screenshots taken
- [ ] Report updated
- [ ] Demo video recorded

---

## 🎯 Quick Status Check

### **LOCAL:**
```bash
cd /Users/chandrababu.y/self/bits/assignments/mlops/heart-disease-mlops
git status
git log --oneline -5
```

### **REMOTE:**
```bash
ssh user@remote-server
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
git status
git log --oneline -5
tmux ls  # Check running sessions
ps aux | grep -E "mlflow|uvicorn"  # Check running processes
```

### **GITHUB:**
```
# Browser:
https://github.com/2024aa05820/heart-disease-mlops/actions
# Check latest pipeline run
```

---

**Save this file for quick reference during execution!** ⚡

