#!/usr/bin/env bash
# Kroki Health-Check Script
# Prueft ob ein lokaler Kroki-Server erreichbar ist
# Output: JSON mit Status, verfuegbaren Engines und Latenz
#
# Usage:
#   bash scripts/kroki-health.sh
#   KROKI_ENDPOINT=http://localhost:9000 bash scripts/kroki-health.sh

set -euo pipefail

KROKI_ENDPOINT="${KROKI_ENDPOINT:-http://localhost:8000}"
TIMEOUT=5

check_health() {
    local start_time=$(date +%s%N)
    local http_code

    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout "$TIMEOUT" \
        "$KROKI_ENDPOINT/health" 2>/dev/null) || true

    local end_time=$(date +%s%N)
    local latency_ms=$(( (end_time - start_time) / 1000000 ))

    if [ "$http_code" = "200" ]; then
        echo "{\"available\": true, \"endpoint\": \"$KROKI_ENDPOINT\", \"latency_ms\": $latency_ms}"
    else
        echo "{\"available\": false, \"endpoint\": \"$KROKI_ENDPOINT\", \"error\": \"HTTP $http_code\", \"fallback\": \"mermaid-js\"}"
    fi
}

check_health
