# 🔧 Fix: "Cannot uninstall requests" Error

## ❌ The Problem

When running `rocky-setup.sh`, you encountered this error:

```
× Cannot uninstall requests 2.25.1
╰─> The package's contents are unknown: no RECORD file was found for requests.

hint: The package was installed by rpm. You should check if it can uninstall the package.
```

### Why This Happens:

- Rocky Linux installs Python `requests` package via **RPM** (system package manager)
- pip tries to upgrade/uninstall it but **cannot** because it's managed by RPM
- This creates a conflict between system packages and pip packages

---

## ✅ The Solution

We now use a **Python virtual environment** to isolate MLflow and its dependencies from system packages.

### What Changed:

1. **Virtual Environment**: MLflow is installed in `/opt/mlflow-env`
2. **Wrapper Script**: `/usr/local/bin/mlflow` activates the venv automatically
3. **No Conflicts**: System packages remain untouched

---

## 🚀 How to Fix (Two Options)

### Option 1: Fresh Install (Recommended)

If you haven't completed the setup yet:

```bash
# Pull the latest code
cd heart-disease-mlops
git pull origin main

# Run the updated setup script
sudo ./scripts/rocky-setup.sh --skip-update
```

The script will now:
- Create a virtual environment at `/opt/mlflow-env`
- Install MLflow and dependencies in isolation
- Create a wrapper script for easy access
- No more conflicts! ✅

---

### Option 2: Fix Existing Installation

If you already ran the old script and got the error:

```bash
# Pull the latest code
cd heart-disease-mlops
git pull origin main

# Run the fix script
sudo ./scripts/fix-mlflow-install.sh
```

This will:
- Create the virtual environment
- Install MLflow properly
- Set up the wrapper script
- Fix permissions for Jenkins

---

## 🧪 Verify the Fix

After running either option, verify MLflow is working:

```bash
# Check MLflow version
mlflow --version

# Should output something like:
# mlflow, version 2.x.x

# Check the virtual environment
ls -la /opt/mlflow-env

# Start MLflow UI
./scripts/start-mlflow.sh
```

---

## 📋 Technical Details

### Before (Problematic):

```bash
# Direct pip install (conflicts with system packages)
pip3 install mlflow scikit-learn pandas numpy matplotlib seaborn
```

### After (Fixed):

```bash
# Create isolated environment
python3 -m venv /opt/mlflow-env

# Install in virtual environment
source /opt/mlflow-env/bin/activate
pip install mlflow scikit-learn pandas numpy matplotlib seaborn
deactivate

# Create wrapper for easy access
cat > /usr/local/bin/mlflow << 'EOF'
#!/bin/bash
source /opt/mlflow-env/bin/activate
exec python -m mlflow "$@"
EOF
```

---

## 🎯 Benefits of This Approach

1. **No Conflicts**: System packages remain untouched
2. **Clean Installation**: All dependencies isolated
3. **Easy to Use**: Wrapper script makes it transparent
4. **Jenkins Compatible**: Proper permissions set
5. **Reproducible**: Same environment every time

---

## 📁 Files Modified

1. **`scripts/rocky-setup.sh`** - Uses virtual environment
2. **`scripts/start-mlflow.sh`** - Uses venv MLflow command
3. **`start-mlflow-simple.sh`** - Uses venv MLflow command
4. **`scripts/fix-mlflow-install.sh`** - New fix script (NEW!)
5. **`QUICK-START.md`** - Added troubleshooting section

---

## 🔍 How It Works

### When you run `mlflow` command:

1. Wrapper script at `/usr/local/bin/mlflow` is executed
2. It activates the virtual environment: `source /opt/mlflow-env/bin/activate`
3. Runs MLflow from the venv: `python -m mlflow "$@"`
4. All dependencies are loaded from `/opt/mlflow-env`
5. No interference with system packages!

### When Jenkins runs MLflow:

1. Jenkins user has access to `/opt/mlflow-env` (permissions set)
2. Uses the same wrapper script
3. Consistent environment across all users

---

## 🆘 Still Having Issues?

### Check if virtual environment exists:

```bash
ls -la /opt/mlflow-env
```

### Check wrapper script:

```bash
cat /usr/local/bin/mlflow
which mlflow
```

### Check permissions:

```bash
ls -la /opt/mlflow-env | head
# Should show: drwxr-xr-x jenkins jenkins
```

### Reinstall if needed:

```bash
sudo rm -rf /opt/mlflow-env
sudo rm /usr/local/bin/mlflow
sudo ./scripts/fix-mlflow-install.sh
```

---

## 📚 Related Documentation

- **Quick Start**: `QUICK-START.md`
- **Full Setup**: `ROCKY_LINUX_SETUP.md`
- **MLflow Setup**: `MLFLOW-SETUP-SUMMARY.md`
- **Service Access**: `ACCESS-SERVICES.md`

---

## ✅ Summary

**Problem**: pip cannot uninstall RPM-installed packages  
**Solution**: Use Python virtual environment  
**Fix**: Run `sudo ./scripts/fix-mlflow-install.sh`  
**Result**: Clean, isolated MLflow installation ✨

