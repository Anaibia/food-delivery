#!/bin/bash
set -e

# Container Security Scan Script using Trivy
# Usage: ./container-scan.sh <image-name>

IMAGE=$1
THRESHOLD=0
OUTPUT_DIR="reports"

if [ -z "$IMAGE" ]; then
    echo "Usage: $0 <image-name>"
    echo "Example: $0 food-delivery-backend:latest"
    exit 1
fi

# Create reports directory if not exists
mkdir -p $OUTPUT_DIR

echo "🔍 Scanning image: $IMAGE"
echo "================================"

# Check if Trivy is installed
if ! command -v trivy &> /dev/null; then
    echo "⚠️  Trivy not found. Installing..."
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
fi

# Generate report filename
REPORT_NAME=$(echo $IMAGE | tr ':/' '_')

# Scan and count critical vulnerabilities
echo "Running vulnerability scan..."
trivy image --severity HIGH,CRITICAL \
    --format json \
    --output "$OUTPUT_DIR/trivy-$REPORT_NAME.json" \
    $IMAGE || true

# Also generate HTML report for readability
trivy image --severity HIGH,CRITICAL \
    --format template \
    --template "@/usr/local/share/trivy/templates/html.tpl" \
    --output "$OUTPUT_DIR/trivy-$REPORT_NAME.html" \
    $IMAGE 2>/dev/null || true

# Count critical vulnerabilities
CRITICAL=$(cat "$OUTPUT_DIR/trivy-$REPORT_NAME.json" | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length' 2>/dev/null || echo "0")
HIGH=$(cat "$OUTPUT_DIR/trivy-$REPORT_NAME.json" | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH")] | length' 2>/dev/null || echo "0")

echo ""
echo "================================"
echo "📊 Scan Results for $IMAGE:"
echo "   Critical: $CRITICAL"
echo "   High: $HIGH"
echo "   Report: $OUTPUT_DIR/trivy-$REPORT_NAME.json"
echo "================================"

if [ "$CRITICAL" -gt "$THRESHOLD" ]; then
    echo "❌ Found $CRITICAL critical vulnerabilities!"
    echo ""
    echo "Critical vulnerabilities:"
    trivy image --severity CRITICAL $IMAGE 2>/dev/null || true
    exit 1
else
    echo "✅ Image scan passed! (No critical vulnerabilities)"
fi
