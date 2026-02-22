#!/bin/bash
# config-reader.sh - Read GitHub config from PWD/.claude/github.json
# Usage: source config-reader.sh && read_github_config
# Returns: 0 = OK (sets GITHUB_REPO, GITHUB_TYPE), 1 = not found, 2 = invalid

CONFIG_PATH="${GITHUB_CONFIG:-.claude/github.json}"

config_exists() {
    [[ -f "$CONFIG_PATH" ]]
}

read_github_config() {
    if ! config_exists; then
        echo "ERROR: Keine GitHub-Config gefunden."
        echo ""
        echo "Config erwartet in: $PWD/$CONFIG_PATH"
        echo ""
        echo "Bitte erst /github-init ausführen."
        return 1
    fi

    # Parse JSON (requires jq or fallback to grep)
    if command -v jq &> /dev/null; then
        GITHUB_REPO=$(jq -r '.repo // empty' "$CONFIG_PATH" 2>/dev/null)
        GITHUB_TYPE=$(jq -r '.type // "project"' "$CONFIG_PATH" 2>/dev/null)
    else
        # Fallback: Simple grep (less robust)
        GITHUB_REPO=$(grep -oP '"repo":\s*"\K[^"]+' "$CONFIG_PATH" 2>/dev/null)
        GITHUB_TYPE=$(grep -oP '"type":\s*"\K[^"]+' "$CONFIG_PATH" 2>/dev/null)
        GITHUB_TYPE=${GITHUB_TYPE:-project}
    fi

    if [[ -z "$GITHUB_REPO" ]]; then
        echo "ERROR: Config ungültig - 'repo' fehlt."
        echo ""
        echo "Erwartet in $CONFIG_PATH:"
        echo '  { "repo": "github.com/user/repo", "type": "project" }'
        return 2
    fi

    export GITHUB_REPO
    export GITHUB_TYPE

    echo "OK: Config geladen"
    echo "  Repo: $GITHUB_REPO"
    echo "  Type: $GITHUB_TYPE"
    return 0
}

get_repo_url() {
    if [[ -z "$GITHUB_REPO" ]]; then
        read_github_config > /dev/null || return 1
    fi
    echo "https://$GITHUB_REPO"
}

get_repo_name() {
    if [[ -z "$GITHUB_REPO" ]]; then
        read_github_config > /dev/null || return 1
    fi
    # Extract repo name from "github.com/user/repo"
    echo "$GITHUB_REPO" | sed 's|.*/||'
}

# Run if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    read_github_config
    exit $?
fi
