#!/bin/bash
# session-handoff-loader.sh — Injects latest session handoff as additionalContext
# Part of TASK-036: Session-Start Handoff-Injection
#
# Searches $PWD/docs/handoffs/ for the newest SESSION-HANDOFF-*.md
# and injects its content (truncated to 2000 chars) into the session.
# Optionally runs projekt-health-check.sh for a compact status line.
#
# Hook type: SessionStart
# Output: JSON with hookSpecificOutput.additionalContext
# Exit: Always 0 (non-blocking)

set -uo pipefail

# ============================================================================
# Configuration
# ============================================================================

# Auto-detect docs path: 90_DOCS (new default) or docs (legacy)
if [[ -d "$PWD/90_DOCS/handoffs" ]]; then
  DOCS_PATH="90_DOCS"
elif [[ -d "$PWD/docs/handoffs" ]]; then
  DOCS_PATH="docs"
else
  DOCS_PATH="docs"
fi
HANDOFF_DIR="$PWD/$DOCS_PATH/handoffs"
PROJEKT_FILE="$PWD/$DOCS_PATH/PROJEKT.md"
HEALTH_CHECK="$HOME/.claude/skills/session-refresh/bin/projekt-health-check.sh"
MAX_CHARS=2000

# ============================================================================
# Silent skip: Not a session-continuous project
# ============================================================================

if [[ ! -d "$HANDOFF_DIR" ]]; then
  # No handoffs directory - not a session-continuous project, skip silently
  exit 0
fi

# ============================================================================
# Find newest handoff
# ============================================================================

NEWEST_HANDOFF=""
# Use ls -t for modification-time sort, take first match
for f in $(ls -t "$HANDOFF_DIR"/SESSION-HANDOFF-*.md 2>/dev/null); do
  if [[ -f "$f" ]]; then
    NEWEST_HANDOFF="$f"
    break
  fi
done

if [[ -z "$NEWEST_HANDOFF" ]]; then
  # Handoff dir exists but no handoffs found
  echo "{\"systemMessage\":\"SessionStart:handoff-loader: Kein Handoff gefunden in ${DOCS_PATH}/handoffs/ - manuell orientieren (CLAUDE.md + PROJEKT.md lesen)\"}"
  exit 0
fi

# ============================================================================
# Read and truncate handoff content
# ============================================================================

HANDOFF_CONTENT=$(cat "$NEWEST_HANDOFF")
HANDOFF_BASENAME=$(basename "$NEWEST_HANDOFF")

# Truncate if necessary
if [[ ${#HANDOFF_CONTENT} -gt $MAX_CHARS ]]; then
  HANDOFF_CONTENT="${HANDOFF_CONTENT:0:$MAX_CHARS}

[... truncated at ${MAX_CHARS} chars]"
fi

# ============================================================================
# Optional: Health-Check compact status
# ============================================================================

HEALTH_LINE=""
if [[ -f "$PROJEKT_FILE" && -x "$HEALTH_CHECK" ]]; then
  # Run health-check, capture summary line only (first non-empty content line)
  HEALTH_OUTPUT=$("$HEALTH_CHECK" "$PROJEKT_FILE" 2>/dev/null || true)

  # Extract summary line and NEEDS_RESTRUCTURE
  SUMMARY_LINE=$(echo "$HEALTH_OUTPUT" | grep '^\*\*Summary:\*\*\|^📊' | head -1)
  NEEDS_RESTRUCTURE=$(echo "$HEALTH_OUTPUT" | grep '^NEEDS_RESTRUCTURE=' | head -1)
  READY_LINE=$(echo "$HEALTH_OUTPUT" | grep -A1 '### ✅ Ready Tasks' | tail -1)

  if [[ -n "$SUMMARY_LINE" ]]; then
    HEALTH_LINE="

Health: ${SUMMARY_LINE} | ${NEEDS_RESTRUCTURE:-unknown}
Ready Tasks: ${READY_LINE:-none detected}"
  fi
fi

# ============================================================================
# Optional: SETUP-REFERENCE.md Staleness-Check
# ============================================================================

STALENESS_LINE=""
SETUP_REF="$HOME/.claude/skills/setup-reference/references/SETUP-REFERENCE.md"
if [[ -f "$SETUP_REF" ]]; then
  # Extract timestamp from first line: "# SETUP-REFERENCE — Auto-generated: YYYY-MM-DD HH:MM"
  REF_DATE=$(head -1 "$SETUP_REF" | grep -oP '\d{4}-\d{2}-\d{2}' || true)
  if [[ -n "$REF_DATE" ]]; then
    # Portable date: macOS (BSD) uses -jf, GNU (Linux/Git Bash) uses -d
    if [[ "$(uname -s)" == "Darwin" ]]; then
      REF_EPOCH=$(date -jf "%Y-%m-%d" "$REF_DATE" +%s 2>/dev/null || echo 0)
    else
      REF_EPOCH=$(date -d "$REF_DATE" +%s 2>/dev/null || echo 0)
    fi
    NOW_EPOCH=$(date +%s)
    DAYS_OLD=$(( (NOW_EPOCH - REF_EPOCH) / 86400 ))
    if [[ $DAYS_OLD -gt 7 ]]; then
      STALENESS_LINE="
SETUP-REFERENCE.md ist ${DAYS_OLD} Tage alt. Empfehlung: /refresh-reference ausfuehren."
    fi
  fi
fi

# ============================================================================
# Build additionalContext
# ============================================================================

CONTEXT="Session-Handoff geladen (${HANDOFF_BASENAME}):
---
${HANDOFF_CONTENT}${HEALTH_LINE}${STALENESS_LINE}
---
Hinweis: CLAUDE.md + PROJEKT.md nur bei Bedarf lesen (Handoff enthaelt Kontext der letzten Session)."

# ============================================================================
# Output JSON (use jq for safe escaping)
# ============================================================================

if command -v jq &>/dev/null; then
  # Safe: jq handles all JSON escaping
  jq -n --arg ctx "$CONTEXT" '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: $ctx
    }
  }'
else
  # Fallback: python for JSON escaping
  python3 -c "
import json, sys
ctx = sys.stdin.read()
print(json.dumps({
    'hookSpecificOutput': {
        'hookEventName': 'SessionStart',
        'additionalContext': ctx
    }
}))
" <<< "$CONTEXT"
fi

exit 0
