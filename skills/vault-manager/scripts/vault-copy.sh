#!/bin/bash
# vault-copy.sh - Copy or move files into/within Obsidian Vault
# Part of vault-manager skill (CLI+Bash Hybrid — ADR-005)
#
# Usage: vault-copy.sh <source> [target-folder] [--move] [--dry-run] [--force]
#
# Source can be:
#   - Absolute path:  /tmp/report.md (external file)
#   - vault: prefix:  vault:document-name (vault-internal, resolved via CLI)
#   - Document name:  "my-document" (vault-internal, resolved via CLI)
#
# Example:
#   vault-copy.sh /tmp/report.md                              # External → Vault
#   vault-copy.sh /tmp/report.md "03-Spaces/Gesundheit" --move
#   vault-copy.sh vault:my-document "03-Spaces/" --move       # Vault-internal move
#   vault-copy.sh "my-document" "00-Inbox" --move             # Vault-internal move
#   vault-copy.sh /tmp/report.md --dry-run

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/vault-lib.sh"
VAULT_ROOT=""  # resolved later (after --dry-run check)
DEFAULT_TARGET="04 RESSOURCEN"

# --- Functions ---
usage() {
    cat <<EOF
Usage: vault-copy.sh <source> [target-folder] [--move] [--dry-run] [--force]

Copy or move files into or within the Obsidian Vault.

Arguments:
  <source>         File path, vault: reference, or document name (required)
                   - Absolute path: /tmp/report.md (external file)
                   - vault: prefix: vault:document-name (vault-internal)
                   - Document name: "my-document" (vault-internal, no .md needed)
  [target-folder]  Target folder relative to \$OBSIDIAN_VAULT (default: "$DEFAULT_TARGET")

Options:
  --move       Remove source file after copy (mv instead of cp)
  --dry-run    Show what would happen without writing
  --force      Overwrite existing file at target (default: error on collision)
  --help       Show this help

Environment:
  OBSIDIAN_VAULT    Path to Obsidian vault (optional fallback, CLI-primary)

Examples:
  vault-copy.sh /tmp/report.md                          # External -> Vault
  vault-copy.sh /tmp/report.md "03-Spaces/Gesundheit"
  vault-copy.sh vault:my-document "00-Inbox" --move     # Vault-internal move
  vault-copy.sh "my-document" "03-Spaces/" --move       # Vault-internal move
  vault-copy.sh /tmp/report.md --dry-run
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

# --- Argument Parsing ---
DRY_RUN=false
MOVE=false
FORCE=false
SOURCE=""
TARGET_FOLDER=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            usage
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --move)
            MOVE=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -*)
            error "Unknown option: $1. Use --help for usage."
            ;;
        *)
            if [[ -z "$SOURCE" ]]; then
                SOURCE="$1"
            elif [[ -z "$TARGET_FOLDER" ]]; then
                TARGET_FOLDER="$1"
            else
                error "Too many arguments. Use --help for usage."
            fi
            shift
            ;;
    esac
done

TARGET_FOLDER="${TARGET_FOLDER:-$DEFAULT_TARGET}"

# --- Validation ---
if [[ -z "$SOURCE" ]]; then
    error "Missing source. Usage: vault-copy.sh <source> [target-folder]"
fi

if [[ "$DRY_RUN" == "true" ]]; then
    VAULT_ROOT=$(get_vault_path 2>/dev/null) || VAULT_ROOT="<VAULT>"
else
    VAULT_ROOT=$(get_vault_path) || error "Vault nicht erreichbar. Obsidian starten oder OBSIDIAN_VAULT setzen."
fi

# --- Source Resolution (CLI+Bash Hybrid — ADR-005) ---
# Detect if source is an absolute path or a vault reference
if [[ "$SOURCE" == /* ]] && [[ -f "$SOURCE" ]]; then
    # Absolute path to existing file (external or vault-internal)
    SOURCE_PATH="$SOURCE"
    info "Source: $SOURCE_PATH (absolute path)"
else
    # Vault reference: strip vault: prefix, resolve via CLI + find fallback
    DOC_NAME=$(echo "$SOURCE" | sed 's/^vault://')
    info "Resolving vault document: $DOC_NAME"

    SOURCE_PATH=""

    # Primary: obsidian.com CLI search (uses Obsidian's internal index)
    if command -v obsidian.com &>/dev/null; then
        CLI_PATH=$(obsidian.com file file="$DOC_NAME" 2>/dev/null \
            | grep -oP '(?<=^path:\s).*' | head -1) || true
        if [[ -n "$CLI_PATH" && -f "$CLI_PATH" ]]; then
            SOURCE_PATH="$CLI_PATH"
            info "Found via CLI: $SOURCE_PATH"
        fi
    fi

    # Fallback: filesystem search (exact match, then partial)
    if [[ -z "$SOURCE_PATH" ]] && [[ "$VAULT_ROOT" != "<VAULT>" ]]; then
        info "CLI unavailable or no match, using filesystem search"
        SOURCE_PATH=$(find "$VAULT_ROOT" -type f \
            -name "${DOC_NAME}.md" \
            ! -path "*/.obsidian/*" ! -path "*/.trash/*" \
            -print -quit 2>/dev/null) || true

        if [[ -z "$SOURCE_PATH" ]]; then
            SOURCE_PATH=$(find "$VAULT_ROOT" -type f \
                -iname "*${DOC_NAME}*.md" \
                ! -path "*/.obsidian/*" ! -path "*/.trash/*" \
                2>/dev/null | head -1) || true
        fi
    fi

    if [[ -z "$SOURCE_PATH" ]] || { [[ "$DRY_RUN" == "false" ]] && [[ ! -f "$SOURCE_PATH" ]]; }; then
        error "Source not found: $SOURCE (tried CLI search + filesystem)"
    fi

    info "Resolved: $SOURCE_PATH"
fi

TARGET_DIR="$VAULT_ROOT/$TARGET_FOLDER"

if [[ "$DRY_RUN" == "false" ]] && [[ ! -d "$TARGET_DIR" ]]; then
    error "Target directory does not exist: $TARGET_DIR"
fi

# --- Build target path ---
FILENAME=$(basename "$SOURCE_PATH")
TARGET_PATH="$TARGET_DIR/$FILENAME"

# --- Collision Detection ---
if [[ "$DRY_RUN" == "false" ]] && [[ -f "$TARGET_PATH" ]] && [[ "$FORCE" == "false" ]]; then
    error "Target file already exists: $TARGET_PATH (use --force to overwrite)"
fi

# --- Execute ---
ACTION="Copy"
[[ "$MOVE" == "true" ]] && ACTION="Move"

if [[ "$DRY_RUN" == "true" ]]; then
    echo "=== DRY RUN ==="
    echo "Action:  $ACTION"
    echo "Source:  $SOURCE_PATH"
    echo "Target:  $TARGET_PATH"
    [[ -f "$TARGET_PATH" ]] && echo "Warning: Target exists (--force would overwrite)"
    echo "=== No changes made ==="
else
    if [[ "$MOVE" == "true" ]]; then
        mv "$SOURCE_PATH" "$TARGET_PATH"
    else
        cp "$SOURCE_PATH" "$TARGET_PATH"
    fi

    info "${ACTION}: $SOURCE_PATH → $TARGET_PATH"
    echo "$TARGET_PATH"
fi
