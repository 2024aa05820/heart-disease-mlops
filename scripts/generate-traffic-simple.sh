#!/bin/bash
#
# Simple one-liner version for quick traffic generation
# Usage: ./generate-traffic-simple.sh [API_URL] [COUNT] [INTERVAL]
#

API_URL="${1:-http://localhost:8000}"
COUNT="${2:-500}"
INTERVAL="${3:-1}"

echo "Generating $COUNT requests to $API_URL (${INTERVAL}s interval)"
echo "Press Ctrl+C to stop"
echo ""

for i in $(seq 1 $COUNT); do
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{
            \"age\": $((RANDOM % 61 + 20)),
            \"sex\": $((RANDOM % 2)),
            \"cp\": $((RANDOM % 4)),
            \"trestbps\": $((RANDOM % 91 + 90)),
            \"chol\": $((RANDOM % 151 + 150)),
            \"fbs\": $((RANDOM % 2)),
            \"restecg\": $((RANDOM % 3)),
            \"thalach\": $((RANDOM % 101 + 100)),
            \"exang\": $((RANDOM % 2)),
            \"oldpeak\": $(awk "BEGIN {printf \"%.1f\", $RANDOM/8192}"),
            \"slope\": $((RANDOM % 3)),
            \"ca\": $((RANDOM % 4)),
            \"thal\": $((RANDOM % 4))
        }" \
        "${API_URL}/predict" > /dev/null 2>&1 && echo -ne "\r[$i/$COUNT] ✅" || echo -ne "\r[$i/$COUNT] ❌"
    [ $i -lt $COUNT ] && sleep $INTERVAL
done
echo ""
echo "Done!"

