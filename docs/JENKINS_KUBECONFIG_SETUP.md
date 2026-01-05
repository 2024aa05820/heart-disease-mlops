# Jenkins Kubeconfig Setup Guide

This guide explains how to set up Jenkins to deploy to Kubernetes using a kubeconfig with embedded certificates.

## 🎯 Why This Approach?

The pipeline was failing with permission errors because Jenkins couldn't read certificate files in `/home/cloud/.minikube/`. 

**Solution:** Use a kubeconfig with **embedded base64-encoded certificates** instead of file paths. This is the industry-standard approach for CI/CD systems.

---

## 📋 One-Time Setup (5 minutes)

### Step 1: Generate Kubeconfig with Embedded Certs

SSH into your Jenkins server and run:

```bash
# Navigate to the project directory
cd /var/lib/jenkins/workspace/heart-disease-mlops

# Pull latest changes
git pull

# Run the generator script
./scripts/generate-kubeconfig-for-jenkins.sh
```

This creates a file called `jenkins-kubeconfig.yaml` with embedded certificates.

---

### Step 2: Download the Kubeconfig File

Copy the file to your local machine:

```bash
# From your local machine
scp <user>@<jenkins-server>:/var/lib/jenkins/workspace/heart-disease-mlops/jenkins-kubeconfig.yaml .
```

**OR** if you're already on the Jenkins server, just note the file location.

---

### Step 3: Upload to Jenkins as a Credential

1. **Open Jenkins UI** in your browser
2. **Navigate to:** `Manage Jenkins` → `Credentials` → `System` → `Global credentials (unrestricted)`
3. **Click:** `Add Credentials`
4. **Fill in the form:**
   - **Kind:** `Secret file`
   - **File:** Click `Choose File` and select `jenkins-kubeconfig.yaml`
   - **ID:** `kubeconfig-minikube` (⚠️ **MUST be exactly this**)
   - **Description:** `Minikube kubeconfig with embedded certs`
5. **Click:** `Create`

---

### Step 4: Verify the Credential

1. Go back to `Manage Jenkins` → `Credentials`
2. You should see a credential with ID `kubeconfig-minikube`

---

### Step 5: Trigger a Build

1. Go to your pipeline job
2. Click `Build Now`
3. The deployment should now work! ✅

---

## 🔍 How It Works

### Before (Failed):
```yaml
users:
- name: minikube
  user:
    client-certificate: /home/cloud/.minikube/.../client.crt  # ❌ Jenkins can't read this
    client-key: /home/cloud/.minikube/.../client.key          # ❌ Jenkins can't read this
```

### After (Works):
```yaml
users:
- name: minikube
  user:
    client-certificate-data: LS0tLS1CRUdJTi...  # ✅ Base64-encoded cert (no file path)
    client-key-data: LS0tLS1CRUdJTiBSU0E...      # ✅ Base64-encoded key (no file path)
```

---

## 🔄 When to Regenerate

You'll need to regenerate and re-upload the kubeconfig if:

- Minikube certificates expire (usually after 1 year)
- You delete and recreate the minikube cluster
- You see authentication errors in Jenkins

Just re-run the script and update the Jenkins credential.

---

## 🛡️ Security Notes

- ✅ The kubeconfig file contains credentials - keep it secure!
- ✅ Jenkins stores credentials encrypted at rest
- ✅ The credential is only accessible to authorized Jenkins jobs
- ⚠️ Delete the `jenkins-kubeconfig.yaml` file after uploading to Jenkins

---

## 🐛 Troubleshooting

### Error: "Credential 'kubeconfig-minikube' not found"

**Solution:** Make sure you uploaded the credential with **exactly** the ID `kubeconfig-minikube`

### Error: "Unable to connect to the server"

**Solution:** The kubeconfig might be pointing to the wrong server. Regenerate it:
```bash
./scripts/generate-kubeconfig-for-jenkins.sh
```

### Error: "x509: certificate has expired"

**Solution:** Minikube certificates expired. Regenerate them:
```bash
minikube update-context
./scripts/generate-kubeconfig-for-jenkins.sh
```
Then re-upload to Jenkins.

---

## ✅ Success Indicators

When the setup is correct, you'll see in the Jenkins console:

```
🚀 Deploying to Kubernetes...
Kubernetes control plane is running at https://192.168.49.2:8443
deployment.apps/heart-disease-api configured
deployment.apps/heart-disease-api restarted
Waiting for deployment "heart-disease-api" rollout to finish...
deployment "heart-disease-api" successfully rolled out
```

---

## 📚 Additional Resources

- [Kubernetes Authentication](https://kubernetes.io/docs/reference/access-authn-authz/authentication/)
- [Jenkins Credentials Plugin](https://plugins.jenkins.io/credentials/)
- [Kubeconfig File Format](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/)

