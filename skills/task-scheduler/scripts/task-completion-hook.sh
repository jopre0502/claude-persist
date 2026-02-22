#!/bin/bash
# task-completion-hook.sh - Triggered after task completion
# Updates PROJEKT.md + task-file, triggers next ready tasks
#
# Input (JSON via stdin):
# {
#   "task_uuid": "TASK-005",
#   "status": "completed",
#   "result": "Success",
#   "completion_timestamp": "2026-01-19 15:30"
# }

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[TASK-HOOK]${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
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

# Update PROJEKT.md with new task status
update_projekt_md() {
    local projekt_file="$1"
    local uuid="$2"
    local new_status="$3"
    local timestamp="$4"

    if [ ! -f "$projekt_file" ]; then
        log_error "PROJEKT.md not found: $projekt_file"
        return 1
    fi

    log "Updating PROJEKT.md: $uuid → $new_status"

    # Use sed to replace task status in table
    # Pattern: | TASK-XXX | Task Name | old_status | ...
    # Replace with: | TASK-XXX | Task Name | new_status | ...

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS sed
        sed -i "" "s/| \($uuid\) | \(.*\) | [^ ]* | /| \1 | \2 | $new_status | /" "$projekt_file"
    else
        # Linux sed
        sed -i "s/| \($uuid\) | \(.*\) | [^ ]* | /| \1 | \2 | $new_status | /" "$projekt_file"
    fi

    log_success "PROJEKT.md updated"
}

# Update task-file with completion info
update_task_file() {
    local uuid="$1"
    local status="$2"
    local timestamp="$3"

    # Find task file: docs/tasks/TASK-XXX-*.md
    local task_file=$(find . -name "${uuid}-*.md" -type f 2>/dev/null | head -1)

    if [ -z "$task_file" ]; then
        log_error "Task file not found for $uuid"
        return 1
    fi

    log "Updating task file: $task_file"

    # Update frontmatter: status and completed timestamp
    # Replace:
    #   status: pending
    #   completed:
    # With:
    #   status: completed
    #   completed: 2026-01-19 15:30

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS sed
        sed -i "" "s/^status: .*/status: $status/" "$task_file"
        sed -i "" "s/^completed:.*$/completed: $timestamp/" "$task_file"
    else
        # Linux sed
        sed -i "s/^status: .*/status: $status/" "$task_file"
        sed -i "s/^completed:.*$/completed: $timestamp/" "$task_file"
    fi

    # Append completion note to "Ergebnis" section
    if grep -q "## Ergebnis" "$task_file"; then
        # Find line number of Ergebnis section
        local ergebnis_line=$(grep -n "## Ergebnis" "$task_file" | cut -d: -f1)
        local insert_line=$((ergebnis_line + 1))

        # Insert completion info
        local completion_text="**Completion-Datum:** $timestamp"

        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i "" "${insert_line}a\\
$completion_text
" "$task_file"
        else
            sed -i "${insert_line}i\\$completion_text" "$task_file"
        fi
    fi

    log_success "Task file updated"
}

# Trigger next ready tasks (recursive scheduler call)
trigger_next_tasks() {
    local projekt_file="$1"

    log "Checking for next ready tasks..."

    # Re-run scheduler to find newly-ready tasks
    if [ -x "$SCRIPT_DIR/scheduler.sh" ]; then
        "$SCRIPT_DIR/scheduler.sh" "$projekt_file" false
    else
        log_error "scheduler.sh not found"
        return 1
    fi
}

# Notify user of completion
notify_user() {
    local uuid="$1"
    local status="$2"

    log_success "Task $uuid completed with status: $status"
    echo ""
    echo "📋 Task Completion Report"
    echo "========================="
    echo "UUID: $uuid"
    echo "Status: $status"
    echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
}

# Main function
main() {
    log "Task Completion Hook triggered"

    # Read JSON from stdin
    local input_json
    input_json=$(read_input_json)

    if [ -z "$input_json" ]; then
        log_error "No input JSON provided"
        return 1
    fi

    # Parse JSON
    local uuid=$(echo "$input_json" | jq -r '.task_uuid // empty' 2>/dev/null)
    local status=$(echo "$input_json" | jq -r '.status // empty' 2>/dev/null)
    local result=$(echo "$input_json" | jq -r '.result // "Unknown"' 2>/dev/null)
    local timestamp=$(echo "$input_json" | jq -r '.completion_timestamp // empty' 2>/dev/null)

    if [ -z "$uuid" ] || [ -z "$status" ] || [ -z "$timestamp" ]; then
        log_error "Invalid JSON format"
        return 1
    fi

    log "Processing completion for: $uuid"

    # Find PROJEKT.md
    local projekt_file="./docs/PROJEKT.md"
    if [ ! -f "$projekt_file" ]; then
        projekt_file="./PROJEKT.md"
    fi

    if [ ! -f "$projekt_file" ]; then
        log_error "PROJEKT.md not found"
        return 1
    fi

    # Update files
    update_projekt_md "$projekt_file" "$uuid" "$status" "$timestamp" || return 1
    update_task_file "$uuid" "$status" "$timestamp" || true  # Non-critical

    # Notify user
    notify_user "$uuid" "$status"

    # Trigger next tasks
    trigger_next_tasks "$projekt_file" || true  # Non-critical

    log_success "Hook processing complete"
}

# Run main function
main "$@"
