#!/bin/bash
# scheduler.sh - Task Orchestration Engine
# Reads PROJEKT.md, resolves dependencies, starts ready tasks
#
# Usage: scheduler.sh [PROJEKT_PATH] [DRY_RUN]
# Example: scheduler.sh docs/PROJEKT.md false

set -euo pipefail

# Configuration
PROJEKT_PATH="${1:-.}"
DRY_RUN="${2:-false}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/hooks"

# Logging Configuration
START_TIME=$SECONDS
LOG_DIR=""  # Will be set in main() after finding PROJECT_ROOT
LOG_FILE=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log() {
    local msg="$1"
    echo -e "${BLUE}[SCHEDULER]${NC} $msg" >&2
    log_to_file "$msg"
}

log_success() {
    local msg="$1"
    echo -e "${GREEN}✓${NC} $msg"
    log_to_file "✓ $msg"
}

log_warn() {
    local msg="$1"
    echo -e "${YELLOW}⚠${NC} $msg"
    log_to_file "⚠ $msg"
}

log_error() {
    local msg="$1"
    echo -e "${RED}✗${NC} $msg" >&2
    log_to_file "✗ $msg"
}

# Log to file (dual output: stdout + file)
log_to_file() {
    local msg="$1"
    if [ -n "$LOG_FILE" ]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "[$timestamp] $msg" >> "$LOG_FILE"
    fi
}

# Extract task table from PROJEKT.md
# Returns JSON array of tasks
extract_task_table() {
    local projekt_file="$1"

    if [ ! -f "$projekt_file" ]; then
        log_error "PROJEKT.md not found: $projekt_file"
        return 1
    fi

    log "Extracting tasks from $projekt_file"

    # Parse markdown table: | UUID | Task | Status | Dependencies | ... |
    # Output: JSON array of tasks
    # KRITISCH: mawk verwenden statt awk (compatibility)
    mawk '
        /^\|.*UUID.*Task.*Status/ {
            in_table = 1
            next
        }
        in_table && /^\|---/ {
            next
        }
        in_table && /^\|/ {
            # Parse table row - KRITISCH: Lokale Variable verwenden, nicht $0 modifizieren
            # (AWK Pattern-Matching wird durch $0-Modifikation beeinflusst)
            line = $0
            gsub(/^\||\|$/, "", line)  # Remove leading/trailing pipes
            gsub(/^ +| +$/, "", line)  # Trim spaces

            split(line, cols, "|")
            for (i in cols) gsub(/^ +| +$/, "", cols[i])

            # Extract UUID and clean it (remove **bold** markers)
            uuid = cols[1]
            gsub(/\*\*|\*/, "", uuid)

            # Only process valid TASK-NNN rows
            if (uuid ~ /^TASK-[0-9]+$/) {
                task_name = cols[2]
                status = cols[3]
                deps = cols[4]
                effort = cols[5]
                deliverable = cols[6]

                # Clean status field (remove emoji/bold)
                gsub(/[^a-zA-Z_]/, "", status)  # Keep only letters and underscore

                # Convert to lowercase for case-insensitive matching
                status = tolower(status)

                # Clean up status based on common patterns (6 MECE status)
                if (status ~ /completed|complete/) status = "completed"
                else if (status ~ /pending/) status = "pending"
                else if (status ~ /inprogress/) status = "in_progress"
                else if (status ~ /ongoing/) status = "ongoing"
                else if (status ~ /blocked/) status = "blocked"
                else if (status ~ /cancelled|canceled/) status = "cancelled"

                # Output JSON only for valid status (6 MECE)
                if (status ~ /^(pending|in_progress|ongoing|completed|blocked|cancelled)$/) {
                    printf "{\"uuid\":\"%s\",\"name\":\"%s\",\"status\":\"%s\",\"dependencies\":\"%s\",\"effort\":\"%s\",\"deliverable\":\"%s\"}\n", uuid, task_name, status, deps, effort, deliverable
                }
            }
        }
        in_table && /^[^|]/ {
            in_table = 0
        }
    ' "$projekt_file"
}

# Resolve dependencies for a single task
# Returns: "ready" | "blocked"
resolve_dependencies() {
    local uuid="$1"
    local deps="$2"
    local tasks_status="$3"

    # Parse dependency list: [TASK-001, TASK-002] or "None"
    if [ "$deps" = "None" ] || [ -z "$deps" ] || [ "$deps" = "[]" ]; then
        echo "ready"
        return
    fi

    # Extract task UUIDs from dependency string
    local task_list=$(echo "$deps" | sed -E 's/\[|\]//g; s/,/ /g; s/^ +| +$//g')

    # Check if all dependencies are completed
    for dep_task in $task_list; do
        dep_task=$(echo "$dep_task" | xargs)  # Trim whitespace

        # Find dependency task status
        local dep_status=$(echo "$tasks_status" | jq -r ".[] | select(.uuid == \"$dep_task\") | .status" 2>/dev/null || echo "unknown")

        # Terminal status (completed OR cancelled) satisfies dependencies
        if [ "$dep_status" != "completed" ] && [ "$dep_status" != "cancelled" ]; then
            echo "blocked"
            return
        fi
    done

    echo "ready"
}

# Find ready tasks (no pending dependencies)
identify_ready_tasks() {
    local tasks_json="$1"

    log "Analyzing dependencies..."

    local ready_tasks=()
    local blocked_tasks=()

    # For each pending task, check dependencies
    echo "$tasks_json" | jq -r '.[] | select(.status == "pending") | .uuid' | while read -r uuid; do
        local task_data=$(echo "$tasks_json" | jq -r ".[] | select(.uuid == \"$uuid\")")
        local deps=$(echo "$task_data" | jq -r '.dependencies')
        local status=$(resolve_dependencies "$uuid" "$deps" "$tasks_json")

        if [ "$status" = "ready" ]; then
            echo "$uuid|ready"
        else
            echo "$uuid|blocked"
        fi
    done
}

# Main orchestration logic
main() {
    # Initialize logging FIRST (before any log() calls)
    local PROJECT_ROOT="."
    if [ -d "./docs" ]; then
        PROJECT_ROOT="."
    fi

    # Setup log directory and file
    LOG_DIR="$PROJECT_ROOT/docs/tasks/TASK-012/execution-logs"
    mkdir -p "$LOG_DIR" 2>/dev/null || true
    LOG_FILE="$LOG_DIR/scheduler-run-$(date +%Y-%m-%d-%H-%M-%S).log"

    # Now logging is ready
    log "Task Scheduler starting (DRY_RUN=$DRY_RUN)"

    # Find PROJEKT.md
    if [ "$PROJEKT_PATH" = "." ]; then
        # Search for PROJEKT.md in current directory or docs/
        if [ -f "./docs/PROJEKT.md" ]; then
            PROJEKT_PATH="./docs/PROJEKT.md"
        elif [ -f "./PROJEKT.md" ]; then
            PROJEKT_PATH="./PROJEKT.md"
        else
            log_error "PROJEKT.md not found"
            return 1
        fi
    fi

    log "Using PROJEKT: $PROJEKT_PATH"

    # Extract tasks from PROJEKT.md
    local tasks_json
    tasks_json=$(extract_task_table "$PROJEKT_PATH" | jq -s '.' 2>/dev/null || echo "[]")

    if [ "$tasks_json" = "[]" ]; then
        log_warn "No tasks found in PROJEKT.md"
        return 0
    fi

    log "Found $(echo "$tasks_json" | jq 'length') tasks"

    # Analyze and identify ready tasks
    local ready_count=0
    local blocked_count=0

    echo "$tasks_json" | jq -r '.[] | select(.status == "pending") | .uuid + "|" + .name' | while read -r line; do
        uuid=$(echo "$line" | cut -d'|' -f1)
        name=$(echo "$line" | cut -d'|' -f2)

        local task_data=$(echo "$tasks_json" | jq -r ".[] | select(.uuid == \"$uuid\")")
        local deps=$(echo "$task_data" | jq -r '.dependencies // "None"')
        local dep_status=$(resolve_dependencies "$uuid" "$deps" "$tasks_json")

        if [ "$dep_status" = "ready" ]; then
            log_success "READY: $uuid - $name"
            ready_count=$((ready_count + 1))

            # In dry-run mode, just show what would run
            if [ "$DRY_RUN" = "true" ]; then
                log "(DRY RUN: would start this task)"
            else
                # Start background task
                log "Starting background task: $uuid"
                # In real implementation, would call Claude Code API
                # For now, just show notification
            fi
        else
            log_warn "BLOCKED: $uuid - $name (waiting for dependencies)"
            blocked_count=$((blocked_count + 1))
        fi
    done

    log "Summary: $ready_count ready, $blocked_count blocked"

    if [ "$ready_count" -gt 0 ]; then
        log_success "Tasks ready for execution"
    else
        log_warn "No tasks ready to execute"
    fi

    # Log completion with duration
    local duration=$((SECONDS - START_TIME))
    log "Task Scheduler completed in ${duration}s"
    log "Log saved to: $LOG_FILE"
}

# Run main function
main "$@"
