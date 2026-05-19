#!/bin/bash
# session-handoff-loader.sh — Injects latest session handoff as additionalContext
# Part of TASK-036: Session-Start Handoff-Injection
# Updated TASK-086: Akkumulierende Handoffs (SESSION-HANDOFF-YYYY-MM-DD-SNNN.md)
#
# Finds newest SESSION-HANDOFF-*.md file in handoffs directory.
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
HEALTH_CHECK="${CLAUDE_PLUGIN_ROOT}/skills/session-refresh/bin/projekt-health-check.sh"
MAX_CHARS=2000

# ============================================================================
# Silent skip: Not a session-continuous project
# ============================================================================

if [[ ! -d "$HANDOFF_DIR" ]]; then
  # No handoffs directory - not a session-continuous project, skip silently
  exit 0
fi

# ============================================================================
# Find newest SESSION-HANDOFF-*.md (akkumulierendes Pattern)
# ============================================================================

# Use ls -t to find newest file matching the pattern (no subprocesses in loop)
LATEST_HANDOFF=""
HANDOFF_BASENAME=""

# Try akkumulating pattern first, fall back to LATEST-HANDOFF.md for migration
for f in "$HANDOFF_DIR"/SESSION-HANDOFF-*.md; do
  if [[ -f "$f" ]]; then
    # At least one match exists — use ls -t to find newest
    LATEST_HANDOFF=$(ls -t "$HANDOFF_DIR"/SESSION-HANDOFF-*.md 2>/dev/null | head -1)
    HANDOFF_BASENAME="${LATEST_HANDOFF##*/}"
    break
  fi
done

# Fallback: Legacy LATEST-HANDOFF.md (migration period)
if [[ -z "$LATEST_HANDOFF" && -f "$HANDOFF_DIR/LATEST-HANDOFF.md" ]]; then
  LATEST_HANDOFF="$HANDOFF_DIR/LATEST-HANDOFF.md"
  HANDOFF_BASENAME="LATEST-HANDOFF.md"
fi

if [[ -z "$LATEST_HANDOFF" ]]; then
  # No handoff yet — first session or handoffs not migrated
  echo "{\"systemMessage\":\"SessionStart:handoff-loader: Kein Handoff in ${DOCS_PATH}/handoffs/ - manuell orientieren (CLAUDE.md + PROJEKT.md lesen)\"}"
  exit 0
fi

# ============================================================================
# Read and truncate handoff content
# ============================================================================

HANDOFF_CONTENT=$(<"$LATEST_HANDOFF")

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
# Optional: HOW-TO Staleness-Check (from CLAUDE.md tracking line)
# ============================================================================

HOWTO_STALENESS=""
CLAUDE_MD="$PWD/CLAUDE.md"
if [[ -f "$CLAUDE_MD" ]]; then
  # Look for: **HOW-TO zuletzt aktualisiert:** YYYY-MM-DD
  HOWTO_DATE=$(grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' <<< "$(grep 'HOW-TO zuletzt aktualisiert' "$CLAUDE_MD" 2>/dev/null)" 2>/dev/null | head -1)
  HOWTO_DATE="${HOWTO_DATE:-}"
  if [[ -n "$HOWTO_DATE" ]]; then
    if [[ "$(uname -s)" == "Darwin" ]]; then
      HOWTO_EPOCH=$(date -jf "%Y-%m-%d" "$HOWTO_DATE" +%s 2>/dev/null || echo 0)
    else
      HOWTO_EPOCH=$(date -d "$HOWTO_DATE" +%s 2>/dev/null || echo 0)
    fi
    NOW_EPOCH=${NOW_EPOCH:-$(date +%s)}
    HOWTO_DAYS=$(( (NOW_EPOCH - HOWTO_EPOCH) / 86400 ))
    if [[ $HOWTO_DAYS -gt 7 ]]; then
      HOWTO_STALENESS="
HOW-TO ist ${HOWTO_DAYS} Tage alt. Empfehlung: /generate-pwd-howto ausfuehren."
    fi
  elif [[ -d "$PWD/$DOCS_PATH/handoffs" ]]; then
    # Session-continuous project but no HOW-TO ever generated
    HOWTO_STALENESS="
Kein HOW-TO fuer dieses Projekt gefunden. Empfehlung: /generate-pwd-howto ausfuehren."
  fi
fi

# ============================================================================
# Build additionalContext
# ============================================================================

CONTEXT="Session-Handoff geladen (${HANDOFF_BASENAME}):
---
${HANDOFF_CONTENT}${HEALTH_LINE}${STALENESS_LINE}${HOWTO_STALENESS}
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
