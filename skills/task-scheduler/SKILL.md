---
name: task-scheduler
description: |
  Automatically orchestrate and execute project tasks from PROJEKT.md.
  Use this skill when you want to analyze pending tasks, resolve dependencies,
  and start background work. Triggered at session-start (optional) or via
  /run-next-tasks command.

  This skill reads PROJEKT.md, identifies ready tasks (dependencies met),
  starts background executions, and monitors completion via hooks.

model: sonnet
context: fork
agent: general-purpose
allowed-tools: Read, Bash, Glob, Grep
---

# Task Scheduler Skill

Automatisches Task-Management für dieses Projekt mit Dependency-Auflösung und Background-Execution.

## Funktionalität

### 1. Task Discovery & Dependency Resolution

**Input:** `docs/PROJEKT.md` (aktuelle Session-Phase)

**Process:**
1. Parse Task-Tabelle aus PROJEKT.md
2. Identifiziere Tasks mit Status `pending`
3. Überprüfe Dependencies (sind alle Voraussetzungen erfüllt?)
4. Kategorisiere in: `Ready` (keine Dependencies), `Blocked` (Dependencies pending)

**Output:** Task-Liste mit Dependency-Status

### 2. Background Task Execution

**For Ready Tasks:**
- Starte Background-Task via Claude Code Task-System
- Überwache Completion via Hook
- Bei Completion: Trigger Dependency-Release

**For Blocked Tasks:**
- Warte auf Dependency-Completion
- Zeige User: "Task X kann nach Task Y starten"

### 3. Token-Budget Awareness

**Monitoring:**
- Check Token-Usage bei jedem Task-Start
- Warn User bei 70% Verbrauch
- Suggest `/project-doc-restructure` bei >70%
- Recommend `/exit` bei >85%

### 3b. Vault-Enhanced Discovery (wenn Obsidian CLI verfuegbar)

**Feature-Detection:** `obsidian.com version 2>/dev/null` — wenn erfolgreich:

```bash
# Cross-Project Task-Uebersicht (alle Projekte, nicht nur aktuelles PWD)
obsidian.com base:query path="_dashboards/BASE_Claude_Tasks.base" format=json
```

**Nutzen:** Findet Tasks aus ALLEN Projekten im Claude Vault — nicht nur aus dem aktuellen PROJEKT.md. Ermoeglicht Cross-PWD Dependency-Checks.

**Fallback:** Ohne Obsidian CLI → nur PROJEKT.md-basierte Discovery (bisheriges Verhalten).

### 4. Automated PROJEKT.md Updates

**Nach Task-Completion:**
- Update Task-Status: `pending` → `completed`
- Notiere Completion-Timestamp
- Trigger nächste Ready-Tasks automatisch
- Aktualisiere Phase-Status

### 4b. Vault Status-Sync (wenn Obsidian CLI verfuegbar)

**Nach jedem PROJEKT.md-Update zusaetzlich:**

```bash
# Task-Status im Vault aktualisieren
obsidian.com property:set name="status" value="completed" type=text file="TASK-NNN-name"
```

**Wichtig:** PROJEKT.md bleibt SSOT. Vault-Updates sind Sync, nicht Ersatz. Bei Konflikten gilt PROJEKT.md.

## Komponenten

### Hauptscripts

#### `scheduler.sh` (~200 Zeilen Bash)

**Kernlogik:**
```bash
scheduler.sh [PROJEKT_PATH] [DRY_RUN=false]
```

**Funktionen:**
- `extract_task_table()`: Parse Task-Tabelle aus PROJEKT.md (jq + awk)
- `resolve_dependencies()`: Build Dependency-Graph
- `identify_ready_tasks()`: Filter Tasks ohne ausstehende Dependencies
- `start_background_task()`: Starte Task als Background-Execution
- `monitor_completion()`: Watch für Task-Ende-Events

**Output:** JSON mit Ready-Tasks + Status

#### `task-completion-hook.sh` (~100 Zeilen Bash)

**Trigger:** Nach Background-Task-Completion

**Input (JSON via stdin):**
```json
{
  "task_uuid": "TASK-005",
  "status": "completed",
  "result": "Success",
  "completion_timestamp": "2026-01-19 15:30"
}
```

**Funktionen:**
- `update_projekt_md()`: Update PROJEKT.md Task-Status
- `update_task_file()`: Update Task-Datei mit Completion-Info
- `trigger_next_tasks()`: Rufe Scheduler recursiv auf für nächste Ready-Tasks
- `notify_user()`: User-Notification senden

#### `token-watcher.sh` (~50 Zeilen Bash)

**Trigger:** Vor jedem Task-Start

**Input (JSON via stdin):**
```json
{
  "usage_pct": 72,
  "current": 144000,
  "limit": 200000
}
```

**Funktionen:**
- Check Token-Percentage
- Bei >70%: Warn User + suggest `/project-doc-restructure`
- Bei >85%: Recommend `/exit`

## Usage

### Automatisch bei Session-Start (Optional)

**Via Hook** (Plugin hooks.json registriert `session-start-scheduler.sh`):
```bash
#!/bin/bash
INPUT=$(cat)
if [ "$(echo "$INPUT" | jq -r '.event')" = "SessionStart" ]; then
    ${CLAUDE_PLUGIN_ROOT}/skills/task-scheduler/scripts/scheduler.sh
fi
```

### Manuell triggern

**Command:** `/run-next-tasks`
```bash
/run-next-tasks              # Normal mode
/run-next-tasks --dry-run    # Analyze only, don't execute
```

### Kombination mit Priorisierung

Für optimale Task-Auswahl, kombiniere mit `/prioritize-tasks`:

```bash
# Schritt 1: Ready-Tasks identifizieren
/run-next-tasks
# Output: TASK-023 ready, TASK-024 ready, TASK-025 blocked

# Schritt 2: Optimale Reihenfolge bestimmen (optional)
/prioritize-tasks
# Output: TASK-024 (Score 8.5) > TASK-023 (Score 6.2)

# Schritt 3: Höchste Priorität ausführen
"Arbeite TASK-024 ab"
```

**Workflow-Empfehlung:**
- `/run-next-tasks` = **WAS** ist bereit?
- `/prioritize-tasks` = **WELCHES** zuerst?

### Integration mit anderen Skills

**Called by:** `project-doc-restructure` Skill (nach DoD-Check)
**Calls:** Depends auf Background-Task-API (Claude Code)

## Task-Completion Workflow

**Sequence:**

```
1. User/Scheduler starts TASK-005
   ↓
2. Background Task runs (asynchronous)
   ↓
3. Task completed → Hook triggered
   ↓
4. task-completion-hook.sh receives JSON
   ↓
5. Updates PROJEKT.md + Task-Datei
   ↓
6. Re-runs scheduler.sh (finds TASK-006 now ready)
   ↓
7. Starts TASK-006 automatically
   ↓
8. Repeat until all ready tasks started
```

## Dependency Resolution Algorithm

**3-Schritt-Prozess:**

```
1. Extract Phase & Task-Status from PROJEKT.md
   └─ Find all Tasks with status "pending"

2. Build Dependency-Graph
   └─ For each pending Task:
      └─ Extract dependencies (TASK-XXX list)
      └─ Check if all dependencies "completed"

3. Categorize Tasks
   ├─ Ready: All dependencies met → can start
   ├─ Blocked: Some dependencies pending → wait
   └─ Unreachable: Circular dependency → error
```

**Example:**

```
TASK-005 depends on: [TASK-004]
  → If TASK-004 "completed" → Ready
  → If TASK-004 "pending" → Blocked

TASK-006 depends on: [TASK-005]
  → If TASK-005 "in_progress" → Blocked (wait)
  → If TASK-005 "completed" → Ready
```

## Parallel Execution Strategy

**Single-Thread Mode (Default):**
- Start one ready task at a time
- Wait for completion
- Then start next ready task
- Good for sequential dependencies

**Parallel Mode (Optional, Phase D+):**
- Group independent ready tasks
- Start multiple in parallel
- Reduces total execution time

**Example:**

```
Sequential:
  TASK-001 (1h) → TASK-002 (2h) → TASK-003 (1.5h)
  Total: 4.5h

Parallel (if independent):
  [TASK-001 (1h), TASK-004 (2h)] → TASK-005 (1.5h)
  Total: 3.5h (saves 1h)
```

## Error Handling

### Circular Dependencies

**Detection:**
```bash
if [ dependency_count -eq dependency_visited ]; then
  echo "Error: Circular dependency detected"
  exit 1
fi
```

**Resolution:** Fail gracefully, show dependency chain to user

### Task File Not Found

**Scenario:** Task-Datei existiert nicht
**Resolution:** Erstelle von Template, oder skip task

### PROJEKT.md Parse Error

**Scenario:** Ungültiges Markdown/JSON
**Resolution:** Show parse error, suggest manual PROJEKT.md review

### Token Budget Exceeded

**Scenario:** >85% Token-Usage
**Resolution:** Pause task execution, recommend `/exit`

## Configuration

### Environment Variables

```bash
# Optional: Override defaults
SCHEDULER_DRY_RUN=true          # Only analyze, don't execute
SCHEDULER_TOKEN_WARN_PCT=70     # Warning threshold
SCHEDULER_TOKEN_STOP_PCT=85     # Stop threshold
SCHEDULER_PARALLEL_MODE=false   # Single-thread (default)
```

### Task-Metadata Format (in PROJEKT.md)

```markdown
| UUID | Task | Status | Dependencies | Effort | Deliverable | Task-File |
|------|------|--------|--------------|--------|-------------|-----------|
| TASK-005 | Query Task | pending | [TASK-004] | 2h | artifact | [Link](tasks/...) |
```

**Required Fields:**
- UUID: TASK-NNN format
- Status: One of the 6 MECE status values (see below)
- Dependencies: JSON array or empty

### SSOT: Task-Status-Definitionen (6 MECE)

Dies ist die **kanonische Referenz** für alle Task-Status-Werte im gesamten Ecosystem.

| Status | Icon | Bedeutung | Scheduler-Verhalten |
|--------|------|-----------|---------------------|
| `pending` | 📋 | Wartet auf Start | → Prüft Dependencies → ready/blocked |
| `in_progress` | ⏳ | Wird aktiv bearbeitet (hat Endpunkt) | → Ignoriert (bereits gestartet) |
| `ongoing` | 📘 | Dauerhaft gepflegt (Living Document) | → Ignoriert (kein Endpunkt) |
| `completed` | ✅ | Erfolgreich abgeschlossen | → Terminal (erfüllt Dependencies) |
| `blocked` | 🚫 | Externe Abhängigkeit verhindert Fortschritt | → Ignoriert (wartet auf externen Input) |
| `cancelled` | ❌ | Bewusst abgebrochen, nicht mehr relevant | → Terminal (erfüllt Dependencies) |

**Regeln:**
- **Terminal-Status:** `completed` und `cancelled` erfüllen Dependencies anderer Tasks
- **Aktiv-Status:** `in_progress` und `ongoing` werden vom Scheduler nicht angetastet
- **Wartend-Status:** `pending` wird auf Dependency-Erfüllung geprüft
- **Pausiert-Status:** `blocked` wartet auf manuelles Unblocking

## Integration Points

### Hooks

**Pre-Execution:**
- `PreTaskStart`: Token-Watcher activation
- `PostTaskStart`: Logging + Notification

**Post-Execution:**
- `PostTaskComplete`: task-completion-hook.sh
- `PreDocumentUpdate`: Validate PROJEKT.md before update

### Commands

- `/run-next-tasks`: Manual trigger
- `/run-next-tasks --dry-run`: Analysis only

### Skills

- `project-doc-restructure`: Calls scheduler before restructuring
- `vault-manager`: Can be triggered by scheduler for UC2/UC3 tasks

## Performance Metrics

| Operation | Time | Notes |
|-----------|------|-------|
| Parse PROJEKT.md | ~50ms | Depends on file size |
| Dependency Resolution | ~10ms | O(n²) but small n |
| Task Start | ~100-500ms | Depends on background system |
| Hook Execution | ~50ms | Bash script overhead |
| PROJEKT.md Update | ~20ms | sed replacement |

**Total End-to-End:** ~200-700ms per task cycle

## Testing & Validation

### Test 1: Basic Task Discovery

**Inputs:** PROJEKT.md with 5 Tasks (3 pending, 2 completed)
**Expected:** Extract 3 pending tasks, show names

### Test 2: Dependency Resolution

**Inputs:** TASK-A depends on TASK-B (pending)
**Expected:** TASK-A marked as "Blocked", TASK-B marked as "Ready"

### Test 3: Completion Hook

**Inputs:** JSON with TASK-XXX completion
**Expected:** PROJEKT.md updated, next task started automatically

### Test 4: Token-Budget Trigger

**Inputs:** Token usage 72%
**Expected:** Warning message + `/project-doc-restructure` suggestion

## Deployment

### Installation (Plugin)

```bash
# Via Claude Code Plugin Marketplace:
claude plugin marketplace add <marketplace-url>
claude plugin install persist@<marketplace>
# Session neustarten — Plugin wird automatisch geladen
```

### Troubleshooting

**Scheduler not triggering:**
- Check: Plugin ist installiert (`claude plugin list`)
- Check: Auto-Discovery keywords in description

**Tasks not progressing:**
- Check: Dependencies in PROJEKT.md (correct format?)
- Check: Task file paths exist
- Run: `/run-next-tasks --dry-run` to diagnose

**Token-Watcher not alerting:**
- Check: Hook registered in Claude Code
- Check: Token-calculation is correct

---

## Further Reading

- **SETUP.md**: Installation guide + configuration
- **SCHEDULER-ARCHITECTURE.md**: Deep technical details + algorithms
- **PROJEKT.md**: Current tasks + phase status
- **docs/tasks-template.md**: Task-file format reference

---

**Autor:** Claude Haiku 4.5
**Erstellt:** 2026-01-19
**Aktualisiert:** 2026-01-19
**Status:** ⏳ In Development (Phase C)
