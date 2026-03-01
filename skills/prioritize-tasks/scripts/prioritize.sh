#!/bin/bash
# prioritize.sh - Task Prioritization Engine
# Analyzes PROJEKT.md, calculates priority scores, suggests optimal execution order
#
# Usage: prioritize.sh [PROJEKT_PATH] [--reorder]
# Example: prioritize.sh docs/PROJEKT.md --reorder

set -euo pipefail

# Configuration
PROJEKT_PATH="${1:-.}"
REORDER_FLAG="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Scoring weights (configurable via env vars)
EFFORT_WEIGHT="${PRIORITIZE_EFFORT_WEIGHT:-3}"
DEPS_WEIGHT="${PRIORITIZE_DEPS_WEIGHT:-1}"
UNBLOCKS_WEIGHT="${PRIORITIZE_UNBLOCKS_WEIGHT:-0.5}"
ISSUES_WEIGHT="${PRIORITIZE_ISSUES_WEIGHT:-2}"

# Logging Configuration
START_TIME=$SECONDS
LOG_DIR=""
LOG_FILE=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Helper functions - all log to stderr to keep stdout clean for piping
log() {
    local msg="$1"
    echo -e "${BLUE}[PRIORITIZE]${NC} $msg" >&2
    log_to_file "$msg"
}

log_success() {
    local msg="$1"
    echo -e "${GREEN}✓${NC} $msg" >&2
    log_to_file "✓ $msg"
}

log_warn() {
    local msg="$1"
    echo -e "${YELLOW}⚠${NC} $msg" >&2
    log_to_file "⚠ $msg"
}

log_error() {
    local msg="$1"
    echo -e "${RED}✗${NC} $msg" >&2
    log_to_file "✗ $msg"
}

log_to_file() {
    local msg="$1"
    if [ -n "$LOG_FILE" ] && [ -w "$(dirname "$LOG_FILE")" ]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "[$timestamp] $msg" >> "$LOG_FILE"
    fi
}

# Parse effort string to hours
# Input: "1h", "2h", "1d", "2d", "3d+"
# Output: numeric hours
parse_effort_to_hours() {
    local effort="$1"

    # Clean up effort string
    effort=$(echo "$effort" | tr -d ' ' | tr '[:upper:]' '[:lower:]')

    case "$effort" in
        1h) echo 1 ;;
        2h) echo 2 ;;
        4h) echo 4 ;;
        1d) echo 8 ;;
        2d) echo 16 ;;
        3d*) echo 24 ;;
        *) echo 4 ;; # Default: 4h (medium)
    esac
}

# Extract task table from PROJEKT.md
# Returns JSON array of tasks
extract_task_table() {
    local projekt_file="$1"

    if [ ! -f "$projekt_file" ]; then
        log_error "PROJEKT.md not found: $projekt_file"
        return 1
    fi

    # Parse markdown table: | UUID | Task | Status | Dependencies | ... |
    awk '
        /^\|.*UUID.*Task.*Status/ {
            in_table = 1
            next
        }
        in_table && /^\|---/ {
            next
        }
        in_table && /^\|/ {
            line = $0
            gsub(/\r/, "", line)
            gsub(/^\||\|$/, "", line)
            gsub(/^ +| +$/, "", line)

            split(line, cols, "|")
            for (i in cols) gsub(/^ +| +$/, "", cols[i])

            uuid = cols[1]
            gsub(/\*\*|\*/, "", uuid)

            if (uuid ~ /^TASK-[0-9]+$/) {
                task_name = cols[2]
                status = cols[3]
                deps = cols[4]
                effort = cols[5]
                deliverable = cols[6]
                task_file = cols[7]

                gsub(/[^a-zA-Z_]/, "", status)
                status = tolower(status)

                if (status ~ /completed|complete/) status = "completed"
                else if (status ~ /cancelled|canceled/) status = "cancelled"
                else if (status ~ /blocked/) status = "blocked"
                else if (status ~ /inprogress/) status = "in_progress"
                else if (status ~ /pending/) status = "pending"

                if (status ~ /^(pending|in_progress|completed|blocked|cancelled)$/) {
                    # Escape double quotes in string fields to produce valid JSON
                    gsub(/"/, "\\\"", task_name)
                    gsub(/"/, "\\\"", deliverable)
                    gsub(/"/, "\\\"", deps)
                    printf "{\"uuid\":\"%s\",\"name\":\"%s\",\"status\":\"%s\",\"dependencies\":\"%s\",\"effort\":\"%s\",\"deliverable\":\"%s\"}\n", uuid, task_name, status, deps, effort, deliverable
                }
            }
        }
        in_table && /^[^|]/ {
            in_table = 0
        }
    ' "$projekt_file"
}

# Extract Known Issues section from PROJEKT.md
# Returns JSON array of issues with affected tasks
# Supports both bullet-list and table formats
extract_known_issues() {
    local projekt_file="$1"

    awk '
        BEGIN { in_issues = 0; in_table = 0 }

        # Start of Known Issues section
        /^##.*Known Issues|^##.*Blockers/ {
            in_issues = 1
            in_table = 0
            next
        }

        # End of section (new ## header, horizontal rule, or HTML tag)
        in_issues && /^##[^#]|^---|^</ {
            in_issues = 0
            in_table = 0
        }

        # Table header detection
        in_issues && /^\|.*Issue.*\|/ {
            in_table = 1
            next
        }

        # Skip table separator
        in_issues && in_table && /^\|---/ {
            next
        }

        # Parse table rows
        in_issues && in_table && /^\|/ {
            line = $0
            gsub(/\r/, "", line)
            gsub(/^\||\|$/, "", line)
            split(line, cols, "|")
            for (i in cols) gsub(/^ +| +$/, "", cols[i])

            # Extract description (usually column 2) and affected tasks
            desc = cols[2]
            gsub(/\*\*/, "", desc)

            # Look for TASK references in any column
            affected = ""
            for (i in cols) {
                temp = cols[i]
                while (match(temp, /TASK-[0-9]+/)) {
                    if (affected != "") affected = affected ","
                    affected = affected substr(temp, RSTART, RLENGTH)
                    temp = substr(temp, RSTART + RLENGTH)
                }
            }

            if (length(desc) > 0) {
                printf "{\"description\":\"%s\",\"affected_tasks\":\"%s\"}\n", desc, affected
            }
            next
        }

        # Parse bullet-list items (original format)
        in_issues && !in_table && /^-.*\*\*|^[0-9]+\./ {
            line = $0
            gsub(/\r/, "", line)

            # Extract issue description
            gsub(/^[-0-9.]+\s*\*\*/, "", line)
            gsub(/\*\*:?/, "", line)

            # Extract affected tasks
            affected = ""
            if (match(line, /Affects:.*TASK-[0-9]+/)) {
                affected = substr(line, RSTART)
                gsub(/Affects:\s*/, "", affected)
                gsub(/[^TASK0-9,\- ]/, "", affected)
            } else if (match(line, /TASK-[0-9]+/)) {
                temp = line
                while (match(temp, /TASK-[0-9]+/)) {
                    if (affected != "") affected = affected ","
                    affected = affected substr(temp, RSTART, RLENGTH)
                    temp = substr(temp, RSTART + RLENGTH)
                }
            }

            # Clean description
            gsub(/\(Affects:.*\)/, "", line)
            gsub(/^ +| +$/, "", line)

            if (length(line) > 0) {
                printf "{\"description\":\"%s\",\"affected_tasks\":\"%s\"}\n", line, affected
            }
        }
    ' "$projekt_file"
}

# Count how many tasks this task unblocks
# (tasks that have this task as a dependency)
count_unblocks() {
    local uuid="$1"
    local tasks_json="$2"

    echo "$tasks_json" | jq -r "
        [.[] | select(.status == \"pending\") |
         select(.dependencies | contains(\"$uuid\"))] | length
    "
}

# Count dependencies for a task
count_dependencies() {
    local deps="$1"

    if [ -z "$deps" ] || [ "$deps" = "None" ] || [ "$deps" = "[]" ]; then
        echo 0
        return
    fi

    # Count TASK-XXX occurrences
    echo "$deps" | grep -oE 'TASK-[0-9]+' | wc -l | tr -d ' '
}

# Check if task is affected by known issues
get_issue_impact() {
    local uuid="$1"
    local issues_json="$2"

    if [ -z "$issues_json" ] || [ "$issues_json" = "[]" ]; then
        echo 0
        return
    fi

    # Count how many issues affect this task
    local count=$(echo "$issues_json" | jq -r "
        [.[] | select(.affected_tasks | contains(\"$uuid\"))] | length
    " 2>/dev/null || echo 0)

    echo "$count"
}

# Calculate priority score for a task
# Formula: (1/effort)*3 + (1/(deps+1))*1 + (unblocks*0.5) - (issues*2)
calculate_priority_score() {
    local effort_hours="$1"
    local deps_count="$2"
    local unblocks_count="$3"
    local issue_impact="$4"

    # Use awk for floating point math
    awk -v effort="$effort_hours" \
        -v deps="$deps_count" \
        -v unblocks="$unblocks_count" \
        -v issues="$issue_impact" \
        -v w_effort="$EFFORT_WEIGHT" \
        -v w_deps="$DEPS_WEIGHT" \
        -v w_unblocks="$UNBLOCKS_WEIGHT" \
        -v w_issues="$ISSUES_WEIGHT" \
        'BEGIN {
            score = (1/effort) * w_effort
            score += (1/(deps+1)) * w_deps
            score += unblocks * w_unblocks
            score -= issues * w_issues
            printf "%.2f", score
        }'
}

# Get reason for priority score
get_score_reason() {
    local effort="$1"
    local deps="$2"
    local unblocks="$3"
    local issues="$4"
    local status="$5"

    local reasons=()

    # Status-basierte Reasons zuerst
    case "$status" in
        blocked)
            reasons+=("Blocked status")
            ;;
        cancelled)
            reasons+=("Cancelled")
            ;;
        completed)
            reasons+=("Already completed")
            ;;
    esac

    if [ "$effort" -le 2 ]; then
        reasons+=("Quick win (${effort}h)")
    elif [ "$effort" -ge 16 ]; then
        reasons+=("High effort (${effort}h)")
    fi

    if [ "$deps" -eq 0 ]; then
        reasons+=("No dependencies")
    elif [ "$deps" -ge 3 ]; then
        reasons+=("Many dependencies ($deps)")
    fi

    if [ "$unblocks" -ge 2 ]; then
        reasons+=("Unblocks $unblocks tasks")
    elif [ "$unblocks" -eq 1 ]; then
        reasons+=("Unblocks 1 task")
    fi

    if [ "$issues" -gt 0 ]; then
        reasons+=("Affected by $issues issue(s)")
    fi

    # Join reasons
    local IFS=", "
    echo "${reasons[*]:-Standard}"
}

# Identify critical path (tasks that unblock others)
identify_critical_path() {
    local scored_tasks="$1"

    # Critical path = Tasks with highest unblocks_count that are pending
    echo "$scored_tasks" | jq -r '
        [.[] | select(.status == "pending" or .status == "in_progress")] |
        sort_by(-.unblocks_count) |
        [.[] | select(.unblocks_count > 0)] |
        .[0:3] |
        .[] |
        "\(.uuid)|\(.name)|\(.unblocks_count)"
    '
}

# Generate markdown report
generate_report() {
    local scored_tasks="$1"
    local issues_json="$2"

    # Count pending tasks
    local pending_count=$(echo "$scored_tasks" | jq '[.[] | select(.status == "pending" or .status == "in_progress")] | length')
    local blocked_count=$(echo "$scored_tasks" | jq '[.[] | select(.status == "blocked")] | length')
    local completed_count=$(echo "$scored_tasks" | jq '[.[] | select(.status == "completed" or .status == "cancelled")] | length')

    echo ""
    echo "## Task-Priorität Analyse"
    echo ""
    echo "**Übersicht:** $pending_count ausstehend | $blocked_count blockiert | $completed_count abgeschlossen"
    echo ""

    # Critical Path Section
    echo "### 🔥 Kritischer Pfad"
    echo ""
    local critical_path=$(identify_critical_path "$scored_tasks")
    if [ -n "$critical_path" ]; then
        echo "Diese Tasks schalten andere frei und sollten priorisiert werden:"
        echo ""
        echo "$critical_path" | while IFS='|' read -r uuid name unblocks; do
            echo "- **$uuid** ($name) → schaltet **$unblocks Tasks** frei"
        done
        echo ""
    else
        echo "*Keine kritischen Pfad-Tasks identifiziert (keine Dependencies zwischen pending Tasks)*"
        echo ""
    fi

    # Recommended Order Section
    echo "### 🚀 Empfohlene Reihenfolge"
    echo ""
    echo "| Rang | Task | Score | Begründung |"
    echo "|------|------|-------|------------|"

    local rank=1
    echo "$scored_tasks" | jq -r '
        sort_by(-.score) |
        .[] |
        select(.status == "pending" or .status == "in_progress") |
        "\(.uuid)|\(.score)|\(.reason)"
    ' | while IFS='|' read -r uuid score reason; do
        local name=$(echo "$scored_tasks" | jq -r ".[] | select(.uuid == \"$uuid\") | .name")
        echo "| $rank | **$uuid** - $name | $score | $reason |"
        rank=$((rank + 1))
    done

    # Blocked by issues section
    local blocked_by_issues=$(echo "$scored_tasks" | jq -r '
        .[] |
        select(.issue_impact > 0) |
        "\(.uuid)|\(.name)"
    ')

    if [ -n "$blocked_by_issues" ]; then
        echo ""
        echo "### ⚠️ Beeinflusst durch Known Issues"
        echo ""
        echo "| Task | Known Issue | Empfehlung |"
        echo "|------|-------------|------------|"

        echo "$blocked_by_issues" | while IFS='|' read -r uuid name; do
            # Find which issue affects this task
            local issue_desc=$(echo "$issues_json" | jq -r ".[] | select(.affected_tasks | contains(\"$uuid\")) | .description" | head -1)
            echo "| $uuid - $name | $issue_desc | Review required |"
        done
    fi

    # Suggest new tasks from issues without task references
    local orphan_issues=$(echo "$issues_json" | jq -r '
        .[] | select(.affected_tasks == "" or .affected_tasks == null) | .description
    ' 2>/dev/null)

    if [ -n "$orphan_issues" ]; then
        echo ""
        echo "### 💡 Vorgeschlagene neue Tasks (aus Known Issues)"
        echo ""
        echo "$orphan_issues" | while read -r desc; do
            echo "- **Neuer Task vorgeschlagen:** $desc"
        done
    fi

    # Scoring details
    echo ""
    echo "### 📊 Scoring-Details"
    echo ""
    echo "| Task | Effort | Deps | Unblocks | Issues | Score |"
    echo "|------|--------|------|----------|--------|-------|"

    echo "$scored_tasks" | jq -r '
        sort_by(-.score) |
        .[] |
        "\(.uuid)|\(.effort_hours)h|\(.deps_count)|\(.unblocks_count)|\(.issue_impact)|\(.score)"
    ' | while IFS='|' read -r uuid effort deps unblocks issues score; do
        echo "| $uuid | $effort | $deps | $unblocks | $issues | $score |"
    done

    echo ""
    echo "---"
    echo ""

    # Explanation Section
    echo "### 💡 Strategie-Erläuterung"
    echo ""
    echo "**Priorisierungs-Logik:**"
    echo "1. **Quick Wins zuerst:** Kleine Tasks (≤2h) haben höhere Priorität"
    echo "2. **Kritischer Pfad:** Tasks die andere freischalten werden bevorzugt"
    echo "3. **Unabhängigkeit:** Tasks ohne Dependencies sind flexibler planbar"
    echo "4. **Known Issues:** Betroffene Tasks werden deprioritisiert (erst Blocker klären)"
    echo ""
    echo "*Scoring-Formel: (1/effort)×$EFFORT_WEIGHT + (1/(deps+1))×$DEPS_WEIGHT + (unblocks×$UNBLOCKS_WEIGHT) - (issues×$ISSUES_WEIGHT)*"
    echo ""

    # JSON Output for Claude (machine-readable)
    echo "### 📋 Sortierte Reihenfolge (für PROJEKT.md Update)"
    echo ""
    echo '```json'
    echo "$scored_tasks" | jq -c '
        sort_by(-.score) |
        {
            sorted_uuids: [.[] | select(.status == "pending" or .status == "in_progress") | .uuid],
            completed_uuids: [.[] | select(.status == "completed" or .status == "cancelled") | .uuid],
            blocked_uuids: [.[] | select(.status == "blocked") | .uuid]
        }
    '
    echo '```'
    echo ""
    echo "---"
    echo ""
    echo "**⚡ Nächster Schritt:** Soll die Task-Tabelle in PROJEKT.md entsprechend dieser Reihenfolge umsortiert werden?"
}

# Reorder task table in PROJEKT.md by priority score
reorder_projekt_md() {
    local projekt_file="$1"
    local scored_tasks="$2"

    log "Reordering task table in $projekt_file..."

    # Get sorted UUIDs
    local sorted_uuids=$(echo "$scored_tasks" | jq -r 'sort_by(-.score) | .[].uuid')

    # Create backup
    cp "$projekt_file" "${projekt_file}.backup-$(date +%Y-%m-%d)"

    # TODO: Implement actual reordering
    # This is complex because we need to preserve table formatting
    # For now, just output the suggested order

    log_warn "Automatisches Reordering noch nicht implementiert"
    log "Manuelle Reihenfolge basierend auf Scores:"
    echo "$sorted_uuids" | nl -w2 -s'. '
}

# Main orchestration logic
main() {
    # Find PROJEKT.md
    if [ "$PROJEKT_PATH" = "." ]; then
        if [ -f "./docs/PROJEKT.md" ]; then
            PROJEKT_PATH="./docs/PROJEKT.md"
        elif [ -f "./PROJEKT.md" ]; then
            PROJEKT_PATH="./PROJEKT.md"
        else
            log_error "PROJEKT.md not found"
            echo "Error: PROJEKT.md nicht gefunden"
            return 1
        fi
    fi

    # Initialize logging
    local PROJECT_ROOT="."
    if [ -d "./docs" ]; then
        PROJECT_ROOT="."
        LOG_DIR="$PROJECT_ROOT/docs/tasks/prioritize-logs"
        mkdir -p "$LOG_DIR" 2>/dev/null || true
        LOG_FILE="$LOG_DIR/prioritize-run-$(date +%Y-%m-%d-%H-%M-%S).log"
    fi

    log "Task Prioritization starting"
    log "Using PROJEKT: $PROJEKT_PATH"
    log "Scoring weights: Effort=$EFFORT_WEIGHT, Deps=$DEPS_WEIGHT, Unblocks=$UNBLOCKS_WEIGHT, Issues=$ISSUES_WEIGHT"

    # Extract tasks
    local tasks_json
    tasks_json=$(extract_task_table "$PROJEKT_PATH" | jq -s '.' 2>/dev/null || echo "[]")

    if [ "$tasks_json" = "[]" ]; then
        log_warn "No tasks found in PROJEKT.md"
        echo "Keine Tasks in PROJEKT.md gefunden"
        return 0
    fi

    local task_count=$(echo "$tasks_json" | jq 'length')
    log "Found $task_count tasks"

    # Extract known issues
    local issues_json
    issues_json=$(extract_known_issues "$PROJEKT_PATH" | jq -s '.' 2>/dev/null || echo "[]")

    local issue_count=$(echo "$issues_json" | jq 'length')
    log "Found $issue_count known issues"

    # Calculate scores for each task
    log "Calculating priority scores..."

    local scored_tasks="[]"

    while IFS= read -r task; do
        local uuid=$(echo "$task" | jq -r '.uuid')
        local name=$(echo "$task" | jq -r '.name')
        local status=$(echo "$task" | jq -r '.status')
        local deps=$(echo "$task" | jq -r '.dependencies')
        local effort=$(echo "$task" | jq -r '.effort')

        # Calculate factors
        local effort_hours=$(parse_effort_to_hours "$effort")
        local deps_count=$(count_dependencies "$deps")
        local unblocks_count=$(count_unblocks "$uuid" "$tasks_json")
        local issue_impact=$(get_issue_impact "$uuid" "$issues_json")

        # Calculate score based on status
        # Sortierung: pending/in_progress (nach Score) > blocked (0) > completed/cancelled (-1)
        local score
        case "$status" in
            completed|cancelled)
                score="-1.00"  # Abgeschlossene Tasks ans Ende
                ;;
            blocked)
                score="0.00"   # Blockierte Tasks niedrige Priorität
                ;;
            pending|in_progress)
                score=$(calculate_priority_score "$effort_hours" "$deps_count" "$unblocks_count" "$issue_impact")
                ;;
            *)
                # Unbekannter Status: niedrige Priorität
                score="0.50"
                log_warn "Unknown status '$status' for $uuid"
                ;;
        esac

        local reason=$(get_score_reason "$effort_hours" "$deps_count" "$unblocks_count" "$issue_impact" "$status")

        # Add scored task to array
        scored_tasks=$(echo "$scored_tasks" | jq \
            --arg uuid "$uuid" \
            --arg name "$name" \
            --arg status "$status" \
            --arg score "$score" \
            --arg reason "$reason" \
            --argjson effort_hours "$effort_hours" \
            --argjson deps_count "$deps_count" \
            --argjson unblocks_count "$unblocks_count" \
            --argjson issue_impact "$issue_impact" \
            '. + [{
                uuid: $uuid,
                name: $name,
                status: $status,
                score: ($score | tonumber),
                reason: $reason,
                effort_hours: $effort_hours,
                deps_count: $deps_count,
                unblocks_count: $unblocks_count,
                issue_impact: $issue_impact
            }]'
        )

        log "Scored $uuid: $score ($reason)"

    done < <(echo "$tasks_json" | jq -c '.[]')

    # Generate report
    generate_report "$scored_tasks" "$issues_json"

    # Optional: Reorder PROJEKT.md
    if [ "$REORDER_FLAG" = "--reorder" ]; then
        reorder_projekt_md "$PROJEKT_PATH" "$scored_tasks"
    fi

    # Log completion
    local duration=$((SECONDS - START_TIME))
    log "Task Prioritization completed in ${duration}s"
    if [ -n "$LOG_FILE" ]; then
        log "Log saved to: $LOG_FILE"
    fi
}

# Run main function
main "$@"
