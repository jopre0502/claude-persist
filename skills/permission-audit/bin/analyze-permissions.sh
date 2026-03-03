#!/bin/bash
# Permission Audit: Analyzer
# Vergleicht Tool-Call-Log gegen settings.json Allow-Rules

LOG_DIR="$HOME/.claude/skills/permission-audit/artifacts"
SETTINGS="$HOME/.claude/settings.json"
DATE="${1:-$(date +%Y-%m-%d)}"
LOG="$LOG_DIR/tool-calls-${DATE}.log"

if [ ! -f "$LOG" ]; then
  echo "Kein Log fuer $DATE gefunden: $LOG"
  exit 1
fi

TOTAL=$(wc -l < "$LOG")
AUTO_APPROVED=0
ALLOW_MATCHED=0
UNMATCHED=0
UNMATCHED_LINES=""

# Auto-approved tools (read-only, immer auto-approved unabhaengig von settings)
AUTO_TOOLS="Read Grep Glob LS NotebookRead AskUserQuestion TaskOutput"

# Allow-Rules aus settings.json laden
ALLOW_RULES=$(jq -r '.permissions.allow[]' "$SETTINGS" 2>/dev/null | tr -d '\r')

while IFS='|' read -r TIME TOOL SIG; do
  # Auto-approved?
  if echo "$AUTO_TOOLS" | grep -qw "$TOOL"; then
    ((AUTO_APPROVED++))
    continue
  fi

  MATCHED=false

  while IFS= read -r RULE; do
    [ -z "$RULE" ] && continue

    # Typ 1: Exakter Tool-Name (z.B. "Edit", "WebSearch")
    if [ "$RULE" = "$TOOL" ]; then
      MATCHED=true; break
    fi

    # Typ 2: Tool-Name-Glob ohne Klammern (z.B. "mcp__obsidian__*")
    if [[ ! "$RULE" == *"("* ]] && [[ "$TOOL" == $RULE ]]; then
      MATCHED=true; break
    fi

    # Typ 3: Tool(Pattern) (z.B. "Bash(git *)", "Task(*)", "Skill(*)")
    if [[ "$RULE" == *"("*")"* ]]; then
      RULE_TOOL="${RULE%%(*}"
      RULE_PATTERN="${RULE#*(}"
      RULE_PATTERN="${RULE_PATTERN%)}"

      if [ "$RULE_TOOL" = "$TOOL" ]; then
        if [ "$RULE_PATTERN" = "*" ] || [[ "$SIG" == $RULE_PATTERN ]]; then
          MATCHED=true; break
        fi
      fi
    fi
  done <<< "$ALLOW_RULES"

  if $MATCHED; then
    ((ALLOW_MATCHED++))
  else
    ((UNMATCHED++))
    UNMATCHED_LINES="${UNMATCHED_LINES}  ${TIME} | ${TOOL}(${SIG})\n"
  fi
done < "$LOG"

echo "## Permission Audit: $DATE"
echo ""
echo "| Kategorie | Anzahl |"
echo "|-----------|--------|"
echo "| Total Tool-Calls | $TOTAL |"
echo "| Auto-approved (Read-only) | $AUTO_APPROVED |"
echo "| Allow-Rule matched | $ALLOW_MATCHED |"
echo "| **Unmatched (Prompt erwartet)** | **$UNMATCHED** |"

if [ "$UNMATCHED" -gt 0 ]; then
  echo ""
  echo "### Unmatched Calls (haetten prompten muessen):"
  echo -e "$UNMATCHED_LINES"
fi

echo ""
echo "Log: $LOG ($TOTAL Eintraege)"
