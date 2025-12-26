# 🚀 Jenkins Quick Start - 10 Minutes to Automated Deployment

**Get Jenkins CI/CD running in 10 minutes!**

---

## ✅ What You'll Get

After this setup:
- ✅ Push code to GitHub → Jenkins automatically deploys to Minikube
- ✅ No manual deployment needed
- ✅ Production-like CI/CD pipeline
- ✅ Free and open-source

---

## 📋 Prerequisites

- Remote Linux machine with:
  - Docker installed and running
  - Minikube installed and running
  - Git installed
  - Internet access

---

## 🚀 Quick Setup (10 Minutes)

### **Step 1: Install Jenkins (2 minutes)**

```bash
# SSH to your remote machine
ssh username@remote-server-ip

# Install Java and Jenkins
sudo dnf install java-17-openjdk jenkins -y

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Get initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### **Step 2: Access Jenkins (1 minute)**

```bash
# Open browser
http://your-remote-ip:8080

# Enter initial admin password
# Click "Install suggested plugins"
# Create admin user
# Save and finish
```

### **Step 3: Configure Jenkins (2 minutes)**

```bash
# Add jenkins user to docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

**In Jenkins UI:**
1. Go to: Manage Jenkins → Credentials → System → Global credentials
2. Click "Add Credentials"
3. Select "Username with password"
4. Enter:
   - Username: `2024aa05820`
   - Password: Your GitHub Personal Access Token
   - ID: `github-credentials`
5. Click "Create"

### **Step 4: Create Pipeline Job (2 minutes)**

1. Click "New Item"
2. Name: `heart-disease-mlops-pipeline`
3. Select "Pipeline"
4. Click OK

**Configure:**
- General → ✅ GitHub project
  - URL: `https://github.com/2024aa05820/heart-disease-mlops/`
- Build Triggers → ✅ GitHub hook trigger for GITScm polling
- Pipeline:
  - Definition: "Pipeline script from SCM"
  - SCM: Git
  - Repository URL: `https://github.com/2024aa05820/heart-disease-mlops.git`
  - Credentials: `github-credentials`
  - Branch: `*/main`
  - Script Path: `Jenkinsfile`
- Click "Save"

### **Step 5: Configure GitHub Webhook (2 minutes)**

1. Go to: https://github.com/2024aa05820/heart-disease-mlops/settings/hooks
2. Click "Add webhook"
3. Configure:
   - Payload URL: `http://your-remote-ip:8080/github-webhook/`
   - Content type: `application/json`
   - Events: "Just the push event"
   - ✅ Active
4. Click "Add webhook"

### **Step 6: Test! (1 minute)**

```bash
# Make a small change
echo "# Jenkins test" >> README.md
git add README.md
git commit -m "Test: Jenkins webhook"
git push origin main

# Watch Jenkins automatically build and deploy!
# Go to: http://your-remote-ip:8080/job/heart-disease-mlops-pipeline/
```

---

## 🎉 Success!

**You now have:**
- ✅ Jenkins running on your remote machine
- ✅ GitHub webhook configured
- ✅ Automated deployment pipeline

**Every time you push to GitHub:**
1. GitHub sends webhook to Jenkins
2. Jenkins pulls code
3. Runs tests
4. Trains models
5. Builds Docker image
6. Deploys to Minikube
7. Starts MLflow UI

**All automatically! 🚀**

---

## 📊 Monitor Your Builds

**Jenkins Dashboard:**
- URL: `http://your-remote-ip:8080`
- View build history
- Check console output
- See build status

**Check Deployment:**
```bash
# SSH to remote machine
ssh username@remote-server-ip

# Check pods
kubectl get pods

# Get service URL
minikube service heart-disease-api-service --url

# Test API
curl $(minikube service heart-disease-api-service --url)/health
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

### **Issue: Build fails**
- Check Jenkins console output
- Verify Minikube is running
- Check Docker is running

---

## 📚 Next Steps

1. **Customize Pipeline** - Edit `Jenkinsfile` to add more stages
2. **Add Notifications** - Configure email/Slack notifications
3. **Secure Jenkins** - Enable HTTPS, configure authentication
4. **Monitor Metrics** - Add Prometheus/Grafana monitoring

**See:** [JENKINS_SETUP_GUIDE.md](JENKINS_SETUP_GUIDE.md) for detailed documentation.

---

## ✅ Quick Commands

```bash
# Check Jenkins status
sudo systemctl status jenkins

# Restart Jenkins
sudo systemctl restart jenkins

# View Jenkins logs
sudo journalctl -u jenkins -f

# Check if webhook is configured
curl -X POST http://your-remote-ip:8080/github-webhook/

# Manual build trigger (if needed)
# Go to Jenkins → Job → Build Now
```

---

**You're all set! Happy deploying! 🚀**

