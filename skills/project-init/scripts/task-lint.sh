#!/usr/bin/env bash
# task-lint.sh - Validates Task-Files against SSOT template
# SSOT: ${CLAUDE_PLUGIN_ROOT}/skills/project-init/assets/task-md-template.txt
# Location: ${CLAUDE_PLUGIN_ROOT}/skills/project-init/scripts/task-lint.sh (GLOBAL)
#
# Supports TWO metadata formats:
#   1. YAML frontmatter (new): ---\nuuid: TASK-NNN\nstatus: pending\ntags: [infrastructure]\n---
#   2. Bold-inline (legacy): **UUID:** TASK-NNN\n**Status:** pending
#
# Usage:
#   task-lint.sh docs/tasks/TASK-057-name.md   # single file
#   task-lint.sh --all                          # all TASK-*.md in docs/tasks/
#   task-lint.sh --staged                       # git staged only (for pre-commit)
#
# Exit codes: 0 = all valid, 1 = validation errors found
#
# MINGW/Git-Bash compatible: no grep -P, no readarray, no [[ ]] in critical paths

set -euo pipefail

# --- Valid status values (SSOT: task-scheduler/SKILL.md) ---
VALID_STATUSES="pending in_progress ongoing completed blocked cancelled"

# --- Required metablock fields (lowercase, used for both formats) ---
REQUIRED_FIELDS_LC="uuid status created updated effort dependencies"

# --- Colors (if terminal supports it) ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

errors=0
warnings=0
files_checked=0
files_failed=0

error() {
  printf "${RED}ERROR${NC} [%s]: %s\n" "$1" "$2" >&2
  errors=$((errors + 1))
}

warn() {
  printf "${YELLOW}WARN${NC}  [%s]: %s\n" "$1" "$2" >&2
  warnings=$((warnings + 1))
}

pass() {
  printf "${GREEN}OK${NC}    %s\n" "$1"
}

# --- Detect metadata format: "frontmatter" or "legacy" ---
detect_format() {
  local file="$1"
  local first_line
  first_line="$(head -1 "$file" | tr -d '\r')"
  if [ "$first_line" = "---" ]; then
    echo "frontmatter"
  else
    echo "legacy"
  fi
}

# --- Extract field value from YAML frontmatter ---
# Usage: get_frontmatter_field FILE FIELDNAME
get_frontmatter_field() {
  local file="$1"
  local field="$2"
  local in_fm=0
  local line_count=0
  while IFS= read -r line && [ "$line_count" -lt 30 ]; do
    line="${line%$'\r'}"
    line_count=$((line_count + 1))
    if [ "$line_count" -eq 1 ] && [ "$line" = "---" ]; then
      in_fm=1
      continue
    fi
    if [ "$in_fm" -eq 1 ]; then
      if [ "$line" = "---" ]; then
        break
      fi
      # Match field: value (case-insensitive key)
      case "$(echo "$line" | tr '[:upper:]' '[:lower:]')" in
        "${field}:"*)
          echo "$line" | sed "s/^[^:]*:[[:space:]]*//"
          return
          ;;
      esac
    fi
  done < "$file"
}

# --- Validate a single task file ---
validate_file() {
  local file="$1"
  local file_errors=0
  local basename
  basename="$(basename "$file")"

  # Skip non-TASK files
  case "$basename" in
    TASK-[0-9]*-*.md) ;;
    *)
      warn "$basename" "Filename does not match TASK-NNN-name.md pattern, skipping"
      return 0
      ;;
  esac

  files_checked=$((files_checked + 1))

  local format
  format="$(detect_format "$file")"

  if [ "$format" = "frontmatter" ]; then
    # --- YAML frontmatter validation ---
    for field in $REQUIRED_FIELDS_LC; do
      local value
      value="$(get_frontmatter_field "$file" "$field")"
      if [ -z "$value" ]; then
        error "$basename" "Missing frontmatter field: $field"
        file_errors=$((file_errors + 1))
      fi
    done

    # UUID format check
    local uuid_val
    uuid_val="$(get_frontmatter_field "$file" "uuid" | tr -d '[:space:]')"
    if [ -n "$uuid_val" ]; then
      case "$uuid_val" in
        TASK-[0-9]*) ;;
        *)
          error "$basename" "UUID format invalid: '$uuid_val' (expected TASK-NNN)"
          file_errors=$((file_errors + 1))
          ;;
      esac
    fi

    # Status validation
    local status_val
    status_val="$(get_frontmatter_field "$file" "status")"
    if [ -n "$status_val" ]; then
      local status_valid=false
      for valid in $VALID_STATUSES; do
        if echo "$status_val" | grep -qi "$valid"; then
          status_valid=true
          break
        fi
      done
      if [ "$status_valid" = "false" ]; then
        error "$basename" "Invalid status: '$status_val'"
        printf "  Valid: %s\n" "$VALID_STATUSES" >&2
        file_errors=$((file_errors + 1))
      fi
    fi

    # Tags soft warning (not an error — does not block commit)
    # Supports both inline (`tags: [a, b]`) and multi-line YAML list (`tags:\n  - a\n  - b`)
    local tags_val has_list_items
    tags_val="$(get_frontmatter_field "$file" "tags")"
    # Detect multi-line list: a line "tags:" followed by one or more "  - item" lines within frontmatter
    has_list_items="$(awk '
      /^---$/ { fm = !fm; next }
      fm && /^tags:[[:space:]]*$/ { in_tags = 1; next }
      fm && in_tags && /^[[:space:]]+-[[:space:]]+/ { print "yes"; exit }
      fm && in_tags && /^[^[:space:]-]/ { in_tags = 0 }
    ' "$file")"
    if { [ -z "$tags_val" ] || [ "$tags_val" = "[]" ]; } && [ -z "$has_list_items" ]; then
      warn "$basename" "No tags set (consider: infrastructure, feature, bugfix, documentation, refactor, security, spike)"
    fi

  else
    # --- Legacy bold-inline validation ---
    for field in UUID Status Created Updated Effort Dependencies; do
      if ! grep -qF "**${field}:**" "$file"; then
        error "$basename" "Missing metablock field: **${field}:**"
        file_errors=$((file_errors + 1))
      fi
    done

    # UUID format check
    local uuid_line
    uuid_line="$(grep -F '**UUID:**' "$file" | sed 's/.*\*\*UUID:\*\*[[:space:]]*//' | tr -d '[:space:]' || true)"
    if [ -n "$uuid_line" ]; then
      case "$uuid_line" in
        TASK-[0-9]*) ;;
        *)
          error "$basename" "UUID format invalid: '$uuid_line' (expected TASK-NNN)"
          file_errors=$((file_errors + 1))
          ;;
      esac
    fi

    # Status validation
    local status_line
    status_line="$(grep -F '**Status:**' "$file" | sed 's/.*\*\*Status:\*\*[[:space:]]*//' || true)"
    if [ -n "$status_line" ]; then
      local status_valid=false
      for valid in $VALID_STATUSES; do
        if echo "$status_line" | grep -qi "$valid"; then
          status_valid=true
          break
        fi
      done
      if [ "$status_valid" = "false" ]; then
        error "$basename" "Invalid status: '$status_line'"
        printf "  Valid: %s\n" "$VALID_STATUSES" >&2
        file_errors=$((file_errors + 1))
      fi
    fi
  fi

  # --- Required sections (same for both formats) ---
  for section in Objective "Audit Trail" "Acceptance Criteria"; do
    if ! grep -qF "## $section" "$file"; then
      error "$basename" "Missing required section: '## $section'"
      file_errors=$((file_errors + 1))
    fi
  done

  if [ "$file_errors" -gt 0 ]; then
    files_failed=$((files_failed + 1))
  else
    pass "$basename [$format]"
  fi
}

# --- Resolve file list ---
files=""
file_count=0

# Auto-detect docs path: try docs/tasks/ then 90_DOCS/tasks/
TASK_DIR=""
for candidate in docs/tasks 90_DOCS/tasks; do
  if [ -d "$candidate" ]; then
    TASK_DIR="$candidate"
    break
  fi
done

if [ "${1:-}" = "--all" ]; then
  if [ -z "$TASK_DIR" ]; then
    echo "No task directory found (tried docs/tasks/, 90_DOCS/tasks/)" >&2
    exit 0
  fi
  for f in "$TASK_DIR"/TASK-*.md; do
    [ -f "$f" ] || continue
    files="$files
$f"
    file_count=$((file_count + 1))
  done

  if [ "$file_count" -eq 0 ]; then
    echo "No TASK-*.md files found in $TASK_DIR/" >&2
    exit 0
  fi

elif [ "${1:-}" = "--staged" ]; then
  staged="$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep -E 'TASK-[0-9]+-.*\.md$' || true)"
  if [ -z "$staged" ]; then
    exit 0  # No staged task files = nothing to validate
  fi
  files="$staged"
  file_count="$(echo "$staged" | wc -l)"

elif [ $# -gt 0 ]; then
  for arg in "$@"; do
    if [ -f "$arg" ]; then
      files="$files
$arg"
      file_count=$((file_count + 1))
    else
      echo "File not found: $arg" >&2
      exit 1
    fi
  done
else
  echo "Usage: task-lint.sh [--all | --staged | FILE...]" >&2
  exit 1
fi

# --- Write file list to temp file to avoid subshell counter loss ---
tmpfile="$(mktemp)"
trap 'rm -f "$tmpfile"' EXIT
echo "$files" > "$tmpfile"

# --- Run validation ---
echo "task-lint: Validating $file_count file(s)..."
echo "---"

while IFS= read -r file; do
  [ -z "$file" ] && continue
  validate_file "$file"
done < "$tmpfile"

echo "---"
printf "Checked: %d | Passed: %d | Failed: %d | Errors: %d | Warnings: %d\n" \
  "$files_checked" "$((files_checked - files_failed))" "$files_failed" "$errors" "$warnings"

if [ "$errors" -gt 0 ]; then
  printf "${RED}Validation failed.${NC} Fix errors above before committing.\n" >&2
  exit 1
fi

printf "${GREEN}All task files valid.${NC}\n"
exit 0
