#!/bin/bash

# Simple MLflow starter script
# Works from any directory

echo "🚀 Starting MLflow UI..."

# Check if MLflow is already running
if pgrep -f "mlflow ui" > /dev/null; then
    echo "⚠️  MLflow UI is already running"
    PID=$(pgrep -f "mlflow ui")
    echo "   PID: $PID"
    echo ""
    echo "To stop it: kill $PID"
    echo "To view logs: tail -f logs/mlflow.log"
    exit 0
fi

# Create necessary directories
mkdir -p mlruns
mkdir -p logs

# Start MLflow
echo "Starting MLflow on port 5001..."
nohup mlflow ui --host 0.0.0.0 --port 5001 > logs/mlflow.log 2>&1 &

# Get the PID
MLFLOW_PID=$!

# Wait a moment
sleep 2

# Check if it's running
if ps -p $MLFLOW_PID > /dev/null 2>&1; then
    echo "✅ MLflow started successfully!"
    echo "   PID: $MLFLOW_PID"
    echo "   Port: 5001"
    echo "   Logs: logs/mlflow.log"
    echo ""
    echo "Access it at: http://localhost:5001"
    echo ""
    echo "To stop: kill $MLFLOW_PID"
else
    echo "❌ Failed to start MLflow"
    echo "Check logs: cat logs/mlflow.log"
    exit 1
fi

