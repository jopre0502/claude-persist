#!/bin/bash
# projekt-health-check.sh - Token-efficient PROJEKT.md health analysis
# Part of session-refresh skill
#
# Usage: projekt-health-check.sh <PROJEKT.md-path> [tasks-dir]
#
# Output: Compact Markdown health report on stdout
# Exit codes: 0 = healthy, 1 = warnings, 2 = critical issues, 3 = error

set -uo pipefail
# Note: -e disabled because grep/head return exit 1 on no matches, which is expected behavior

# ============================================================================
# Configuration
# ============================================================================

PROJEKT_FILE="${1:-}"
TASKS_DIR="${2:-}"

# Counters
TOTAL_TASKS=0
MISSING_FILES=()
STATUS_MISMATCHES=()
BROKEN_DEPS=()
READY_TASKS=()

# ============================================================================
# Helpers
# ============================================================================

die() {
    echo "ERROR: $1" >&2
    exit 3
}

log_debug() {
    # Uncomment for debugging: echo "[DEBUG] $1" >&2
    :
}

# Trim leading/trailing whitespace - pure bash, zero subprocesses
# Usage: trim VAR_NAME (modifies variable in-place via indirect expansion)
# Compatible with Bash 3.2+ (no nameref/local -n required)
trim() {
    local _val="${!1}"
    _val="${_val#"${_val%%[![:space:]]*}"}"
    _val="${_val%"${_val##*[![:space:]]}"}"
    eval "$1=\$_val"
}

# Normalize status emoji to canonical form
# Sets REPLY variable instead of echo (avoids subshell)
normalize_status() {
    local status="$1"
    case "$status" in
        *completed*|*✅*) REPLY="completed" ;;
        *in_progress*|*⏳*) REPLY="in_progress" ;;
        *pending*|*📋*) REPLY="pending" ;;
        *blocked*|*🚫*) REPLY="blocked" ;;
        *ongoing*|*📘*) REPLY="ongoing" ;;
        *) REPLY="unknown" ;;
    esac
}

# Extract status from task file header - pure bash, zero subprocesses
# Sets REPLY variable instead of echo (avoids subshell)
# Supports: YAML frontmatter (---\nstatus: ...\n---) and legacy bold-inline (**Status:** ...)
get_task_file_status() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        REPLY="missing"
        return
    fi
    local line_count=0
    local status_line=""
    local in_frontmatter=0
    while IFS= read -r fline && (( line_count++ < 20 )); do
        fline="${fline%$'\r'}"
        # YAML frontmatter detection
        if (( line_count == 1 )) && [[ "$fline" == "---" ]]; then
            in_frontmatter=1
            continue
        fi
        if (( in_frontmatter == 1 )); then
            if [[ "$fline" == "---" ]]; then
                break
            fi
            if [[ "${fline,,}" == status:* ]]; then
                status_line="$fline"
                break
            fi
            continue
        fi
        # Legacy bold-inline format
        if [[ "$fline" == \*\*Status:\*\** ]]; then
            status_line="$fline"
            break
        elif [[ -z "$status_line" && "${fline,,}" == status:* ]]; then
            status_line="$fline"
            break
        fi
    done < "$file"
    if [[ -n "$status_line" ]]; then
        normalize_status "$status_line"
    else
        REPLY="unknown"
    fi
}

# ============================================================================
# Input Validation
# ============================================================================

if [[ -z "$PROJEKT_FILE" ]]; then
    die "Usage: projekt-health-check.sh <PROJEKT.md-path> [tasks-dir]"
fi

if [[ ! -f "$PROJEKT_FILE" ]]; then
    die "PROJEKT.md not found: $PROJEKT_FILE"
fi

# Compute PROJEKT_DIR once (pure bash, no dirname subprocess)
PROJEKT_DIR="${PROJEKT_FILE%/*}"

# Auto-detect tasks directory if not provided
if [[ -z "$TASKS_DIR" ]]; then
    if [[ -d "$PROJEKT_DIR/tasks" ]]; then
        TASKS_DIR="$PROJEKT_DIR/tasks"
    elif [[ -d "${PROJEKT_DIR%/*}/docs/tasks" ]]; then
        TASKS_DIR="${PROJEKT_DIR%/*}/docs/tasks"
    else
        TASKS_DIR="$PROJEKT_DIR/tasks"  # Default, will report missing
    fi
fi

log_debug "PROJEKT_FILE: $PROJEKT_FILE"
log_debug "TASKS_DIR: $TASKS_DIR"

# ============================================================================
# Parse Task Table
# ============================================================================

# Extract all task rows from markdown tables
# Format: | UUID | Task | Status | Dependencies | Effort | Deliverable | Task-File |

declare -A TASK_STATUS
declare -A TASK_DEPS
declare -A TASK_FILES

while IFS= read -r line; do
    # Skip header/separator lines
    [[ "$line" =~ ^[[:space:]]*\|[[:space:]]*[-]+[[:space:]]*\| ]] && continue
    [[ "$line" =~ ^[[:space:]]*\|[[:space:]]*UUID ]] && continue

    # Parse task row: | TASK-XXX | Name | Status | Deps | Effort | Deliverable | File |
    # Must start with | to avoid matching TASK refs in prose text
    if [[ "$line" =~ ^[[:space:]]*\| ]] && [[ "$line" =~ \|[[:space:]]*\*?\*?(TASK-[0-9]+)\*?\*?[[:space:]]*\| ]]; then
        uuid="${BASH_REMATCH[1]}"

        # Extract fields using awk (more robust than bash regex for multiple fields)
        IFS='|' read -ra fields <<< "$line"

        if [[ ${#fields[@]} -ge 8 ]]; then
            # Field indices: 0=empty, 1=UUID, 2=Task, 3=Status, 4=Deps, 5=Effort, 6=Deliverable, 7=File
            status="${fields[3]}"
            trim status
            deps="${fields[4]}"
            trim deps
            task_file="${fields[7]:-}"
            trim task_file
            # Extract URL from [text](url) markdown link pattern
            _md_link_re='\[.*\]\(([^)]*)\)'
            if [[ "$task_file" =~ $_md_link_re ]]; then
                task_file="${BASH_REMATCH[1]}"
            fi

            normalize_status "$status"
            TASK_STATUS["$uuid"]="$REPLY"
            TASK_DEPS["$uuid"]="$deps"
            TASK_FILES["$uuid"]="$task_file"
            ((TOTAL_TASKS++))

            log_debug "Parsed: $uuid | Status: ${TASK_STATUS[$uuid]} | Deps: $deps | File: $task_file"
        fi
    fi
done < "$PROJEKT_FILE"

if [[ $TOTAL_TASKS -eq 0 ]]; then
    die "No tasks found in $PROJEKT_FILE (expected 7-column table format)"
fi

# ============================================================================
# Check 1: File Existence
# ============================================================================

for uuid in "${!TASK_FILES[@]}"; do
    task_file="${TASK_FILES[$uuid]}"

    # Handle relative paths (pure bash — no dirname/basename subprocesses)
    if [[ "$task_file" == tasks/* ]]; then
        full_path="$PROJEKT_DIR/$task_file"
    elif [[ "$task_file" == /* ]]; then
        full_path="$task_file"
    else
        full_path="$TASKS_DIR/${task_file##*/}"
    fi

    # Also try direct path under TASKS_DIR
    if [[ ! -f "$full_path" ]]; then
        alt_path="$TASKS_DIR/${task_file##*/}"
        if [[ -f "$alt_path" ]]; then
            full_path="$alt_path"
        fi
    fi

    if [[ "$task_file" == "—" || "$task_file" == "-" ]]; then
        log_debug "SKIP file check: $uuid has no task file (intentional)"
    elif [[ ! -f "$full_path" ]]; then
        MISSING_FILES+=("$uuid → $task_file")
        log_debug "MISSING: $uuid → $full_path"
    else
        # Store resolved path for status check
        TASK_FILES["$uuid"]="$full_path"
    fi
done

# ============================================================================
# Check 2: Status Consistency
# ============================================================================

for uuid in "${!TASK_STATUS[@]}"; do
    projekt_status="${TASK_STATUS[$uuid]}"
    task_file="${TASK_FILES[$uuid]}"

    # Skip if file is missing (already reported)
    [[ ! -f "$task_file" ]] && continue

    get_task_file_status "$task_file"
    file_status="$REPLY"

    if [[ "$file_status" != "unknown" && "$projekt_status" != "$file_status" ]]; then
        STATUS_MISMATCHES+=("$uuid: PROJEKT=$projekt_status, File=$file_status")
        log_debug "MISMATCH: $uuid PROJEKT=$projekt_status FILE=$file_status"
    fi
done

# ============================================================================
# Check 3: Dependency Validation
# ============================================================================

# Build list of all known task UUIDs
declare -A KNOWN_TASKS
for uuid in "${!TASK_STATUS[@]}"; do
    KNOWN_TASKS["$uuid"]=1
done

for uuid in "${!TASK_DEPS[@]}"; do
    deps="${TASK_DEPS[$uuid]}"

    # Skip empty or "None" dependencies
    [[ -z "$deps" || "$deps" == "None" || "$deps" == "-" ]] && continue

    # Parse comma-separated dependencies
    IFS=',' read -ra dep_list <<< "$deps"
    for dep in "${dep_list[@]}"; do
        trim dep

        # Extract TASK-XXX pattern
        if [[ "$dep" =~ (TASK-[0-9]+) ]]; then
            dep_uuid="${BASH_REMATCH[1]}"

            # Check if dependency exists (or was archived)
            if [[ -z "${KNOWN_TASKS[$dep_uuid]:-}" ]]; then
                # Archived task - treat as completed for dependency resolution
                TASK_STATUS["$dep_uuid"]="completed"
                KNOWN_TASKS["$dep_uuid"]=1
                log_debug "Archived dep: $dep_uuid (not in PROJEKT.md, assumed completed)"
            fi
        fi
    done
done

# ============================================================================
# Identify Ready Tasks
# ============================================================================

for uuid in "${!TASK_STATUS[@]}"; do
    status="${TASK_STATUS[$uuid]}"

    # Only pending tasks can be "ready"
    [[ "$status" != "pending" ]] && continue

    deps="${TASK_DEPS[$uuid]}"
    is_ready=true

    # Check if all dependencies are completed
    if [[ -n "$deps" && "$deps" != "None" && "$deps" != "-" ]]; then
        IFS=',' read -ra dep_list <<< "$deps"
        for dep in "${dep_list[@]}"; do
            trim dep
            if [[ "$dep" =~ (TASK-[0-9]+) ]]; then
                dep_uuid="${BASH_REMATCH[1]}"
                dep_status="${TASK_STATUS[$dep_uuid]:-unknown}"
                if [[ "$dep_status" != "completed" ]]; then
                    is_ready=false
                    break
                fi
            fi
        done
    fi

    if $is_ready; then
        READY_TASKS+=("$uuid")
    fi
done

# ============================================================================
# Check 4: NEEDS_RESTRUCTURE Flag
# ============================================================================

NEEDS_RESTRUCTURE=false
RESTRUCTURE_REASONS=()

# Criterion 1: File size > 10K chars (pure bash, no wc subprocess)
PROJEKT_CONTENT=$(<"$PROJEKT_FILE")
PROJEKT_SIZE=${#PROJEKT_CONTENT}
unset PROJEKT_CONTENT
if [[ "$PROJEKT_SIZE" -gt 10000 ]]; then
    NEEDS_RESTRUCTURE=true
    RESTRUCTURE_REASONS+=("File size ${PROJEKT_SIZE} chars (>10K)")
fi

# Criterion 2: Many active tasks (>5 non-completed/cancelled)
ACTIVE_TASKS=0
for uuid in "${!TASK_STATUS[@]}"; do
    status="${TASK_STATUS[$uuid]}"
    if [[ "$status" != "completed" && "$status" != "unknown" ]]; then
        ((ACTIVE_TASKS++))
    fi
done
if [[ "$ACTIVE_TASKS" -gt 5 ]]; then
    NEEDS_RESTRUCTURE=true
    RESTRUCTURE_REASONS+=("$ACTIVE_TASKS active tasks (>5)")
fi

# Criterion 3: Critical issues detected
# (will be set after CRITICAL_COUNT is calculated below)

# ============================================================================
# Generate Report
# ============================================================================

# Count issues
CRITICAL_COUNT=$((${#MISSING_FILES[@]} + ${#BROKEN_DEPS[@]}))
WARNING_COUNT=${#STATUS_MISMATCHES[@]}

# Criterion 3 (deferred): Critical issues
if [[ $CRITICAL_COUNT -gt 0 ]]; then
    NEEDS_RESTRUCTURE=true
    RESTRUCTURE_REASONS+=("$CRITICAL_COUNT critical issues")
fi

echo "## PROJEKT Health-Check"
echo ""
echo "📊 **Summary:** $TOTAL_TASKS Tasks | $CRITICAL_COUNT Critical | $WARNING_COUNT Warnings"
echo ""

# Critical Issues
if [[ $CRITICAL_COUNT -gt 0 ]]; then
    echo "### 🔴 Critical Issues"
    for issue in "${MISSING_FILES[@]}"; do
        echo "- File missing: $issue"
    done
    for issue in "${BROKEN_DEPS[@]}"; do
        echo "- Broken dependency: $issue"
    done
    echo ""
fi

# Warnings
if [[ $WARNING_COUNT -gt 0 ]]; then
    echo "### 🟡 Warnings"
    for issue in "${STATUS_MISMATCHES[@]}"; do
        echo "- Status mismatch: $issue"
    done
    echo ""
fi

# Ready Tasks
if [[ ${#READY_TASKS[@]} -gt 0 ]]; then
    echo "### ✅ Ready Tasks"
    echo "${READY_TASKS[*]}"
    echo ""
fi

# All clear
if [[ $CRITICAL_COUNT -eq 0 && $WARNING_COUNT -eq 0 ]]; then
    echo "### ✅ All Checks Passed"
    echo "No issues detected."
    echo ""
fi

# NEEDS_RESTRUCTURE flag
echo "### NEEDS_RESTRUCTURE"
if $NEEDS_RESTRUCTURE; then
    echo "NEEDS_RESTRUCTURE=true"
    for reason in "${RESTRUCTURE_REASONS[@]}"; do
        echo "- $reason"
    done
else
    echo "NEEDS_RESTRUCTURE=false"
fi
echo ""

echo "---"
_now=$(date '+%Y-%m-%d %H:%M:%S')
echo "*Generated: $_now*"

# ============================================================================
# Exit Code
# ============================================================================

if [[ $CRITICAL_COUNT -gt 0 ]]; then
    exit 2
elif [[ $WARNING_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
