#!/bin/bash
# session-start-scheduler.sh - Optional auto-trigger on session start
#
# This hook triggers the task scheduler automatically at session start
# to identify and start ready tasks.
#
# Installation:
#   1. Save this file to ~/.claude/hooks/
#   2. Make executable: chmod +x ~/.claude/hooks/session-start-scheduler.sh
#   3. Register with Claude Code hooks system (if supported)

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEDULER_SCRIPT="${HOME}/.claude/skills/task-scheduler/scripts/scheduler.sh"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[SESSION-HOOK]${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Main function
main() {
    # Read input from stdin (Hook will provide context)
    local input=""
    while IFS= read -r line; do
        input="${input}${line}"
    done

    # Determine if this is a SessionStart event
    # Hook format may vary, check for session start indicators
    if echo "$input" | grep -qi "SessionStart\|session.*start" 2>/dev/null || [ -z "$input" ]; then
        # This is a session start event (or default trigger)
        log "Session started - checking for ready tasks"

        # Run scheduler
        if [ -x "$SCHEDULER_SCRIPT" ]; then
            log "Running task scheduler..."

            # Execute scheduler in background to not block session
            # Auto-detect docs path: 90_DOCS (new default) or docs (legacy)
            if [[ -f "90_DOCS/PROJEKT.md" ]]; then
                PROJEKT_PATH="90_DOCS/PROJEKT.md"
            else
                PROJEKT_PATH="docs/PROJEKT.md"
            fi
            "$SCHEDULER_SCRIPT" "$PROJEKT_PATH" false &
            SCHEDULER_PID=$!

            # Give scheduler a moment to analyze
            sleep 1

            # Check if any tasks are ready
            if ps -p $SCHEDULER_PID > /dev/null 2>&1; then
                # Scheduler still running, give it more time
                wait $SCHEDULER_PID 2>/dev/null || true
            fi

            log_success "Task scheduler completed"
            echo ""
        else
            log "Warning: scheduler.sh not found at $SCHEDULER_SCRIPT"
        fi
    fi
}

# Run main function
main "$@"
