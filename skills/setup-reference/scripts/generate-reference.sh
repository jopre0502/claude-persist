#!/usr/bin/env bash
# generate-reference.sh — Scannt ~/.claude/ und generiert SETUP-REFERENCE.md
# Verwendung: bash generate-reference.sh [output-path]
# Default output: ~/.claude/skills/setup-reference/references/SETUP-REFERENCE.md

set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
STATIC_SECTIONS="$SKILL_DIR/references/static-sections.md"
OUTPUT="${1:-$SKILL_DIR/references/SETUP-REFERENCE.md}"

TIMESTAMP="$(date '+%Y-%m-%d %H:%M')"

# Counters
SKILL_COUNT=0
AGENT_COUNT=0
COMMAND_COUNT=0
HOOK_COUNT=0
PLUGIN_COUNT=0

# --- Helper: Extract YAML frontmatter field ---
extract_yaml_field() {
  local file="$1"
  local field="$2"
  # Handle multi-line fields (| or >) by taking first meaningful line
  sed -n '/^---$/,/^---$/p' "$file" 2>/dev/null \
    | grep -E "^${field}:" \
    | head -1 \
    | sed "s/^${field}:[[:space:]]*//" \
    | sed 's/^["'"'"']//;s/["'"'"']$//' \
    | sed 's/^|$//' \
    | sed 's/^>$//'
}

# For description fields that span multiple lines after "description: |" or "description: >"
extract_description() {
  local file="$1"
  local in_fm=false
  local in_desc=false
  local desc=""

  while IFS= read -r line; do
    if [[ "$line" == "---" ]]; then
      if $in_fm; then break; fi
      in_fm=true
      continue
    fi
    if ! $in_fm; then continue; fi

    if [[ "$line" =~ ^description: ]]; then
      local val="${line#description:}"
      val="${val#"${val%%[![:space:]]*}"}" # trim leading spaces
      if [[ "$val" == "|" || "$val" == ">" || -z "$val" ]]; then
        in_desc=true
        continue
      else
        # Single-line description
        echo "$val" | sed 's/^["'"'"']//;s/["'"'"']$//'
        return
      fi
    fi

    if $in_desc; then
      if [[ "$line" =~ ^[a-zA-Z_-]+: || "$line" == "---" ]]; then
        break
      fi
      local trimmed="${line#"${line%%[![:space:]]*}"}"
      if [[ -n "$trimmed" ]]; then
        if [[ -z "$desc" ]]; then
          desc="$trimmed"
        else
          desc="$desc $trimmed"
        fi
      fi
    fi
  done < "$file"

  # Truncate to first sentence or 120 chars
  if [[ ${#desc} -gt 120 ]]; then
    echo "${desc:0:117}..."
  else
    echo "$desc"
  fi
}

# --- Start output ---
{
  echo "# SETUP-REFERENCE — Auto-generated: $TIMESTAMP"
  echo ""
  echo "Generiert aus Live-System (\`~/.claude/\`). Nicht manuell bearbeiten."
  echo ""
  echo "---"
  echo ""

  # --- 1. Skills ---
  echo "## 1. Installierte Skills"
  echo ""
  echo "| Skill | Beschreibung |"
  echo "|-------|-------------|"
  if [[ -d "$CLAUDE_DIR/skills" ]]; then
    for skill_dir in "$CLAUDE_DIR/skills"/*/; do
      [[ -d "$skill_dir" ]] || continue
      skill_name="$(basename "$skill_dir")"
      skill_file="$skill_dir/SKILL.md"
      if [[ -f "$skill_file" ]]; then
        desc="$(extract_description "$skill_file")"
        [[ -z "$desc" ]] && desc="(keine Beschreibung)"
      else
        # Check for BLUEPRINT.md (secrets-blueprint)
        alt_file="$(find "$skill_dir" -maxdepth 1 -name '*.md' -not -name 'README*' | head -1)"
        if [[ -n "$alt_file" ]]; then
          desc="$(extract_description "$alt_file")"
          [[ -z "$desc" ]] && desc="(alternatives Format)"
        else
          desc="(kein SKILL.md)"
        fi
      fi
      echo "| \`$skill_name\` | $desc |"
      SKILL_COUNT=$((SKILL_COUNT + 1))
    done
  fi
  echo ""
  echo "**Gesamt:** $SKILL_COUNT Skills"
  echo ""
  echo "---"
  echo ""

  # --- 2. Agents ---
  echo "## 2. Agents"
  echo ""
  echo "| Agent | Beschreibung |"
  echo "|-------|-------------|"
  if [[ -d "$CLAUDE_DIR/agents" ]]; then
    for agent_file in "$CLAUDE_DIR/agents"/*.md; do
      [[ -f "$agent_file" ]] || continue
      agent_name="$(basename "$agent_file" .md)"
      desc="$(extract_description "$agent_file")"
      [[ -z "$desc" ]] && desc="(keine Beschreibung)"
      echo "| \`$agent_name\` | $desc |"
      AGENT_COUNT=$((AGENT_COUNT + 1))
    done
  fi
  echo ""
  echo "**Gesamt:** $AGENT_COUNT Agents"
  echo ""
  echo "---"
  echo ""

  # --- 3. Commands ---
  echo "## 3. Commands (Slash-Commands)"
  echo ""
  echo "| Command | Beschreibung |"
  echo "|---------|-------------|"
  if [[ -d "$CLAUDE_DIR/commands" ]]; then
    for cmd_file in "$CLAUDE_DIR/commands"/*.md; do
      [[ -f "$cmd_file" ]] || continue
      cmd_name="$(basename "$cmd_file" .md)"
      desc="$(extract_description "$cmd_file")"
      [[ -z "$desc" ]] && desc="(keine Beschreibung)"
      echo "| \`/$cmd_name\` | $desc |"
      COMMAND_COUNT=$((COMMAND_COUNT + 1))
    done
  fi
  echo ""
  echo "**Gesamt:** $COMMAND_COUNT Commands"
  echo ""
  echo "---"
  echo ""

  # --- 4. Hooks ---
  echo "## 4. Hooks (settings.json)"
  echo ""
  echo "| Event | Hook-Script | Timeout |"
  echo "|-------|-------------|---------|"
  if [[ -f "$SETTINGS" ]] && command -v jq &>/dev/null; then
    jq -r '
      .hooks // {} | to_entries[] |
      .key as $event |
      .value[] |
      .hooks[]? |
      "| \($event) | `\(.command | split("/") | last)` | \(.timeout // "default")s |"
    ' "$SETTINGS" 2>/dev/null || echo "| (jq Fehler) | — | — |"
    HOOK_COUNT=$(jq '[.hooks // {} | to_entries[] | .value[] | .hooks[]?] | length' "$SETTINGS" 2>/dev/null || echo 0)
  else
    echo "| (settings.json nicht gefunden oder jq fehlt) | — | — |"
  fi
  echo ""
  echo "**Gesamt:** $HOOK_COUNT Hooks"
  echo ""
  echo "---"
  echo ""

  # --- 5. Permissions ---
  echo "## 5. Permissions"
  echo ""
  echo "### Allow-Rules"
  echo ""
  if [[ -f "$SETTINGS" ]] && command -v jq &>/dev/null; then
    jq -r '.permissions.allow // [] | .[]' "$SETTINGS" 2>/dev/null | while read -r rule; do
      echo "- \`$rule\`"
    done
  fi
  echo ""
  echo "### Deny-Rules"
  echo ""
  if [[ -f "$SETTINGS" ]] && command -v jq &>/dev/null; then
    jq -r '.permissions.deny // [] | .[]' "$SETTINGS" 2>/dev/null | while read -r rule; do
      echo "- \`$rule\`"
    done
  fi
  echo ""
  echo "---"
  echo ""

  # --- 6. Plugins ---
  echo "## 6. Aktivierte Plugins"
  echo ""
  echo "| Plugin | Quelle |"
  echo "|--------|--------|"
  if [[ -f "$SETTINGS" ]] && command -v jq &>/dev/null; then
    jq -r '
      .enabledPlugins // {} | to_entries[] |
      select(.value == true) |
      .key | split("@") |
      "| `\(.[0])` | \(.[1] // "unknown") |"
    ' "$SETTINGS" 2>/dev/null || echo "| (jq Fehler) | — |"
    PLUGIN_COUNT=$(jq '[.enabledPlugins // {} | to_entries[] | select(.value == true)] | length' "$SETTINGS" 2>/dev/null || echo 0)
  fi
  echo ""
  echo "**Gesamt:** $PLUGIN_COUNT Plugins"
  echo ""
  echo "---"
  echo ""

  # --- 7. Global Settings ---
  echo "## 7. Globale Einstellungen"
  echo ""
  echo "| Setting | Wert |"
  echo "|---------|------|"
  if [[ -f "$SETTINGS" ]] && command -v jq &>/dev/null; then
    model=$(jq -r '.model // "default"' "$SETTINGS" 2>/dev/null)
    style=$(jq -r '.outputStyle // "default"' "$SETTINGS" 2>/dev/null)
    effort=$(jq -r '.effortLevel // "default"' "$SETTINGS" 2>/dev/null)
    notif=$(jq -r '.preferredNotifChannel // "default"' "$SETTINGS" 2>/dev/null)
    echo "| \`model\` | $model |"
    echo "| \`outputStyle\` | $style |"
    echo "| \`effortLevel\` | $effort |"
    echo "| \`preferredNotifChannel\` | $notif |"
  fi
  echo ""
  echo "---"
  echo ""

  # --- 8. Secrets (nur Dateinamen) ---
  echo "## 8. Secrets-Dateien (nur Namen)"
  echo ""
  SECRETS_DIR="$HOME/.config/secrets/env.d"
  if [[ -d "$SECRETS_DIR" ]]; then
    echo "| Datei | Groesse |"
    echo "|-------|---------|"
    for env_file in "$SECRETS_DIR"/*.env; do
      [[ -f "$env_file" ]] || continue
      fname="$(basename "$env_file")"
      fsize="$(stat --printf='%s' "$env_file" 2>/dev/null || echo '?')"
      echo "| \`$fname\` | ${fsize}B |"
    done
  else
    echo "Verzeichnis \`$SECRETS_DIR\` nicht gefunden."
  fi
  echo ""
  echo "---"
  echo ""

  # --- 9. Static Sections ---
  if [[ -f "$STATIC_SECTIONS" ]]; then
    cat "$STATIC_SECTIONS"
    echo ""
    echo "---"
    echo ""
  fi

  # --- Footer ---
  echo "*Generiert: $TIMESTAMP | Script: generate-reference.sh*"
  echo "*Naechste Aktualisierung: /refresh-reference ausfuehren*"

} > "$OUTPUT"

echo "SETUP-REFERENCE.md generiert: $OUTPUT"
echo "  Skills:   $SKILL_COUNT"
echo "  Agents:   $AGENT_COUNT"
echo "  Commands: $COMMAND_COUNT"
echo "  Hooks:    $HOOK_COUNT"
echo "  Plugins:  $PLUGIN_COUNT"
