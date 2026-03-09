#!/bin/bash
# session-env-loader.sh v4 — 1Password Health Check
# Prueft ob op CLI verfuegbar und 1Password erreichbar ist.
# Secrets werden NICHT gecached — op read on-demand in Scripts die es brauchen.
# Architektur: TASK-073 v4

OP_EXE=""
for candidate in "op" "op.exe" "$LOCALAPPDATA/Microsoft/WinGet/Links/op.exe"; do
  if command -v "$candidate" &>/dev/null; then
    OP_EXE="$candidate"
    break
  fi
done

if [ -z "$OP_EXE" ]; then
  echo '{"systemMessage":"env-loader: op CLI nicht gefunden. 1Password Secrets nicht verfuegbar."}'
  exit 0
fi

if "$OP_EXE" read "op://Private/Claude-Code-N8N/api-key" &>/dev/null; then
  echo '{"systemMessage":"env-loader: 1Password OK. Secrets via op read on-demand verfuegbar. Pattern: N8N_KEY=$(op read op://Private/Claude-Code-N8N/api-key | tr -d \\\\r)"}'
else
  echo '{"systemMessage":"env-loader: op CLI gefunden aber 1Password nicht erreichbar (locked?). Secrets nicht verfuegbar."}'
fi
exit 0
