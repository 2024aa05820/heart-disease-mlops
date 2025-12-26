#!/bin/bash

################################################################################
# Download GitHub Actions Artifact Script
# 
# Downloads the latest Docker image artifact from GitHub Actions
# 
# Usage:
#   ./scripts/download_github_artifact.sh [run-id]
#
# Example:
#   ./scripts/download_github_artifact.sh           # Latest successful run
#   ./scripts/download_github_artifact.sh 12345678  # Specific run ID
#
# Requirements:
#   - GitHub Personal Access Token in GITHUB_TOKEN env var
#   - jq installed (for JSON parsing)
#   - curl installed
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Configuration
GITHUB_REPO="2024aa05820/heart-disease-mlops"
ARTIFACT_NAME="docker-image"
RUN_ID="${1:-}"

# Check for GitHub token
if [ -z "$GITHUB_TOKEN" ]; then
    print_error "GITHUB_TOKEN environment variable not set"
    echo ""
    echo "Please set your GitHub Personal Access Token:"
    echo "  export GITHUB_TOKEN='your-token-here'"
    echo ""
    echo "Create a token at: https://github.com/settings/tokens"
    echo "Required scopes: repo, workflow"
    exit 1
fi

# Check for jq
if ! command -v jq &> /dev/null; then
    print_error "jq is not installed"
    echo ""
    echo "Install jq:"
    echo "  Rocky Linux/RHEL: sudo dnf install jq"
    echo "  Ubuntu/Debian: sudo apt install jq"
    echo "  macOS: brew install jq"
    exit 1
fi

print_header "🚀 GitHub Actions Artifact Downloader"
echo ""

# Get run ID if not provided
if [ -z "$RUN_ID" ]; then
    print_info "Finding latest successful GitHub Actions run..."
    
    RUN_ID=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/${GITHUB_REPO}/actions/runs?status=success&per_page=1" \
        | jq -r '.workflow_runs[0].id')
    
    if [ "$RUN_ID" = "null" ] || [ -z "$RUN_ID" ]; then
        print_error "No successful workflow runs found"
        exit 1
    fi
    
    print_success "Found run ID: $RUN_ID"
else
    print_info "Using provided run ID: $RUN_ID"
fi

echo ""

# Get workflow run details
print_info "Getting workflow run details..."
WORKFLOW_INFO=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/${GITHUB_REPO}/actions/runs/$RUN_ID")

WORKFLOW_NAME=$(echo "$WORKFLOW_INFO" | jq -r '.name')
WORKFLOW_STATUS=$(echo "$WORKFLOW_INFO" | jq -r '.status')
WORKFLOW_CONCLUSION=$(echo "$WORKFLOW_INFO" | jq -r '.conclusion')
CREATED_AT=$(echo "$WORKFLOW_INFO" | jq -r '.created_at')

echo ""
print_info "Workflow: $WORKFLOW_NAME"
print_info "Status: $WORKFLOW_STATUS"
print_info "Conclusion: $WORKFLOW_CONCLUSION"
print_info "Created: $CREATED_AT"
echo ""

# Get artifact download URL
print_info "Getting artifact download URL..."
ARTIFACT_URL=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/${GITHUB_REPO}/actions/runs/$RUN_ID/artifacts" \
    | jq -r ".artifacts[] | select(.name==\"${ARTIFACT_NAME}\") | .archive_download_url")

if [ -z "$ARTIFACT_URL" ] || [ "$ARTIFACT_URL" = "null" ]; then
    print_error "Artifact '${ARTIFACT_NAME}' not found in run $RUN_ID"
    echo ""
    print_info "Available artifacts:"
    curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/${GITHUB_REPO}/actions/runs/$RUN_ID/artifacts" \
        | jq -r '.artifacts[].name'
    exit 1
fi

print_success "Found artifact URL"
echo ""

# Download artifact
print_info "Downloading artifact..."
curl -L -H "Authorization: token $GITHUB_TOKEN" \
    -o docker-image.zip "$ARTIFACT_URL" \
    --progress-bar

print_success "Artifact downloaded: docker-image.zip"
echo ""

# Extract artifact
print_info "Extracting artifact..."
unzip -o docker-image.zip

if [ -f "docker-image.tar.gz" ]; then
    print_success "Extracted: docker-image.tar.gz"
    
    # Show file size
    SIZE=$(du -h docker-image.tar.gz | cut -f1)
    print_info "File size: $SIZE"
    
    # Clean up zip file
    rm docker-image.zip
    print_info "Cleaned up: docker-image.zip"
else
    print_error "Expected file docker-image.tar.gz not found"
    exit 1
fi

echo ""
print_header "✅ Download Complete!"
echo ""
print_success "Docker image artifact ready: docker-image.tar.gz"
echo ""
print_info "Next steps:"
echo "  1. Load image: docker load -i docker-image.tar.gz"
echo "  2. Load to Minikube: minikube image load heart-disease-api:latest"
echo "  3. Deploy: kubectl apply -f deploy/k8s/"
echo ""
print_info "Or use the deployment script:"
echo "  ./scripts/deploy_github_artifact.sh docker-image.tar.gz"
echo ""

