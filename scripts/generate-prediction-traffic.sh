#!/bin/bash
#
# Generate Prediction Traffic Script
# Sends prediction requests to the Heart Disease API with varying parameters
# Runs 500 times or until stopped (Ctrl+C)
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
API_URL="${API_URL:-http://localhost:8000}"
MAX_REQUESTS="${MAX_REQUESTS:-500}"
REQUEST_INTERVAL="${REQUEST_INTERVAL:-1}"  # seconds between requests
LOG_RESPONSES="${LOG_RESPONSES:-false}"

# Counters
REQUEST_COUNT=0
SUCCESS_COUNT=0
ERROR_COUNT=0

# Trap Ctrl+C to show summary
trap 'show_summary; exit 0' INT TERM

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

show_summary() {
    echo ""
    echo "========================================="
    echo "📊 Traffic Generation Summary"
    echo "========================================="
    echo "Total Requests:  $REQUEST_COUNT"
    echo "Successful:      $SUCCESS_COUNT"
    echo "Errors:          $ERROR_COUNT"
    echo "Success Rate:    $(( SUCCESS_COUNT * 100 / REQUEST_COUNT ))%"
    echo "========================================="
}

# Generate random patient data
generate_patient_data() {
    # Age: 20-80 (realistic range)
    age=$((RANDOM % 61 + 20))
    
    # Sex: 0 or 1
    sex=$((RANDOM % 2))
    
    # Chest pain type: 0-3
    cp=$((RANDOM % 4))
    
    # Resting blood pressure: 90-180 (realistic range)
    trestbps=$((RANDOM % 91 + 90))
    
    # Cholesterol: 150-300 (realistic range)
    chol=$((RANDOM % 151 + 150))
    
    # Fasting blood sugar: 0 or 1
    fbs=$((RANDOM % 2))
    
    # Resting ECG: 0-2
    restecg=$((RANDOM % 3))
    
    # Max heart rate: 100-200 (realistic range)
    thalach=$((RANDOM % 101 + 100))
    
    # Exercise induced angina: 0 or 1
    exang=$((RANDOM % 2))
    
    # ST depression: 0.0-4.0 (realistic range)
    oldpeak=$(awk "BEGIN {printf \"%.1f\", $RANDOM/8192}")
    
    # Slope: 0-2
    slope=$((RANDOM % 3))
    
    # Number of vessels: 0-3 (realistic range, avoiding 4)
    ca=$((RANDOM % 4))
    
    # Thalassemia: 0-3
    thal=$((RANDOM % 4))
    
    # Output JSON
    cat <<EOF
{
  "age": $age,
  "sex": $sex,
  "cp": $cp,
  "trestbps": $trestbps,
  "chol": $chol,
  "fbs": $fbs,
  "restecg": $restecg,
  "thalach": $thalach,
  "exang": $exang,
  "oldpeak": $oldpeak,
  "slope": $slope,
  "ca": $ca,
  "thal": $thal
}
EOF
}

# Make prediction request
make_prediction() {
    local patient_data="$1"
    local request_num="$2"
    
    if [ "$LOG_RESPONSES" = "true" ]; then
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
            -X POST \
            -H "Content-Type: application/json" \
            -d "$patient_data" \
            "${API_URL}/predict")
        
        http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
        body=$(echo "$response" | sed '/HTTP_CODE:/d')
        
        if [ "$http_code" = "200" ]; then
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            if [ "$LOG_RESPONSES" = "true" ]; then
                echo "[$request_num] ✅ Success: $(echo "$body" | grep -o '"prediction_label":"[^"]*"' | cut -d'"' -f4)"
            fi
        else
            ERROR_COUNT=$((ERROR_COUNT + 1))
            echo "[$request_num] ❌ Error (HTTP $http_code): $body"
        fi
    else
        # Silent mode - just check HTTP status
        http_code=$(curl -s -o /dev/null -w "%{http_code}" \
            -X POST \
            -H "Content-Type: application/json" \
            -d "$patient_data" \
            "${API_URL}/predict")
        
        if [ "$http_code" = "200" ]; then
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            echo -ne "\r[$request_num/$MAX_REQUESTS] ✅ Success: $SUCCESS_COUNT | ❌ Errors: $ERROR_COUNT"
        else
            ERROR_COUNT=$((ERROR_COUNT + 1))
            echo -ne "\r[$request_num/$MAX_REQUESTS] ✅ Success: $SUCCESS_COUNT | ❌ Errors: $ERROR_COUNT (HTTP $http_code)"
        fi
    fi
}

# Main execution
main() {
    echo "========================================="
    echo "🚀 Prediction Traffic Generator"
    echo "========================================="
    echo ""
    print_info "API URL: $API_URL"
    print_info "Max Requests: $MAX_REQUESTS"
    print_info "Interval: ${REQUEST_INTERVAL}s"
    print_info "Log Responses: $LOG_RESPONSES"
    echo ""
    print_warning "Press Ctrl+C to stop early"
    echo ""
    
    # Test API connectivity
    print_info "Testing API connectivity..."
    if ! curl -s -f "${API_URL}/health" > /dev/null 2>&1; then
        print_error "Cannot connect to API at $API_URL"
        print_info "Make sure the API is running and accessible"
        print_info "You can set API_URL environment variable:"
        print_info "  export API_URL=http://your-api-url:port"
        exit 1
    fi
    print_success "API is reachable"
    echo ""
    
    # Start generating traffic
    print_info "Starting traffic generation..."
    echo ""
    
    START_TIME=$(date +%s)
    
    while [ $REQUEST_COUNT -lt $MAX_REQUESTS ]; do
        REQUEST_COUNT=$((REQUEST_COUNT + 1))
        
        # Generate random patient data
        patient_data=$(generate_patient_data)
        
        # Make prediction
        make_prediction "$patient_data" "$REQUEST_COUNT"
        
        # Wait before next request (except for last one)
        if [ $REQUEST_COUNT -lt $MAX_REQUESTS ]; then
            sleep "$REQUEST_INTERVAL"
        fi
    done
    
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    echo ""
    echo ""
    show_summary
    echo ""
    print_info "Duration: ${DURATION}s"
    print_info "Average Rate: $(awk "BEGIN {printf \"%.2f\", $REQUEST_COUNT/$DURATION}") requests/sec"
    echo ""
}

# Run main function
main

