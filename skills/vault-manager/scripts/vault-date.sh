#!/bin/bash
#
# vault-date.sh - Date-Range Vault Search
# Searches Obsidian Vault documents by date fields in YAML frontmatter.
#
# Usage:
#   vault-date.sh --last 7d                        # Documents from last 7 days
#   vault-date.sh --last 30d --field modified       # Modified in last 30 days
#   vault-date.sh --from 2026-01-01                 # Since Jan 1st
#   vault-date.sh --from 2026-01-01 --to 2026-01-31  # January only
#   vault-date.sh --last 7d --field file.mtime      # Filesystem mtime
#
# Supported date fields:
#   erstellt     (default) - Creation date in frontmatter
#   modified     - Modified date in frontmatter (set by vault-edit.sh)
#   datum        - Generic date field
#   file.mtime   - Filesystem modification time (no frontmatter needed)
#
# Date formats recognized:
#   YYYY-MM-DD
#   YYYY-MM-DD HH:MM
#   YYYY-MM-DDTHH:MM
#
# Duration units for --last:
#   d = days, w = weeks, m = months

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/vault-lib.sh"
VAULT_PATH=$(get_vault_path) || { echo -e "\033[0;31mError: Vault nicht erreichbar. Obsidian starten oder OBSIDIAN_VAULT setzen.\033[0m"; exit 1; }

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Validate vault path (already resolved by get_vault_path, but extra safety)
if [ ! -d "$VAULT_PATH" ]; then
    echo -e "${RED}Error: Vault path not found: $VAULT_PATH${NC}"
    exit 1
fi

# Exclude pattern (shared with vault-tags.sh)
EXCLUDE_PATTERN='/.obsidian/\|/.trash/\|/.claude/\|/10 ARCHIV/'

# --- Argument Parsing ---

FIELD="erstellt"
FROM_DATE=""
TO_DATE=""
LAST_DURATION=""

show_usage() {
    echo "vault-date.sh - Date-Range Vault Search"
    echo ""
    echo "Usage:"
    echo "  vault-date.sh --last <duration>             Documents from last N days/weeks/months"
    echo "  vault-date.sh --from <YYYY-MM-DD>           Documents since date"
    echo "  vault-date.sh --from <date> --to <date>     Documents in date range"
    echo ""
    echo "Options:"
    echo "  --field <name>    Date field to filter (default: erstellt)"
    echo "                    Options: erstellt, modified, datum, file.mtime"
    echo "  --last <Nd|Nw|Nm> Relative duration (7d, 2w, 3m)"
    echo "  --from <date>     Start date (YYYY-MM-DD)"
    echo "  --to <date>       End date (YYYY-MM-DD, default: today)"
    echo ""
    echo "Examples:"
    echo "  vault-date.sh --last 7d"
    echo "  vault-date.sh --last 30d --field modified"
    echo "  vault-date.sh --from 2026-01-01 --to 2026-01-31"
    echo "  vault-date.sh --last 2w --field file.mtime"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --field)
            FIELD="${2:?Error: --field requires a value}"
            shift 2
            ;;
        --from)
            FROM_DATE="${2:?Error: --from requires a date (YYYY-MM-DD)}"
            shift 2
            ;;
        --to)
            TO_DATE="${2:?Error: --to requires a date (YYYY-MM-DD)}"
            shift 2
            ;;
        --last)
            LAST_DURATION="${2:?Error: --last requires a duration (e.g. 7d, 2w, 3m)}"
            shift 2
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_usage
            ;;
    esac
done

# Validate: at least --last or --from required
if [ -z "$LAST_DURATION" ] && [ -z "$FROM_DATE" ]; then
    echo -e "${RED}Error: Specify --last <duration> or --from <date>${NC}"
    echo ""
    show_usage
fi

# --- Duration to date conversion ---

parse_duration_to_date() {
    local dur="$1"
    local num="${dur%[dwmDWM]}"
    local unit="${dur##*[0-9]}"

    if ! [[ "$num" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error: Invalid duration '$dur'. Use format: 7d, 2w, 3m${NC}" >&2
        exit 1
    fi

    # Portable date: macOS (BSD) uses -v, GNU (Linux/Git Bash) uses -d
    if [[ "$(uname -s)" == "Darwin" ]]; then
        case "$unit" in
            d|D) date -v-${num}d +%Y-%m-%d ;;
            w|W) date -v-$(( num * 7 ))d +%Y-%m-%d ;;
            m|M) date -v-${num}m +%Y-%m-%d ;;
            *)
                echo -e "${RED}Error: Unknown unit '$unit'. Use d (days), w (weeks), m (months)${NC}" >&2
                exit 1
                ;;
        esac
    else
        case "$unit" in
            d|D) date -d "$num days ago" +%Y-%m-%d ;;
            w|W) date -d "$((num * 7)) days ago" +%Y-%m-%d ;;
            m|M) date -d "$num months ago" +%Y-%m-%d ;;
            *)
                echo -e "${RED}Error: Unknown unit '$unit'. Use d (days), w (weeks), m (months)${NC}" >&2
                exit 1
                ;;
        esac
    fi
}

# Resolve dates
if [ -n "$LAST_DURATION" ]; then
    FROM_DATE=$(parse_duration_to_date "$LAST_DURATION")
fi
if [ -z "$TO_DATE" ]; then
    TO_DATE=$(date +%Y-%m-%d)
fi

# Validate date format
validate_date() {
    local d="$1"
    local label="$2"
    if ! [[ "$d" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo -e "${RED}Error: Invalid $label date '$d'. Use YYYY-MM-DD format.${NC}"
        exit 1
    fi
}
validate_date "$FROM_DATE" "from"
validate_date "$TO_DATE" "to"

echo -e "${BLUE}Searching:${NC} $FIELD between $FROM_DATE and $TO_DATE"
echo ""

# --- Search by file.mtime (filesystem) ---

search_by_mtime() {
    # Use find with -newermt for date range
    local results
    results=$(find "$VAULT_PATH" -type f -name "*.md" \
        -newermt "$FROM_DATE" ! -newermt "$TO_DATE 23:59:59" \
        2>/dev/null \
        | grep -v "$EXCLUDE_PATTERN" \
        | sort || true)

    output_results "$results"
}

# --- Search by frontmatter field ---

search_by_frontmatter() {
    local field="$1"

    # Awk script: extract date value from frontmatter field
    # Field name passed via -v field="..." (not ENVIRON — pipeline scope issue)
    local AWK_DATE_PARSER
    AWK_DATE_PARSER='
    FNR==1 { in_fm=0 }
    FNR==1 && /^---$/ { in_fm=1; next }
    FNR==1 && !/^---$/ { next }
    in_fm && /^---$/ { in_fm=0; next }
    !in_fm { next }
    in_fm {
        pat = "^" field ":"
        if ($0 ~ pat) {
            val = $0
            sub("^" field ":[[:space:]]*", "", val)
            # Normalize: strip time portion, keep YYYY-MM-DD
            gsub(/T/, " ", val)
            sub(/[[:space:]][0-9][0-9]:[0-9][0-9].*/, "", val)
            # Strip quotes
            gsub(/["'"'"']/, "", val)
            # Trim whitespace
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
            if (val ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) {
                print FILENAME "\t" val
            }
        }
    }
    '

    # Step 1: grep prefilter — find files with the field name
    # Step 2: single awk pass — extract date values (field via -v)
    # Step 3: awk — filter by date range
    local results
    results=$(grep -rl --include="*.md" "${field}:" "$VAULT_PATH" 2>/dev/null \
        | grep -v "$EXCLUDE_PATTERN" \
        | xargs -d '\n' awk -v field="$field" "$AWK_DATE_PARSER" 2>/dev/null \
        | awk -F'\t' -v from="$FROM_DATE" -v to="$TO_DATE" \
            '{ if ($2 >= from && $2 <= to) print $1 }' \
        | sort -u || true)

    output_results "$results"
}

# --- Output ---

output_results() {
    local results="$1"

    if [ -z "$results" ]; then
        echo -e "${YELLOW}No documents found for $FIELD between $FROM_DATE and $TO_DATE${NC}"
        echo ""
        echo "Suggestions:"
        echo "  - Try a wider range: vault-date.sh --last 30d"
        echo "  - Try file.mtime: vault-date.sh --last 7d --field file.mtime"
        echo "  - Check field name: common fields are 'erstellt', 'modified', 'datum'"
        return
    fi

    local count=0
    local vault_prefix="$VAULT_PATH/"
    while IFS= read -r path; do
        echo "  ${path#$vault_prefix}"
        ((count++))
    done <<< "$results"
    echo ""
    echo -e "${GREEN}$count document(s) found${NC} ($FIELD: $FROM_DATE to $TO_DATE)"
}

# --- Dispatch ---

case "$FIELD" in
    file.mtime)
        search_by_mtime
        ;;
    erstellt|modified|datum|created)
        search_by_frontmatter "$FIELD"
        ;;
    *)
        echo -e "${YELLOW}Warning: Non-standard field '$FIELD'. Attempting frontmatter search.${NC}"
        search_by_frontmatter "$FIELD"
        ;;
esac
