#!/bin/bash
#
# Service Management Script for Heart Disease MLOps
#
# Manage Docker, Jenkins, Minikube, and MLflow services
#

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to show usage
show_usage() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Service Management - Heart Disease MLOps ${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start-all       - Start all services (Docker, Jenkins, Minikube)"
    echo "  stop-all        - Stop all services"
    echo "  restart-all     - Restart all services"
    echo "  status          - Show status of all services"
    echo ""
    echo "  start-docker    - Start Docker service"
    echo "  stop-docker     - Stop Docker service"
    echo "  restart-docker  - Restart Docker service"
    echo ""
    echo "  start-jenkins   - Start Jenkins service"
    echo "  stop-jenkins    - Stop Jenkins service"
    echo "  restart-jenkins - Restart Jenkins service"
    echo ""
    echo "  start-minikube  - Start Minikube cluster"
    echo "  stop-minikube   - Stop Minikube cluster"
    echo "  restart-minikube- Restart Minikube cluster"
    echo ""
    echo "  start-mlflow    - Start MLflow UI"
    echo "  stop-mlflow     - Stop MLflow UI"
    echo ""
    echo "Examples:"
    echo "  $0 start-all"
    echo "  $0 status"
    echo "  $0 restart-jenkins"
    echo ""
}

# Function to check if running as root (for systemctl commands)
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}This command requires root privileges${NC}"
        echo -e "${YELLOW}Run with: sudo $0 $1${NC}"
        exit 1
    fi
}

# Docker functions
start_docker() {
    check_root "start-docker"
    echo -e "${YELLOW}Starting Docker...${NC}"
    systemctl start docker
    echo -e "${GREEN}✅ Docker started${NC}"
}

stop_docker() {
    check_root "stop-docker"
    echo -e "${YELLOW}Stopping Docker...${NC}"
    systemctl stop docker
    echo -e "${GREEN}✅ Docker stopped${NC}"
}

restart_docker() {
    check_root "restart-docker"
    echo -e "${YELLOW}Restarting Docker...${NC}"
    systemctl restart docker
    echo -e "${GREEN}✅ Docker restarted${NC}"
}

# Jenkins functions
start_jenkins() {
    check_root "start-jenkins"
    echo -e "${YELLOW}Starting Jenkins...${NC}"
    systemctl start jenkins
    echo -e "${GREEN}✅ Jenkins started${NC}"
    echo -e "${BLUE}Access at: http://$(hostname -I | awk '{print $1}'):8080${NC}"
}

stop_jenkins() {
    check_root "stop-jenkins"
    echo -e "${YELLOW}Stopping Jenkins...${NC}"
    systemctl stop jenkins
    echo -e "${GREEN}✅ Jenkins stopped${NC}"
}

restart_jenkins() {
    check_root "restart-jenkins"
    echo -e "${YELLOW}Restarting Jenkins...${NC}"
    systemctl restart jenkins
    echo -e "${GREEN}✅ Jenkins restarted${NC}"
    echo -e "${BLUE}Access at: http://$(hostname -I | awk '{print $1}'):8080${NC}"
}

# Minikube functions
start_minikube() {
    echo -e "${YELLOW}Starting Minikube...${NC}"
    minikube start --driver=docker --cpus=2 --memory=4096
    echo -e "${GREEN}✅ Minikube started${NC}"
    minikube status
}

stop_minikube() {
    echo -e "${YELLOW}Stopping Minikube...${NC}"
    minikube stop
    echo -e "${GREEN}✅ Minikube stopped${NC}"
}

restart_minikube() {
    echo -e "${YELLOW}Restarting Minikube...${NC}"
    minikube stop
    sleep 2
    minikube start --driver=docker --cpus=2 --memory=4096
    echo -e "${GREEN}✅ Minikube restarted${NC}"
    minikube status
}

# MLflow functions
start_mlflow() {
    echo -e "${YELLOW}Starting MLflow UI...${NC}"
    
    # Check if already running
    if pgrep -f "mlflow ui" > /dev/null; then
        echo -e "${YELLOW}⚠️  MLflow UI is already running${NC}"
        echo -e "${BLUE}Access at: http://$(hostname -I | awk '{print $1}'):5001${NC}"
        return
    fi
    
    # Start MLflow in background
    nohup mlflow ui --host 0.0.0.0 --port 5001 > mlflow.log 2>&1 &
    sleep 2
    
    if pgrep -f "mlflow ui" > /dev/null; then
        echo -e "${GREEN}✅ MLflow UI started${NC}"
        echo -e "${BLUE}Access at: http://$(hostname -I | awk '{print $1}'):5001${NC}"
    else
        echo -e "${RED}❌ Failed to start MLflow UI${NC}"
        echo -e "${YELLOW}Check mlflow.log for errors${NC}"
    fi
}

stop_mlflow() {
    echo -e "${YELLOW}Stopping MLflow UI...${NC}"
    
    if pgrep -f "mlflow ui" > /dev/null; then
        pkill -f "mlflow ui"
        echo -e "${GREEN}✅ MLflow UI stopped${NC}"
    else
        echo -e "${YELLOW}⚠️  MLflow UI is not running${NC}"
    fi
}

# Status function
show_status() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Service Status${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
    
    # Docker status
    echo -e "${YELLOW}Docker:${NC}"
    if systemctl is-active --quiet docker; then
        echo -e "${GREEN}  ✅ Running${NC}"
    else
        echo -e "${RED}  ❌ Stopped${NC}"
    fi
    echo ""
    
    # Jenkins status
    echo -e "${YELLOW}Jenkins:${NC}"
    if systemctl is-active --quiet jenkins; then
        echo -e "${GREEN}  ✅ Running${NC}"
        echo -e "${BLUE}  URL: http://$(hostname -I | awk '{print $1}'):8080${NC}"
    else
        echo -e "${RED}  ❌ Stopped${NC}"
    fi
    echo ""
    
    # Minikube status
    echo -e "${YELLOW}Minikube:${NC}"
    if minikube status &> /dev/null; then
        echo -e "${GREEN}  ✅ Running${NC}"
        minikube status | sed 's/^/  /'
    else
        echo -e "${RED}  ❌ Stopped${NC}"
    fi
    echo ""
    
    # MLflow status
    echo -e "${YELLOW}MLflow UI:${NC}"
    if pgrep -f "mlflow ui" > /dev/null; then
        echo -e "${GREEN}  ✅ Running${NC}"
        echo -e "${BLUE}  URL: http://$(hostname -I | awk '{print $1}'):5001${NC}"
    else
        echo -e "${RED}  ❌ Stopped${NC}"
    fi
    echo ""
}

# Start all services
start_all() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Starting All Services${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
    
    start_docker
    echo ""
    start_jenkins
    echo ""
    start_minikube
    echo ""
    start_mlflow
    echo ""
    
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  ✅ All Services Started!${NC}"
    echo -e "${GREEN}============================================${NC}"
}

# Stop all services
stop_all() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Stopping All Services${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
    
    stop_mlflow
    echo ""
    stop_minikube
    echo ""
    stop_jenkins
    echo ""
    stop_docker
    echo ""
    
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  ✅ All Services Stopped!${NC}"
    echo -e "${GREEN}============================================${NC}"
}

# Restart all services
restart_all() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Restarting All Services${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
    
    stop_all
    echo ""
    sleep 3
    echo ""
    start_all
}

# Main script
case "$1" in
    start-all)
        start_all
        ;;
    stop-all)
        stop_all
        ;;
    restart-all)
        restart_all
        ;;
    status)
        show_status
        ;;
    start-docker)
        start_docker
        ;;
    stop-docker)
        stop_docker
        ;;
    restart-docker)
        restart_docker
        ;;
    start-jenkins)
        start_jenkins
        ;;
    stop-jenkins)
        stop_jenkins
        ;;
    restart-jenkins)
        restart_jenkins
        ;;
    start-minikube)
        start_minikube
        ;;
    stop-minikube)
        stop_minikube
        ;;
    restart-minikube)
        restart_minikube
        ;;
    start-mlflow)
        start_mlflow
        ;;
    stop-mlflow)
        stop_mlflow
        ;;
    *)
        show_usage
        exit 1
        ;;
esac

