#!/usr/bin/env bash
# parse-next-action.sh — Action Tracking Parser
# Liest Action Tracking Tabelle aus Task-File, gibt naechste pending Action als JSON zurueck.
#
# Usage: parse-next-action.sh <TASK_FILE_PATH>
# Exit 0 = pending Action gefunden (JSON auf stdout)
# Exit 1 = alle Actions complete/cancelled/skipped (JSON auf stdout)
# Exit 2 = Parse-Error (Fehler auf stderr)
#
# Output JSON:
#   {"nr":"2","name":"Helper-Script erstellen","total":"6","status":"pending"}
#   {"nr":"0","name":"","total":"6","status":"all_complete"}
#
# Windows Performance: Nur ein grep-Aufruf, danach reine Bash-String-Ops.
# CRLF-defensiv: tr -d '\r' auf grep-Output.

set -euo pipefail

# --- Argument Check ---
if [[ $# -lt 1 ]] || [[ -z "$1" ]]; then
  echo "Error: Task file path required" >&2
  echo '{"nr":"0","name":"","total":"0","status":"error"}'
  exit 2
fi

task_file="$1"

if [[ ! -f "$task_file" ]]; then
  echo "Error: Task file not found: $task_file" >&2
  echo '{"nr":"0","name":"","total":"0","status":"error"}'
  exit 2
fi

# --- Extract Action Table Rows ---
# Einziger externer Aufruf: grep + tr (Pipe, kein Loop)
# Matcht Zeilen wie: | 1 | Action Name | pending | ... |
# Auch: | 1 | Action Name | ✅ completed | ... |
table_lines=$(grep -E '^\| [0-9]+ \|' "$task_file" | tr -d '\r') || true

if [[ -z "$table_lines" ]]; then
  echo "Error: No action tracking table found in $task_file" >&2
  echo '{"nr":"0","name":"","total":"0","status":"error"}'
  exit 2
fi

# --- Parse: Count total + find first pending ---
total=0
found_nr=""
found_name=""

while IFS= read -r line; do
  total=$((total + 1))

  # Bereits gefunden? Nur noch zaehlen.
  [[ -n "$found_nr" ]] && continue

  # Felder extrahieren: | NR | NAME | STATUS | ...
  # Pipe-Delimiter splitten via Bash-intern
  rest="${line#|}"            # fuehrenden | entfernen
  nr_field="${rest%%|*}"      # erstes Feld (Nummer)
  rest="${rest#*|}"           # nach erstem |
  name_field="${rest%%|*}"    # zweites Feld (Name)
  rest="${rest#*|}"           # nach zweitem |
  status_field="${rest%%|*}"  # drittes Feld (Status)

  # Trim whitespace (Bash-intern, kein Subprozess)
  nr_field="${nr_field#"${nr_field%%[![:space:]]*}"}"
  nr_field="${nr_field%"${nr_field##*[![:space:]]}"}"
  name_field="${name_field#"${name_field%%[![:space:]]*}"}"
  name_field="${name_field%"${name_field##*[![:space:]]}"}"
  status_field="${status_field#"${status_field%%[![:space:]]*}"}"
  status_field="${status_field%"${status_field##*[![:space:]]}"}"

  # Status-Check: "pending" irgendwo im Status-Feld (case-insensitive via lowercase)
  status_lower="${status_field,,}"
  if [[ "$status_lower" == *"pending"* ]]; then
    found_nr="$nr_field"
    found_name="$name_field"
  fi
done <<< "$table_lines"

# --- JSON escaping fuer name (Backticks, Quotes) ---
json_escape_name() {
  local s="$1"
  s="${s//\\/\\\\}"   # backslash
  s="${s//\"/\\\"}"   # double quote
  printf '%s' "$s"
}

# --- Output ---
if [[ -n "$found_nr" ]]; then
  escaped_name=$(json_escape_name "$found_name")
  printf '{"nr":"%s","name":"%s","total":"%s","status":"pending"}\n' \
    "$found_nr" "$escaped_name" "$total"
  exit 0
else
  printf '{"nr":"0","name":"","total":"%s","status":"all_complete"}\n' "$total"
  exit 1
fi
