#!/bin/bash
# session-env-loader.sh — Bridge: secrets-blueprint → Claude Code Session
# Laedt alle ~/.config/secrets/env.d/*.env in CLAUDE_ENV_FILE
# Siehe: ADR-003 (projekt-automation-hub/docs/decisions/ADR-003-config-architecture.md)

ENV_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/secrets/env.d"
LOADED=0

if [ -n "$CLAUDE_ENV_FILE" ] && [ -d "$ENV_DIR" ]; then
  for env_file in "$ENV_DIR"/*.env; do
    [ -f "$env_file" ] || continue
    while IFS= read -r line || [ -n "$line" ]; do
      line="${line%$'\r'}"
      [[ "$line" =~ ^[[:space:]]*# ]] && continue
      [[ -z "${line// }" ]] && continue
      echo "export $line" >> "$CLAUDE_ENV_FILE"
      ((LOADED++))
    done < "$env_file"
  done
  echo '{"systemMessage":"env-loader: '"$LOADED"' vars loaded from env.d"}'
else
  echo '{"systemMessage":"env-loader: CLAUDE_ENV_FILE='${CLAUDE_ENV_FILE:-UNSET}' ENV_DIR_EXISTS='$([ -d "$ENV_DIR" ] && echo yes || echo no)'"}'
fi
exit 0
