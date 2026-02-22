# Task Scheduler - Installation & Configuration Guide

## Quick Start

### 1. Installation

Die Scheduler-Skill wird bereits bereitgestellt in:
```
~/.claude/skills/task-scheduler/
├── SKILL.md                              # Main Skill Definition
├── scripts/
│   ├── scheduler.sh                     # Task orchestration engine
│   ├── task-completion-hook.sh          # Post-completion handler
│   └── token-watcher.sh                 # Token budget monitor
└── references/
    ├── SETUP.md                         # This file
    └── SCHEDULER-ARCHITECTURE.md        # Technical details
```

**No additional installation required** - Scripts sind bereits vorhanden und executable.

### 2. Manual Trigger (Verify Installation)

```bash
# Navigate to project directory
cd /mnt/c/Development/Projects/Claude/ObsidianClaude/

# Run scheduler manually (dry-run)
~/.claude/skills/task-scheduler/scripts/scheduler.sh docs/PROJEKT.md true

# Output:
# [SCHEDULER] Task Scheduler starting (DRY_RUN=true)
# [SCHEDULER] Using PROJEKT: docs/PROJEKT.md
# [SCHEDULER] Extracting tasks from docs/PROJEKT.md
# [SCHEDULER] Found X tasks
# ✓ READY: TASK-XXX - Task Name
# ...
```

If you see ready tasks listed, installation is working! ✅

### 3. Optional: Enable Auto-Trigger at Session-Start

**Option A: Via Hook (Recommended)**

Create `~/.claude/hooks/session-start-scheduler.sh`:

```bash
#!/bin/bash
INPUT=$(cat)
EVENT_TYPE=$(echo "$INPUT" | jq -r '.type' 2>/dev/null || echo "")

if [ "$EVENT_TYPE" = "SessionStart" ]; then
    echo "🤖 Running Task Scheduler at session start..."
    ~/.claude/skills/task-scheduler/scripts/scheduler.sh
fi
```

Make executable:
```bash
chmod +x ~/.claude/hooks/session-start-scheduler.sh
```

Then register in Claude Code (if hook system supports it).

**Option B: Manual Trigger via Command**

Use `/run-next-tasks` Command (siehe Phase D).

### 4. Project Configuration

**Location:** Current working directory needs access to `docs/PROJEKT.md`

Scheduler sucht automatisch nach PROJEKT.md in:
1. `./docs/PROJEKT.md` (preferred)
2. `./PROJEKT.md` (fallback)

Stelle sicher, dass du im Projekt-Root-Directory bist, wenn du Scheduler startest.

---

## Configuration Options

### Environment Variables

Set these vor Scheduler-Ausführung (optional):

```bash
# Only analyze, don't execute
export SCHEDULER_DRY_RUN=true

# Token warning threshold (default: 70)
export SCHEDULER_TOKEN_WARN_PCT=70

# Token critical threshold (default: 85)
export SCHEDULER_TOKEN_STOP_PCT=85

# Enable parallel task execution (future feature)
export SCHEDULER_PARALLEL_MODE=false

# Then run:
~/.claude/skills/task-scheduler/scripts/scheduler.sh
```

### Task Dependencies Format

**In PROJEKT.md Task-Tabelle:**

```markdown
| UUID | Task | Status | Dependencies | Effort | Deliverable | Task-File |
|------|------|--------|--------------|--------|-------------|-----------|
| TASK-005 | Query Task | pending | TASK-004 | 2h | artifact | [Link] |
| TASK-006 | Tag Search | pending | [TASK-005, TASK-007] | 1h | search | [Link] |
```

**Format:**
- Single dependency: `TASK-004` or `[TASK-004]`
- Multiple dependencies: `[TASK-005, TASK-007]`
- No dependencies: `None` or leave empty

---

## Usage Scenarios

### Scenario 1: Manual Task Orchestration

```bash
# Check which tasks are ready
~/.claude/skills/task-scheduler/scripts/scheduler.sh docs/PROJEKT.md true

# Output shows:
# ✓ READY: TASK-005 - Backlinks Query
# ⚠ BLOCKED: TASK-006 - Tag Search (waiting for TASK-005)

# Now manually start TASK-005
# (In real implementation, would start via Claude Code Task API)
```

### Scenario 2: Automatic Task Completion Handling

After manually completing a task:

```bash
# Send completion notification via hook
cat <<EOF | ~/.claude/skills/task-scheduler/scripts/task-completion-hook.sh
{
  "task_uuid": "TASK-005",
  "status": "completed",
  "result": "Success",
  "completion_timestamp": "$(date '+%Y-%m-%d %H:%M')"
}
EOF

# Hook will:
# 1. Update PROJEKT.md: TASK-005 status → "completed"
# 2. Update task-file: docs/tasks/TASK-005-*.md
# 3. Re-run scheduler (finds TASK-006 now ready)
# 4. Notify user
```

### Scenario 3: Token Budget Monitoring

```bash
# Check token usage before starting expensive task
cat <<EOF | ~/.claude/skills/task-scheduler/scripts/token-watcher.sh
{
  "usage_pct": 72,
  "current": 144000,
  "limit": 200000
}
EOF

# Output:
# ⚠ WARNING: Token budget at 72% (limit: 200000)
#
# 📊 Session Token Budget High
# ===============================
# Current usage: 72% (144000 / 200000 tokens)
# Remaining: ~56000 tokens
#
# Recommended action: Run /project-doc-restructure
```

---

## Troubleshooting

### Issue: "PROJEKT.md not found"

**Solution:**
```bash
# Verify you're in correct directory
pwd

# Verify PROJEKT.md exists
ls -la docs/PROJEKT.md

# Or create symlink if needed
ln -s /path/to/PROJEKT.md docs/PROJEKT.md
```

### Issue: Tasks not parsing correctly

**Solution:**
```bash
# Check task table format (must have | UUID | Task | Status | ... |)
grep "^|.*TASK-" docs/PROJEKT.md | head -5

# Verify jq is installed for JSON parsing
which jq
```

### Issue: Scripts not executable

**Solution:**
```bash
chmod +x ~/.claude/skills/task-scheduler/scripts/*.sh
```

### Issue: Token-watcher not alerting

**Solution:**
```bash
# Verify bc is available (for numeric comparison)
which bc

# Or use alternative comparison
# (Script has fallback if bc not available)
```

---

## Integration with Other Skills

### project-doc-restructure

Nach `project-doc-restructure` Execution:
```bash
# Scheduler wird automatisch aufgerufen
# um neu-verfügbare Tasks zu identifizieren
```

### vault-manager

Scheduler kann vault-manager Tasks triggern:
```bash
# Future: TASK-005 könnte vault-manager Operation sein
# Scheduler würde automatisch den @notation-Trigger setzen
```

---

## Performance Tips

| Tip | Impact | Implementation |
|-----|--------|-----------------|
| **Keep PROJEKT.md small** | Faster parsing | Archive completed phases |
| **Limit dependencies** | Fewer cycles | Minimize cross-phase deps |
| **Pre-stage tasks** | Faster identification | Mark dependencies correctly |
| **Cache task metadata** | 10x faster (future) | Store task-name cache |

---

## Advanced: Custom Task Hook

Um eigene Post-Completion-Logik hinzuzufügen:

```bash
# Create ~/.claude/hooks/custom-task-hook.sh
#!/bin/bash

# Called after task-completion-hook.sh
INPUT=$(cat)
TASK_UUID=$(echo "$INPUT" | jq -r '.task_uuid')

# Custom logic here
echo "Custom hook for $TASK_UUID"

# Example: Trigger Slack notification
# curl -X POST $SLACK_WEBHOOK -d "Task $TASK_UUID completed"
```

Then register in Hook-System.

---

## Further Reading

- **SKILL.md**: Main skill documentation
- **SCHEDULER-ARCHITECTURE.md**: Technical deep-dive
- **docs/PROJEKT.md**: Current tasks + status
- **docs/tasks-template.md**: Task file format

---

**Last Updated:** 2026-01-19
**Version:** 1.0 (Phase C)
