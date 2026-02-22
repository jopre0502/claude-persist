#!/bin/bash
#------------------------------------------------------------------------------
# SATE Checkpoint Script
# Automatischer Git-Commit + Task-File Audit Trail Update nach jeder Action.
#
# Usage: checkpoint.sh <TASK-ID> <ACTION_NR> <ACTION_TOTAL> <ACTION_NAME> [PROJECT_ROOT]
# Example: checkpoint.sh TASK-041 2 4 "Budget Intelligence"
#
# Was passiert:
# 1. git add -A (im PROJECT_ROOT)
# 2. git commit mit Format: feat: TASK-XXX Action N/M - Action-Name
# 3. Audit Trail im Task-File aktualisieren (Datum + Action + Ergebnis)
#
# Exit Codes:
# 0 = Commit erfolgreich
# 1 = Fehler (Parameter, git, etc.)
# 2 = Nichts zu committen (clean working tree)
#------------------------------------------------------------------------------

set -euo pipefail

#--- Parameter Validation ---
if [ $# -lt 4 ]; then
    echo "ERROR: Mindestens 4 Parameter erforderlich."
    echo "Usage: checkpoint.sh <TASK-ID> <ACTION_NR> <ACTION_TOTAL> <ACTION_NAME> [PROJECT_ROOT]"
    exit 1
fi

TASK_ID="$1"
ACTION_NR="$2"
ACTION_TOTAL="$3"
ACTION_NAME="$4"
PROJECT_ROOT="${5:-$(pwd)}"

# Validate TASK-ID format
if [[ ! "$TASK_ID" =~ ^TASK-[0-9]+$ ]]; then
    echo "ERROR: TASK-ID muss Format TASK-NNN haben. Erhalten: $TASK_ID"
    exit 1
fi

# Validate action numbers are numeric
if [[ ! "$ACTION_NR" =~ ^[0-9]+$ ]] || [[ ! "$ACTION_TOTAL" =~ ^[0-9]+$ ]]; then
    echo "ERROR: ACTION_NR und ACTION_TOTAL muessen numerisch sein."
    exit 1
fi

if [ "$ACTION_NR" -gt "$ACTION_TOTAL" ]; then
    echo "ERROR: ACTION_NR ($ACTION_NR) > ACTION_TOTAL ($ACTION_TOTAL)."
    exit 1
fi

#--- Git Operations ---
cd "$PROJECT_ROOT"

# Check if we're in a git repo
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "ERROR: $PROJECT_ROOT ist kein Git-Repository."
    exit 1
fi

# Check if there are changes to commit
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
    echo "INFO: Keine Aenderungen zum Committen (clean working tree)."
    exit 2
fi

# Stage all changes
git add -A

# Commit with SATE format
COMMIT_MSG="feat: ${TASK_ID} Action ${ACTION_NR}/${ACTION_TOTAL} - ${ACTION_NAME}"
git commit -m "$(cat <<EOF
${COMMIT_MSG}

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"

COMMIT_HASH=$(git rev-parse --short HEAD)
echo "OK: Commit ${COMMIT_HASH} - ${COMMIT_MSG}"

#--- Audit Trail Update ---
TASK_FILE=$(find "$PROJECT_ROOT/docs/tasks" -name "${TASK_ID}-*.md" -type f 2>/dev/null | head -1)

if [ -z "$TASK_FILE" ]; then
    echo "WARN: Task-File fuer ${TASK_ID} nicht gefunden. Audit Trail nicht aktualisiert."
    exit 0
fi

# Append to audit trail
TODAY=$(date +%Y-%m-%d)
AUDIT_LINE="- ${TODAY} - Action ${ACTION_NR}/${ACTION_TOTAL} (${ACTION_NAME}) completed - Commit: ${COMMIT_HASH}"

# Check if Audit Trail section exists
if grep -q "## Audit Trail" "$TASK_FILE"; then
    echo "$AUDIT_LINE" >> "$TASK_FILE"
    echo "OK: Audit Trail in ${TASK_FILE} aktualisiert."
else
    echo "WARN: Keine '## Audit Trail' Section in ${TASK_FILE}. Audit Trail nicht aktualisiert."
fi

#--- Action Tracking Table Update ---
if grep -q "| ${ACTION_NR} |" "$TASK_FILE"; then
    sed -i "s/| ${ACTION_NR} |\(.*\)| 📋 pending |/| ${ACTION_NR} |\1| ✅ completed |/" "$TASK_FILE"
    echo "OK: Action Tracking Tabelle aktualisiert (Action ${ACTION_NR} -> completed)."
fi

echo ""
echo "=== CHECKPOINT COMPLETE ==="
echo "Task: ${TASK_ID}"
echo "Action: ${ACTION_NR}/${ACTION_TOTAL} - ${ACTION_NAME}"
echo "Commit: ${COMMIT_HASH}"
