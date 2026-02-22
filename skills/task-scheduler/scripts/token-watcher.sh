#!/bin/bash
# token-watcher.sh - Token budget monitoring
# Triggered before task execution to check token usage
#
# Input (JSON via stdin):
# {
#   "usage_pct": 72,
#   "current": 144000,
#   "limit": 200000
# }

set -euo pipefail

# Configuration
WARN_THRESHOLD=70  # Warn at 70%
STOP_THRESHOLD=85  # Recommend stop at 85%

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[TOKEN-WATCHER]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_critical() {
    echo -e "${RED}✗${NC} $1" >&2
}

# Read input JSON from stdin
read_input_json() {
    local json=""
    while IFS= read -r line; do
        json="${json}${line}"
    done
    echo "$json"
}

# Main function
main() {
    log "Token budget check"

    # Read JSON from stdin
    local input_json
    input_json=$(read_input_json)

    if [ -z "$input_json" ]; then
        # If no input, skip check (not an error)
        log "No token data provided, skipping check"
        return 0
    fi

    # Parse JSON
    local usage_pct=$(echo "$input_json" | jq -r '.usage_pct // 0' 2>/dev/null || echo "0")
    local current=$(echo "$input_json" | jq -r '.current // 0' 2>/dev/null || echo "0")
    local limit=$(echo "$input_json" | jq -r '.limit // 200000' 2>/dev/null || echo "200000")

    # Validate numeric values
    if ! [[ "$usage_pct" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        usage_pct=0
    fi

    log "Token usage: $current / $limit (${usage_pct}%)"

    # Check thresholds
    if (( $(echo "$usage_pct > $STOP_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
        # Critical: >85% - recommend stopping
        log_critical "⚠️  CRITICAL: Token budget at ${usage_pct}% (limit: $limit)"
        echo ""
        echo "🛑 Session Token Budget Critical"
        echo "================================="
        echo "Current usage: ${usage_pct}% ($current / $limit tokens)"
        echo ""
        echo "Recommendation: Consider ending this session to preserve context"
        echo "  → Run: /exit"
        echo ""
        echo "If continuing, only critical tasks:"
        echo "  → Run: /project-doc-restructure (optional)"
        echo ""
        return 2  # Exit code 2 = critical

    elif (( $(echo "$usage_pct >= $WARN_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
        # Warning: 70-85% - suggest restructure + continue
        log_warn "⚠️  WARNING: Token budget at ${usage_pct}% (limit: $limit)"
        echo ""
        echo "📊 Session Token Budget High"
        echo "=============================="
        echo "Current usage: ${usage_pct}% ($current / $limit tokens)"
        echo "Remaining: ~$((limit - current)) tokens"
        echo ""
        echo "Recommended action: Run /project-doc-restructure"
        echo "  → This will optimize documentation for next session"
        echo "  → Takes ~2-5 min"
        echo ""
        echo "You can continue working, but monitor token usage closely"
        echo ""
        return 1  # Exit code 1 = warning

    else
        # OK: <70% - proceed normally
        log "✓ Token budget OK: ${usage_pct}%"
        return 0  # Exit code 0 = OK
    fi
}

# Run main function
main "$@"
exit_code=$?

# Return appropriate exit code
exit $exit_code
