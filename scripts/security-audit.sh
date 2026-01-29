#!/bin/bash
set -e

echo "🔍 Starting Security Audit..."
echo "================================"

# Create reports directory if not exists
mkdir -p reports

# Backend audit
echo ""
echo "📦 Auditing Backend dependencies..."
cd backend
npm audit --json > ../reports/npm-audit-backend.json 2>&1 || true
BACKEND_VULNS=$(cat ../reports/npm-audit-backend.json | jq '.metadata.vulnerabilities.high + .metadata.vulnerabilities.critical' 2>/dev/null || echo "0")
cd ..

# Frontend audit
echo "📦 Auditing Frontend dependencies..."
cd frontend
npm audit --json > ../reports/npm-audit-frontend.json 2>&1 || true
FRONTEND_VULNS=$(cat ../reports/npm-audit-frontend.json | jq '.metadata.vulnerabilities.high + .metadata.vulnerabilities.critical' 2>/dev/null || echo "0")
cd ..

# Admin audit
echo "📦 Auditing Admin dependencies..."
cd admin
npm audit --json > ../reports/npm-audit-admin.json 2>&1 || true
ADMIN_VULNS=$(cat ../reports/npm-audit-admin.json | jq '.metadata.vulnerabilities.high + .metadata.vulnerabilities.critical' 2>/dev/null || echo "0")
cd ..

# Summary
echo ""
echo "================================"
echo "📊 Audit Summary:"
echo "   Backend High/Critical: $BACKEND_VULNS"
echo "   Frontend High/Critical: $FRONTEND_VULNS"
echo "   Admin High/Critical: $ADMIN_VULNS"
echo "================================"

TOTAL=$((BACKEND_VULNS + FRONTEND_VULNS + ADMIN_VULNS))

if [ "$TOTAL" -gt 0 ]; then
    echo "❌ Found $TOTAL high/critical vulnerabilities!"
    echo "   Check reports/ directory for details."
    exit 1
else
    echo "✅ No high/critical vulnerabilities found!"
fi
