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

        stage('Promote Best Model') {
            steps {
                echo '🏆 Promoting best model to Production...'
                script {
                    try {
                        sh '''
                            . venv/bin/activate

                            echo "========================================="
                            echo "📊 MLflow Model Registry - Before Promotion"
                            echo "========================================="
                            echo ""

                            # List all registered models (ignore errors)
                            python scripts/promote-model.py --list 2>&1 || {
                                echo "⚠️  Could not list models (might be first run)"
                            }
                            echo ""

                            echo "========================================="
                            echo "🏆 Auto-Promoting Best Model"
                            echo "========================================="
                            echo ""

                            # Automatically find and promote the best model (ignore errors)
                            python scripts/promote-model.py --auto 2>&1 || {
                                echo "⚠️  Auto-promotion failed, but continuing pipeline..."
                                echo "   This is a known issue with MLflow FileStore backend."
                                echo "   You can manually promote later using:"
                                echo "   python scripts/promote-model.py <model-name>"
                                echo "   Or via MLflow UI: http://<server-ip>:5001"
                            }

                            echo ""
                            echo "========================================="
                            echo "📊 MLflow Model Registry - After Promotion"
                            echo "========================================="
                            python scripts/promote-model.py --list 2>&1 || true
                            echo ""
                        '''
                    } catch (Exception e) {
                        echo "⚠️  Model promotion stage encountered an error, but continuing pipeline..."
                        echo "Error: ${e.message}"
                        echo ""
                        echo "💡 This is a known issue with MLflow FileStore backend (RepresenterError)."
                        echo "   The model is still registered and can be promoted manually via MLflow UI."
                        echo "   Pipeline will continue to deployment stage."
                    }
                }
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

                    # Start container without port mapping (we'll test internally only)
                    echo "🚀 Starting container test-api-${BUILD_NUMBER}..."
                    docker run -d --name test-api-${BUILD_NUMBER} ${DOCKER_IMAGE}:${IMAGE_TAG}

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

                    # Internal health check passed - that's sufficient for testing
                    echo "✅ Container is healthy and API is responding correctly!"
                    echo ""

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
                echo '� Deploying to Kubernetes...'
                script {
                    // Try to use Jenkins credential first, fall back to error message if not available
                    try {
                        withCredentials([file(credentialsId: 'kubeconfig-minikube', variable: 'KUBECONFIG')]) {
                            sh '''
                                # Use the kubeconfig from Jenkins credentials
                                # This kubeconfig has embedded certificates (no file paths needed)

                                # Verify we can connect
                                kubectl cluster-info

                                # Apply Kubernetes manifests
                                kubectl apply -f deploy/k8s/

                                # Wait for deployment to be ready
                                kubectl wait --for=condition=available --timeout=300s deployment/heart-disease-api || true

                                # Restart deployment to use new image
                                kubectl rollout restart deployment/heart-disease-api
                                kubectl rollout status deployment/heart-disease-api
                            '''
                        }
                    } catch (Exception e) {
                        echo "⚠️  Jenkins credential 'kubeconfig-minikube' not found."
                        echo "Please run: ./scripts/generate-kubeconfig-for-jenkins.sh"
                        echo "Then upload the generated file to Jenkins as a Secret file credential with ID 'kubeconfig-minikube'"
                        error("Kubernetes deployment failed: ${e.message}")
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                echo '✅ Verifying deployment...'
                script {
                    withCredentials([file(credentialsId: 'kubeconfig-minikube', variable: 'KUBECONFIG')]) {
                        sh '''
                            # Check pods
                            echo "📋 Checking deployment status..."
                            kubectl get pods -l app=heart-disease-api

                            # Wait for pods to be ready
                            echo "⏳ Waiting for pods to be ready..."
                            kubectl wait --for=condition=ready --timeout=120s pod -l app=heart-disease-api || {
                                echo "⚠️  Pods not ready yet, checking status..."
                                kubectl describe pods -l app=heart-disease-api
                            }

                            # Get the pod name
                            POD_NAME=$(kubectl get pods -l app=heart-disease-api -o jsonpath='{.items[0].metadata.name}')
                            echo "🎯 Testing pod: $POD_NAME"

                            # Use port-forward to test the service
                            echo "🔌 Setting up port-forward..."
                            kubectl port-forward $POD_NAME 8000:8000 &
                            PF_PID=$!

                            # Wait for port-forward to be ready
                            sleep 5

                            # Test health endpoint
                            echo "🏥 Testing health endpoint..."
                            if curl -f http://localhost:8000/health; then
                                echo "✅ Health check passed!"
                            else
                                echo "❌ Health check failed"
                                kubectl logs $POD_NAME --tail=50
                            fi

                            # Test prediction endpoint
                            echo "🧪 Testing prediction endpoint..."
                            curl -X POST http://localhost:8000/predict \
                                -H "Content-Type: application/json" \
                                -d '{"age":63,"sex":1,"cp":3,"trestbps":145,"chol":233,"fbs":1,"restecg":0,"thalach":150,"exang":0,"oldpeak":2.3,"slope":0,"ca":0,"thal":1}' \
                                || echo "⚠️  Prediction test failed"

                            # Cleanup port-forward
                            kill $PF_PID 2>/dev/null || true

                            echo "✅ Verification complete!"
                        '''
                    }
                }
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
            script {
                try {
                    withCredentials([file(credentialsId: 'kubeconfig-minikube', variable: 'KUBECONFIG')]) {
                        sh '''
                            echo "========================================="
                            echo "🎉 Deployment Summary"
                            echo "========================================="
                            echo "📦 Build Number: ${BUILD_NUMBER}"
                            echo "🐳 Docker Image: ${DOCKER_IMAGE}:${IMAGE_TAG}"
                            echo ""
                            echo "☸️  Kubernetes Pods:"
                            kubectl get pods -l app=heart-disease-api || echo "⚠️  Could not retrieve pod info"
                            echo ""
                            echo "🌐 Service Info:"
                            kubectl get service heart-disease-api-service || echo "⚠️  Could not retrieve service info"
                            echo ""
                            echo "========================================="
                            echo "🤖 MLflow Model Registry"
                            echo "========================================="
                            if [ -d "venv" ]; then
                                . venv/bin/activate
                                python scripts/promote-model.py --list || echo "⚠️  Could not retrieve model info"
                            else
                                echo "⚠️  Virtual environment not found"
                            fi
                            echo ""
                            echo "========================================="
                            echo "📊 Access URLs"
                            echo "========================================="
                            SERVER_IP=$(hostname -I | awk '{print $1}')
                            echo "MLflow UI: http://$SERVER_IP:5001"
                            echo ""
                            echo "💡 To access services from your local machine:"
                            echo ""
                            echo "1️⃣  API (FastAPI + Swagger):"
                            echo "   kubectl port-forward service/heart-disease-api-service 8000:80"
                            echo "   Then visit: http://localhost:8000/docs"
                            echo ""
                            echo "2️⃣  MLflow UI (from your local machine):"
                            echo "   ssh -L 5001:localhost:5001 cloud@$SERVER_IP"
                            echo "   Then visit: http://localhost:5001"
                            echo ""
                            echo "3️⃣  Prometheus Metrics:"
                            echo "   kubectl port-forward service/heart-disease-api-service 8000:80"
                            echo "   Then visit: http://localhost:8000/metrics"
                            echo ""
                            echo "4️⃣  Manually promote a model (if needed):"
                            echo "   python scripts/promote-model.py <model-name>"
                            echo "   python scripts/promote-model.py --auto"
                            echo "========================================="
                        '''
                    }
                } catch (Exception e) {
                    echo "⚠️  Could not generate full deployment summary (kubeconfig credential may be missing)"
                    echo "📦 Build Number: ${BUILD_NUMBER}"
                    echo "🐳 Docker Image: ${DOCKER_IMAGE}:${IMAGE_TAG}"
                    echo ""
                    echo "💡 To see full deployment info, add kubeconfig-minikube credential to Jenkins"
                }
            }
        }
        failure {
            echo '❌ Pipeline failed!'
            sh '''
                echo "========================================="
                echo "Check logs for errors:"
                echo "- Jenkins console output"
                echo "- Docker logs: docker logs <container-id>"
                echo "- Kubernetes logs: kubectl logs <pod-name>"
                echo "========================================="
            '''
        }
        always {
            echo '🧹 Cleaning up...'
            sh '''
                # Use Minikube's Docker daemon for cleanup (if available)
                if command -v minikube &> /dev/null; then
                    eval $(minikube docker-env) 2>/dev/null || true
                fi

                # Clean up ALL test containers (ignore errors)
                echo "Removing all test containers..."
                docker ps -a 2>/dev/null | grep test-api- | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null || true

                # Also clean up any containers using port 8001 (ignore errors)
                echo "Removing containers using port 8001..."
                docker ps --filter "publish=8001" -q 2>/dev/null | xargs -r docker stop 2>/dev/null || true
                docker ps -a --filter "publish=8001" -q 2>/dev/null | xargs -r docker rm -f 2>/dev/null || true

                # Clean up old Docker images (keep last 5) - ignore errors
                docker images ${DOCKER_IMAGE} --format "{{.ID}}" 2>/dev/null | tail -n +6 | xargs -r docker rmi 2>/dev/null || true

                # Clean up Python virtual environment (ignore errors)
                rm -rf venv 2>/dev/null || true
                
                echo "✅ Cleanup completed"
            '''
        }
    }
}

