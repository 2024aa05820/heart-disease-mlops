pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'heart-disease-api'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        MINIKUBE_HOME = '/var/lib/jenkins/.minikube'
        PATH = "/usr/local/bin:${env.PATH}"
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
                    set -e  # Exit on any error

                    echo "📂 Current directory: $(pwd)"
                    echo "📂 Models directory before training:"
                    ls -la models/ || echo "models/ directory not found"
                    echo ""

                    . venv/bin/activate

                    echo "🚀 Starting model training..."
                    python scripts/train.py
                    TRAIN_EXIT_CODE=$?

                    if [ $TRAIN_EXIT_CODE -ne 0 ]; then
                        echo "❌ ERROR: Training script failed with exit code $TRAIN_EXIT_CODE"
                        exit 1
                    fi

                    echo ""
                    echo "📂 Models directory after training:"
                    ls -la models/
                    echo ""

                    # Verify models were created
                    if [ ! -f "models/best_model.joblib" ]; then
                        echo "❌ ERROR: best_model.joblib not found!"
                        echo "Training completed but model file is missing."
                        echo "This might indicate an issue with the training script."
                        exit 1
                    fi

                    if [ ! -f "models/preprocessing_pipeline.joblib" ]; then
                        echo "❌ ERROR: preprocessing_pipeline.joblib not found!"
                        echo "Training completed but preprocessing pipeline is missing."
                        exit 1
                    fi

                    echo "✅ Model files verified:"
                    ls -lh models/*.joblib
                '''
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                sh """
                    # Verify models exist before building Docker image
                    echo "🔍 Verifying model files before Docker build..."
                    if [ ! -f "models/best_model.joblib" ] || [ ! -f "models/preprocessing_pipeline.joblib" ]; then
                        echo "❌ ERROR: Model files not found!"
                        echo "Contents of models/ directory:"
                        ls -la models/
                        echo ""
                        echo "This usually means the 'Train Models' stage failed or was skipped."
                        echo "Please check the training logs above."
                        exit 1
                    fi

                    echo "✅ Model files verified:"
                    ls -lh models/*.joblib
                    echo ""

                    # Use Minikube's Docker daemon to build image directly
                    # Check if minikube is available
                    if command -v minikube &> /dev/null; then
                        echo "✅ Minikube found, using Minikube's Docker daemon"
                        eval \$(minikube docker-env) || {
                            echo "⚠️  Failed to set Minikube Docker env, using local Docker"
                        }
                    else
                        echo "⚠️  Minikube command not found, using local Docker"
                    fi

                    # Build the image
                    docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} .
                    docker tag ${DOCKER_IMAGE}:${IMAGE_TAG} ${DOCKER_IMAGE}:latest

                    # Verify image was built
                    echo "📦 Docker images:"
                    docker images | grep ${DOCKER_IMAGE}
                    echo ""

                    # Verify models are in the image
                    echo "🔍 Verifying models are in Docker image..."
                    docker run --rm ${DOCKER_IMAGE}:${IMAGE_TAG} ls -lh /app/models/
                """
            }
        }
        
        stage('Test Docker Image') {
            steps {
                echo '🧪 Testing Docker image...'
                sh """
                    # Use Minikube's Docker daemon (where the image was built)
                    if command -v minikube &> /dev/null; then
                        echo "✅ Using Minikube's Docker daemon for testing"
                        eval \$(minikube docker-env) || echo "⚠️  Using local Docker"
                    else
                        echo "⚠️  Using local Docker for testing"
                    fi

                    # Verify image exists
                    docker images | grep ${DOCKER_IMAGE} || {
                        echo "❌ Image not found"
                        echo "Available images:"
                        docker images
                        exit 1
                    }

                    # Clean up ALL old test containers (from any build)
                    echo "🧹 Cleaning up any existing test containers..."
                    docker ps -a | grep test-api- | awk '{print \$1}' | xargs -r docker rm -f 2>/dev/null || true

                    # Start container (no port mapping needed, we'll use container IP)
                    echo "🚀 Starting container test-api-${BUILD_NUMBER}..."
                    docker run -d --name test-api-${BUILD_NUMBER} ${DOCKER_IMAGE}:${IMAGE_TAG}

                    # Get container IP address
                    CONTAINER_IP=\$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' test-api-${BUILD_NUMBER})
                    echo "📍 Container IP: \$CONTAINER_IP"

                    # Check if container started
                    echo "📊 Container status:"
                    docker ps -a | grep test-api-${BUILD_NUMBER}
                    echo ""

                    # Wait a bit and show initial logs
                    echo "⏳ Waiting 5 seconds for initial startup..."
                    sleep 5

                    # Show initial container logs
                    echo "📋 Initial container logs:"
                    docker logs test-api-${BUILD_NUMBER}
                    echo ""

                    # Check if container is still running after initial startup
                    if ! docker ps | grep -q test-api-${BUILD_NUMBER}; then
                        echo "❌ Container crashed during startup!"
                        echo ""
                        echo "📋 Full container logs:"
                        docker logs test-api-${BUILD_NUMBER}
                        echo ""
                        echo "💡 Common causes:"
                        echo "   - Missing model files (check if models were trained)"
                        echo "   - Python import errors"
                        echo "   - Missing dependencies in requirements.txt"
                        docker rm -f test-api-${BUILD_NUMBER}
                        exit 1
                    fi

                    # Wait more for app to fully start
                    echo "⏳ Waiting 10 more seconds for app to fully start..."
                    sleep 10

                    # Show updated logs
                    echo "📋 Updated container logs:"
                    docker logs test-api-${BUILD_NUMBER}
                    echo ""

                    # Final check if container is still running
                    if ! docker ps | grep -q test-api-${BUILD_NUMBER}; then
                        echo "❌ Container is not running!"
                        echo "Container logs:"
                        docker logs test-api-${BUILD_NUMBER}
                        docker rm -f test-api-${BUILD_NUMBER}
                        exit 1
                    fi

                    # Test health endpoint with retries
                    echo "🏥 Testing health endpoint..."

                    # First, test from inside the container
                    echo "Testing from inside container (port 8000)..."
                    docker exec test-api-${BUILD_NUMBER} curl -f http://localhost:8000/health || {
                        echo "❌ Health check failed from inside container!"
                        echo "Container logs:"
                        docker logs test-api-${BUILD_NUMBER}
                        docker rm -f test-api-${BUILD_NUMBER}
                        exit 1
                    }
                    echo "✅ Internal health check passed!"
                    echo ""

                    # Now test from host using container IP
                    echo "Testing from host using container IP \$CONTAINER_IP..."
                    for i in 1 2 3 4 5; do
                        echo "Attempt \$i/5..."

                        # Try to curl using container IP
                        HTTP_CODE=\$(curl -s -o /tmp/health_response.txt -w "%{http_code}" http://\$CONTAINER_IP:8000/health || echo "000")
                        echo "HTTP Status Code: \$HTTP_CODE"

                        if [ -f /tmp/health_response.txt ]; then
                            echo "Response body:"
                            cat /tmp/health_response.txt
                            echo ""
                        fi

                        if [ "\$HTTP_CODE" = "200" ]; then
                            echo "✅ Health check passed!"
                            break
                        fi

                        if [ \$i -eq 5 ]; then
                            echo "❌ Health check failed after 5 attempts"
                            echo ""
                            echo "Debug info:"
                            echo "Docker port mapping:"
                            docker port test-api-${BUILD_NUMBER}
                            echo ""
                            echo "Container logs:"
                            docker logs test-api-${BUILD_NUMBER}
                            docker rm -f test-api-${BUILD_NUMBER}
                            exit 1
                        fi
                        sleep 5
                    done

                    # Stop and remove container
                    echo "🧹 Cleaning up test container..."
                    docker stop test-api-${BUILD_NUMBER}
                    docker rm test-api-${BUILD_NUMBER}
                    echo "✅ Docker image test completed successfully!"
                """
            }
        }
        
        stage('Load Image to Minikube') {
            steps {
                echo '📦 Verifying image in Minikube...'
                sh """
                    # Check if minikube is available
                    if command -v minikube &> /dev/null; then
                        echo "✅ Minikube found, verifying image"

                        # Since we built with minikube docker-env, image should already be there
                        eval \$(minikube docker-env) || {
                            echo "⚠️  Cannot set Minikube Docker env"
                            exit 0
                        }

                        # Verify image exists in Minikube's Docker
                        if docker images | grep -q ${DOCKER_IMAGE}; then
                            echo "✅ Image found in Minikube Docker daemon"
                            docker images | grep ${DOCKER_IMAGE}
                        else
                            echo "⚠️  Image not found in Minikube Docker, attempting to load..."
                            # Fallback: try minikube image load
                            minikube image load ${DOCKER_IMAGE}:latest || {
                                echo "❌ Failed to load image to Minikube"
                                echo "Available images in Minikube:"
                                docker images
                                exit 1
                            }
                        fi
                    else
                        echo "⚠️  Minikube not available, skipping verification"
                        echo "Image should be available in local Docker"
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
                # Use Minikube's Docker daemon for cleanup
                if command -v minikube &> /dev/null; then
                    eval $(minikube docker-env) || true
                fi

                # Clean up ALL test containers
                echo "Removing all test containers..."
                docker ps -a | grep test-api- | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null || true

                # Also clean up any containers using port 8001
                echo "Removing containers using port 8001..."
                docker ps --filter "publish=8001" -q | xargs -r docker stop 2>/dev/null || true
                docker ps -a --filter "publish=8001" -q | xargs -r docker rm -f 2>/dev/null || true

                # Clean up old Docker images (keep last 5)
                docker images ${DOCKER_IMAGE} --format "{{.ID}}" | tail -n +6 | xargs -r docker rmi || true

                # Clean up Python virtual environment
                rm -rf venv || true
            '''
        }
    }
}

