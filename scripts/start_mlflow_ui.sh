#!/bin/bash

################################################################################
# Heart Disease MLOps - MLflow UI Startup Script
# 
# This script starts the MLflow UI server on the remote machine
# 
# Usage:
#   ./scripts/start_mlflow_ui.sh [options]
#
# Options:
#   --port PORT     Port to run MLflow UI (default: 5001)
#   --host HOST     Host to bind to (default: 0.0.0.0)
#   --background    Run in background
#   --stop          Stop running MLflow UI
#   --status        Check MLflow UI status
#   --help          Show this help message
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
MLFLOW_PORT=5001
MLFLOW_HOST="0.0.0.0"
MLFLOW_BACKEND_STORE="./mlruns"
LOG_FILE="mlflow_ui.log"
PID_FILE="mlflow_ui.pid"

# Functions
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

check_mlflow_installed() {
    if ! command -v mlflow &> /dev/null; then
        print_error "MLflow is not installed"
        print_info "Install with: pip install mlflow"
        exit 1
    fi
    print_success "MLflow is installed"
}

check_mlflow_status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            print_success "MLflow UI is running (PID: $PID)"
            print_info "Access at: http://localhost:${MLFLOW_PORT}"
            
            # Show recent logs
            if [ -f "$LOG_FILE" ]; then
                echo ""
                print_info "Recent logs:"
                tail -n 10 "$LOG_FILE"
            fi
            return 0
        else
            print_warning "PID file exists but process is not running"
            rm -f "$PID_FILE"
            return 1
        fi
    else
        print_info "MLflow UI is not running"
        return 1
    fi
}

stop_mlflow() {
    print_header "Stopping MLflow UI"
    
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            print_info "Stopping MLflow UI (PID: $PID)..."
            kill "$PID"
            sleep 2
            
            # Force kill if still running
            if ps -p "$PID" > /dev/null 2>&1; then
                print_warning "Process still running, force killing..."
                kill -9 "$PID"
            fi
            
            rm -f "$PID_FILE"
            print_success "MLflow UI stopped"
        else
            print_warning "Process not found, cleaning up PID file"
            rm -f "$PID_FILE"
        fi
    else
        # Try to find and kill any running MLflow processes
        PIDS=$(pgrep -f "mlflow ui" || true)
        if [ -n "$PIDS" ]; then
            print_info "Found running MLflow processes: $PIDS"
            echo "$PIDS" | xargs kill
            print_success "Stopped running MLflow processes"
        else
            print_info "No running MLflow UI found"
        fi
    fi
}

start_mlflow_foreground() {
    print_header "Starting MLflow UI (Foreground)"
    
    print_info "Configuration:"
    echo "  Host: ${MLFLOW_HOST}"
    echo "  Port: ${MLFLOW_PORT}"
    echo "  Backend Store: ${MLFLOW_BACKEND_STORE}"
    echo ""
    
    print_info "Starting MLflow UI..."
    print_warning "Press Ctrl+C to stop"
    echo ""
    
    mlflow ui \
        --host "${MLFLOW_HOST}" \
        --port "${MLFLOW_PORT}" \
        --backend-store-uri "${MLFLOW_BACKEND_STORE}"
}

start_mlflow_background() {
    print_header "Starting MLflow UI (Background)"
    
    # Check if already running
    if check_mlflow_status > /dev/null 2>&1; then
        print_warning "MLflow UI is already running"
        print_info "Use --stop to stop it first, or --status to check status"
        exit 1
    fi
    
    print_info "Configuration:"
    echo "  Host: ${MLFLOW_HOST}"
    echo "  Port: ${MLFLOW_PORT}"
    echo "  Backend Store: ${MLFLOW_BACKEND_STORE}"
    echo "  Log File: ${LOG_FILE}"
    echo ""
    
    print_info "Starting MLflow UI in background..."
    
    nohup mlflow ui \
        --host "${MLFLOW_HOST}" \
        --port "${MLFLOW_PORT}" \
        --backend-store-uri "${MLFLOW_BACKEND_STORE}" \
        > "${LOG_FILE}" 2>&1 &
    
    PID=$!
    echo "$PID" > "$PID_FILE"
    
    # Wait a bit and check if it started successfully
    sleep 3
    
    if ps -p "$PID" > /dev/null 2>&1; then
        print_success "MLflow UI started successfully (PID: $PID)"
        echo ""
        print_info "Access MLflow UI at:"
        echo "  Local:  http://localhost:${MLFLOW_PORT}"
        echo "  Remote: http://<your-server-ip>:${MLFLOW_PORT}"
        echo ""
        print_info "View logs with:"
        echo "  tail -f ${LOG_FILE}"
        echo ""
        print_info "Stop with:"
        echo "  ./scripts/start_mlflow_ui.sh --stop"
    else
        print_error "Failed to start MLflow UI"
        print_info "Check logs: cat ${LOG_FILE}"
        rm -f "$PID_FILE"
        exit 1
    fi
}

show_help() {
    echo "Heart Disease MLOps - MLflow UI Startup Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --port PORT     Port to run MLflow UI (default: 5001)"
    echo "  --host HOST     Host to bind to (default: 0.0.0.0)"
    echo "  --background    Run in background"
    echo "  --stop          Stop running MLflow UI"
    echo "  --status        Check MLflow UI status"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Start in foreground"
    echo "  $0 --background         # Start in background"
    echo "  $0 --port 5002          # Start on port 5002"
    echo "  $0 --status             # Check status"
    echo "  $0 --stop               # Stop MLflow UI"
    echo ""
    echo "SSH Tunnel (from local machine):"
    echo "  ssh -L 5001:localhost:5001 user@remote-server"
    echo "  Then access: http://localhost:5001"
    echo ""
}

# Main script
main() {
    BACKGROUND=false
    ACTION="start"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --port)
                MLFLOW_PORT="$2"
                shift 2
                ;;
            --host)
                MLFLOW_HOST="$2"
                shift 2
                ;;
            --background)
                BACKGROUND=true
                shift
                ;;
            --stop)
                ACTION="stop"
                shift
                ;;
            --status)
                ACTION="status"
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Check if MLflow is installed
    check_mlflow_installed
    
    # Execute action
    case $ACTION in
        start)
            if [ "$BACKGROUND" = true ]; then
                start_mlflow_background
            else
                start_mlflow_foreground
            fi
            ;;
        stop)
            stop_mlflow
            ;;
        status)
            check_mlflow_status
            ;;
    esac
}

# Run main function
main "$@"

