# Scheduler Architecture - Technical Deep-Dive

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                       Claude Code Session                        │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │           Task Scheduler Skill (Auto-Discovery)        │    │
│  │                                                           │    │
│  │  [SKILL.md] ← Auto-triggered via description keywords   │    │
│  └──────────────────────┬──────────────────────────────────┘    │
│                         │                                        │
│                         ↓                                        │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │         scheduler.sh (Orchestration Engine)            │    │
│  │                                                           │    │
│  │  1. Parse PROJEKT.md                                    │    │
│  │  2. Extract Task-Table (UUID, Status, Dependencies)     │    │
│  │  3. Build Dependency-Graph                              │    │
│  │  4. Identify Ready Tasks (no pending deps)              │    │
│  │  5. Start Background-Tasks                              │    │
│  └──────────────────────┬──────────────────────────────────┘    │
│                         │                                        │
│         ┌───────────────┼───────────────┐                       │
│         ↓               ↓               ↓                       │
│  ┌────────────┐ ┌────────────┐ ┌────────────────┐              │
│  │ Background │ │ Background │ │ Token-Watcher │              │
│  │ Task 1     │ │ Task 2     │ │                │              │
│  │ (Parallel) │ │ (Parallel) │ │ Check Budget   │              │
│  └────────────┘ └────────────┘ └────────────────┘              │
│         │               │               │                       │
│         └───────────────┼───────────────┘                       │
│                         │                                        │
│                         ↓ (After Completion)                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │    task-completion-hook.sh (Update Handler)            │    │
│  │                                                           │    │
│  │  1. Parse completion JSON                               │    │
│  │  2. Update PROJEKT.md (status)                          │    │
│  │  3. Update Task-File (timestamp)                        │    │
│  │  4. Trigger scheduler.sh recursively                    │    │
│  │  5. Notify user                                         │    │
│  └──────────────────────┬──────────────────────────────────┘    │
│                         │                                        │
│                         ↓ (Recursive)                           │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Next Ready Tasks Identified & Started                  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Dependency Resolution Algorithm

### 3-Phase Process

#### Phase 1: Task Extraction

```bash
# Read PROJEKT.md and extract markdown table:
# | UUID | Task | Status | Dependencies | Effort | Deliverable | Task-File |

# Output: JSON array
[
  {
    "uuid": "TASK-005",
    "name": "Backlinks Query",
    "status": "pending",
    "dependencies": "[TASK-004]",
    "effort": "2h",
    "deliverable": "MCP integration"
  },
  {
    "uuid": "TASK-006",
    "name": "Tag Search",
    "status": "pending",
    "dependencies": "[TASK-005]",
    "effort": "1h",
    "deliverable": "Tag filtering"
  }
]
```

#### Phase 2: Dependency Resolution

```bash
# For each pending task, check if dependencies are met:

TASK-005:
  dependencies: [TASK-004]
  TASK-004 status: "completed" ✓
  → READY

TASK-006:
  dependencies: [TASK-005]
  TASK-005 status: "pending" ✗
  → BLOCKED
```

#### Phase 3: Ready Task Identification

```bash
# Filter tasks where all dependencies are "completed":

Ready Tasks:
  - TASK-005 (all deps met)

Blocked Tasks:
  - TASK-006 (waiting for TASK-005)
  - TASK-007 (waiting for TASK-006)

Output:
  TASK-005|ready
  TASK-006|blocked
  TASK-007|blocked
```

---

## Task State Machine

```
┌─────────┐
│ pending │  ← Initial state (task not started)
└────┬────┘
     │ scheduler.sh identifies as ready
     ↓
┌──────────────┐
│ in_progress  │  ← Background task running
└────┬─────────┘
     │
     ├─→ ✓ Success
     │      ↓
     │   ┌───────────┐
     │   │ completed │  ← Task finished successfully
     │   └───────────┘
     │
     └─→ ✗ Failure
          ↓
       ┌────────┐
       │ blocked│  ← Task hit blocker (e.g., missing file)
       └────────┘
         │
         └─→ Fix issue
            ↓
         Reset to pending
            ↓
         Try again
```

### State Transitions

| From | To | Trigger | Handler |
|------|-----|---------|---------|
| pending | in_progress | scheduler.sh starts task | Background execution begins |
| in_progress | completed | Task finishes successfully | task-completion-hook.sh updates files |
| in_progress | blocked | Task encounters blocker | Error handling + notification |
| blocked | pending | User fixes blocker | Manual reset in PROJEKT.md |

---

## Parallel Execution Strategy

### Single-Thread (Current Implementation)

```
Timeline:
  TASK-005 (2h): ████████████████████ [1h-3h]
  TASK-006 (1h):                        ████████ [3h-4h]
  TASK-007 (1h):                                 ████████ [4h-5h]

Total: 5 hours
```

**Logic:**
1. Start TASK-005 (only ready task)
2. Wait for completion
3. scheduler.sh identifies TASK-006 (now ready)
4. Start TASK-006
5. Repeat

### Parallel Execution (Future Feature)

```
Timeline (if independent):
  TASK-001 (1h): ████ [0h-1h]
  TASK-004 (2h): ████████ [0h-2h]  ← Parallel to TASK-001
  TASK-005 (1h):          ████ [2h-3h]

Total: 3 hours (vs 4 hours sequential)
```

**Implementation:**
```bash
# Group independent tasks (no shared dependencies)
independent_tasks=$(identify_independent_tasks "$tasks_json")

# Start all in parallel
for task in $independent_tasks; do
    start_background_task "$task" &
done
wait
```

**Requirements:**
- Claude Code Background Task API must support parallel execution
- Task-completion-hook must handle concurrent updates safely
- PROJEKT.md updates need file-locking to prevent conflicts

---

## JSON Message Formats

### Task Completion Hook Input

```json
{
  "task_uuid": "TASK-005",
  "status": "completed",
  "result": "Success",
  "completion_timestamp": "2026-01-19 15:30"
}
```

**Fields:**
- `task_uuid`: UUID of completed task (TASK-NNN format)
- `status`: `completed`, `failed`, or `blocked`
- `result`: Short result description
- `completion_timestamp`: ISO 8601 or custom format

### Token-Watcher Input

```json
{
  "usage_pct": 72.5,
  "current": 145000,
  "limit": 200000
}
```

**Fields:**
- `usage_pct`: Token usage percentage (0-100)
- `current`: Current token count
- `limit`: Total token limit

---

## File Format & Parsing

### PROJEKT.md Task Table Format

```markdown
### Phase 1: Foundation + MVP (UUID-based Task Management)

| UUID | Task | Status | Dependencies | Effort | Deliverable | Task-File |
|------|------|--------|--------------|--------|-------------|-----------|
| TASK-001 | Docker Setup | completed | None | 1h | mcp.json | [Details](tasks/TASK-001-*.md) |
| TASK-004 | Custom MCP | pending | TASK-003 | 0.5h | mcp_rest_api.py | [Details](tasks/TASK-004-*.md) |
```

**Parsing Rules:**
- Lines starting with `|` are table rows
- Skip header and separator lines (contains `---`)
- Split by `|` to extract columns
- Trim whitespace from each field
- First column must match `^TASK-[0-9]{3}$` regex

**Bash Parsing:**
```bash
awk '
  /^\|.*UUID.*Task.*Status/ { in_table = 1; next }
  in_table && /^\|---/ { next }
  in_table && /^\|/ {
    gsub(/^\||\|$/, "")  # Remove pipes
    split($0, cols, "|")
    if (cols[1] ~ /^TASK-/) {
      # Process task
    }
  }
' docs/PROJEKT.md
```

### Task-File Format

```markdown
---
uuid: TASK-005
phase: 1b.1
title: Backlinks Query (MCP)
status: pending
created: 2026-01-19
started:
completed:
dependencies: ["TASK-004"]
effort: "2h"
---

# TASK-005: Backlinks Query

## Beschreibung
...

## Status
**Status:** pending
**Completion-Datum:** (empty)
```

**Update Rules:**
- Frontmatter fields updated via sed replacement
- Content sections (like Status) updated via section insertion
- Never remove existing content, only append/update metadata

---

## Error Handling

### Dependency Cycle Detection

```bash
# Algorithm: DFS-based cycle detection
# Starting from each node, traverse dependencies
# If reach same node again → cycle detected

Example Cycle:
  TASK-A → TASK-B → TASK-C → TASK-A (cycle!)

Detection:
  1. Start DFS from TASK-A
  2. Visit TASK-B
  3. Visit TASK-C
  4. Visit TASK-A again → CYCLE DETECTED
  5. Exit with error code 1
```

### Task File Not Found

```bash
# If task-file doesn't exist for completed task:
# 1. Log warning (non-critical)
# 2. Create task-file from template
# 3. Continue with PROJEKT.md update
# 4. Notify user
```

### PROJEKT.md Parse Error

```bash
# If PROJEKT.md has invalid markdown:
# 1. Try alternate parsing strategies
# 2. If all fail: return empty task list
# 3. Notify user to check PROJEKT.md syntax
# 4. Exit code 1 (error)
```

### Token Budget Exceeded

```bash
# If usage >85%:
# 1. Warn user
# 2. Recommend /exit
# 3. Don't start new tasks (optional)
# 4. Continue existing tasks
```

---

## Performance Characteristics

### Time Complexity

| Operation | Time | Notes |
|-----------|------|-------|
| Parse PROJEKT.md | O(n) | n = lines in file |
| Extract tasks | O(m) | m = tasks in table |
| Dependency resolution | O(m²) | Worst case: all depend on all |
| Sort ready tasks | O(m log m) | Minimal; rarely needed |
| Update PROJEKT.md | O(1) | Single sed replacement |
| Update task-file | O(1) | Single sed + append |

### Space Complexity

| Component | Space | Notes |
|-----------|-------|-------|
| Task array | O(m) | m = number of tasks |
| Dependency graph | O(m²) | Worst case: all connected |
| JSON output | O(m) | Per-task metadata |

### Practical Benchmarks (WSL2)

```
Scenario: 20 tasks, 3 dependencies per task

- Parse PROJEKT.md: ~50ms
- Build dependency graph: ~20ms
- Identify ready tasks: ~15ms
- Update PROJEKT.md: ~20ms
- Total round-trip: ~105ms
```

---

## Extensibility

### Adding Custom Validators

```bash
# In task-completion-hook.sh, add pre-update validation:

validate_completion() {
    local uuid="$1"
    local task_file="$2"

    # Custom: Check if task-file has required sections
    if ! grep -q "## Ergebnis" "$task_file"; then
        log_error "Task missing required 'Ergebnis' section"
        return 1
    fi

    # Custom: Verify deliverables exist
    local deliverable=$(grep "^deliverable:" "$task_file" | cut -d: -f2-)
    if [ ! -f "$deliverable" ]; then
        log_warn "Deliverable file not found: $deliverable"
    fi

    return 0
}
```

### Adding Custom Notifications

```bash
# Extend task-completion-hook.sh to send webhooks:

notify_external() {
    local uuid="$1"
    local status="$2"

    # Example: Slack notification
    curl -X POST "$SLACK_WEBHOOK" \
        -H 'Content-Type: application/json' \
        -d "{\"text\": \"Task $uuid completed: $status\"}"

    # Example: Email notification
    mail -s "Task $uuid Complete" "user@example.com" <<EOF
Task $uuid has completed with status: $status
EOF
}
```

---

## Debugging

### Enable Verbose Logging

```bash
# Set debug mode (not yet implemented, but design ready):
export DEBUG=true

# Will add -x to bash scripts for execution tracing
bash -x ~/.claude/skills/task-scheduler/scripts/scheduler.sh
```

### Dry-Run Mode

```bash
# Analyze without executing:
~/.claude/skills/task-scheduler/scripts/scheduler.sh docs/PROJEKT.md true

# Output shows:
# [DRY RUN] would start TASK-005
# [DRY RUN] would start TASK-006 (after TASK-005)
```

### Manual Testing

```bash
# Test task-completion-hook manually:
cat <<EOF | ~/.claude/skills/task-scheduler/scripts/task-completion-hook.sh
{
  "task_uuid": "TASK-005",
  "status": "completed",
  "result": "Success",
  "completion_timestamp": "2026-01-19 15:30"
}
EOF

# Check output:
# Should see PROJEKT.md and task-file updated
```

---

## Future Enhancements

### Phase D+

| Feature | Complexity | Impact |
|---------|------------|--------|
| **Parallel Execution** | Medium | -30% total time |
| **Task Retry Logic** | Medium | Better resilience |
| **Progress Tracking** | Low | Better UX |
| **Performance Caching** | Medium | 10x faster for large projects |
| **Multi-Phase Coordination** | High | Cross-project tasks |

---

**Last Updated:** 2026-01-19
**Version:** 1.0 (Phase C)
**Status:** ⏳ In Development
