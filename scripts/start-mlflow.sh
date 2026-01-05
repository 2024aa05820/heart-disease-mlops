#!/bin/bash

# Start MLflow UI
# Run this on the Jenkins server

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

MLFLOW_PORT=5001
MLFLOW_HOST="0.0.0.0"

echo "🚀 Starting MLflow UI..."

# Check if MLflow is already running
if pgrep -f "mlflow ui" > /dev/null; then
    echo -e "${YELLOW}⚠️  MLflow UI is already running${NC}"
    
    # Get the PID
    PID=$(pgrep -f "mlflow ui")
    echo "   PID: $PID"
    
    # Check the port
    PORT=$(netstat -tlnp 2>/dev/null | grep "$PID" | grep -oP ':\K[0-9]+' | head -1 || echo "unknown")
    echo "   Port: $PORT"
    
    echo ""
    echo "To restart MLflow:"
    echo "  1. Kill the process: kill $PID"
    echo "  2. Run this script again"
    exit 0
fi

# Get the workspace directory
if [ -d "/var/lib/jenkins/workspace/heart-disease-mlops" ]; then
    WORKSPACE="/var/lib/jenkins/workspace/heart-disease-mlops"
elif [ -d "$PWD" ]; then
    WORKSPACE="$PWD"
else
    echo "❌ Cannot find workspace directory"
    exit 1
fi

cd "$WORKSPACE"

# Create mlruns directory if it doesn't exist
mkdir -p mlruns

# Start MLflow UI
echo "Starting MLflow UI on port $MLFLOW_PORT..."
nohup mlflow ui --host $MLFLOW_HOST --port $MLFLOW_PORT --backend-store-uri file:///$WORKSPACE/mlruns > mlflow.log 2>&1 &

# Wait a bit for it to start
sleep 3

# Check if it started successfully
if pgrep -f "mlflow ui" > /dev/null; then
    PID=$(pgrep -f "mlflow ui")
    echo -e "${GREEN}✅ MLflow UI started successfully${NC}"
    echo "   PID: $PID"
    echo "   Port: $MLFLOW_PORT"
    echo "   Log file: $WORKSPACE/mlflow.log"
    echo ""
    
    # Get server IP
    SERVER_IP=$(hostname -I | awk '{print $1}' || echo "YOUR_SERVER_IP")
    
    echo -e "${BLUE}📊 Access MLflow UI:${NC}"
    echo ""
    echo "From your LOCAL machine, run:"
    echo -e "  ${GREEN}ssh -L 5001:localhost:$MLFLOW_PORT cloud@$SERVER_IP${NC}"
    echo ""
    echo "Then visit: http://localhost:5001"
    echo ""
else
    echo "❌ Failed to start MLflow UI"
    echo "Check the log file: $WORKSPACE/mlflow.log"
    exit 1
fi

