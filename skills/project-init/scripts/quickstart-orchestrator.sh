#!/usr/bin/env bash
#------------------------------------------------------------------------------
# quickstart-orchestrator.sh
#
# Phase 4 of persist:project-init — orchestrates Windows Quickstart creation.
#
# 1. OS-gates to Windows (silent exit 0 otherwise — graceful for Linux/Mac)
# 2. Detects wt.exe (silent exit 0 if Windows Terminal not installed)
# 3. Delegates icon generation to quickstart-icon.py
# 4. Delegates WT profile insert to quickstart-wt-profile.py
# 5. Delegates desktop shortcut creation to quickstart-shortcut.ps1
#
# This script has NO user interaction — it returns exit codes that the
# LLM-skill-layer (SKILL.md Phase 4) interprets and surfaces via
# AskUserQuestion when needed.
#
# Usage:
#   quickstart-orchestrator.sh <PWD> <PROJECT_NAME> <SYMBOL> <ACCENT_HEX> [FORCE]
#
# Args:
#   PWD            Absolute path to the project root (Unix or Windows style)
#   PROJECT_NAME   Display name (used for WT profile, tabTitle, .lnk basename)
#   SYMBOL         One of the symbols supported by quickstart-icon.py
#                  (sparkle, code, terminal, gear, brain, ...)
#   ACCENT_HEX     Accent color, e.g. "#D4724A"
#   FORCE          Optional: "true" to overwrite existing profile + shortcut
#
# Exit Codes:
#   0   Success — all 3 artifacts created
#   10  Not on Windows (gracefully skipped)
#   11  wt.exe not found (gracefully skipped)
#   20  settings.json not found at expected path
#   21  pwsh.exe not found
#   30  Icon generation failed
#   31  WT profile insert failed (general error)
#   32  WT profile already exists (caller should retry with FORCE=true)
#   33  Desktop shortcut creation failed (general error)
#   34  Desktop shortcut already exists (caller should retry with FORCE=true)
#   40  Missing dependency (python, jq)
#------------------------------------------------------------------------------

set -euo pipefail

#--- Args ---------------------------------------------------------------------
if [ $# -lt 4 ]; then
    echo "ERROR: Usage: $0 <PWD> <PROJECT_NAME> <SYMBOL> <ACCENT_HEX> [FORCE]" >&2
    exit 1
fi

PWD_ARG="$1"
PROJECT_NAME="$2"
SYMBOL="$3"
ACCENT_HEX="$4"
FORCE="${5:-false}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#--- OS Detection -------------------------------------------------------------
case "${OSTYPE:-}" in
    msys*|cygwin*|win32*)
        ;;
    *)
        # Also accept Windows_NT via $OS env var (PowerShell-launched bash)
        if [ "${OS:-}" != "Windows_NT" ]; then
            echo "INFO: Windows Quickstart skipped (OS: ${OSTYPE:-unknown})." >&2
            exit 10
        fi
        ;;
esac

#--- Dependency Check ---------------------------------------------------------
command -v python >/dev/null 2>&1 || { echo "ERROR: python not in PATH" >&2; exit 40; }
command -v jq >/dev/null 2>&1 || { echo "ERROR: jq not in PATH (needed to parse icon meta JSON)" >&2; exit 40; }

#--- wt.exe Detection ---------------------------------------------------------
WT_EXE=""
for candidate in \
    "${LOCALAPPDATA:-}/Microsoft/WindowsApps/wt.exe" \
    "/c/Users/${USERNAME:-${USER:-}}/AppData/Local/Microsoft/WindowsApps/wt.exe"
do
    if [ -n "$candidate" ] && [ -f "$candidate" ]; then
        WT_EXE="$candidate"
        break
    fi
done

if [ -z "$WT_EXE" ]; then
    echo "INFO: wt.exe not found — Windows Terminal not installed. Quickstart skipped." >&2
    exit 11
fi

#--- pwsh.exe Detection -------------------------------------------------------
PWSH_EXE=""
for candidate in \
    "${LOCALAPPDATA:-}/Microsoft/WindowsApps/pwsh.exe" \
    "/c/Users/${USERNAME:-${USER:-}}/AppData/Local/Microsoft/WindowsApps/pwsh.exe"
do
    if [ -n "$candidate" ] && [ -f "$candidate" ]; then
        PWSH_EXE="$candidate"
        break
    fi
done

if [ -z "$PWSH_EXE" ]; then
    echo "ERROR: pwsh.exe not found (required for .lnk creation)" >&2
    exit 21
fi

#--- Settings & Desktop Paths -------------------------------------------------
SETTINGS_JSON="${LOCALAPPDATA:-/c/Users/${USERNAME:-${USER:-}}/AppData/Local}/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"

if [ ! -f "$SETTINGS_JSON" ]; then
    echo "ERROR: Windows Terminal settings.json not found at: $SETTINGS_JSON" >&2
    echo "       (Preview/Unpackaged installations not yet supported.)" >&2
    exit 20
fi

# Desktop path — prefer USERPROFILE, fall back to HOME
DESKTOP_DIR="${USERPROFILE:-${HOME:-}}/Desktop"
if [ ! -d "$DESKTOP_DIR" ]; then
    # Last resort: Git Bash style
    DESKTOP_DIR="/c/Users/${USERNAME:-${USER:-}}/Desktop"
fi
SHORTCUT_PATH="$DESKTOP_DIR/$PROJECT_NAME.lnk"

#--- Force-Flag Translation ---------------------------------------------------
WT_FORCE_FLAG=""
SHORTCUT_FORCE_FLAG=""
if [ "$FORCE" = "true" ]; then
    WT_FORCE_FLAG="--force"
    SHORTCUT_FORCE_FLAG="-Force"
fi

#--- Project ID Sanitization (lowercase, hyphen-only) -------------------------
PROJECT_ID=$(echo "$PROJECT_NAME" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -c 'a-z0-9-' '-' \
    | sed 's/--*/-/g; s/^-//; s/-$//')

# Truncate to 30 chars max (constraint from quickstart-icon.py)
PROJECT_ID="${PROJECT_ID:0:30}"

#--- Step 1: Icon Generation --------------------------------------------------
echo "[1/3] Generating project icon..." >&2

ICON_META=$(python "$SCRIPT_DIR/quickstart-icon.py" \
    --pwd "$PWD_ARG" \
    --project-id "$PROJECT_ID" \
    --symbol "$SYMBOL" \
    --accent "$ACCENT_HEX") || {
    echo "ERROR: Icon generation failed." >&2
    exit 30
}

# Parse meta JSON — accent_color may differ from input if normalized
ACCENT_COLOR=$(echo "$ICON_META" | jq -r '.accent_color')
ICON_PATH=$(echo "$ICON_META" | jq -r '.icon_path')

echo "      Icon: $ICON_PATH" >&2
echo "      Accent: $ACCENT_COLOR" >&2

#--- Step 2: WT Profile Insert ------------------------------------------------
echo "[2/3] Inserting Windows Terminal profile..." >&2

# Disable -e temporarily to capture non-zero exit codes
set +e
WT_OUTPUT=$(python "$SCRIPT_DIR/quickstart-wt-profile.py" \
    --settings "$SETTINGS_JSON" \
    --project-name "$PROJECT_NAME" \
    --pwd "$PWD_ARG" \
    --tab-color "$ACCENT_COLOR" \
    --icon-path "$ICON_PATH" \
    --pwsh-path "$PWSH_EXE" \
    $WT_FORCE_FLAG 2>&1)
WT_EXIT=$?
set -e

if [ $WT_EXIT -eq 2 ]; then
    echo "WARN: WT profile '$PROJECT_NAME' already exists." >&2
    echo "      Retry with FORCE=true to overwrite." >&2
    exit 32
elif [ $WT_EXIT -ne 0 ]; then
    echo "ERROR: WT profile insert failed (exit $WT_EXIT)" >&2
    echo "$WT_OUTPUT" >&2
    exit 31
fi

WT_GUID=$(echo "$WT_OUTPUT" | jq -r '.guid' 2>/dev/null || echo "?")
WT_ACTION=$(echo "$WT_OUTPUT" | jq -r '.action' 2>/dev/null || echo "?")
echo "      Action: $WT_ACTION | GUID: $WT_GUID" >&2

#--- Step 3: Desktop Shortcut -------------------------------------------------
echo "[3/3] Creating desktop shortcut..." >&2

# Convert paths to Windows style for PowerShell using cygpath
WT_EXE_WIN=$(cygpath -w "$WT_EXE" 2>/dev/null || echo "$WT_EXE")
ICON_PATH_WIN=$(cygpath -w "$ICON_PATH" 2>/dev/null || echo "$ICON_PATH")
SHORTCUT_PATH_WIN=$(cygpath -w "$SHORTCUT_PATH" 2>/dev/null || echo "$SHORTCUT_PATH")

set +e
SHORTCUT_OUTPUT=$("$PWSH_EXE" -NoProfile -ExecutionPolicy Bypass \
    -File "$(cygpath -w "$SCRIPT_DIR/quickstart-shortcut.ps1" 2>/dev/null || echo "$SCRIPT_DIR/quickstart-shortcut.ps1")" \
    -TargetPath "$WT_EXE_WIN" \
    -Arguments "-p \"$PROJECT_NAME\"" \
    -IconPath "$ICON_PATH_WIN" \
    -OutputPath "$SHORTCUT_PATH_WIN" \
    $SHORTCUT_FORCE_FLAG 2>&1)
SHORTCUT_EXIT=$?
set -e

if [ $SHORTCUT_EXIT -eq 2 ]; then
    echo "WARN: Desktop shortcut already exists at: $SHORTCUT_PATH" >&2
    echo "      Retry with FORCE=true to overwrite." >&2
    exit 34
elif [ $SHORTCUT_EXIT -ne 0 ]; then
    echo "ERROR: Desktop shortcut creation failed (exit $SHORTCUT_EXIT)" >&2
    echo "$SHORTCUT_OUTPUT" >&2
    exit 33
fi

#--- Summary ------------------------------------------------------------------
echo "" >&2
echo "=== Windows Quickstart Complete ===" >&2
echo "  Icon:       $ICON_PATH" >&2
echo "  WT Profile: $PROJECT_NAME (tab color: $ACCENT_COLOR)" >&2
echo "  Shortcut:   $SHORTCUT_PATH" >&2
echo "" >&2
echo "  Test it: Double-click $SHORTCUT_PATH" >&2
echo "  (Restart Windows Terminal once to register the new profile.)" >&2

# Machine-readable summary on stdout
jq -n \
    --arg icon "$ICON_PATH" \
    --arg profile "$PROJECT_NAME" \
    --arg color "$ACCENT_COLOR" \
    --arg guid "$WT_GUID" \
    --arg shortcut "$SHORTCUT_PATH" \
    '{status: "ok", icon: $icon, wt_profile: {name: $profile, tab_color: $color, guid: $guid}, shortcut: $shortcut}'

exit 0
