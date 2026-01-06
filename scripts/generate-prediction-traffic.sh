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
VALID_COUNT=0
INVALID_COUNT=0

# Error injection rate (0-100, percentage of requests that should be invalid)
ERROR_RATE="${ERROR_RATE:-10}"  # 10% invalid requests by default

# Error types generated:
# 0: Missing required field (trestbps)
# 1: Out of range age (> 120)
# 2: High cholesterol (550 - valid but edge case, user example)
# 3: Invalid type (string instead of number)
# 4: Out of range cp (> 3)
# 5: Out of range chol (> 600)
# 6: User-provided example (high cholesterol case)

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
    echo "Valid Requests:  $VALID_COUNT"
    echo "Invalid Requests: $INVALID_COUNT"
    echo "Successful:      $SUCCESS_COUNT"
    echo "Errors:          $ERROR_COUNT"
    if [ $REQUEST_COUNT -gt 0 ]; then
        echo "Success Rate:    $(( SUCCESS_COUNT * 100 / REQUEST_COUNT ))%"
        echo "Error Rate:      $(( ERROR_COUNT * 100 / REQUEST_COUNT ))%"
    fi
    echo "========================================="
}

# Generate random patient data (valid)
generate_valid_patient_data() {
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

# Generate invalid patient data (for error testing)
generate_invalid_patient_data() {
    local error_type=$((RANDOM % 7))
    
    case $error_type in
        0)
            # Missing required field
            age=$((RANDOM % 61 + 20))
            sex=$((RANDOM % 2))
            cp=$((RANDOM % 4))
            # Missing trestbps
            chol=$((RANDOM % 151 + 150))
            fbs=$((RANDOM % 2))
            restecg=$((RANDOM % 3))
            thalach=$((RANDOM % 101 + 100))
            exang=$((RANDOM % 2))
            oldpeak=$(awk "BEGIN {printf \"%.1f\", $RANDOM/8192}")
            slope=$((RANDOM % 3))
            ca=$((RANDOM % 4))
            thal=$((RANDOM % 4))
            cat <<EOF
{
  "age": $age,
  "sex": $sex,
  "cp": $cp,
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
            ;;
        1)
            # Out of range value (age > 120)
            cat <<EOF
{
  "age": 150,
  "sex": 1,
  "cp": 2,
  "trestbps": 145,
  "chol": 233,
  "fbs": 1,
  "restecg": 0,
  "thalach": 150,
  "exang": 0,
  "oldpeak": 2.3,
  "slope": 0,
  "ca": 0,
  "thal": 1
}
EOF
            ;;
        2)
            # Out of range value (chol > 600) - using user's example with high cholesterol
            cat <<EOF
{
  "age": 78,
  "sex": 1,
  "cp": 2,
  "trestbps": 145,
  "chol": 550,
  "fbs": 1,
  "restecg": 0,
  "thalach": 150,
  "exang": 0,
  "oldpeak": 2.3,
  "slope": 0,
  "ca": 0,
  "thal": 1
}
EOF
            ;;
        3)
            # Invalid type (string instead of number)
            cat <<EOF
{
  "age": "sixty",
  "sex": 1,
  "cp": 2,
  "trestbps": 145,
  "chol": 233,
  "fbs": 1,
  "restecg": 0,
  "thalach": 150,
  "exang": 0,
  "oldpeak": 2.3,
  "slope": 0,
  "ca": 0,
  "thal": 1
}
EOF
            ;;
        4)
            # Out of range value (cp > 3)
            cat <<EOF
{
  "age": 63,
  "sex": 1,
  "cp": 5,
  "trestbps": 145,
  "chol": 233,
  "fbs": 1,
  "restecg": 0,
  "thalach": 150,
  "exang": 0,
  "oldpeak": 2.3,
  "slope": 0,
  "ca": 0,
  "thal": 1
}
EOF
            ;;
        5)
            # Out of range value (chol > 600) - actual invalid case
            cat <<EOF
{
  "age": 78,
  "sex": 1,
  "cp": 2,
  "trestbps": 145,
  "chol": 650,
  "fbs": 1,
  "restecg": 0,
  "thalach": 150,
  "exang": 0,
  "oldpeak": 2.3,
  "slope": 0,
  "ca": 0,
  "thal": 1
}
EOF
            ;;
        6)
            # User-provided example case (high cholesterol, valid but edge case)
            cat <<EOF
{
  "age": 78,
  "ca": 0,
  "chol": 550,
  "cp": 2,
  "exang": 0,
  "fbs": 1,
  "oldpeak": 2.3,
  "restecg": 0,
  "sex": 1,
  "slope": 0,
  "thal": 1,
  "thalach": 150,
  "trestbps": 145
}
EOF
            ;;
    esac
}

# Generate patient data (valid or invalid based on error rate)
generate_patient_data() {
    local should_error=$((RANDOM % 100))
    
    if [ $should_error -lt $ERROR_RATE ]; then
        INVALID_COUNT=$((INVALID_COUNT + 1))
        generate_invalid_patient_data
    else
        VALID_COUNT=$((VALID_COUNT + 1))
        generate_valid_patient_data
    fi
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
                prediction=$(echo "$body" | grep -o '"prediction_label":"[^"]*"' | cut -d'"' -f4 || echo "N/A")
                echo "[$request_num] ✅ Success: $prediction"
            fi
        else
            ERROR_COUNT=$((ERROR_COUNT + 1))
            if [ "$LOG_RESPONSES" = "true" ]; then
                error_msg=$(echo "$body" | grep -o '"detail":"[^"]*"' | cut -d'"' -f4 || echo "$body" | head -c 100)
                echo "[$request_num] ❌ Error (HTTP $http_code): $error_msg"
            fi
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
            echo -ne "\r[$request_num/$MAX_REQUESTS] ✅ Valid: $VALID_COUNT | ❌ Invalid: $INVALID_COUNT | ✅ Success: $SUCCESS_COUNT | ❌ Errors: $ERROR_COUNT"
        else
            ERROR_COUNT=$((ERROR_COUNT + 1))
            echo -ne "\r[$request_num/$MAX_REQUESTS] ✅ Valid: $VALID_COUNT | ❌ Invalid: $INVALID_COUNT | ✅ Success: $SUCCESS_COUNT | ❌ Errors: $ERROR_COUNT"
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
    print_info "Error Rate: ${ERROR_RATE}% (invalid requests)"
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

