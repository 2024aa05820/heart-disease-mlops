.PHONY: help init install lint format test train serve docker-build docker-run deploy clean

PYTHON := python3
VENV := .venv
PIP := $(VENV)/bin/pip
PYTHON_VENV := $(VENV)/bin/python

help:
	@echo "Heart Disease MLOps Project"
	@echo ""
	@echo "Available commands:"
	@echo "  make init          - Create virtual environment and install dependencies"
	@echo "  make install       - Install dependencies only"
	@echo "  make lint          - Run linting (ruff)"
	@echo "  make format        - Format code (black)"
	@echo "  make test          - Run pytest"
	@echo "  make download      - Download the dataset"
	@echo "  make train         - Train the model"
	@echo "  make serve         - Run the API server locally"
	@echo "  make docker-build  - Build Docker image"
	@echo "  make docker-run    - Run Docker container"
	@echo "  make deploy        - Deploy to Kubernetes (Minikube)"
	@echo "  make clean         - Remove generated files"

init:
	$(PYTHON) -m venv $(VENV)
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt
	@echo "Virtual environment created. Activate with: source $(VENV)/bin/activate"

install:
	$(PIP) install -r requirements.txt

lint:
	$(VENV)/bin/ruff check src/ tests/ scripts/

format:
	$(VENV)/bin/black src/ tests/ scripts/

test:
	$(VENV)/bin/pytest tests/ -v --cov=src --cov-report=term-missing

download:
	$(PYTHON_VENV) scripts/download_data.py

train:
	$(PYTHON_VENV) scripts/train.py

serve:
	$(VENV)/bin/uvicorn src.api.app:app --host 0.0.0.0 --port 8000 --reload

docker-build:
	docker build -t heart-disease-api:latest .

docker-run:
	docker run -p 8000:8000 --name heart-api heart-disease-api:latest

docker-stop:
	docker stop heart-api && docker rm heart-api

deploy:
	kubectl apply -f deploy/k8s/

undeploy:
	kubectl delete -f deploy/k8s/

clean:
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	rm -rf .coverage htmlcov/ dist/ build/ *.egg-info/


