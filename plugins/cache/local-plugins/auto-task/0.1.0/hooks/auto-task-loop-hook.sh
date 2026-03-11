#!/usr/bin/env bash
# auto-task-loop-hook.sh — Stop-Hook fuer autonomen Task-Execution-Loop
#
# Feuert bei JEDEM Stop-Event. Prueft ob ein auto-task State-File existiert,
# ob noch pending Actions vorhanden sind, und blockiert den Stop mit einem
# Re-Inject Prompt wenn ja.
#
# Pattern: ralph-loop (offizielles Anthropic Plugin)
# API: JSON auf stdout {"decision":"block","reason":"...","systemMessage":"..."}
# Exit 0 = immer (JSON steuert, nicht der Exit Code)

set -euo pipefail

# --- Resolve Script Directory + Plugin Root ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="${SCRIPT_DIR%/*}"

# --- Read Hook Input from stdin ---
HOOK_INPUT=$(cat)

# --- State-File Discovery ---
# State-File lebt in docs/tasks/TASK-NNN/auto-task.state
# Suche vom CWD aus (Claude Code setzt CWD auf Projekt-Root)
find_state_file() {
  local search_dir="docs/tasks"
  if [[ ! -d "$search_dir" ]]; then
    return 1
  fi
  # Einziger externer Aufruf: find (einmal, kein Loop)
  local found
  found=$(find "$search_dir" -name "auto-task.state" -type f 2>/dev/null | tr -d '\r')
  if [[ -z "$found" ]]; then
    return 1
  fi
  # Genau ein State-File erlaubt
  local count=0
  local result=""
  while IFS= read -r line; do
    line="${line%$'\r'}"
    count=$((count + 1))
    result="$line"
  done <<< "$found"
  if [[ $count -gt 1 ]]; then
    echo "auto-task: Multiple state files found ($count). Only one loop at a time." >&2
    return 1
  fi
  printf '%s' "$result"
}

STATE_FILE=$(find_state_file) || true

if [[ -z "$STATE_FILE" ]] || [[ ! -f "$STATE_FILE" ]]; then
  # Kein aktiver Loop — normales Session-Ende erlauben
  exit 0
fi

# --- Parse State-File (key=value Format) ---
parse_state() {
  local key="$1"
  local file="$2"
  local value=""
  while IFS= read -r line; do
    line="${line%$'\r'}"
    case "$line" in
      "${key}="*)
        value="${line#*=}"
        ;;
    esac
  done < "$file"
  printf '%s' "$value"
}

TASK_ID=$(parse_state "task_id" "$STATE_FILE")
TASK_FILE=$(parse_state "task_file" "$STATE_FILE")
ITERATION=$(parse_state "iteration" "$STATE_FILE")
MAX_ITERATIONS=$(parse_state "max_iterations" "$STATE_FILE")
SESSION_ID_STATE=$(parse_state "session_id" "$STATE_FILE")

# --- Session Isolation ---
# Verhindert, dass parallele Sessions den Loop stoeren
HOOK_SESSION=$(echo "$HOOK_INPUT" | jq -r '.session_id // ""' 2>/dev/null | tr -d '\r') || true
if [[ -n "$SESSION_ID_STATE" ]] && [[ -n "$HOOK_SESSION" ]] && [[ "$SESSION_ID_STATE" != "$HOOK_SESSION" ]]; then
  exit 0
fi

# --- Validate Numeric Fields ---
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  echo "auto-task: State file corrupted (iteration='$ITERATION'). Cleaning up." >&2
  rm -f "$STATE_FILE"
  exit 0
fi

if [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  echo "auto-task: State file corrupted (max_iterations='$MAX_ITERATIONS'). Cleaning up." >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# --- Max Iterations Check ---
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "auto-task: Max iterations ($MAX_ITERATIONS) reached for $TASK_ID. Loop beendet." >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# --- Task-File Existenz Check ---
if [[ ! -f "$TASK_FILE" ]]; then
  echo "auto-task: Task file not found: $TASK_FILE. Cleaning up." >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# --- Parse Next Action ---
PARSE_SCRIPT="${PLUGIN_ROOT}/scripts/parse-next-action.sh"

if [[ ! -f "$PARSE_SCRIPT" ]]; then
  echo "auto-task: parse-next-action.sh not found at $PARSE_SCRIPT. Cleaning up." >&2
  rm -f "$STATE_FILE"
  exit 0
fi

set +e
ACTION_JSON=$(bash "$PARSE_SCRIPT" "$TASK_FILE" 2>/dev/null)
PARSE_EXIT=$?
set -e

if [[ $PARSE_EXIT -eq 1 ]]; then
  # Alle Actions complete
  echo "auto-task: All actions complete for $TASK_ID. Loop beendet." >&2
  rm -f "$STATE_FILE"
  exit 0
fi

if [[ $PARSE_EXIT -ne 0 ]]; then
  # Parse-Error
  echo "auto-task: Parse error (exit $PARSE_EXIT) for $TASK_FILE. Cleaning up." >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# --- Extract Action Details ---
ACTION_NR=$(echo "$ACTION_JSON" | jq -r '.nr' 2>/dev/null | tr -d '\r') || true
ACTION_NAME=$(echo "$ACTION_JSON" | jq -r '.name' 2>/dev/null | tr -d '\r') || true
ACTION_TOTAL=$(echo "$ACTION_JSON" | jq -r '.total' 2>/dev/null | tr -d '\r') || true

if [[ -z "$ACTION_NR" ]] || [[ "$ACTION_NR" == "null" ]]; then
  echo "auto-task: Could not parse action from JSON. Cleaning up." >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# --- Increment Iteration ---
NEXT_ITERATION=$((ITERATION + 1))
TEMP_FILE="${STATE_FILE}.tmp.$$"
while IFS= read -r line; do
  line="${line%$'\r'}"
  case "$line" in
    iteration=*)
      printf 'iteration=%s\n' "$NEXT_ITERATION"
      ;;
    *)
      printf '%s\n' "$line"
      ;;
  esac
done < "$STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$STATE_FILE"

# --- Build Re-Inject Prompt ---
COMPACT_HINT=""
if [[ $NEXT_ITERATION -gt 5 ]]; then
  COMPACT_HINT=" Halte diese Action kompakt — Context-Budget wird knapp."
fi

REASON="AUTO-TASK LOOP: Lies das Task-File ${TASK_FILE} KOMPLETT NEU (kein Verlass auf Context nach Compaction). Fuehre jetzt Action #${ACTION_NR} aus: ${ACTION_NAME}. Fuehre NUR diese eine Action aus. Nach Abschluss: (1) Aktualisiere den Action-Status im Task-File auf 'complete', (2) Erstelle einen Git-Commit mit der Aenderung.${COMPACT_HINT}"

SYSTEM_MSG="Auto-Task Iteration ${NEXT_ITERATION}/${MAX_ITERATIONS} | Task: ${TASK_ID} | Action ${ACTION_NR}/${ACTION_TOTAL}: ${ACTION_NAME} | To cancel: /cancel-auto-task"

# --- Output JSON (Block Stop + Re-Inject) ---
# Nutze jq fuer sicheres JSON-Escaping (keine Shell-Interpolation in JSON-Strings)
jq -n \
  --arg reason "$REASON" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $reason,
    "systemMessage": $msg
  }'

exit 0
