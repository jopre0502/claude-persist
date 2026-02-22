#!/bin/bash
# commit-counter.sh - Generate indexed commit message for today
# Usage: source commit-counter.sh && get_sync_message
# Output: "Sync 2026-02-06-01" (increments with each commit today)

get_today_commit_count() {
    local today
    today=$(date +%Y-%m-%d)

    # Count commits from today (midnight onwards)
    # Handle case where no commits exist yet
    local count
    count=$(git -C "${GIT_WORK_DIR:-.}" log --oneline --since="$today 00:00:00" 2>/dev/null | wc -l)

    # Trim whitespace
    echo "$count" | tr -d ' '
}

get_next_index() {
    local count
    count=$(get_today_commit_count)
    echo $((count + 1))
}

get_sync_message() {
    local today
    local index

    today=$(date +%Y-%m-%d)
    index=$(get_next_index)

    # Format: Sync YYYY-MM-DD-NN (zero-padded index)
    printf "Sync %s-%02d" "$today" "$index"
}

# Run if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Today's commits: $(get_today_commit_count)"
    echo "Next index: $(get_next_index)"
    echo "Message: $(get_sync_message)"
fi
