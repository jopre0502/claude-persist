---
name: run-next-tasks
description: Manually trigger the task scheduler to identify and start ready tasks
model: sonnet
---

# /run-next-tasks Command

Manually orchestrate tasks from PROJEKT.md. Analyzes dependencies, identifies ready tasks, and provides execution status.

## Usage

### Basic Usage

```
/run-next-tasks
```

Analyzes current phase tasks, identifies which ones are ready to execute, and reports status.

### Dry-Run (Analysis Only)

```
/run-next-tasks --dry-run
```

Analyzes tasks WITHOUT executing anything. Shows what WOULD happen:

```
[SCHEDULER] Task Scheduler starting (DRY_RUN=true)
[SCHEDULER] Found 8 tasks
✓ READY: TASK-005 - Backlinks Query (MCP)
  (DRY RUN: would start this task)
⚠ BLOCKED: TASK-006 - Tag Search
  (waiting for: TASK-005)

Summary: 1 ready, 7 blocked
```

### Force Single-Thread Mode

```
/run-next-tasks --sequential
```

Ensures tasks run one-at-a-time (default behavior).

## What This Command Does

1. **Locates PROJEKT.md**
   - Searches: `./docs/PROJEKT.md` or `./PROJEKT.md`

2. **Extracts Task Table**
   - Parses markdown table format
   - Identifies tasks with `status: pending`

3. **Resolves Dependencies**
   - For each pending task, checks if dependencies are met
   - Marks tasks as `ready` or `blocked`

4. **Reports Status**
   - Lists ready tasks (can start now)
   - Lists blocked tasks (waiting for dependencies)
   - Provides summary

5. **Optional: Starts Background Tasks**
   - If dependencies met: triggers background execution
   - (In dry-run mode: only reports, doesn't execute)

## Scenarios

### Scenario 1: Check Progress After Completing a Task

```
User action:
1. Completed TASK-005 manually
2. Updated PROJEKT.md: TASK-005 status → "completed"
3. Runs: /run-next-tasks

Output:
✓ READY: TASK-006 - Tag Search
  (TASK-005 dependency now satisfied)

→ Now TASK-006 can start
```

### Scenario 2: Identify Blockers

```
/run-next-tasks

Output:
✓ READY: TASK-001 - Docker Setup
⚠ BLOCKED: TASK-002 - Skill (needs TASK-001)
⚠ BLOCKED: TASK-003 - Testing (needs TASK-002)

→ User knows: "Start TASK-001, then rest will unblock"
```

### Scenario 3: Verify Before Session-End

```
/run-next-tasks

Output:
Summary: 0 ready, 3 blocked
⚠ All pending tasks are blocked
→ Phase complete! Move to next phase.
```

## Integration

### After /project-doc-restructure

The `project-doc-restructure` skill automatically calls this command after restructuring documentation.

### Manual Completion Handling

After manually completing a task:

```bash
# 1. Update PROJEKT.md manually (change status to "completed")
# 2. Then run:
/run-next-tasks

# This identifies newly-ready tasks
```

## Command Options Summary

| Option | Effect | Use Case |
|--------|--------|----------|
| (none) | Normal execution | Regular workflow |
| `--dry-run` | Analysis only, no execution | Check what would happen |
| `--sequential` | Single-thread execution | Force sequential |
| `--verbose` | Show detailed logs | Debugging |

## Output Interpretation

### Status Indicators

```
✓ READY: Can start immediately
⚠ BLOCKED: Waiting for dependencies
✗ ERROR: Configuration or parsing issue
```

### Exit Codes

```
0  = Success (tasks analyzed)
1  = Warning (token budget high)
2  = Critical (token budget critical)
```

## Example Workflows

### Workflow 1: Sequential Task Execution

```
Session Start:
  → /run-next-tasks
  → Identifies TASK-001 ready
  → (starts TASK-001 in background)

TASK-001 Completes:
  → Hook triggered
  → PROJEKT.md updated automatically
  → Scheduler re-runs
  → Identifies TASK-002 ready
  → (starts TASK-002)

... (repeats until all tasks complete)

Session End:
  → All ready tasks completed
  → /run-next-tasks shows "0 ready"
  → Phase complete
```

### Workflow 2: Manual Control

```
Session Start:
  → Check: /run-next-tasks --dry-run
  → See: TASK-001, TASK-005 ready

User decides:
  → "I want to work on TASK-001 first"
  → Manually starts TASK-001

Later:
  → /run-next-tasks
  → Shows TASK-001 in_progress, TASK-005 still ready
  → User can start TASK-005 in parallel
```

## Troubleshooting

### "PROJEKT.md not found"

**Solution:**
```bash
# Verify you're in correct directory
pwd

# Find PROJEKT.md
find . -name "PROJEKT.md" -type f

# Run from project root
```

### "No tasks found"

**Cause:** PROJEKT.md exists but has no valid task table

**Solution:**
```bash
# Check PROJEKT.md format:
grep "^|.*TASK-" docs/PROJEKT.md

# Format must be:
# | TASK-001 | Task Name | status | deps | effort | ...
```

### "jq: command not found"

**Solution:**
```bash
# Install jq (JSON parser)
# On Ubuntu:
sudo apt-get install jq

# On macOS:
brew install jq
```

### Tasks Not Progressing

**Check:**
1. Is PROJEKT.md being updated after task completion?
2. Are dependencies listed correctly in PROJEKT.md?
3. Run: `/run-next-tasks --dry-run` to see detailed analysis

## Advanced: Scripting

### Automated Monitoring

```bash
#!/bin/bash
# Check every 5 minutes if new tasks are ready

while true; do
    /run-next-tasks > /tmp/scheduler-status.txt 2>&1

    # Check if new ready tasks appeared
    if grep "READY" /tmp/scheduler-status.txt; then
        echo "New tasks ready!"
        notify-send "Task Scheduler: New tasks available"
    fi

    sleep 300
done
```

### Parse Output Programmatically

```bash
# Extract ready task UUIDs
/run-next-tasks | grep "✓ READY" | awk '{print $3}'

# Example output:
# TASK-001
# TASK-005
```

---

## See Also

- **SKILL.md**: Main scheduler skill documentation
- **SETUP.md**: Installation & configuration guide
- **PROJEKT.md**: Current tasks and phase status
- **docs/tasks/**: Individual task documentation

---

**Autor:** Claude Haiku 4.5
**Erstellt:** 2026-01-19
**Status:** ⏳ Phase D Implementation
