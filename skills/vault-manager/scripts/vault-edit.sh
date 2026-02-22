#!/bin/bash
# vault-edit.sh - Edit vault documents with diff preview and backup
# Part of vault-manager skill (UC3: Edit)
#
# Usage: vault-edit.sh [--dry-run] <document-name> <new-content>
#        echo "new content" | vault-edit.sh [--dry-run] <document-name>
#        echo "new content" | vault-edit.sh [--dry-run] --path <full-path>
#
# Features:
#   - Document discovery via obsidian.com CLI search (fallback: find)
#   - Diff preview (old vs new)
#   - Backup before overwrite (.bak)
#   - Automatic 'modified' frontmatter update
#   - --dry-run: show diff without writing
#
# Example:
#   vault-edit.sh "my-document" "Updated content here"
#   vault-edit.sh --dry-run "my-document" "Preview changes"
#   echo "New content" | vault-edit.sh "my-document"

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TODAY=$(date +%Y-%m-%d)

# --- Functions ---
usage() {
    cat <<EOF
Usage: vault-edit.sh [--dry-run] <document-name> [new-content]
       echo "content" | vault-edit.sh [--dry-run] <document-name>
       echo "content" | vault-edit.sh [--dry-run] --path <full-path>

Options:
  --dry-run        Show diff without writing changes
  --path <path>    Use direct file path (skip CLI discovery)
  --help           Show this help

Environment:
  OBSIDIAN_VAULT    Path to Obsidian vault (required)

Examples:
  vault-edit.sh "my-document" "Updated content here"
  vault-edit.sh --dry-run "my-document" "Preview only"
  echo "New content" | vault-edit.sh "my-document"
  echo "New content" | vault-edit.sh --path "/vault/04 RESSOURCEN/doc.md"
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

# Extract frontmatter from file (between --- markers)
extract_frontmatter() {
    local file="$1"
    if head -1 "$file" | grep -q "^---$"; then
        sed -n '1,/^---$/p' "$file" | tail -n +2
        # Get second --- line number
        local end_line
        end_line=$(grep -n "^---$" "$file" | sed -n '2p' | cut -d: -f1)
        if [ -n "$end_line" ]; then
            head -n "$end_line" "$file" | tail -n +2 | head -n -1
        fi
    fi
}

# Get content after frontmatter
get_content_after_frontmatter() {
    local file="$1"
    local marker_count
    marker_count=$(grep -c "^---$" "$file" || true)

    if [ "$marker_count" -lt 2 ]; then
        cat "$file"
    else
        local end_line
        end_line=$(grep -n "^---$" "$file" | sed -n '2p' | cut -d: -f1)
        tail -n +"$((end_line + 1))" "$file"
    fi
}

# Update or add 'modified' field in frontmatter
update_modified_frontmatter() {
    local file="$1"
    local date="$2"

    if grep -q "^modified:" "$file"; then
        # Update existing modified field
        sed -i "s/^modified:.*$/modified: $date/" "$file"
    else
        # Add modified after 'erstellt:' if it exists, otherwise after first ---
        if grep -q "^erstellt:" "$file"; then
            sed -i "/^erstellt:/a modified: $date" "$file"
        else
            sed -i "0,/^---$/!{0,/^---$/s/^---$/modified: $date\n---/}" "$file"
        fi
    fi
}

# --- Main ---
DRY_RUN=false
DIRECT_PATH=""

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
        --path)
            if [[ $# -lt 2 ]]; then
                error "--path requires a file path argument"
            fi
            DIRECT_PATH="$2"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

# Validate arguments (--path mode vs cold-start mode)
if [[ -n "$DIRECT_PATH" ]]; then
    # Warm-Path: no DOC_NAME needed, content from $1 or stdin
    DOC_NAME=""
    NEW_CONTENT="${1:-}"
else
    # Cold-Start: DOC_NAME required
    if [[ $# -lt 1 ]]; then
        error "Missing arguments. Usage: vault-edit.sh [--dry-run] <document-name> [new-content]"
    fi
    DOC_NAME="$1"
    NEW_CONTENT="${2:-}"
fi

# Read content from stdin if not provided as argument
if [[ -z "$NEW_CONTENT" ]] && [[ ! -t 0 ]]; then
    NEW_CONTENT=$(cat)
fi

if [[ -z "$NEW_CONTENT" ]]; then
    error "No new content provided. Pass as argument or pipe via stdin."
fi

# Check vault path
if [[ -z "${OBSIDIAN_VAULT:-}" ]]; then
    error "OBSIDIAN_VAULT environment variable not set."
fi

# --- Step 1: Find document ---
if [[ -n "$DIRECT_PATH" ]]; then
    # Warm-Path: skip discovery, use direct path
    DOC_PATH="$DIRECT_PATH"
    if [[ ! -f "$DOC_PATH" ]]; then
        error "File not found: $DOC_PATH"
    fi
    info "Direct path: $DOC_PATH"
else
    # Cold-Start: discover via CLI (primary) or find (fallback)
    # Strip vault: prefix if present
    DOC_NAME=$(echo "$DOC_NAME" | sed 's/^vault://')
    info "Searching for: $DOC_NAME"

    DOC_PATH=""

    # Primary: obsidian.com CLI file command (returns path + metadata)
    if command -v obsidian.com &>/dev/null; then
        CLI_PATH=$(obsidian.com file file="$DOC_NAME" 2>/dev/null \
            | grep -oP '(?<=^path:\s).*' | head -1) || true
        if [[ -n "$CLI_PATH" && -f "$CLI_PATH" ]]; then
            DOC_PATH="$CLI_PATH"
            info "Found via CLI: $DOC_PATH"
        fi
    fi

    # Fallback: filesystem search (exact match, then partial)
    if [[ -z "$DOC_PATH" ]]; then
        info "CLI unavailable or no match, using filesystem search"
        DOC_PATH=$(find "$OBSIDIAN_VAULT" -type f \
            -name "${DOC_NAME}.md" \
            ! -path "*/.obsidian/*" ! -path "*/.trash/*" \
            -print -quit 2>/dev/null) || true

        # Partial match fallback
        if [[ -z "$DOC_PATH" ]]; then
            DOC_PATH=$(find "$OBSIDIAN_VAULT" -type f \
                -iname "*${DOC_NAME}*.md" \
                ! -path "*/.obsidian/*" ! -path "*/.trash/*" \
                2>/dev/null | head -1) || true
        fi
    fi

    if [[ -z "$DOC_PATH" || ! -f "$DOC_PATH" ]]; then
        error "Document not found: $DOC_NAME"
    fi

    info "Found: $DOC_PATH"
fi

# --- Step 2: Read existing content ---
EXISTING_CONTENT=$(cat "$DOC_PATH")
EXISTING_BODY=$(get_content_after_frontmatter "$DOC_PATH")

# --- Step 3: Build new document ---
# Preserve frontmatter, replace body content
if head -1 "$DOC_PATH" | grep -q "^---$"; then
    # Has frontmatter - preserve it
    FRONTMATTER_END=$(grep -n "^---$" "$DOC_PATH" | sed -n '2p' | cut -d: -f1)
    FRONTMATTER_BLOCK=$(head -n "$FRONTMATTER_END" "$DOC_PATH")
    NEW_DOCUMENT="${FRONTMATTER_BLOCK}
${NEW_CONTENT}"
else
    # No frontmatter
    NEW_DOCUMENT="$NEW_CONTENT"
fi

# --- Step 4: Show diff ---
TEMP_OLD=$(mktemp)
TEMP_NEW=$(mktemp)
trap 'rm -f "$TEMP_OLD" "$TEMP_NEW"' EXIT

echo "$EXISTING_CONTENT" > "$TEMP_OLD"
echo "$NEW_DOCUMENT" > "$TEMP_NEW"

REL_PATH="${DOC_PATH#${OBSIDIAN_VAULT}/}"

echo "=== DIFF: $REL_PATH ==="
echo ""

DIFF_OUTPUT=$(diff --unified=3 "$TEMP_OLD" "$TEMP_NEW" || true)

if [[ -z "$DIFF_OUTPUT" ]]; then
    info "No changes detected. Document is identical."
    exit 0
fi

echo "$DIFF_OUTPUT"
echo ""
echo "=== END DIFF ==="

# --- Step 5: Write (or dry-run) ---
if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    info "DRY RUN - no changes written."
    info "Target: $DOC_PATH"
    exit 0
fi

# Create backup
BACKUP_PATH="${DOC_PATH}.bak"
cp "$DOC_PATH" "$BACKUP_PATH"
info "Backup created: $BACKUP_PATH"

# Write new content
echo "$NEW_DOCUMENT" > "$DOC_PATH"

# Update modified frontmatter
update_modified_frontmatter "$DOC_PATH" "$TODAY"

info "Document updated: $DOC_PATH"
info "Modified date set to: $TODAY"
echo "$DOC_PATH"
