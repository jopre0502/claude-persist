#!/usr/bin/env bash
# git-safety-guard.sh — PreToolUse Hook fuer deterministische Git-Sicherheit
#
# Blockiert drei Klassen gefaehrlicher Git-Operationen:
#   A) git add -f / --force      → erzwingt .gitignored Files in den Index
#   B) --no-verify / --no-gpg-sign auf git commit|push → ueberspringt Hooks/Signierung
#   C) git push --force|-f auf main/master → schreibt geteilte History um
#
# Override (Notfall): Inline-Marker `# CLAUDE-ALLOW-DESTRUCTIVE` im Command.
# Diese Markierung ist im git/bash-History sichtbar — voller Audit-Trail.
#
# Output-API (PreToolUse):
#   {} oder kein Output                     → allow (Default)
#   permissionDecision: "deny" + Message    → block
#
# Exit 0 immer; die JSON entscheidet.
# Bei jq-/parse-Fehlern: silent allow (Hook darf nie selbst etwas brechen).

set -euo pipefail

# --- Read Hook Input ---
INPUT=$(cat)

# Tool-Name pruefen — nur Bash interessiert uns
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null | tr -d '\r') || exit 0
[[ "$TOOL_NAME" == "Bash" ]] || exit 0

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null | tr -d '\r') || exit 0
[[ -n "$COMMAND" ]] || exit 0

# --- Override Marker ---
# Notfall-Escape: User/Claude haengt `# CLAUDE-ALLOW-DESTRUCTIVE` an
# (z.B. fuer kaputten pre-commit Hook bei dringendem Hotfix).
if [[ "$COMMAND" == *"# CLAUDE-ALLOW-DESTRUCTIVE"* ]]; then
  exit 0
fi

# --- Helper: Deny mit klarer Begruendung ---
deny() {
  local rule="$1"     # Z.B. "Hook-A"
  local pattern="$2"  # Z.B. "git add --force"
  local reason="$3"   # Erklaerung warum blockiert
  local advice="$4"   # Was stattdessen tun

  local msg
  msg=$(cat <<EOF
[${rule}] Blockiert: ${pattern}

Grund: ${reason}

Stattdessen: ${advice}

Notfall-Override: \`# CLAUDE-ALLOW-DESTRUCTIVE\` am Command-Ende anhaengen.
Quelle: persist Plugin git-safety-guard (TASK-106)
EOF
)

  jq -n \
    --arg m "$msg" \
    '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny"
      },
      "systemMessage": $m
    }'
  exit 0
}

# --- Pipeline-Split ---
# `cd /tmp && git add -f` muss Hook A triggern, auch wenn es nicht das erste Kommando ist.
# Split bei &&, ||, ;, | auf Newlines. sed-Einzelaufruf (kein Loop) → CreateProcess OK.
SUBCMDS=$(printf '%s' "$COMMAND" | sed -E 's/(\&\&|\|\||;|\|)/\n/g')

# --- Pro Sub-Command: drei Pattern-Checks ---
while IFS= read -r sub; do
  sub="${sub%$'\r'}"
  # Trim whitespace (Pure-Bash, kein xargs)
  sub="${sub#"${sub%%[![:space:]]*}"}"
  sub="${sub%"${sub##*[![:space:]]}"}"
  [[ -z "$sub" ]] && continue

  # --- Pattern A: git add -f / --force ---
  # Match: git ... add ... irgendwo (-f|--force) als isoliertes Token
  # Globale Git-Flags (-C, -c) zwischen "git" und "add" werden via Lazy-Pattern erlaubt.
  if [[ "$sub" =~ (^|[[:space:]])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+add([[:space:]]|$) ]] \
  && [[ "$sub" =~ (^|[[:space:]])(-f|--force)([[:space:]]|$) ]]; then
    deny "Hook-A" \
      "git add -f / --force" \
      ".gitignore ist eine Sicherheitsgrenze, kein Hindernis. Force-Add umgeht den Schutz gegen versehentlichen Commit von Secrets/Build-Artefakten/IDE-Configs." \
      "Pruefe .gitignore. Wenn das File ins Repo gehoert, .gitignore-Eintrag anpassen, dann normal 'git add <file>'."
  fi

  # --- Pattern B: --no-verify / --no-gpg-sign auf commit/push ---
  # Match: git ... (commit|push) ... mit --no-verify oder --no-gpg-sign
  if [[ "$sub" =~ (^|[[:space:]])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+(commit|push)([[:space:]]|$) ]] \
  && [[ "$sub" =~ (^|[[:space:]])(--no-verify|--no-gpg-sign)([[:space:]]|$) ]]; then
    deny "Hook-B" \
      "--no-verify / --no-gpg-sign" \
      "Pre-commit Hooks und GPG-Signierung sind Qualitaets-/Sicherheitsgrenzen. Skip umgeht Lint, Tests, Signatur-Verifikation." \
      "Wenn ein Hook bricht: Root-Cause fixen, nicht ueberspringen. Wenn explizit gewollt (z.B. WIP-Commit auf eigenem Branch): User-Bestaetigung im Prompt einholen."
  fi

  # --- Pattern C: git push --force auf main/master ---
  # Match: git push mit (--force | -f) UND main|master als isoliertes Argument
  # WICHTIG: --force-with-lease ist KEIN Match (sicherer Force-Push, erlaubt).
  if [[ "$sub" =~ (^|[[:space:]])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+push([[:space:]]|$) ]] \
  && [[ "$sub" =~ (^|[[:space:]])(--force([[:space:]]|$)|-f([[:space:]]|$)) ]] \
  && [[ "$sub" =~ (^|[[:space:]:])(main|master)([[:space:]:]|$) ]]; then
    deny "Hook-C" \
      "git push --force auf main/master" \
      "Force-Push auf den Hauptbranch zerstoert geteilte History. Andere Klone werden inkompatibel, Code kann verloren gehen." \
      "Nutze 'git push --force-with-lease' (sicherer Force, prueft Upstream-State). Auf Feature-Branches ist Force-Push OK — diese Regel greift nur auf main/master."
  fi

done <<< "$SUBCMDS"

# --- Default: allow (kein Match) ---
exit 0
