# Docker Container Issue - Debug Guide

## Problem
The Docker container starts but the FastAPI app doesn't respond to health checks, causing the Jenkins pipeline to fail.

## Root Cause
The `models/` directory is empty (only contains `.gitkeep`). The Docker image is built without the trained model files, causing the app to fail on startup.

## Solution

### Quick Fix (On Jenkins Server)

1. **Ensure models are trained before building Docker image:**
   ```bash
   # SSH to your Jenkins server
   cd /path/to/heart-disease-mlops
   
   # Activate virtual environment
   source venv/bin/activate
   
   # Train models
   python scripts/train.py
   
   # Verify models were created
   ls -lh models/*.joblib
   ```

2. **Re-run the Jenkins pipeline:**
   - The updated Jenkinsfile will now verify models exist before building the Docker image
   - It will show detailed logs if the container crashes
   - It will verify models are in the Docker image

### Debug Locally (Optional)

If you want to debug locally:

```bash
# 1. Train models first
python scripts/train.py

# 2. Run the debug script
./scripts/debug_docker.sh
```

This script will:
- ✅ Check if models exist locally
- ✅ Build Docker image
- ✅ Verify models are in the image
- ✅ Start container and show logs
- ✅ Test health endpoint
- ✅ Clean up automatically

## What Changed in Jenkinsfile

### 1. Added Model Verification Before Docker Build
```groovy
# Verify models exist before building Docker image
if [ ! -f "models/best_model.joblib" ] || [ ! -f "models/preprocessing_pipeline.joblib" ]; then
    echo "❌ ERROR: Model files not found!"
    exit 1
fi
```

### 2. Verify Models in Docker Image
```groovy
# Verify models are in the image
docker run --rm ${DOCKER_IMAGE}:${IMAGE_TAG} ls -lh /app/models/
```

### 3. Better Container Logging
- Shows logs after 5 seconds (initial startup)
- Shows logs after 15 seconds (full startup)
- Shows helpful error messages if container crashes
- Lists common causes of failures

## Common Issues

### Issue 1: Models Not Found
**Symptom:** Build fails with "Model files not found!"
**Solution:** Run `python scripts/train.py` before building Docker image

### Issue 2: Container Crashes on Startup
**Symptom:** Container starts but exits immediately
**Possible Causes:**
- Missing Python dependencies
- Import errors in code
- Model files corrupted

**Debug:**
```bash
# Check container logs
docker logs <container-name>

# Run container interactively to debug
docker run -it --rm heart-disease-api:latest /bin/bash
```

### Issue 3: Health Check Fails
**Symptom:** Container runs but health endpoint doesn't respond
**Possible Causes:**
- App crashed after startup
- Port not exposed correctly
- Firewall blocking port

**Debug:**
```bash
# Check if app is listening on port 8000
docker exec <container-name> netstat -tlnp | grep 8000

# Check app logs
docker logs <container-name>

# Try accessing from inside container
docker exec <container-name> curl http://localhost:8000/health
```

## Verification Steps

After fixing, verify everything works:

1. **Check models exist:**
   ```bash
   ls -lh models/*.joblib
   ```

2. **Build and test Docker image:**
   ```bash
   docker build -t heart-disease-api:test .
   docker run -d --name test-api -p 8001:8000 heart-disease-api:test
   sleep 10
   curl http://localhost:8001/health
   docker stop test-api && docker rm test-api
   ```

3. **Run Jenkins pipeline:**
   - Should pass all stages
   - Should show model verification messages
   - Should show container logs
   - Should pass health check

## Next Steps

1. ✅ Train models: `python scripts/train.py`
2. ✅ Commit and push changes to trigger Jenkins build
3. ✅ Monitor Jenkins console output for detailed logs
4. ✅ Verify health check passes

## Need More Help?

If the issue persists:
1. Check Jenkins console output for the exact error
2. Run `./scripts/debug_docker.sh` to debug locally
3. Check container logs: `docker logs <container-name>`
4. Verify Python dependencies are installed: `pip list`

