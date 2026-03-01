#!/bin/bash
# session-env-loader.sh — Bridge: secrets-blueprint → Claude Code Session
# Laedt alle ~/.config/secrets/env.d/*.env (SOPS-verschluesselt oder Klartext) in CLAUDE_ENV_FILE
# Siehe: ADR-003 (projekt-automation-hub/docs/decisions/ADR-003-config-architecture.md)

ENV_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/secrets/env.d"
IS_MINGW=false
if [[ "$(uname -s)" == MINGW* ]] || [[ "$(uname -s)" == MSYS* ]]; then
  IS_MINGW=true
fi

# SOPS braucht Windows-Pfade auf MINGW/MSYS (nicht /c/Users/... sondern C:\Users\...)
if $IS_MINGW; then
  export SOPS_AGE_KEY_FILE="$(cygpath -w "$HOME/.config/secrets/age-key.txt")"
else
  export SOPS_AGE_KEY_FILE="$HOME/.config/secrets/age-key.txt"
fi

# Helper: Pfad fuer sops konvertieren (MINGW → Windows)
sops_path() {
  if $IS_MINGW; then cygpath -w "$1"; else echo "$1"; fi
}
LOADED=0

if [ -n "$CLAUDE_ENV_FILE" ] && [ -d "$ENV_DIR" ]; then
  for env_file in "$ENV_DIR"/*.env; do
    [ -f "$env_file" ] || continue
    # Entschluesseln via sops, Fallback auf Klartext (Migration-Phase)
    decrypted=$(sops -d "$(sops_path "$env_file")" 2>/dev/null)
    if [ $? -ne 0 ]; then
      decrypted=$(cat "$env_file")
    fi
    while IFS= read -r line || [ -n "$line" ]; do
      line="${line%$'\r'}"
      [[ "$line" =~ ^[[:space:]]*# ]] && continue
      [[ -z "${line// }" ]] && continue
      echo "export $line" >> "$CLAUDE_ENV_FILE"
      ((LOADED++))
    done <<< "$decrypted"
  done
  # Platform-Translation: WSL2-Pfade (/mnt/c/) auf MINGW-Format (/c/) konvertieren
  if $IS_MINGW; then
    sed -i 's|/mnt/c/|/c/|g' "$CLAUDE_ENV_FILE"
  fi
  echo '{"systemMessage":"env-loader: '"$LOADED"' vars loaded from env.d (sops+age), platform='"$(uname -s)"'"}'
else
  # Fallback (Bug #15840): CLAUDE_ENV_FILE nicht gesetzt.
  # Entschluessele trotzdem und gib Werte als additionalContext aus,
  # damit Claude die Pfade kennt (auch wenn Shell-Env leer bleibt).
  # Whitelist: Nur Pfad-Variablen im Klartext ausgeben, Secrets maskieren
  SAFE_VARS="OBSIDIAN_VAULT OBSIDIAN_HOST OBSIDIAN_PORT N8N_BASE_URL"
  CONTEXT_LINES=""
  if [ -d "$ENV_DIR" ]; then
    for env_file in "$ENV_DIR"/*.env; do
      [ -f "$env_file" ] || continue
      decrypted=$(sops -d "$(sops_path "$env_file")" 2>/dev/null)
      if [ $? -ne 0 ]; then
        decrypted=$(cat "$env_file")
      fi
      while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        # Platform-Translation: /mnt/c/ → /c/ auf MINGW/MSYS
        if $IS_MINGW; then
          line=$(echo "$line" | sed 's|/mnt/c/|/c/|g')
        fi
        # Nur Whitelist-Variablen im Klartext, Rest als KEY=*** maskieren
        varname="${line%%=*}"
        if echo "$SAFE_VARS" | grep -qw "$varname"; then
          CONTEXT_LINES="${CONTEXT_LINES}${line} | "
        else
          CONTEXT_LINES="${CONTEXT_LINES}${varname}=*** | "
        fi
        ((LOADED++))
      done <<< "$decrypted"
    done
  fi
  # JSON-safe: Anfuehrungszeichen escapen
  SAFE_CONTEXT=$(printf '%s' "$CONTEXT_LINES" | sed 's/"/\\"/g')
  echo '{"systemMessage":"env-loader: CLAUDE_ENV_FILE='${CLAUDE_ENV_FILE:-UNSET}' (Bug #15840). '"$LOADED"' vars decoded via fallback, platform='"$(uname -s)"'","hookSpecificOutput":{"additionalContext":"Environment (fallback, nicht in Shell-Env gesetzt — nutze secret-run fuer Bash-Zugriff): '"$SAFE_CONTEXT"'"}}'
fi
exit 0
