#!/usr/bin/env bash
# Erstellt einen neuen Visualisierungs-Projektordner
# Usage: bash scripts/init-project.sh "Projekt Titel" [output-dir]

set -euo pipefail

TITLE="${1:?Usage: init-project.sh \"Titel\" [output-dir]}"
OUTPUT_DIR="${2:-./output}"

# Slug generieren (Umlaute, Sonderzeichen)
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' \
    | sed 's/ä/ae/g; s/ö/oe/g; s/ü/ue/g; s/ß/ss/g' \
    | sed 's/[^a-z0-9]/-/g' \
    | sed 's/--*/-/g; s/^-//; s/-$//' \
    | cut -c1-50)

PROJECT_DIR="$OUTPUT_DIR/$SLUG"

mkdir -p "$PROJECT_DIR/assets"

# Leeres content.json Scaffold
cat > "$PROJECT_DIR/content.json" << EOF
{
  "title": "$TITLE",
  "subtitle": "",
  "visualProfile": {
    "theme": "default",
    "layoutStyle": "presentation",
    "creativityLevel": 3
  },
  "sections": [],
  "metadata": {
    "author": "",
    "date": "$(date +%d.%m.%Y)",
    "version": "1.0"
  }
}
EOF

echo "Projekt erstellt: $PROJECT_DIR"
echo "  content.json: $PROJECT_DIR/content.json"
echo "  assets/:      $PROJECT_DIR/assets/"
