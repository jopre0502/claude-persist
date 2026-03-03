#!/bin/bash
# vault-lib.sh — Shared utilities for vault scripts
# Source this file: source "$(dirname "${BASH_SOURCE[0]}")/vault-lib.sh"

get_vault_path() {
  # 1. CLI (primary) — funktioniert auch in Sub-Agents (Named Pipe, OS-Level)
  local cli_path
  cli_path=$(obsidian.com vault 2>/dev/null | awk -F'\t' '/^path/{print $2}' | tr -d '\r')
  if [[ -n "$cli_path" && -d "$cli_path" ]]; then
    echo "$cli_path"
    return 0
  fi
  # 2. Environment variable (offline fallback)
  if [[ -n "${OBSIDIAN_VAULT:-}" && -d "$OBSIDIAN_VAULT" ]]; then
    echo "$OBSIDIAN_VAULT"
    return 0
  fi
  # 3. Failure
  return 1
}
