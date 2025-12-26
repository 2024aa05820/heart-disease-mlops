# 🚀 Jenkins CI/CD Setup for Heart Disease MLOps

**Complete guide to set up Jenkins for automated deployment to Minikube with GitHub webhooks.**

---

## 📋 Overview

This guide shows you how to:
1. Install Jenkins on your remote Linux machine
2. Configure Jenkins to pull from GitHub
3. Set up GitHub webhooks for automatic triggers
4. Deploy to Minikube automatically

---

## 🎯 Architecture

```
GitHub Push → GitHub Webhook → Jenkins → Build Docker Image → Deploy to Minikube
```

**Benefits:**
- ✅ Automatic deployment on every push
- ✅ No need for GitHub Actions minutes
- ✅ Full control over CI/CD pipeline
- ✅ Production-like setup
- ✅ Free and open-source

---

## 📦 Prerequisites

**On your remote Linux machine:**
- Java 11 or 17 (for Jenkins)
- Docker installed
- Minikube running
- kubectl configured
- Git installed

---

## 🔧 Step 1: Install Jenkins

### **On Rocky Linux / RHEL / CentOS:**

```bash
# Install Java (Jenkins requirement)
sudo dnf install java-17-openjdk java-17-openjdk-devel -y

# Verify Java installation
java -version

# Add Jenkins repository
sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Jenkins
sudo dnf install jenkins -y

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Check status
sudo systemctl status jenkins
```

### **On Ubuntu / Debian:**

```bash
# Install Java
sudo apt update
sudo apt install openjdk-17-jdk -y

# Add Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt update
sudo apt install jenkins -y

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

---

## 🌐 Step 2: Access Jenkins

### **Open Firewall (if needed):**

```bash
# Rocky Linux / RHEL / CentOS
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload

# Ubuntu (ufw)
sudo ufw allow 8080/tcp
```

### **Get Initial Admin Password:**

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### **Access Jenkins:**

1. Open browser: `http://your-remote-ip:8080`
2. Enter the initial admin password
3. Click "Install suggested plugins"
4. Create admin user
5. Save and finish

---

## 🔌 Step 3: Install Required Jenkins Plugins

**Go to:** Manage Jenkins → Plugins → Available Plugins

**Install these plugins:**
- ✅ Git Plugin (usually pre-installed)
- ✅ GitHub Plugin
- ✅ Docker Pipeline
- ✅ Kubernetes CLI Plugin (optional)
- ✅ Pipeline

**Restart Jenkins after installation:**
```bash
sudo systemctl restart jenkins
```

---

## 🔑 Step 4: Configure Jenkins Credentials

### **Add GitHub Credentials:**

1. Go to: Manage Jenkins → Credentials → System → Global credentials
2. Click "Add Credentials"
3. Select "Username with password"
4. Enter:
   - **Username:** Your GitHub username (2024aa05820)
   - **Password:** GitHub Personal Access Token (create one if needed)
   - **ID:** `github-credentials`
   - **Description:** GitHub Access Token
5. Click "Create"

### **Create GitHub Personal Access Token:**

1. Go to: https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Select scopes:
   - ✅ `repo` (all)
   - ✅ `admin:repo_hook` (for webhooks)
4. Generate and copy the token
5. Use this token as password in Jenkins credentials

---

## 🔨 Step 5: Add Jenkins User to Docker Group

Jenkins needs permission to run Docker commands:

```bash
# Add jenkins user to docker group
sudo usermod -aG docker jenkins

# Restart Jenkins
sudo systemctl restart jenkins

# Verify
sudo -u jenkins docker ps
```

---

## 📝 Step 6: Create Jenkins Pipeline Job

1. **Go to Jenkins Dashboard**
2. **Click "New Item"**
3. **Enter name:** `heart-disease-mlops-pipeline`
4. **Select:** "Pipeline"
5. **Click OK**

### **Configure the Pipeline:**

**General Section:**
- ✅ Check "GitHub project"
- Project URL: `https://github.com/2024aa05820/heart-disease-mlops/`

**Build Triggers:**
- ✅ Check "GitHub hook trigger for GITScm polling"

**Pipeline Section:**
- Definition: "Pipeline script from SCM"
- SCM: Git
- Repository URL: `https://github.com/2024aa05820/heart-disease-mlops.git`
- Credentials: Select `github-credentials`
- Branch: `*/main`
- Script Path: `Jenkinsfile`

**Click "Save"**

---

## 🪝 Step 7: Configure GitHub Webhook

### **On GitHub:**

1. Go to: https://github.com/2024aa05820/heart-disease-mlops/settings/hooks
2. Click "Add webhook"
3. Configure:
   - **Payload URL:** `http://your-remote-ip:8080/github-webhook/`
   - **Content type:** `application/json`
   - **Secret:** (leave empty for now)
   - **Events:** Select "Just the push event"
   - ✅ Active
4. Click "Add webhook"

### **Test Webhook:**

1. Go back to webhook settings
2. Click on the webhook you just created
3. Scroll to "Recent Deliveries"
4. Click "Redeliver" to test

---

## 🧪 Step 8: Test the Pipeline

### **Manual Trigger:**

1. Go to Jenkins job
2. Click "Build Now"
3. Watch the build progress

### **Automatic Trigger:**

1. Make a small change to your repository
2. Commit and push to GitHub
3. Jenkins should automatically start building

---

## 📊 Step 9: Monitor Builds

**Jenkins Dashboard shows:**
- ✅ Build history
- ✅ Build status (success/failure)
- ✅ Console output
- ✅ Build artifacts

**Access:**
- Dashboard: `http://your-remote-ip:8080`
- Job: `http://your-remote-ip:8080/job/heart-disease-mlops-pipeline/`

---

## 🔒 Security Best Practices

### **1. Enable CSRF Protection:**
- Manage Jenkins → Security → Enable CSRF Protection

### **2. Configure Authentication:**
- Use Jenkins' own user database
- Or integrate with LDAP/Active Directory

### **3. Use HTTPS (Production):**
```bash
# Install nginx as reverse proxy
sudo dnf install nginx -y

# Configure SSL with Let's Encrypt
# (See nginx documentation)
```

### **4. Restrict Access:**
```bash
# Use firewall to limit access
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="your-ip" port port="8080" protocol="tcp" accept'
```

---

## 🛠️ Troubleshooting

### **Issue: Jenkins can't access Docker**
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### **Issue: Webhook not triggering**
- Check firewall allows port 8080
- Verify webhook URL is correct
- Check GitHub webhook delivery logs

### **Issue: Build fails with permission errors**
```bash
# Give Jenkins access to Minikube
sudo usermod -aG docker jenkins
sudo chmod 666 /var/run/docker.sock
```

### **Issue: Can't access Jenkins UI**
```bash
# Check Jenkins is running
sudo systemctl status jenkins

# Check firewall
sudo firewall-cmd --list-ports

# Check logs
sudo journalctl -u jenkins -f
```

---

## ✅ Success Checklist

- [ ] Jenkins installed and running
- [ ] Jenkins accessible at http://remote-ip:8080
- [ ] Required plugins installed
- [ ] GitHub credentials configured
- [ ] Jenkins user added to docker group
- [ ] Pipeline job created
- [ ] GitHub webhook configured
- [ ] Test build successful
- [ ] Automatic trigger working

---

## 🎉 Next Steps

1. **Create Jenkinsfile** - See `Jenkinsfile` in repository
2. **Test deployment** - Push code and watch Jenkins deploy
3. **Monitor builds** - Check Jenkins dashboard
4. **Optimize pipeline** - Add stages, tests, notifications

---

## 📚 Additional Resources

- Jenkins Documentation: https://www.jenkins.io/doc/
- Jenkins Pipeline: https://www.jenkins.io/doc/book/pipeline/
- GitHub Webhooks: https://docs.github.com/en/webhooks

---

**Your Jenkins CI/CD pipeline is ready!** 🚀

