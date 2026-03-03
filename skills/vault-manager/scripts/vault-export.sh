#!/bin/bash
# vault-export.sh - Generate Vault document with Fileclass-based template
# Part of vault-manager skill (UC2: Export)
#
# Usage: vault-export.sh <fileclass> <title> [content]
#        echo "content" | vault-export.sh <fileclass> <title>
#
# Fileclasses: Werk, Memo, Bewerbung, Person, Unternehmen, Produkt, Ort
#
# Example:
#   vault-export.sh Werk "PKM-Workflows mit Claude" "## Summary\n\nContent here..."
#   echo "My memo content" | vault-export.sh Memo "Session-Learning 2026-02-04"

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/vault-lib.sh"
MAPPING_FILE="${FILECLASS_MAPPING:-$HOME/.claude/skills/vault-manager/config/fileclass-mapping.json}"
VAULT_ROOT=""  # resolved later (after --dry-run check)
EXPORT_DIR="04 RESSOURCEN"

# --- Functions ---
usage() {
    cat <<EOF
Usage: vault-export.sh [--tags "tag1,tag2"] [--dry-run] <fileclass> <title> [content]

Fileclasses: Werk, Memo, Bewerbung, Person, Unternehmen, Produkt, Ort

Options:
  --tags TAG   Comma-separated custom tags (overrides fileclass default)
  --dry-run    Show generated document without writing
  --help       Show this help

Environment:
  OBSIDIAN_VAULT    Path to Obsidian vault (optional fallback, CLI-primary)
  FILECLASS_MAPPING Path to fileclass-mapping.json (optional)

Examples:
  vault-export.sh Werk "Mein Artikel" "## Inhalt..."
  vault-export.sh --tags "werk,claude-code,anleitung" Werk "Mein Artikel" "## Inhalt..."
  echo "Memo text" | vault-export.sh Memo "Session-Note"
  vault-export.sh --dry-run Memo "Test" "Test content"
EOF
    exit 0
}

error() {
    echo "[ERROR] $1" >&2
    exit 1
}

info() {
    echo "[INFO] $1" >&2
}

# Validate fileclass exists
validate_fileclass() {
    local fc="$1"
    local valid_classes="Werk Memo Bewerbung Person Unternehmen Produkt Ort"

    if [[ ! " $valid_classes " =~ " $fc " ]]; then
        error "Invalid fileclass: $fc. Valid: $valid_classes"
    fi
}

# Generate YAML frontmatter based on fileclass
generate_frontmatter() {
    local fileclass="$1"
    local title="$2"
    local custom_tags="${3:-}"
    local today
    today=$(date +%Y-%m-%d)
    local tag
    tag=$(echo "$fileclass" | tr '[:upper:]' '[:lower:]')

    # Build tags block: YAML list for custom tags, inline for default
    local tags_block
    if [[ -n "$custom_tags" ]]; then
        tags_block="tags:"
        IFS=',' read -ra tag_arr <<< "$custom_tags"
        for t in "${tag_arr[@]}"; do
            t="${t#"${t%%[![:space:]]*}"}"  # trim leading whitespace
            t="${t%"${t##*[![:space:]]}"}"  # trim trailing whitespace
            tags_block="${tags_block}"$'\n'"  - $t"
        done
    else
        tags_block="tags: $tag"
    fi

    cat <<EOF
---
fileClass: $fileclass
erstellt: $today
$tags_block
space:
projekt:
aliases:
person:
memo:
unternehmen:
werk:
ref_ressource:
EOF

    # Add fileclass-specific properties
    case "$fileclass" in
        Werk)
            cat <<EOF
status: zusammengefasst
url:
typ: Zusammenfassung
jahr_gelesen: $(date +%Y)
EOF
            ;;
        Memo)
            cat <<EOF
typ:
datum: $today
url:
EOF
            ;;
        Bewerbung)
            cat <<EOF
prio:
ort:
headhunter: false
initiativ: false
reminder:
personalberater:
status: 1 - Bewerben
datum_beworben:
datum_veröffentlicht:
url:
job_ref:
datum_Entscheidung:
url_chatGpt:
EOF
            ;;
        Person)
            cat <<EOF
netzwerk_phase:
position:
beruf:
headhunter: false
industrie:
beziehung:
expertise:
prio:
kontaktfrequenz:
reminder:
datum_letzte_Aktion:
nächste_Aktion:
verlinktZuPerson:
verlinktVonPerson:
url_webseite:
url_linkedin:
geburtstag:
url_chatGpt:
EOF
            ;;
        Unternehmen)
            cat <<EOF
prio:
funnel_phase:
url_webseite:
headhunter:
quelle:
industrie:
EOF
            ;;
        Produkt)
            cat <<EOF
art:
hersteller:
typbezeichnung:
variante:
url:
EOF
            ;;
        Ort)
            cat <<EOF
adresse:
googleMaps:
EOF
            ;;
    esac

    echo "---"
}

# Generate content structure based on fileclass
generate_content_structure() {
    local fileclass="$1"
    local title="$2"
    local content="$3"

    echo "# [[$title]]"
    echo ""

    case "$fileclass" in
        Werk)
            echo "## Zusammenfassung"
            echo ""
            echo "$content"
            echo ""
            echo "---"
            echo "## Referenzen"
            echo ""
            ;;
        Memo)
            echo "$content"
            ;;
        Bewerbung)
            echo "## 1 Kontext"
            echo "### 1.1 Stellenbeschreibung"
            echo ""
            echo "$content"
            echo ""
            echo "---"
            echo "## 2 Historie"
            echo "### $(date +%Y-%m-%d)"
            echo ""
            ;;
        Person)
            echo "## 1 Kontext"
            echo ""
            echo "$content"
            echo ""
            echo "---"
            echo "## 2 Aktionen & Historie"
            echo "### $(date +%Y-%m-%d)"
            echo ""
            echo "---"
            echo "## 3 Zur Person / Vita"
            echo ""
            ;;
        Unternehmen)
            echo "## Notizen"
            echo ""
            echo "$content"
            ;;
        Produkt|Ort)
            echo "$content"
            ;;
    esac
}

# Sanitize filename (remove special chars, keep spaces)
sanitize_filename() {
    local name="$1"
    # Remove characters not allowed in filenames, keep spaces and hyphens
    echo "$name" | sed 's/[<>:"/\\|?*]//g' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//'
}

# --- Main ---
DRY_RUN=false
CUSTOM_TAGS=""

# Parse flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            usage
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --tags)
            CUSTOM_TAGS="$2"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

# Validate arguments
if [[ $# -lt 2 ]]; then
    error "Missing arguments. Usage: vault-export.sh <fileclass> <title> [content]"
fi

FILECLASS="$1"
TITLE="$2"
CONTENT="${3:-}"

# Read content from stdin if not provided
if [[ -z "$CONTENT" ]] && [[ ! -t 0 ]]; then
    CONTENT=$(cat)
fi

# Validate
validate_fileclass "$FILECLASS"

if [[ -z "$TITLE" ]]; then
    error "Title cannot be empty"
fi

# Resolve vault path (only if not dry-run)
if [[ "$DRY_RUN" == "false" ]]; then
    VAULT_ROOT=$(get_vault_path) || error "Vault nicht erreichbar. Obsidian starten oder OBSIDIAN_VAULT setzen."
fi

# Generate document
FRONTMATTER=$(generate_frontmatter "$FILECLASS" "$TITLE" "$CUSTOM_TAGS")
BODY=$(generate_content_structure "$FILECLASS" "$TITLE" "$CONTENT")
DOCUMENT="${FRONTMATTER}
${BODY}"

# Output or write
if [[ "$DRY_RUN" == "true" ]]; then
    echo "=== DRY RUN: Would create document ==="
    echo "Fileclass: $FILECLASS"
    echo "Title: $TITLE"
    echo "Target: \$OBSIDIAN_VAULT/$EXPORT_DIR/$(sanitize_filename "$TITLE").md"
    echo "=== Document Content ==="
    echo "$DOCUMENT"
else
    FILENAME=$(sanitize_filename "$TITLE")
    TARGET_PATH="$VAULT_ROOT/$EXPORT_DIR/${FILENAME}.md"

    # Check if file exists
    if [[ -f "$TARGET_PATH" ]]; then
        error "File already exists: $TARGET_PATH. Use different title or delete existing file."
    fi

    # Write file
    echo "$DOCUMENT" > "$TARGET_PATH"
    info "Created: $TARGET_PATH"
    echo "$TARGET_PATH"
fi
