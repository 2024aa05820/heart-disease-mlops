# 🔄 Hybrid Workflow Guide - Local Git + Remote Server

## 🏗️ Your Setup

```
┌─────────────────────────────────────────────────────────────┐
│                    LOCAL MACHINE (Mac)                      │
│                                                             │
│  - Git repository (code editing)                           │
│  - Push/pull from GitHub                                   │
│  - VS Code / IDE                                           │
│  - Augment AI assistant                                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            ↕️ (git push/pull)
┌─────────────────────────────────────────────────────────────┐
│                        GITHUB                               │
│                                                             │
│  - Central repository                                      │
│  - GitHub Actions (CI/CD)                                  │
│  - Version control                                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                            ↕️ (git pull)
┌─────────────────────────────────────────────────────────────┐
│                    REMOTE LINUX SERVER                      │
│                                                             │
│  - Execute training (python scripts/train.py)              │
│  - Run tests (pytest)                                      │
│  - Run MLflow UI                                           │
│  - Run FastAPI                                             │
│  - Docker/Kubernetes deployment                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Complete Workflow

### **Workflow Pattern:**

```
LOCAL MACHINE          GITHUB              REMOTE SERVER
     │                    │                      │
     │  1. Edit code      │                      │
     │  (VS Code)         │                      │
     │                    │                      │
     │  2. git add .      │                      │
     │     git commit     │                      │
     │     git push ──────┼──────────────────────┤
     │                    │                      │
     │                    │  3. Triggers         │
     │                    │     GitHub Actions   │
     │                    │     (CI/CD)          │
     │                    │                      │
     │                    │                      │  4. SSH to server
     │                    │                      │     git pull
     │                    │                      │
     │                    │                      │  5. Execute:
     │                    │                      │     - pytest
     │                    │                      │     - train.py
     │                    │                      │     - mlflow ui
     │                    │                      │     - API
     │                    │                      │
     │  6. Take screenshots from:               │
     │     - Remote server terminal             │
     │     - MLflow UI (browser)                │
     │     - GitHub Actions (browser)           │
     │                    │                      │
```

---

## 📋 Step-by-Step Workflow

### **STEP 1: Work on Local Machine**

```bash
# On your Mac (local machine)
cd /Users/chandrababu.y/self/bits/assignments/mlops/heart-disease-mlops

# Make changes (if needed)
# Edit files in VS Code

# Commit changes
git add .
git commit -m "Update: <description>"
git push origin main
```

**✅ This triggers GitHub Actions automatically!**

---

### **STEP 2: SSH to Remote Server**

```bash
# From your Mac, SSH to remote server
ssh username@your-remote-server-ip

# Example:
# ssh ubuntu@192.168.1.100
# or
# ssh user@your-server.com
```

---

### **STEP 3: Pull Latest Code on Remote Server**

```bash
# On remote server
cd ~/Documents/mlops-assignment-1/heart-disease-mlops

# Pull latest changes from GitHub
git pull origin main

# Verify files updated
git log -1
ls -la
```

---

### **STEP 4: Execute on Remote Server**

```bash
# Still on remote server
# Activate virtual environment
source .venv/bin/activate

# Run tests
pytest tests/ -v --cov=src --cov-report=term --cov-report=html

# Run training (if needed)
python scripts/train.py

# Start MLflow UI
mlflow ui --host 0.0.0.0 --port 5000

# Start API (in another terminal)
uvicorn src.api.app:app --host 0.0.0.0 --port 8000
```

---

### **STEP 5: Access Services from Local Browser**

```bash
# From your Mac browser, access:

# MLflow UI
http://<remote-server-ip>:5000

# FastAPI
http://<remote-server-ip>:8000

# API Docs
http://<remote-server-ip>:8000/docs

# GitHub Actions
https://github.com/2024aa05820/heart-disease-mlops/actions
```

---

## 🧪 Testing Workflow (Hybrid)

### **Option A: Test on Remote Server (Recommended)**

```bash
# LOCAL: Push code
git add .
git commit -m "Add tests"
git push origin main

# REMOTE: Pull and test
ssh user@remote-server
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
git pull origin main
source .venv/bin/activate
pytest tests/ -v --cov=src --cov-report=term --cov-report=html

# LOCAL: Take screenshot of remote terminal
# (screenshot the SSH session)
```

### **Option B: Test Locally (if Python 3.11+ on Mac)**

```bash
# LOCAL: Test before pushing
cd /Users/chandrababu.y/self/bits/assignments/mlops/heart-disease-mlops
source .venv/bin/activate  # if venv exists locally
pytest tests/ -v

# Then push
git push origin main
```

---

## 🔄 CI/CD Workflow (Hybrid)

### **Trigger CI/CD:**

```bash
# LOCAL: Push to trigger GitHub Actions
git add .
git commit -m "Trigger CI/CD"
git push origin main

# BROWSER: Watch pipeline
# Open: https://github.com/2024aa05820/heart-disease-mlops/actions
# Take screenshots of pipeline running

# REMOTE: Pull results (if artifacts needed)
ssh user@remote-server
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
git pull origin main
```

---

## 📸 Screenshot Strategy (Hybrid Setup)

### **Screenshots from Remote Server Terminal:**

```bash
# SSH to remote server
ssh user@remote-server

# Run commands and screenshot the terminal
pytest tests/ -v
python scripts/train.py
mlflow ui --host 0.0.0.0 --port 5000

# Take screenshots of:
# 1. SSH terminal showing pytest output
# 2. SSH terminal showing training output
# 3. SSH terminal showing MLflow UI starting
```

### **Screenshots from Local Browser:**

```bash
# Open in your Mac browser:

# MLflow UI
http://<remote-ip>:5000
# Take screenshots of experiments, runs, artifacts

# FastAPI Docs
http://<remote-ip>:8000/docs
# Take screenshots of API endpoints

# GitHub Actions
https://github.com/2024aa05820/heart-disease-mlops/actions
# Take screenshots of pipeline runs
```

---

## 🛠️ Common Commands (Hybrid)

### **Local Machine (Mac):**

```bash
# Navigate to project
cd /Users/chandrababu.y/self/bits/assignments/mlops/heart-disease-mlops

# Check status
git status
git log --oneline -5

# Make changes and push
git add .
git commit -m "Description"
git push origin main

# SSH to remote
ssh user@remote-server
```

### **Remote Server (Linux):**

```bash
# Navigate to project
cd ~/Documents/mlops-assignment-1/heart-disease-mlops

# Pull latest
git pull origin main

# Activate environment
source .venv/bin/activate

# Run tasks
pytest tests/ -v
python scripts/train.py
mlflow ui --host 0.0.0.0 --port 5000
uvicorn src.api.app:app --host 0.0.0.0 --port 8000
```

---

## 🔐 SSH Tips

### **Keep SSH Session Alive:**

```bash
# Use tmux or screen to keep processes running
# even after disconnecting

# Install tmux (if not installed)
sudo apt-get install tmux  # Ubuntu/Debian
sudo yum install tmux      # CentOS/RHEL

# Start tmux session
tmux new -s mlops

# Run MLflow UI in tmux
mlflow ui --host 0.0.0.0 --port 5000

# Detach from tmux: Ctrl+b, then d
# Reattach later: tmux attach -t mlops
```

### **Multiple SSH Sessions:**

```bash
# Terminal 1: MLflow UI
ssh user@remote-server
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
source .venv/bin/activate
mlflow ui --host 0.0.0.0 --port 5000

# Terminal 2: FastAPI
ssh user@remote-server
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
source .venv/bin/activate
uvicorn src.api.app:app --host 0.0.0.0 --port 8000

# Terminal 3: Run tests/commands
ssh user@remote-server
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
source .venv/bin/activate
pytest tests/ -v
```

---

## 📊 Complete Execution Flow

### **Full Workflow Example:**

```bash
# ============================================
# STEP 1: LOCAL MACHINE (Mac)
# ============================================
cd /Users/chandrababu.y/self/bits/assignments/mlops/heart-disease-mlops

# Check current status
git status
git pull origin main

# Make any changes (if needed)
# ... edit files ...

# Commit and push
git add .
git commit -m "Ready for testing and CI/CD"
git push origin main

# ✅ This triggers GitHub Actions!


# ============================================
# STEP 2: REMOTE SERVER (Linux)
# ============================================
# SSH to server
ssh user@remote-server

# Navigate and pull
cd ~/Documents/mlops-assignment-1/heart-disease-mlops
git pull origin main

# Activate environment
source .venv/bin/activate

# Run tests
pytest tests/ -v --cov=src --cov-report=term --cov-report=html
# 📸 Screenshot this output!

# Run training (if needed)
python scripts/train.py
# 📸 Screenshot this output!

# Start MLflow UI (in tmux or separate terminal)
tmux new -s mlflow
mlflow ui --host 0.0.0.0 --port 5000
# Ctrl+b, d to detach


# ============================================
# STEP 3: LOCAL BROWSER (Mac)
# ============================================
# Open browser and visit:

# MLflow UI
http://<remote-server-ip>:5000
# 📸 Take 7 screenshots (experiments, runs, artifacts)

# GitHub Actions
https://github.com/2024aa05820/heart-disease-mlops/actions
# 📸 Take 7 screenshots (pipeline, jobs, artifacts)


# ============================================
# STEP 4: COLLECT SCREENSHOTS
# ============================================
# You should have:
# - 4 screenshots from remote terminal (tests, training)
# - 7 screenshots from MLflow UI (browser)
# - 7 screenshots from GitHub Actions (browser)
# Total: 18 screenshots
```

---

## ✅ Checklist for Hybrid Setup

### **Local Machine (Mac):**
- [ ] Git repository cloned
- [ ] Can push/pull from GitHub
- [ ] Can SSH to remote server
- [ ] Browser can access remote services

### **Remote Server (Linux):**
- [ ] Git repository cloned
- [ ] Virtual environment created
- [ ] Dependencies installed
- [ ] Can pull from GitHub
- [ ] Ports 5000, 8000 accessible

### **GitHub:**
- [ ] Repository exists
- [ ] GitHub Actions enabled
- [ ] Workflows configured
- [ ] Can view Actions tab

---

## 🆘 Troubleshooting

### **Can't Access Remote Services:**

```bash
# Check if service is running on remote
ssh user@remote-server
netstat -tulpn | grep 5000  # MLflow
netstat -tulpn | grep 8000  # API

# Check firewall
sudo ufw status
sudo ufw allow 5000
sudo ufw allow 8000

# Or use SSH tunneling
# From local machine:
ssh -L 5000:localhost:5000 user@remote-server
# Then access: http://localhost:5000
```

### **Git Pull Fails on Remote:**

```bash
# On remote server
cd ~/Documents/mlops-assignment-1/heart-disease-mlops

# Check git status
git status

# If conflicts, stash changes
git stash
git pull origin main
git stash pop

# Or reset to remote
git fetch origin
git reset --hard origin/main
```

---

## 🎯 Quick Reference

| Task | Where | Command |
|------|-------|---------|
| Edit code | Local | VS Code |
| Commit code | Local | `git push origin main` |
| Pull code | Remote | `git pull origin main` |
| Run tests | Remote | `pytest tests/ -v` |
| Train models | Remote | `python scripts/train.py` |
| Start MLflow | Remote | `mlflow ui --host 0.0.0.0 --port 5000` |
| Start API | Remote | `uvicorn src.api.app:app --host 0.0.0.0 --port 8000` |
| View MLflow | Local Browser | `http://<remote-ip>:5000` |
| View API | Local Browser | `http://<remote-ip>:8000/docs` |
| View CI/CD | Local Browser | GitHub Actions tab |

---

**This is your optimal workflow for the hybrid setup!** 🚀

