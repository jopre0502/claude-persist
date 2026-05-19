#!/bin/bash
# vault-handoff-backfill.sh — Sync local SESSION-HANDOFF files into _claude-pm/.
#
# Scope (D8: A — Hub-only default):
#   - Reads from $PWD/<docs-path>/handoffs/
#   - Writes into <claude-vault-root>/_claude-pm/
#   - Idempotent: never overwrites existing Vault files
#   - Cross-Project mode (--all-projects) is OPT-IN and warns on filename collisions
#
# Usage:
#   vault-handoff-backfill.sh                    # current project, dry-run if --dry-run
#   vault-handoff-backfill.sh --dry-run          # show what would be copied
#   vault-handoff-backfill.sh --all-projects     # scan all Vault sub-projects (opt-in)
#   vault-handoff-backfill.sh --force-newer      # overwrite Vault when local mtime > vault mtime
#   vault-handoff-backfill.sh --quiet            # suppress per-file output
#
# Exit codes:
#   0 — Success (including zero-op when nothing to copy)
#   1 — PWD not in Claude-Vault (cannot determine target)
#   2 — _claude-pm/ does not exist in Vault root
#   3 — Collision detected in --all-projects mode (some files skipped)

set -uo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly DETECT_SCRIPT="$SCRIPT_DIR/detect-claude-vault.sh"

DRY_RUN=0
ALL_PROJECTS=0
QUIET=0
FORCE_NEWER=0

# ---------------------------------------------------------------------------
# Args
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)       DRY_RUN=1 ;;
    --all-projects)  ALL_PROJECTS=1 ;;
    --force-newer)   FORCE_NEWER=1 ;;
    --quiet)         QUIET=1 ;;
    --help|-h)
      sed -n '2,/^# Exit/p' "$0" | sed 's|^# \?||'
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 64 ;;
  esac
  shift
done

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()  { [[ $QUIET == 1 ]] || echo "$@"; }
warn() { echo "WARN: $*" >&2; }
err()  { echo "ERROR: $*" >&2; }

# Resolve Vault root (global mode = path even if PWD outside)
VAULT_ROOT=$("$DETECT_SCRIPT" --global)
if [[ -z "$VAULT_ROOT" ]]; then
  err "Claude-Vault nicht detektierbar. Ist obsidian.com verfuegbar + Vault 'Claude' registriert?"
  exit 1
fi

CLAUDE_PM_DIR="$VAULT_ROOT/_claude-pm"
if [[ ! -d "$CLAUDE_PM_DIR" ]]; then
  err "_claude-pm/ existiert nicht unter $VAULT_ROOT — Vault-Layout unbekannt."
  exit 2
fi

# Auto-detect docs-path for current project
detect_handoff_dir() {
  local proj_dir="$1"
  for sub in docs/handoffs 90_DOCS/handoffs; do
    if [[ -d "$proj_dir/$sub" ]]; then
      echo "$proj_dir/$sub"
      return 0
    fi
  done
  return 1
}

# ---------------------------------------------------------------------------
# Backfill one project's handoffs
# ---------------------------------------------------------------------------
backfill_project() {
  local proj_dir="$1"
  local proj_name="${proj_dir##*/}"
  local handoff_dir

  if ! handoff_dir=$(detect_handoff_dir "$proj_dir"); then
    log "SKIP $proj_name — kein handoffs/ Verzeichnis"
    return 0
  fi

  local copied=0
  local skipped_existing=0
  local skipped_collision=0

  for src in "$handoff_dir"/SESSION-HANDOFF-*.md; do
    [[ -f "$src" ]] || continue
    local bn="${src##*/}"
    local target="$CLAUDE_PM_DIR/$bn"

    if [[ -f "$target" ]]; then
      # Idempotency: target exists. Hash-Check ob es ein echter Konflikt ist.
      local src_size=$(stat -c %s "$src" 2>/dev/null || stat -f %z "$src")
      local tgt_size=$(stat -c %s "$target" 2>/dev/null || stat -f %z "$target")
      if [[ "$src_size" != "$tgt_size" ]]; then
        if [[ $FORCE_NEWER == 1 ]]; then
          # Use mtime as conflict resolver: local newer -> overwrite
          local src_mtime=$(stat -c %Y "$src" 2>/dev/null || stat -f %m "$src")
          local tgt_mtime=$(stat -c %Y "$target" 2>/dev/null || stat -f %m "$target")
          if [[ $src_mtime -gt $tgt_mtime ]]; then
            if [[ $DRY_RUN == 1 ]]; then
              log "  DRY-FORCE: $proj_name/$bn -> _claude-pm/ (overwrites older Vault version)"
            else
              cp "$src" "$target" && log "  FORCE: $proj_name/$bn -> _claude-pm/ (overwrote older Vault version)"
            fi
            copied=$((copied + 1))
            continue
          else
            warn "$bn: Vault is newer than local — keeping Vault (manual sync if you want local)"
            skipped_collision=$((skipped_collision + 1))
            continue
          fi
        fi
        warn "COLLISION $bn: $proj_name lokal != _claude-pm/ (size differs). Skip — re-run mit --force-newer um neueste Version zu pushen."
        skipped_collision=$((skipped_collision + 1))
      else
        skipped_existing=$((skipped_existing + 1))
      fi
      continue
    fi

    if [[ $DRY_RUN == 1 ]]; then
      log "  DRY: $proj_name/$bn -> _claude-pm/"
    else
      cp "$src" "$target" && log "  COPY: $proj_name/$bn -> _claude-pm/"
    fi
    copied=$((copied + 1))
  done

  log "  $proj_name: copied=$copied existing=$skipped_existing collision=$skipped_collision"

  if [[ $skipped_collision -gt 0 ]]; then
    return 3
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
log "=== Vault-Handoff-Backfill ==="
log "Vault-Root:  $VAULT_ROOT"
log "Target-Dir:  $CLAUDE_PM_DIR"
log "Mode:        $([[ $DRY_RUN == 1 ]] && echo "DRY-RUN" || echo "LIVE")"
log "Scope:       $([[ $ALL_PROJECTS == 1 ]] && echo "ALL PROJECTS" || echo "CURRENT PWD")"
log ""

EXIT_CODE=0

if [[ $ALL_PROJECTS == 1 ]]; then
  for proj_dir in "$VAULT_ROOT"/*/; do
    proj_dir="${proj_dir%/}"
    # Skip internal folders + claude-persist (kein eigener Handoff-Folder)
    case "${proj_dir##*/}" in
      _*|claude-persist) continue ;;
    esac
    backfill_project "$proj_dir" || EXIT_CODE=$?
  done
else
  backfill_project "$PWD" || EXIT_CODE=$?
fi

log ""
log "=== Backfill abgeschlossen ==="

exit $EXIT_CODE
