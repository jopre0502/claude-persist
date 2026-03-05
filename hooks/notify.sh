#!/bin/bash
#------------------------------------------------------------------------------
# CLAUDE CODE NOTIFICATION HOOK - Cross-Platform
# Supports: macOS (osascript), Windows/WSL2 (BurntToast), Linux (notify-send)
#------------------------------------------------------------------------------

# Read hook input from stdin (JSON format)
INPUT=$(cat)

#------------------------------------------------------------------------------
# JSON EXTRACTION (jq-based, like statusline.sh)
#------------------------------------------------------------------------------

# Extract notification type
NOTIF_TYPE=$(echo "$INPUT" | jq -r '.type // "notification"' 2>/dev/null)

# Extract session information (if available in hook context)
SESSION_NAME=$(echo "$INPUT" | jq -r '.session.name // .session_name // empty' 2>/dev/null)

# Extract model information
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // .model // empty' 2>/dev/null)

# Extract token usage (similar to statusline.sh)
get_token_usage() {
    local input="$1"

    if command -v jq >/dev/null 2>&1; then
        local usage=$(echo "$input" | jq '.context_window.current_usage // empty' 2>/dev/null)

        if [ -n "$usage" ] && [ "$usage" != "null" ]; then
            local input_tok=$(echo "$usage" | jq '.input_tokens // 0')
            local cache_cr=$(echo "$usage" | jq '.cache_creation_input_tokens // 0')
            local cache_rd=$(echo "$usage" | jq '.cache_read_input_tokens // 0')
            local curr=$((input_tok + cache_cr + cache_rd))
            local size=$(echo "$input" | jq '.context_window.context_window_size // 0')

            if [ "$size" -gt 0 ] 2>/dev/null; then
                local pct=$((curr * 100 / size))
                local curr_k=$((curr / 1000))
                local size_k=$((size / 1000))
                echo "${curr_k}K/${size_k}K (${pct}%)"
                return
            fi
        fi
    fi
    echo ""
}

TOKEN_USAGE=$(get_token_usage "$INPUT")

#------------------------------------------------------------------------------
# NOTIFICATION TYPE MAPPING (German messages)
#------------------------------------------------------------------------------

case "$NOTIF_TYPE" in
    "permission_prompt")
        TITLE="Claude Code - Berechtigung"
        MESSAGE="Deine Eingabe wird benötigt"
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

DETAILS=""

if [ -n "$SESSION_NAME" ] && [ "$SESSION_NAME" != "null" ]; then
    DETAILS="Session: $SESSION_NAME"
fi

if [ -n "$MODEL" ] && [ "$MODEL" != "null" ]; then
    if [ -n "$DETAILS" ]; then
        DETAILS="$DETAILS | $MODEL"
    else
        DETAILS="$MODEL"
    fi
fi

if [ -n "$TOKEN_USAGE" ]; then
    if [ -n "$DETAILS" ]; then
        DETAILS="$DETAILS | $TOKEN_USAGE"
    else
        DETAILS="$TOKEN_USAGE"
    fi
fi

# Add timestamp
TIMESTAMP=$(date +%H:%M:%S)
if [ -n "$DETAILS" ]; then
    DETAILS="$DETAILS | $TIMESTAMP"
else
    DETAILS="$TIMESTAMP"
fi

#------------------------------------------------------------------------------
# EXECUTE PLATFORM-SPECIFIC NOTIFICATION
#------------------------------------------------------------------------------

_OS="$(uname -s)"

case "$_OS" in
    Darwin)
        # macOS: native osascript (no brew required)
        osascript -e "display notification \"$MESSAGE — $DETAILS\" with title \"$TITLE\"" 2>/dev/null
        ;;
    Linux)
        if command -v wslpath &>/dev/null || command -v pwsh.exe &>/dev/null; then
            # WSL2/Windows: BurntToast via PowerShell
            TITLE_ESCAPED="${TITLE//\'/\'\'}"
            MESSAGE_ESCAPED="${MESSAGE//\'/\'\'}"
            DETAILS_ESCAPED="${DETAILS//\'/\'\'}"
            ICON_WSL="/home/jopre/.claude/assets/claude-icon.png"
            ICON_WIN=$(wslpath -w "$ICON_WSL" 2>/dev/null)
            pwsh.exe -NoProfile -Command "
                Import-Module BurntToast -ErrorAction SilentlyContinue
                if (Get-Module BurntToast) {
                    \$iconPath = '$ICON_WIN'
                    if (Test-Path \$iconPath) {
                        New-BurntToastNotification -Text '$TITLE_ESCAPED', '$MESSAGE_ESCAPED', '$DETAILS_ESCAPED' -AppLogo \$iconPath -Sound Default
                    } else {
                        New-BurntToastNotification -Text '$TITLE_ESCAPED', '$MESSAGE_ESCAPED', '$DETAILS_ESCAPED' -Sound Default
                    }
                } else {
                    [System.Media.SystemSounds]::Asterisk.Play()
                }
            " 2>/dev/null
        elif command -v notify-send &>/dev/null; then
            # Linux Desktop: libnotify
            notify-send "$TITLE" "$MESSAGE — $DETAILS" 2>/dev/null
        fi
        ;;
    MINGW*|MSYS*)
        # Git Bash on Windows: BurntToast via PowerShell
        TITLE_ESCAPED="${TITLE//\'/\'\'}"
        MESSAGE_ESCAPED="${MESSAGE//\'/\'\'}"
        DETAILS_ESCAPED="${DETAILS//\'/\'\'}"
        ICON_UNIX="$HOME/.claude/assets/claude-icon.png"
        ICON_WIN=$(cygpath -w "$ICON_UNIX" 2>/dev/null)
        pwsh.exe -NoProfile -Command "
            Import-Module BurntToast -ErrorAction SilentlyContinue
            if (Get-Module BurntToast) {
                \$iconPath = '$ICON_WIN'
                if (\$iconPath -and (Test-Path \$iconPath)) {
                    New-BurntToastNotification -Text '$TITLE_ESCAPED', '$MESSAGE_ESCAPED', '$DETAILS_ESCAPED' -AppLogo \$iconPath -Sound Default
                } else {
                    New-BurntToastNotification -Text '$TITLE_ESCAPED', '$MESSAGE_ESCAPED', '$DETAILS_ESCAPED' -Sound Default
                }
            } else {
                [System.Media.SystemSounds]::Asterisk.Play()
            }
        " 2>/dev/null
        ;;
esac

exit 0
