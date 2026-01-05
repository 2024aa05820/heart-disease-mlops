pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'heart-disease-api'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        MINIKUBE_HOME = '/var/lib/jenkins/.minikube'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '📥 Checking out code from GitHub...'
                checkout scm
                sh 'git log -1 --pretty=format:"%h - %an: %s"'
            }
        }
        
        stage('Setup Python Environment') {
            steps {
                echo '🐍 Setting up Python environment...'
                sh '''
                    python3 -m venv venv || true
                    . venv/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                '''
            }
        }
        
        stage('Lint Code') {
            steps {
                echo '🔍 Running code linters...'
                sh '''
                    . venv/bin/activate
                    pip install ruff black
                    ruff check src/ tests/ scripts/ || true
                    black --check src/ tests/ scripts/ || true
                '''
            }
        }
        
        stage('Run Tests') {
            steps {
                echo '🧪 Running unit tests...'
                sh '''
                    . venv/bin/activate
                    pytest tests/ -v --cov=src --cov-report=xml --cov-report=term-missing || true
                '''
            }
        }
        
        stage('Download Dataset') {
            steps {
                echo '📊 Downloading dataset...'
                sh '''
                    . venv/bin/activate
                    python scripts/download_data.py
                '''
            }
        }
        
        stage('Train Models') {
            steps {
                echo '🤖 Training ML models...'
                sh '''
                    . venv/bin/activate
                    python scripts/train.py
                '''
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                sh """
                    # Use Minikube's Docker daemon to build image directly
                    eval \$(minikube docker-env) || echo "Using local Docker"

                    docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} .
                    docker tag ${DOCKER_IMAGE}:${IMAGE_TAG} ${DOCKER_IMAGE}:latest

                    # Verify image was built
                    docker images | grep ${DOCKER_IMAGE}
                """
            }
        }
        
        stage('Test Docker Image') {
            steps {
                echo '🧪 Testing Docker image...'
                sh """
                    # Start container
                    docker run -d --name test-api-${BUILD_NUMBER} -p 8001:8000 ${DOCKER_IMAGE}:${IMAGE_TAG}
                    
                    # Wait for container to start
                    sleep 10
                    
                    # Test health endpoint
                    curl -f http://localhost:8001/health || exit 1
                    
                    # Stop and remove container
                    docker stop test-api-${BUILD_NUMBER}
                    docker rm test-api-${BUILD_NUMBER}
                """
            }
        }
        
        stage('Load Image to Minikube') {
            steps {
                echo '📦 Verifying image in Minikube...'
                sh """
                    # Since we built with minikube docker-env, image should already be there
                    eval \$(minikube docker-env)

                    # Verify image exists in Minikube's Docker
                    if docker images | grep -q ${DOCKER_IMAGE}; then
                        echo "✅ Image found in Minikube Docker daemon"
                        docker images | grep ${DOCKER_IMAGE}
                    else
                        echo "⚠️  Image not found, attempting to load..."
                        # Fallback: try minikube image load
                        minikube image load ${DOCKER_IMAGE}:latest || {
                            echo "❌ Failed to load image to Minikube"
                            echo "Available images in Minikube:"
                            docker images
                            exit 1
                        }
                    fi
                """
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                echo '🚀 Deploying to Kubernetes...'
                sh '''
                    # Apply Kubernetes manifests
                    kubectl apply -f deploy/k8s/
                    
                    # Wait for deployment to be ready
                    kubectl wait --for=condition=available --timeout=300s deployment/heart-disease-api || true
                    
                    # Restart deployment to use new image
                    kubectl rollout restart deployment/heart-disease-api
                    kubectl rollout status deployment/heart-disease-api
                '''
            }
        }
        
        stage('Verify Deployment') {
            steps {
                echo '✅ Verifying deployment...'
                sh '''
                    # Check pods
                    kubectl get pods -l app=heart-disease-api
                    
                    # Get service URL
                    SERVICE_URL=$(minikube service heart-disease-api-service --url)
                    echo "Service URL: $SERVICE_URL"
                    
                    # Wait for pods to be ready
                    sleep 10
                    
                    # Test health endpoint
                    curl -f $SERVICE_URL/health || echo "Health check failed, but continuing..."
                '''
            }
        }
        
        stage('Start MLflow UI') {
            steps {
                echo '📊 Starting MLflow UI...'
                sh '''
                    # Check if MLflow is already running
                    if pgrep -f "mlflow ui" > /dev/null; then
                        echo "MLflow UI is already running"
                    else
                        # Start MLflow UI in background
                        nohup mlflow ui --host 0.0.0.0 --port 5001 > mlflow.log 2>&1 &
                        echo "MLflow UI started"
                    fi
                '''
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline completed successfully!'
            sh '''
                echo "========================================="
                echo "Deployment Summary"
                echo "========================================="
                echo "Build Number: ${BUILD_NUMBER}"
                echo "Docker Image: ${DOCKER_IMAGE}:${IMAGE_TAG}"
                echo "Kubernetes Pods:"
                kubectl get pods -l app=heart-disease-api
                echo ""
                echo "Service URL:"
                minikube service heart-disease-api-service --url
                echo ""
                echo "MLflow UI: http://$(hostname -I | awk '{print $1}'):5001"
                echo "========================================="
            '''
        }
        failure {
            echo '❌ Pipeline failed!'
            sh '''
                echo "Check logs for errors:"
                echo "- Jenkins console output"
                echo "- Docker logs: docker logs <container-id>"
                echo "- Kubernetes logs: kubectl logs <pod-name>"
            '''
        }
        always {
            echo '🧹 Cleaning up...'
            sh '''
                # Clean up old Docker images (keep last 5)
                docker images ${DOCKER_IMAGE} --format "{{.ID}}" | tail -n +6 | xargs -r docker rmi || true
                
                # Clean up Python virtual environment
                rm -rf venv || true
            '''
        }
    }
}

