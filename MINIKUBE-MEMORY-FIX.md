# Minikube Memory Issue - Quick Fix Guide

## 🚨 Problem
Minikube fails to start due to insufficient memory when using the default 4GB configuration.

## ✅ Solution: Use Low Memory Configuration

### Option 1: Use the Low Memory Script (Recommended)

```bash
# Run the automated low-memory script
./scripts/start-minikube-low-memory.sh
```

This script will:
- Check your available system memory
- Automatically select appropriate settings (2GB or 3GB)
- Start Minikube with optimized memory settings

### Option 2: Manual Start with Reduced Memory

```bash
# Stop and delete existing Minikube (if any)
minikube stop
minikube delete

# Start with 2GB memory (minimum)
minikube start --driver=docker --cpus=2 --memory=2048

# OR start with 3GB memory (better performance)
minikube start --driver=docker --cpus=2 --memory=3072
```

### Option 3: Using Makefile

```bash
# Use the low-memory Makefile target
make rocky-start-low-memory
```

## 📊 Memory Requirements

| Configuration | Memory | CPUs | Use Case |
|--------------|--------|------|----------|
| **Minimum** | 2GB | 2 | Limited RAM systems |
| **Low** | 3GB | 2 | Better performance |
| **Standard** | 4GB | 2 | Recommended (if available) |

## 🔍 Check Your System Memory

```bash
# Check available memory
free -h

# Or on macOS
vm_stat
```

## 🛠️ Troubleshooting

### Issue: Still getting memory errors with 2GB

**Solution:** Try even lower memory (not recommended, may cause instability):
```bash
minikube start --driver=docker --cpus=1 --memory=1536
```

### Issue: Minikube starts but pods fail

**Solution:** This might be due to insufficient memory. Try:
1. Increase memory slightly: `--memory=2560` (2.5GB)
2. Check pod status: `kubectl get pods`
3. Check pod logs: `kubectl describe pod <pod-name>`

### Issue: Docker out of memory

**Solution:** Clean up Docker resources:
```bash
# Clean up unused Docker resources
docker system prune -a

# Check Docker disk usage
docker system df
```

## 📝 After Starting Minikube

Once Minikube starts successfully:

1. **Verify it's running:**
   ```bash
   minikube status
   ```

2. **Configure Jenkins (CRITICAL):**
   ```bash
   sudo ./scripts/configure-jenkins-minikube.sh
   ```

3. **Deploy your application:**
   ```bash
   make deploy
   ```

4. **Check deployment:**
   ```bash
   kubectl get pods
   ```

## 💡 Tips

- **Close unnecessary applications** before starting Minikube
- **Monitor memory usage** while Minikube is running: `watch free -h`
- **Consider using 3GB** if you have at least 6GB total RAM
- **2GB is the absolute minimum** - expect slower performance

## 🔗 Related Documentation

- [ROCKY_LINUX_QUICKSTART.md](ROCKY_LINUX_QUICKSTART.md)
- [ROCKY_LINUX_SETUP.md](ROCKY_LINUX_SETUP.md)
- [TROUBLESHOOTING_PORT_CONFLICTS.md](TROUBLESHOOTING_PORT_CONFLICTS.md)

