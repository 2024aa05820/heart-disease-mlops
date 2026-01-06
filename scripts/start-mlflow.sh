#!/bin/bash

# Start MLflow UI with PostgreSQL Backend
# DEPRECATED: Use ./scripts/setup-postgresql-mlflow.sh instead

# Don't exit on error for initial checks
# set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}⚠️  DEPRECATED: This script uses FileStore backend${NC}"
echo -e "${YELLOW}Use ./scripts/setup-postgresql-mlflow.sh for PostgreSQL backend${NC}"
echo -e "${YELLOW}PostgreSQL eliminates YAML RepresenterError issues${NC}\n"

MLFLOW_PORT=5001
MLFLOW_HOST="0.0.0.0"

# Check if virtual environment exists
if [ -d "/opt/mlflow-env" ]; then
    MLFLOW_CMD="/opt/mlflow-env/bin/mlflow"
else
    MLFLOW_CMD="mlflow"
fi

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

# Get the workspace directory - use current directory
WORKSPACE="$PWD"

echo "Working directory: $WORKSPACE"

# Create mlruns directory if it doesn't exist
mkdir -p mlruns

# Create logs directory for mlflow logs
mkdir -p logs

# Set log file path
LOG_FILE="$WORKSPACE/logs/mlflow.log"

# Start MLflow UI
echo "Starting MLflow UI on port $MLFLOW_PORT..."
echo "Log file: $LOG_FILE"
echo "Using MLflow command: $MLFLOW_CMD"

# Start MLflow with proper error handling
nohup $MLFLOW_CMD ui --host $MLFLOW_HOST --port $MLFLOW_PORT --backend-store-uri file:///$WORKSPACE/mlruns > "$LOG_FILE" 2>&1 &

MLFLOW_PID=$!

# Wait a bit for it to start
echo "Waiting for MLflow to start..."
sleep 3

# Check if it started successfully
if ps -p $MLFLOW_PID > /dev/null 2>&1; then
    echo -e "${GREEN}✅ MLflow UI started successfully${NC}"
    echo "   PID: $MLFLOW_PID"
    echo "   Port: $MLFLOW_PORT"
    echo "   Log file: $LOG_FILE"
    echo ""

    # Get server IP
    SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || hostname)

    echo -e "${BLUE}📊 Access MLflow UI:${NC}"
    echo ""
    echo "Option 1 - Direct access (if on same machine):"
    echo "   http://localhost:$MLFLOW_PORT"
    echo ""
    echo "Option 2 - SSH tunnel (from remote machine):"
    echo -e "   ${GREEN}ssh -L 5001:localhost:$MLFLOW_PORT cloud@$SERVER_IP${NC}"
    echo "   Then visit: http://localhost:5001"
    echo ""
    echo "To view logs:"
    echo "   tail -f $LOG_FILE"
    echo ""
    echo "To stop MLflow:"
    echo "   kill $MLFLOW_PID"
    echo ""
else
    echo -e "${RED}❌ Failed to start MLflow UI${NC}"
    echo ""
    echo "Check the log file for errors:"
    echo "   cat $LOG_FILE"
    echo ""

    # Show last few lines of log if it exists
    if [ -f "$LOG_FILE" ]; then
        echo "Last 10 lines of log:"
        tail -10 "$LOG_FILE"
    fi

    exit 1
fi

