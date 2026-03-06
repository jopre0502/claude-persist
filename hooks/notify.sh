#!/bin/bash
#------------------------------------------------------------------------------
# CLAUDE CODE NOTIFICATION HOOK - Cross-Platform
# Supports: macOS (osascript), Windows/WSL2 (BurntToast), Linux (notify-send)
#------------------------------------------------------------------------------

# Read hook input from stdin (JSON format)
INPUT=$(cat)

#------------------------------------------------------------------------------
# JSON EXTRACTION (single jq call for all fields)
#------------------------------------------------------------------------------

if command -v jq >/dev/null 2>&1; then
    PARSED=$(echo "$INPUT" | jq -r '[
        (.notification_type // .type // "notification"),
        (.session_id // ""),
        (.cwd // ""),
        (.model | if type == "object" then .display_name // "" elif type == "string" then . else "" end),
        (.context_window.current_usage.input_tokens // 0 | tostring),
        (.context_window.current_usage.cache_creation_input_tokens // 0 | tostring),
        (.context_window.current_usage.cache_read_input_tokens // 0 | tostring),
        (.context_window.context_window_size // 0 | tostring)
    ] | join("\t")' 2>/dev/null | tr -d '\r')

    IFS=$'\t' read -r NOTIF_TYPE SESSION_ID CWD MODEL TOK_IN TOK_CACHE_CR TOK_CACHE_RD CTX_SIZE <<< "$PARSED"
fi

# Fallbacks if jq failed or missing
: "${NOTIF_TYPE:=notification}"

# Session-Hash (first 6 chars of session_id UUID)
SESSION_HASH=""
if [ -n "$SESSION_ID" ] && [ "$SESSION_ID" != "null" ]; then
    SESSION_HASH="${SESSION_ID:0:6}"
fi

# PWD-Leaf (last path component)
CWD_LEAF=""
if [ -n "$CWD" ] && [ "$CWD" != "null" ]; then
    CWD_LEAF="${CWD##*/}"
fi

# Token usage (computed from parsed values, no extra jq)
TOKEN_USAGE=""
if [ "${CTX_SIZE:-0}" -gt 0 ] 2>/dev/null; then
    local_curr=$(( ${TOK_IN:-0} + ${TOK_CACHE_CR:-0} + ${TOK_CACHE_RD:-0} ))
    local_pct=$(( local_curr * 100 / CTX_SIZE ))
    TOKEN_USAGE="$(( local_curr / 1000 ))K/$(( CTX_SIZE / 1000 ))K (${local_pct}%)"
fi

# Read active TASK from sidecar file (written by task-orchestrator)
ACTIVE_TASK=""
SIDECAR_FILE="/tmp/claude-active-task.json"
if [ -f "$SIDECAR_FILE" ] && command -v jq >/dev/null 2>&1; then
    SIDECAR_CWD=$(jq -r '.cwd // empty' "$SIDECAR_FILE" 2>/dev/null | tr -d '\r')
    if [ "$SIDECAR_CWD" = "$CWD" ]; then
        ACTIVE_TASK=$(jq -r '.task // empty' "$SIDECAR_FILE" 2>/dev/null | tr -d '\r')
    fi
fi

#------------------------------------------------------------------------------
# NOTIFICATION TYPE MAPPING (German messages)
#------------------------------------------------------------------------------

case "$NOTIF_TYPE" in
    "permission_prompt")
        TITLE="Claude Code - Berechtigung"
        MESSAGE="Deine Eingabe wird benoetig"
        ;;
    "idle_prompt")
        TITLE="Claude Code - Wartet"
        MESSAGE="Claude wartet auf deine Antwort"
        ;;
    "max_turns_reached")
        TITLE="Claude Code - Limit"
        MESSAGE="Maximale Anzahl Turns erreicht"
        ;;
    "task_completed")
        TITLE="Claude Code - Fertig"
        MESSAGE="Aufgabe abgeschlossen"
        ;;
    *)
        TITLE="Claude Code"
        MESSAGE="Aufgabe abgeschlossen"
        ;;
esac

#------------------------------------------------------------------------------
# BUILD SUBTITLE WITH SESSION INFO
#------------------------------------------------------------------------------

DETAILS_PARTS=()

if [ -n "$CWD_LEAF" ] && [ -n "$SESSION_HASH" ]; then
    DETAILS_PARTS+=("$CWD_LEAF #$SESSION_HASH")
elif [ -n "$CWD_LEAF" ]; then
    DETAILS_PARTS+=("$CWD_LEAF")
elif [ -n "$SESSION_HASH" ]; then
    DETAILS_PARTS+=("#$SESSION_HASH")
fi

[ -n "$ACTIVE_TASK" ] && [ "$ACTIVE_TASK" != "null" ] && DETAILS_PARTS+=("$ACTIVE_TASK")
[ -n "$MODEL" ] && [ "$MODEL" != "null" ] && DETAILS_PARTS+=("$MODEL")
[ -n "$TOKEN_USAGE" ] && DETAILS_PARTS+=("$TOKEN_USAGE")

printf -v TIMESTAMP '%(%H:%M)T' -1
DETAILS_PARTS+=("$TIMESTAMP")

# Join with pipe separator
DETAILS=""
for part in "${DETAILS_PARTS[@]}"; do
    if [ -n "$DETAILS" ]; then
        DETAILS="$DETAILS | $part"
    else
        DETAILS="$part"
    fi
done

#------------------------------------------------------------------------------
# PLATFORM-SPECIFIC NOTIFICATION
#------------------------------------------------------------------------------

# BurntToast helper (used by WSL2 + Git Bash)
send_burnttoast() {
    local icon_path="$1"
    local title_esc="${TITLE//\'/\'\'}"
    local msg_esc="${MESSAGE//\'/\'\'}"
    local details_esc="${DETAILS//\'/\'\'}"

    pwsh.exe -NoProfile -Command "
        Import-Module BurntToast -ErrorAction SilentlyContinue
        if (Get-Module BurntToast) {
            \$iconPath = '$icon_path'
            if (\$iconPath -and (Test-Path \$iconPath)) {
                New-BurntToastNotification -Text '$title_esc', '$msg_esc', '$details_esc' -AppLogo \$iconPath -Sound Default
            } else {
                New-BurntToastNotification -Text '$title_esc', '$msg_esc', '$details_esc' -Sound Default
            }
        } else {
            [System.Media.SystemSounds]::Asterisk.Play()
        }
    " 2>/dev/null
}

_OS="$(uname -s)"

case "$_OS" in
    Darwin)
        osascript -e "display notification \"$MESSAGE — $DETAILS\" with title \"$TITLE\"" 2>/dev/null
        ;;
    Linux)
        if command -v wslpath &>/dev/null || command -v pwsh.exe &>/dev/null; then
            ICON_WIN=$(wslpath -w "/home/jopre/.claude/assets/claude-icon.png" 2>/dev/null)
            send_burnttoast "$ICON_WIN"
        elif command -v notify-send &>/dev/null; then
            notify-send "$TITLE" "$MESSAGE — $DETAILS" 2>/dev/null
        fi
        ;;
    MINGW*|MSYS*)
        ICON_WIN=$(cygpath -w "$HOME/.claude/assets/claude-icon.png" 2>/dev/null)
        send_burnttoast "$ICON_WIN"
        ;;
esac

exit 0
