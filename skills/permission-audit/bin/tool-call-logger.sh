#!/bin/bash
# Permission Audit: PreToolUse Hook Logger
# Loggt jeden Tool-Call mit Timestamp + Signatur. Kein Output = keine Permission-Entscheidung.

ARTIFACT_DIR="$HOME/.claude/skills/permission-audit/artifacts"
mkdir -p "$ARTIFACT_DIR"
LOG="$ARTIFACT_DIR/tool-calls-$(date +%Y-%m-%d).log"

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')

case "$TOOL" in
  Bash)    SIG=$(echo "$INPUT" | jq -r '.tool_input.command // ""' | tr '\n' ' ' | head -c 200) ;;
  Read|Edit|Write) SIG=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""') ;;
  Task)    SIG=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // ""') ;;
  Skill)   SIG=$(echo "$INPUT" | jq -r '.tool_input.skill // ""') ;;
  Grep)    SIG=$(echo "$INPUT" | jq -r '.tool_input.pattern // ""' | head -c 60) ;;
  Glob)    SIG=$(echo "$INPUT" | jq -r '.tool_input.pattern // ""') ;;
  *)       SIG="" ;;
esac

echo "$(date +%H:%M:%S)|${TOOL}|${SIG}" >> "$LOG"
