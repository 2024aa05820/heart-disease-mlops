# 🔧 Troubleshooting Port Conflicts on Remote Jenkins

## Problem
When running Jenkins pipeline, you see this error:
```
docker: Error response from daemon: driver failed programming external connectivity on endpoint test-api-17
Bind for 0.0.0.0:8001 failed: port is already allocated
```

This happens when multiple Docker containers are trying to use port 8001 on your remote Jenkins machine.

---

## ✅ Solution 1: Run the Cleanup Script (Recommended)

We've created a cleanup script that will remove all containers using port 8001.

### On your remote Jenkins machine:

```bash
# Navigate to your project directory
cd /path/to/heart-disease-mlops

# Run the cleanup script
./scripts/cleanup_docker_port.sh
```

This script will:
- Stop all containers using port 8001
- Remove all test-api-* containers
- Verify the port is free

---

## ✅ Solution 2: Manual Cleanup Commands

If you prefer to run commands manually on your remote Jenkins machine:

```bash
# 1. Check what's using port 8001
docker ps -a --format '{{.ID}} {{.Names}} {{.Ports}}' | grep '8001'

# 2. Stop running containers on port 8001
docker ps --filter "publish=8001" -q | xargs docker stop

# 3. Remove all containers using port 8001
docker ps -a --filter "publish=8001" -q | xargs docker rm -f

# 4. Clean up all test-api containers
docker ps -a | grep 'test-api-' | awk '{print $1}' | xargs docker rm -f

# 5. Verify cleanup
docker ps -a | grep '8001'
```

---

## ✅ Solution 3: Updated Jenkinsfile (Already Applied)

The Jenkinsfile has been updated with improved cleanup logic that:
- Uses Docker filters to find containers on port 8001
- Stops and removes them before starting new containers
- Waits 3 seconds for the port to be released
- Runs cleanup in the `always` block to prevent future conflicts

The updated cleanup code:
```bash
# Stop any containers using port 8001
docker ps --filter "publish=8001" -q | xargs -r docker stop 2>/dev/null || true
docker ps -a --filter "publish=8001" -q | xargs -r docker rm -f 2>/dev/null || true

# Double check - remove any container with port 8001 in its config
docker ps -a --format '{{.ID}} {{.Ports}}' | grep '8001' | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null || true
```

---

## 🚀 Next Steps

1. **Immediate fix**: Run the cleanup script on your remote Jenkins machine
2. **Commit changes**: Push the updated Jenkinsfile to prevent future issues
3. **Re-run pipeline**: Trigger a new Jenkins build

### Commands to commit and push:

```bash
git add Jenkinsfile scripts/cleanup_docker_port.sh TROUBLESHOOTING_PORT_CONFLICTS.md
git commit -m "fix: improve Docker port cleanup to prevent conflicts"
git push origin main
```

---

## 🔍 Prevention

The updated Jenkinsfile now includes:
- Better cleanup in the "Test Docker Image" stage
- Cleanup in the `always` block (runs even if pipeline fails)
- Multiple methods to find and remove containers using port 8001
- Longer wait time (3 seconds) for port release

This should prevent port conflicts in future builds!

---

## 📊 Verify Everything is Clean

After cleanup, verify with:

```bash
# Check for any containers using port 8001
docker ps -a --format '{{.ID}} {{.Names}} {{.Ports}}' | grep '8001'

# Should return nothing if cleanup was successful

# Check all test-api containers
docker ps -a | grep 'test-api-'

# Should return nothing or only the current build's container
```

---

## 💡 Why This Happened

Jenkins builds multiple times (builds 13, 14, 15, 16, 17) and each created a test container on port 8001. The old cleanup logic using `lsof` might not work on all systems, so containers accumulated. The new cleanup uses Docker's native filtering which is more reliable.

