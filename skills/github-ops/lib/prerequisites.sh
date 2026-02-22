#!/bin/bash
# prerequisites.sh - Check gh CLI installation and authentication
# Usage: source prerequisites.sh && check_prerequisites
# Returns: 0 = OK, 1 = gh not installed, 2 = not authenticated

check_gh_installed() {
    if ! command -v gh &> /dev/null; then
        echo "ERROR: gh CLI ist nicht installiert."
        echo ""
        echo "Installation:"
        echo "  Ubuntu/WSL: sudo apt install gh"
        echo "  macOS:      brew install gh"
        echo "  Windows:    winget install GitHub.cli"
        echo ""
        echo "Oder: https://cli.github.com/"
        return 1
    fi
    return 0
}

check_gh_authenticated() {
    if ! gh auth status &> /dev/null; then
        echo "ERROR: gh CLI ist nicht authentifiziert."
        echo ""
        echo "Authentifizierung starten:"
        echo "  gh auth login"
        echo ""
        echo "Folge den Prompts (Browser-Auth empfohlen)."
        return 2
    fi
    return 0
}

get_gh_user() {
    gh api user --jq '.login' 2>/dev/null
}

check_prerequisites() {
    check_gh_installed || return 1
    check_gh_authenticated || return 2

    local user
    user=$(get_gh_user)
    echo "OK: gh CLI bereit (User: $user)"
    return 0
}

# Run if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    check_prerequisites
    exit $?
fi
