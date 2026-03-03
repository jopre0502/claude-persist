#!/bin/bash
#
# vault-base.sh — Obsidian Base Query Engine
# Parses .base files and executes filter queries via existing vault-manager scripts.
#
# Usage:
#   vault-base.sh <name>              Execute base query, return matching documents
#   vault-base.sh --list              List all .base files in vault
#   vault-base.sh --explain <name>    Show parsed filters (human-readable)
#
# Supported filters (MVP):
#   property == "value"               Frontmatter equality
#   file.tags.containsAny("a","b")    Tag search (→ obsidian.com tag / grep fallback)
#   file.hasTag("tag")                Tag search (→ obsidian.com tag / grep fallback)
#   !property.isEmpty()               Property exists and non-empty
#   property <= today()               Date comparison
#   file.ctime/mtime == today()       Filesystem date
#   space == "value"                  Frontmatter space match
#   and:/or: conjunctions             Set intersection/union
#
# Unsupported filters (Phase 6+): .format(), formula., list(), date(), nested expressions

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/vault-lib.sh"
VAULT_PATH=$(get_vault_path) || { echo -e "\033[0;31m[ERROR] Vault nicht erreichbar. Obsidian starten oder OBSIDIAN_VAULT setzen.\033[0m" >&2; exit 1; }

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'
YELLOW='\033[0;33m'; NC='\033[0m'
EXCLUDE_PATTERN='/.obsidian/\|/.trash/\|/.claude/\|/10 ARCHIV/'

error() { echo -e "${RED}[ERROR] $1${NC}" >&2; exit 1; }
info() { echo "[INFO] $1" >&2; }
warn() { echo -e "${YELLOW}[WARN] $1${NC}" >&2; }

show_usage() {
    cat <<'EOF'
vault-base.sh — Obsidian Base Query Engine

Usage:
  vault-base.sh <name>              Execute base query, return matching documents
  vault-base.sh --list              List all .base files in vault
  vault-base.sh --explain <name>    Show parsed filters (human-readable)
  vault-base.sh --help              Show this help

Arguments:
  <name>    Name or partial name of a .base file (case-insensitive)

Environment:
  OBSIDIAN_VAULT    Path to Obsidian vault (optional fallback, CLI-primary)

Examples:
  vault-base.sh Bewerbungen         Run Bewerbungen_Dashboard query
  vault-base.sh --list              List all base files
  vault-base.sh --explain "Space AI"  Show filter details
EOF
    exit 0
}

# Validate vault
[[ ! -d "$VAULT_PATH" ]] && error "Vault path not found: $VAULT_PATH"

# --- Base Discovery ---

find_base_file() {
    local name="$1" exact="" partial=""
    while IFS= read -r path; do
        local base="${path##*/}"
        base="${base%.base}"
        if [[ "${base,,}" == "${name,,}" ]]; then
            echo "$path"; return 0
        fi
        [[ -z "$partial" ]] && partial="$path"
    done < <(find "$VAULT_PATH" -iname "*${name}*.base" -type f 2>/dev/null)
    [[ -n "$partial" ]] && { echo "$partial"; return 0; }
    return 1
}

# --- YAML Filter Parser ---
# Extracts filter blocks: BLOCK:name, CONJ:and/or, EXPR:expression

parse_filters() {
    awk '
    BEGIN { in_f=0; lvl="" }
    /^filters:/ { in_f=1; lvl="T"; print "BLOCK:_top_"; next }
    in_f && lvl=="T" && /^  (and|or):/ {
        c=$0; gsub(/[[:space:]:]+/, "", c); print "CONJ:" c; next }
    in_f && lvl=="T" && /^    - / {
        line=$0; sub(/^    - /, "", line)
        if (line ~ /^["'"'"']/ && line ~ /["'"'"']$/) line=substr(line,2,length(line)-2)
        print "EXPR:" line; next }
    in_f && lvl=="T" && /^[^ ]/ { in_f=0 }
    /^    name:/ { vn=$0; sub(/^    name:[[:space:]]*/, "", vn) }
    /^    filters:/ { in_f=1; lvl="V"; print "BLOCK:" vn; next }
    in_f && lvl=="V" && /^      (and|or):/ {
        c=$0; gsub(/[[:space:]:]+/, "", c); print "CONJ:" c; next }
    in_f && lvl=="V" && /^        - / {
        line=$0; sub(/^        - /, "", line)
        if (line ~ /^["'"'"']/ && line ~ /["'"'"']$/) line=substr(line,2,length(line)-2)
        print "EXPR:" line; next }
    in_f && lvl=="V" && /^    [a-z]/ && !/^      / { in_f=0 }
    ' "$1"
}

# --- Filter Execution ---
# Each function outputs matching absolute paths on stdout

filter_frontmatter_eq() {
    local prop="$1" val="$2"
    grep -rl --include="*.md" "${prop}:" "$VAULT_PATH" 2>/dev/null \
        | grep -v "$EXCLUDE_PATTERN" \
        | xargs -d '\n' awk -v prop="$prop" -v val="$val" '
        FNR==1 { in_fm=0 }
        FNR==1 && /^---$/ { in_fm=1; next }
        FNR==1 && !/^---$/ { nextfile }
        in_fm && /^---$/ { nextfile }
        !in_fm { next }
        in_fm {
            pat = "^" prop ":"
            if ($0 ~ pat) {
                v=$0; sub("^" prop ":[[:space:]]*", "", v)
                gsub(/["'"'"']/, "", v)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
                if (tolower(v) == tolower(val)) { print FILENAME; nextfile }
            }
        }' 2>/dev/null
}

filter_frontmatter_notempty() {
    local prop="$1"
    grep -rl --include="*.md" "${prop}:" "$VAULT_PATH" 2>/dev/null \
        | grep -v "$EXCLUDE_PATTERN" \
        | xargs -d '\n' awk -v prop="$prop" '
        FNR==1 { in_fm=0 }
        FNR==1 && /^---$/ { in_fm=1; next }
        FNR==1 && !/^---$/ { nextfile }
        in_fm && /^---$/ { nextfile }
        !in_fm { next }
        in_fm {
            pat = "^" prop ":"
            if ($0 ~ pat) {
                v=$0; sub("^" prop ":[[:space:]]*", "", v)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
                if (v != "" && v != "null" && v != "[]") { print FILENAME; nextfile }
            }
        }' 2>/dev/null
}

filter_frontmatter_date_cmp() {
    local prop="$1" op="$2" ref_date="$3"
    grep -rl --include="*.md" "${prop}:" "$VAULT_PATH" 2>/dev/null \
        | grep -v "$EXCLUDE_PATTERN" \
        | xargs -d '\n' awk -v prop="$prop" -v op="$op" -v ref="$ref_date" '
        FNR==1 { in_fm=0 }
        FNR==1 && /^---$/ { in_fm=1; next }
        FNR==1 && !/^---$/ { nextfile }
        in_fm && /^---$/ { nextfile }
        !in_fm { next }
        in_fm {
            pat = "^" prop ":"
            if ($0 ~ pat) {
                v=$0; sub("^" prop ":[[:space:]]*", "", v)
                gsub(/T/, " ", v); sub(/[[:space:]][0-9][0-9]:[0-9][0-9].*/, "", v)
                gsub(/["'"'"']/, "", v)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
                if (v ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) {
                    if (op == "<=" && v <= ref) { print FILENAME; nextfile }
                    if (op == ">=" && v >= ref) { print FILENAME; nextfile }
                    if (op == "<" && v < ref) { print FILENAME; nextfile }
                    if (op == ">" && v > ref) { print FILENAME; nextfile }
                    if (op == "==" && v == ref) { print FILENAME; nextfile }
                }
            }
        }' 2>/dev/null
}

filter_tags() {
    local tags_csv="$1"
    echo "$tags_csv" | tr ',' '\n' | while read -r tag; do
        tag="${tag#"${tag%%[![:space:]]*}"}"; tag="${tag#\"}"; tag="${tag%\"}"; tag="${tag%"${tag##*[![:space:]]}"}"
        [[ -z "$tag" ]] && continue

        # Primary: obsidian.com CLI tag search (10x faster, uses internal index)
        if command -v obsidian.com &>/dev/null; then
            local cli_result
            cli_result=$(obsidian.com tag name="$tag" verbose 2>/dev/null) || true
            if [[ -n "$cli_result" ]]; then
                # CLI outputs relative paths — prepend vault path, filter .md files
                echo "$cli_result" | grep '\.md' | while IFS= read -r line; do
                    line="${line#"${line%%[![:space:]]*}"}"
                    [[ -z "$line" ]] && continue
                    if [[ "$line" == /* ]]; then
                        echo "$line"
                    else
                        echo "$VAULT_PATH/$line"
                    fi
                done
                continue
            fi
        fi

        # Fallback: grep-based tag search (works without running Obsidian)
        grep -rl --include="*.md" -i "tags:.*$tag\|  - $tag" "$VAULT_PATH" 2>/dev/null \
            | grep -v "$EXCLUDE_PATTERN" | sort -u
    done
}

# Dispatch: classify expression and run appropriate filter
exec_filter() {
    local expr="$1"

    # property == "value" / property == value / property == ["[[Name]]"]
    if [[ "$expr" =~ ^([a-zA-Z_.]+)[[:space:]]*==[[:space:]]*(.*) ]]; then
        local prop="${BASH_REMATCH[1]}" val="${BASH_REMATCH[2]}"
        val="${val#\"}" ; val="${val%\"}"
        # Unwrap ["[[Name]]"] or ["Name"]
        if [[ "$val" == \[* ]]; then
            val="${val#\[}" ; val="${val%\]}"
            val="${val#\"}" ; val="${val%\"}"
            val="${val#\[\[}" ; val="${val%\]\]}"
        fi
        if [[ "$val" == "today()" ]]; then
            local today; today=$(date +%Y-%m-%d)
            case "$prop" in
                file.ctime|file.mtime)
                    find "$VAULT_PATH" -name "*.md" -type f \
                        -newermt "$today" ! -newermt "$today 23:59:59" \
                        2>/dev/null | grep -v "$EXCLUDE_PATTERN"
                    return 0 ;;
                *) filter_frontmatter_date_cmp "$prop" "==" "$today"; return 0 ;;
            esac
        fi
        [[ "$prop" == "file.ext" ]] && {
            find "$VAULT_PATH" -name "*.$val" -type f 2>/dev/null \
                | grep -v "$EXCLUDE_PATTERN"; return 0; }
        filter_frontmatter_eq "$prop" "$val"
        return 0
    fi

    # file.tags.containsAny("a", "b", "c")
    if [[ "$expr" =~ file\.tags\.containsAny\((.+)\) ]]; then
        filter_tags "${BASH_REMATCH[1]}"; return 0
    fi

    # file.hasTag("tag")
    if [[ "$expr" =~ file\.hasTag\(\"([^\"]+)\"\) ]]; then
        filter_tags "\"${BASH_REMATCH[1]}\""; return 0
    fi

    # !property.isEmpty()
    if [[ "$expr" =~ ^\!([a-zA-Z_.]+)\.isEmpty\(\) ]]; then
        filter_frontmatter_notempty "${BASH_REMATCH[1]}"; return 0
    fi

    # property <= today() / property < today() etc.
    if [[ "$expr" =~ ^([a-zA-Z_.]+)[[:space:]]*(<=|>=|\<|\>)[[:space:]]*today\(\) ]]; then
        local today; today=$(date +%Y-%m-%d)
        filter_frontmatter_date_cmp "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "$today"
        return 0
    fi

    # Unsupported
    warn "Unsupported: $expr"
    return 1
}

# --- Conjunction Logic ---

run_filter_block() {
    local conjunction="$1"; shift
    local tmpdir; tmpdir=$(mktemp -d)
    local idx=0 skipped=0

    for expr in "$@"; do
        ((idx++))
        local outfile="$tmpdir/f_${idx}.txt"
        if exec_filter "$expr" 2>/dev/null | sort -u > "$outfile"; then
            local cnt=0; while IFS= read -r _; do ((cnt++)); done < "$outfile"
            info "Filter $idx: '$expr' → $cnt matches"
        else
            ((skipped++))
            rm -f "$outfile"
        fi
    done

    # Combine results
    local -a files=("$tmpdir"/f_*.txt)
    if [[ ! -f "${files[0]:-}" ]]; then
        warn "No executable filters produced results"
        rm -rf "$tmpdir"
        return 1
    fi

    local combined="$tmpdir/result.txt"
    if [[ "$conjunction" == "and" ]]; then
        cp "${files[0]}" "$combined"
        for ((i=1; i<${#files[@]}; i++)); do
            [[ -f "${files[$i]}" ]] || continue
            comm -12 "$combined" "${files[$i]}" > "$tmpdir/tmp.txt"
            mv "$tmpdir/tmp.txt" "$combined"
        done
    else
        cat "${files[@]}" | sort -u > "$combined"
    fi

    local total=0
    while IFS= read -r path; do
        [[ -z "$path" ]] && continue
        echo "  ${path#$VAULT_PATH/}"
        ((total++))
    done < "$combined"

    echo ""
    echo -e "${GREEN}$total document(s) matched${NC} (conjunction: $conjunction, filters: $idx, skipped: $skipped)"
    rm -rf "$tmpdir"
}

# --- Commands ---

cmd_list() {
    echo -e "${BLUE}Base files in vault:${NC}"
    echo ""
    local count=0
    while IFS= read -r path; do
        printf "  %s\n" "${path#$VAULT_PATH/}"
        ((count++))
    done < <(find "$VAULT_PATH" -name "*.base" -type f 2>/dev/null | sort)
    echo ""
    echo -e "${GREEN}$count base file(s) found${NC}"
}

cmd_explain() {
    local base_file="$1"
    echo -e "${BLUE}Base:${NC} ${base_file#$VAULT_PATH/}"
    echo ""
    local parsed; parsed=$(parse_filters "$base_file")
    [[ -z "$parsed" ]] && { echo "  (no filters found)"; return; }
    while IFS= read -r line; do
        case "$line" in
            BLOCK:_top_) echo "  Global Filters:" ;;
            BLOCK:*) echo "  View '${line#BLOCK:}' Filters:" ;;
            CONJ:*) echo "    Conjunction: ${line#CONJ:}" ;;
            EXPR:*)
                local e="${line#EXPR:}" s="supported"
                if echo "$e" | grep -qE '\.format\(|formula\.|list\(|date\(|complete_instances|blockedBy|file\(|recurrence'; then
                    s="unsupported"
                fi
                [[ "$s" == "supported" ]] && echo "    [ok] $e" || echo "    [--] $e  (Phase 6+)" ;;
        esac
    done <<< "$parsed"
}

cmd_execute() {
    local base_file="$1"
    echo -e "${BLUE}Executing:${NC} ${base_file#$VAULT_PATH/}"
    echo ""
    local parsed; parsed=$(parse_filters "$base_file")
    [[ -z "$parsed" ]] && { warn "No filters found"; return 1; }

    # Collect first filter block
    local conjunction="and"
    local -a expressions=()
    local found=false

    while IFS= read -r line; do
        case "$line" in
            BLOCK:*)
                if [[ "$found" == true && ${#expressions[@]} -gt 0 ]]; then break; fi
                found=true; expressions=() ;;
            CONJ:*) conjunction="${line#CONJ:}" ;;
            EXPR:*) expressions+=("${line#EXPR:}") ;;
        esac
    done <<< "$parsed"

    [[ ${#expressions[@]} -eq 0 ]] && { warn "No filters to execute"; return 1; }
    info "Conjunction: $conjunction, ${#expressions[@]} filter(s)"
    run_filter_block "$conjunction" "${expressions[@]}"
}

# --- Main ---
case "${1:-}" in
    --help|-h) show_usage ;;
    --list) cmd_list ;;
    --explain)
        [[ -z "${2:-}" ]] && error "Usage: vault-base.sh --explain <name>"
        bf=$(find_base_file "$2") || error "Base not found: $2"
        cmd_explain "$bf" ;;
    "") show_usage ;;
    *)
        bf=$(find_base_file "$1") || error "Base not found: $1"
        cmd_execute "$bf" ;;
esac
