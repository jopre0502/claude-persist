#!/bin/bash
# detect-claude-vault.sh — Robust Claude-Vault Detection (Cache-First).
#
# Returns the Claude-Vault root as Unix path, or empty if not detectable.
#
# Strategy (D3: B + Fallback A, with caching):
#   1. Read cache (~1ms)             — TTL 24h, invalidated if dir vanishes
#   2. CLI verify (~1700ms)          — `obsidian.com vault vault=Claude` + cygpath
#   3. Walk-up heuristic (~3ms)      — find .obsidian + path contains "Claude"
#   4. Empty output                  — caller decides skip/error
#
# Modes:
#   detect-claude-vault.sh            # default: vault root iff PWD inside, else empty
#   detect-claude-vault.sh --global   # vault root unconditional (for backfill targeting)
#   detect-claude-vault.sh --in-vault # echo "1" or "0" (for Hook predicates)
#   detect-claude-vault.sh --refresh  # bypass cache, force CLI lookup
#
# Exit: always 0 (decoupled from match; check stdout)

set -uo pipefail

readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-persist"
readonly CACHE_FILE="$CACHE_DIR/vault-claude-root.txt"
readonly CACHE_TTL_HOURS=24
readonly CLI_TIMEOUT=3
readonly MAX_WALK_DEPTH=6

# ---------------------------------------------------------------------------
# Cache helpers
# ---------------------------------------------------------------------------
cache_read() {
  [[ -f "$CACHE_FILE" ]] || return 1

  local mtime_now=$(date +%s)
  local mtime_file
  if [[ "$(uname -s)" == "Darwin" ]]; then
    mtime_file=$(stat -f %m "$CACHE_FILE" 2>/dev/null) || return 1
  else
    mtime_file=$(stat -c %Y "$CACHE_FILE" 2>/dev/null) || return 1
  fi

  local age_hours=$(( (mtime_now - mtime_file) / 3600 ))
  [[ $age_hours -lt $CACHE_TTL_HOURS ]] || return 1

  local cached_path
  cached_path=$(<"$CACHE_FILE")
  [[ -n "$cached_path" && -d "$cached_path" ]] || return 1

  echo "$cached_path"
  return 0
}

cache_write() {
  local path="$1"
  mkdir -p "$CACHE_DIR" 2>/dev/null || return 1
  echo "$path" > "$CACHE_FILE"
}

cache_clear() {
  rm -f "$CACHE_FILE"
}

# ---------------------------------------------------------------------------
# Detection: CLI (slow but authoritative)
# ---------------------------------------------------------------------------
detect_via_cli() {
  command -v obsidian.com >/dev/null 2>&1 || return 1

  local raw_path
  raw_path=$(timeout "$CLI_TIMEOUT" obsidian.com vault vault=Claude 2>/dev/null \
    | grep '^path' \
    | cut -f2 \
    | tr -d '\r')

  [[ -n "$raw_path" ]] || return 1

  local unix_path
  if command -v cygpath >/dev/null 2>&1; then
    unix_path=$(cygpath -u "$raw_path" 2>/dev/null) || return 1
  else
    unix_path=$(echo "$raw_path" | sed 's|\\|/|g; s|^\([A-Z]\):|/\L\1|')
  fi

  [[ -d "$unix_path" ]] || return 1
  echo "$unix_path"
}

# ---------------------------------------------------------------------------
# Detection: Walk-up (fast heuristic)
# Matches dirs with .obsidian AND name ending in "Claude" — empirically the convention.
# ---------------------------------------------------------------------------
detect_via_walk() {
  local dir="$PWD"
  local depth=0

  while [[ "$dir" != "/" && "$dir" != "" && $depth -lt $MAX_WALK_DEPTH ]]; do
    if [[ -d "$dir/.obsidian" ]]; then
      case "$dir" in
        */Claude) echo "$dir"; return 0 ;;
      esac
    fi
    dir="${dir%/*}"
    depth=$((depth + 1))
  done

  return 1
}

# ---------------------------------------------------------------------------
# Orchestration: cache → cli → walk
# ---------------------------------------------------------------------------
resolve_vault_root() {
  local force_refresh="${1:-0}"
  local root

  if [[ "$force_refresh" != "1" ]]; then
    if root=$(cache_read); then
      echo "$root"
      return 0
    fi
  fi

  if root=$(detect_via_cli); then
    cache_write "$root"
    echo "$root"
    return 0
  fi

  if root=$(detect_via_walk); then
    cache_write "$root"
    echo "$root"
    return 0
  fi

  return 1
}

# ---------------------------------------------------------------------------
# Output modes
# ---------------------------------------------------------------------------
main() {
  local mode="default"
  local refresh=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --global)    mode="global" ;;
      --in-vault)  mode="in-vault" ;;
      --refresh)   refresh=1 ;;
      --help|-h)
        sed -n '2,/^# Exit/p' "$0" | sed 's|^# \?||'
        exit 0
        ;;
      *) ;;
    esac
    shift
  done

  local vault_root=""
  vault_root=$(resolve_vault_root "$refresh") || true

  case "$mode" in
    global)
      echo "$vault_root"
      ;;
    in-vault)
      if [[ -n "$vault_root" ]]; then
        case "$PWD" in "$vault_root"*) echo 1; return 0 ;; esac
      fi
      echo 0
      ;;
    default)
      if [[ -n "$vault_root" ]]; then
        case "$PWD" in "$vault_root"*) echo "$vault_root"; return 0 ;; esac
      fi
      # else: empty
      ;;
  esac

  return 0
}

main "$@"
