.PHONY: help init init-conda install lint format test train serve docker-build docker-run deploy clean mlflow-ui

# Environment name for conda
CONDA_ENV := heart-mlops
PYTHON := python

help:
	@echo "Heart Disease MLOps Project"
	@echo ""
	@echo "🚀 Quick Start (Rocky Linux):"
	@echo "  make rocky-setup   - Install all prerequisites (Java, Docker, k8s, Jenkins)"
	@echo "  make rocky-start   - Start Minikube and show URLs"
	@echo "  make rocky-status  - Check status of all services"
	@echo "  make verify        - Run comprehensive verification"
	@echo ""
	@echo "📦 Development:"
	@echo "  make init-conda    - Create conda environment and install dependencies"
	@echo "  make init          - Create venv and install dependencies (alternative)"
	@echo "  make install       - Install dependencies only (run after activating env)"
	@echo "  make download      - Download the dataset"
	@echo "  make train         - Train the model"
	@echo ""
	@echo "🧪 Testing & Quality:"
	@echo "  make lint          - Run linting (ruff)"
	@echo "  make format        - Format code (black)"
	@echo "  make test          - Run pytest"
	@echo ""
	@echo "🐳 Docker:"
	@echo "  make docker-build  - Build Docker image"
	@echo "  make docker-run    - Run Docker container"
	@echo ""
	@echo "☸️  Kubernetes:"
	@echo "  make deploy        - Deploy to Kubernetes (Minikube)"
	@echo "  make k8s-status    - Check Kubernetes deployment status"
	@echo "  make k8s-logs      - View pod logs"
	@echo "  make k8s-restart   - Restart deployment"
	@echo ""
	@echo "📊 Monitoring:"
	@echo "  make mlflow-ui     - Start MLflow UI"
	@echo "  make urls          - Show all service URLs"
	@echo ""
	@echo "🧹 Cleanup:"
	@echo "  make clean         - Remove generated files"
	@echo ""
	@echo "For Conda: Run 'make init-conda' then 'conda activate $(CONDA_ENV)'"
	@echo "For venv:  Run 'make init' then 'source .venv/bin/activate'"

# ==================== CONDA SETUP ====================
init-conda:
	conda create -n $(CONDA_ENV) python=3.11 -y
	@echo ""
	@echo "============================================"
	@echo "Conda environment '$(CONDA_ENV)' created!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. conda activate $(CONDA_ENV)"
	@echo "  2. make install"
	@echo "  3. make download"
	@echo "  4. make train"
	@echo "============================================"

# ==================== VENV SETUP (Alternative) ====================
init:
	$(PYTHON) -m venv .venv
	.venv/bin/pip install --upgrade pip
	.venv/bin/pip install -r requirements.txt
	@echo "Virtual environment created. Activate with: source .venv/bin/activate"

# ==================== COMMON COMMANDS (work with both) ====================
# These assume the environment (conda or venv) is ALREADY ACTIVATED

install:
	pip install --upgrade pip
	pip install -r requirements.txt

lint:
	ruff check src/ tests/ scripts/

format:
	black src/ tests/ scripts/

test:
	pytest tests/ -v --cov=src --cov-report=term-missing

download:
	$(PYTHON) scripts/download_data.py

train:
	$(PYTHON) scripts/train.py

serve:
	uvicorn src.api.app:app --host 0.0.0.0 --port 8000 --reload

mlflow-ui:
	mlflow ui --backend-store-uri mlruns --port 5000

# ==================== DOCKER ====================
docker-build:
	docker build -t heart-disease-api:latest .

docker-run:
	docker run -d -p 8000:8000 --name heart-api heart-disease-api:latest
	@echo "Container started. API available at http://localhost:8000"
	@echo "Health check: curl http://localhost:8000/health"

docker-stop:
	docker stop heart-api && docker rm heart-api

docker-logs:
	docker logs -f heart-api

# ==================== KUBERNETES ====================
deploy:
	kubectl apply -f deploy/k8s/
	@echo "Deployed! Check status with: kubectl get pods"

undeploy:
	kubectl delete -f deploy/k8s/

k8s-status:
	kubectl get pods,svc,ingress

k8s-logs:
	kubectl logs -f -l app=heart-disease-api

k8s-restart:
	kubectl rollout restart deployment/heart-disease-api
	kubectl rollout status deployment/heart-disease-api

# ==================== ROCKY LINUX SETUP ====================
rocky-setup:
	@echo "🚀 Installing all prerequisites on Rocky Linux..."
	@echo "This will install: Java, Docker, kubectl, Minikube, Jenkins"
	@echo ""
	sudo ./scripts/rocky-setup.sh

rocky-start:
	@echo "🚀 Starting Minikube..."
	minikube start --driver=docker --cpus=2 --memory=4096
	@echo ""
	@echo "============================================"
	@echo "Service URLs:"
	@echo "============================================"
	@echo "Jenkins:    http://$$(hostname -I | awk '{print $$1}'):8080"
	@echo "MLflow:     http://$$(hostname -I | awk '{print $$1}'):5001"
	@echo "Minikube:   $$(minikube ip)"
	@echo "============================================"

rocky-status:
	@echo "============================================"
	@echo "System Status"
	@echo "============================================"
	@echo ""
	@echo "Docker:"
	@sudo systemctl status docker --no-pager | head -3
	@echo ""
	@echo "Jenkins:"
	@sudo systemctl status jenkins --no-pager | head -3
	@echo ""
	@echo "Minikube:"
	@minikube status || echo "Minikube not running"
	@echo ""
	@echo "Kubernetes Pods:"
	@kubectl get pods 2>/dev/null || echo "No pods running"

verify:
	@echo "🔍 Running comprehensive verification..."
	@./scripts/verify-installation.sh

urls:
	@echo "============================================"
	@echo "Service URLs"
	@echo "============================================"
	@MINIKUBE_IP=$$(minikube ip 2>/dev/null || echo "not-running"); \
	SERVER_IP=$$(hostname -I | awk '{print $$1}'); \
	echo "API:        http://$$MINIKUBE_IP:30080"; \
	echo "Swagger:    http://$$MINIKUBE_IP:30080/docs"; \
	echo "MLflow:     http://$$SERVER_IP:5001"; \
	echo "Jenkins:    http://$$SERVER_IP:8080"; \
	echo "============================================"

# ==================== CLEANUP ====================
clean:
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	rm -rf .coverage htmlcov/ dist/ build/ *.egg-info/

clean-all: clean
	rm -rf .venv mlruns/ models/*.joblib models/*.yaml
