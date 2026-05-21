---
name: project-init
description: |
  Complete session-continuous project initialization infrastructure. Creates CLAUDE.md, PROJEKT.md, task tracking system, and activates task-scheduler + session-refresh workflow.

  Use when: (1) Starting a new project and need Session-Continuous setup, (2) Existing project lacks documentation infrastructure, (3) Want to enable automatic task scheduling + documentation optimization.

  Implements: UUID-based task tracking (TASK-001, etc.), session-refresh automation, token budget awareness, phase-based workflow.

  Phase 4 (optional, Windows only): Quickstart artifacts — project icon, Windows Terminal profile with tabColor/tabTitle, Desktop .lnk shortcut. Silently skipped on Linux/Mac.

tools: Read, Edit, Bash, Write
---

# Project Init Skill

Automated setup of session-continuous project infrastructure with task-scheduler integration.

## What This Skill Does

Creates a production-grade project setup in 15-20 minutes:

1. **Directory Structure** - Creates 5 default folders (00_KONTEXT, 10_INPUT, 20_OUTPUT, 90_DOCS, 99_ARCHIV) + task hierarchy
2. **CLAUDE.md** - Project architecture + conventions (uses existing if provided)
   - **Auto-injects:** "Session-Continuous Workflow" section explaining `/session-refresh`, `/run-next-tasks`, task tracking
3. **PROJEKT.md** - Active phase with UUID-based tasks (TASK-001, etc.)
4. **First Task** - TASK-001 (Project Setup) ready to execute
5. **Onboarding Tutorial (optional)** - Asks user if TASK-000 tutorial should be included (10-step guided setup)
6. **Integration** - Hooks into global `/session-refresh` + `/run-next-tasks` skills

**Task Template (SSOT):** `${CLAUDE_PLUGIN_ROOT}/skills/project-init/assets/task-md-template.txt` - NOT copied to projects

**Result:** Complete workflow automatically activated. New developers get embedded workflow documentation in CLAUDE.md. Next session: Read CLAUDE.md + PROJEKT.md (includes workflow instructions) → `/run-next-tasks` → start working. Run `/session-refresh` at session END (or when token >65%).

---

## When to Use This Skill

✅ **Perfect for:**
- Brand new projects (no documentation yet)
- Existing projects without session-continuous setup
- Teams/individuals adopting structured task tracking
- Any project wanting automatic documentation optimization

❌ **Not needed if:**
- Project already has CLAUDE.md + PROJEKT.md + task infrastructure
- Using external project management tool (Jira, Asana, etc.)

---

## Quick Start (5 Steps)

### Step 1: Provide Project Details

Before running initialization, tell me:

```
Project Name: [Your Project]
Description: [One sentence: what does this project do?]
Tech Stack: [Languages/frameworks]
Architecture: [MVC / Microservices / etc.]
```

### Step 2: Run Setup

```bash
# Option A: New project (from scratch)
cd /your/new/project
/project-init

# Option B: Existing project with existing CLAUDE.md
cd /your/existing/project
/project-init --from-claude-md ./CLAUDE.md

# Option C: Custom documentation folder (e.g., 90_DOCS instead of docs)
cd /your/project
/project-init --docs-path 90_DOCS

# Kombiniert: Beides
/project-init --from-claude-md ./CLAUDE.md --docs-path 90_DOCS
```

**Parameter:**
| Parameter | Default | Beschreibung |
|-----------|---------|--------------|
| `--docs-path PATH` | `90_DOCS` | Dokumentations-Ordner (Legacy: `docs`) |
| `--from-claude-md PATH` | - | Existierende CLAUDE.md kopieren |

### Step 3: Customize Files

The skill creates:
- ✓ CLAUDE.md (customize: goals, tech stack, conventions)
- ✓ PROJEKT.md (customize: phase 1 tasks)
- ✓ 90_DOCS/tasks/TASK-001-setup.md (first task)

**Task Template:** Use `${CLAUDE_PLUGIN_ROOT}/skills/project-init/assets/task-md-template.txt` for new tasks

**Action:** Edit CLAUDE.md + PROJEKT.md to add your project-specific details

**Vault-Integration (optional):** Wenn `obsidian.com version 2>/dev/null` erfolgreich:
- Erstelle `claude-project` Dokument im Vault: `obsidian.com create name="PROJECT-{pwd}" path="_claude-pm" content="<Frontmatter + Body>"`
- Erstelle `claude-task` fuer TASK-001: `obsidian.com create name="TASK-001-setup" path="_claude-pm" content="<Frontmatter>"`
- Fallback: Ohne Obsidian CLI werden nur lokale Dateien erstellt (bisheriges Verhalten)

### Step 4: Verify Setup

```bash
# Check file sizes and structure
./scripts/validate-setup.sh .
# Expected: All critical checks ✅, warnings optional
```

### Step 5: Start First Session

```bash
# From project root
/run-next-tasks   # Show next ready task
# Work on tasks...
# At session END (or token >65%):
/session-refresh  # Update docs, optimize context, prepare for next session
```

**Done!** Your project is now integrated into the session-continuous workflow.

---

## Project Structure Created

```
your-project/
├── CLAUDE.md                    # Architecture + conventions (ALWAYS in root)
├── 00_KONTEXT/                  # Project context (briefings, requirements, scope)
├── 10_INPUT/                    # Incoming materials
│   ├── Rohdaten/               # Raw data (CSV, Excel)
│   ├── Zulieferungen/          # Third-party documents
│   ├── Referenzmaterial/       # Best practices, benchmarks
│   └── Vorlagen/               # Templates, forms
├── 20_OUTPUT/                   # Project deliverables
│   ├── Deliverables/           # Final results for clients
│   ├── Praesentationen/        # Slides, pitch decks
│   ├── Reports/                # Analysis, evaluations
│   └── Exports/                # Generated artifacts
├── 90_DOCS/                     # Project management (default --docs-path)
│   ├── PROJEKT.md              # Active phase + tasks (SSOT)
│   ├── tasks/
│   │   ├── TASK-001-setup.md        # Task documentation (DIRECT in tasks/)
│   │   ├── TASK-001/                # Task outputs directory
│   │   │   ├── execution-logs/      # Background agent logs
│   │   │   └── artifacts/           # Generated outputs
│   │   └── TASK-NNN/                # Output directories per task
│   ├── handoffs/                # Session handoff files
│   │   └── LATEST-HANDOFF.md
│   └── phases/                  # Archived completed phases
├── 99_ARCHIV/                   # Completed and outdated materials
│   ├── alte-versionen/          # Superseded documents
│   ├── abgeschlossen/          # Completed work packages
│   └── referenz/               # Historical references
└── [other project files...]
```

**Naming Convention:** `NN_NAME` (two-digit number, uppercase, 10-step increments for future insertions)

**Legacy support:** Use `--docs-path docs` for projects using the old `docs/` structure.

**Task Template (SSOT):** `${CLAUDE_PLUGIN_ROOT}/skills/project-init/assets/task-md-template.txt`

**Key constraints:**
- CLAUDE.md + PROJEKT.md each <8,000 chars (automatically enforced)
- Task outputs go to `tasks/TASK-NNN/execution-logs/` and `tasks/TASK-NNN/artifacts/`
- Completed phases archived to `phases/Phase-NN-Name.md`

---

## Phase Archival (Phasen-Auslagerung)

### Konzept

Wenn eine Phase vollständig abgeschlossen ist, wird ihr Content aus PROJEKT.md in eine separate Datei ausgelagert. Dies hält PROJEKT.md kompakt und fokussiert auf aktive Arbeit.

**Prinzip:**
- PROJEKT.md bleibt SSOT (Single Source of Truth) für **aktuelle** Tasks
- Historische Phasen werden in `docs/phases/` archiviert
- Links in PROJEKT.md verweisen auf archivierte Phasen

### Wann auslagern?

Eine Phase wird ausgelagert wenn:
1. Alle Tasks der Phase: Status `✅ completed`
2. Definition of Done: Alle Kriterien erfüllt
3. Nächste Phase beginnt

### Workflow

```
Phase abgeschlossen?
├─ Erstelle: docs/phases/Phase-NN-Name.md
│   └─ Nutze Template: assets/phase-template.txt
├─ Kopiere: Phase-Content aus PROJEKT.md
│   └─ Header, DoD, Tasks, Learnings
├─ Ersetze in PROJEKT.md:
│   └─ Inline-Content → Link zur Phase-Datei
└─ Verifiziere: PROJEKT.md <8K Bytes
```

### Template

Das Phase-Template (`assets/phase-template.txt`) enthält:
- Header (Phase-Nummer, Name, Status, Zeitraum)
- Definition of Done (erfüllte Checkboxen)
- Tasks-Tabelle (historisch, 7-Column Format)
- Learnings Section (Positive, Verbesserungen, Erkenntnisse)
- Audit Trail (wichtige Ereignisse)
- Referenzen (Links zu verwandten Phasen)

### Beispiel

**Vor Auslagerung (in PROJEKT.md):**
```markdown
### Phase 1: Foundation (AKTIV)
[DoD, Tasks, Details - ca. 2000 Zeichen]
```

**Nach Auslagerung (in PROJEKT.md):**
```markdown
## Abgeschlossene Phasen
| Phase | Status | Zeitraum | Link |
|-------|--------|----------|------|
| Phase 01: Foundation | ✅ | 2025-01-15 - 2025-01-20 | [Details](phases/Phase-01-Foundation.md) |
```

**Archiviert (in docs/phases/Phase-01-Foundation.md):**
```markdown
# Phase 01: Foundation
[Vollständiger Content mit Learnings und Audit Trail]
```

---

## How It Works: Multi-Phase Execution

### Phase 1: Initialize Infrastructure

The skill:
1. Creates `docs/tasks/` directory with TASK-001 output structure
2. Creates/verifies CLAUDE.md (uses existing if provided via `--from-claude-md`)
3. Creates PROJEKT.md with task table structure
4. Creates TASK-001-setup.md (first task, ready to execute)

**Note:** Task template is NOT copied to projects. Use SSOT: `assets/task-md-template.txt`

**Output:** Directory structure complete, all files in place

### Phase 1b: Onboarding Tutorial (TASK-000) — Optional

After creating the base structure, check if the onboarding tutorial assets exist:

```
${CLAUDE_PLUGIN_ROOT}/skills/project-init/assets/onboarding/TASK-000-onboarding.md
```

**If the file exists**, ask the user via AskUserQuestion:

> "Moechten Sie das Onboarding-Tutorial (TASK-000) in Ihr Projekt aufnehmen? Das Tutorial fuehrt durch 10 Schritte: von der Installation bis zur ersten eigenstaendigen Session."
>
> Options: "Ja, Tutorial einbinden" / "Nein, ueberspringen"

**If user says YES:**
1. Read `assets/onboarding/TASK-000-onboarding.md` and write it to `{docs_path}/tasks/TASK-000-onboarding.md`
2. Create directory `{docs_path}/tasks/TASK-000/artifacts/`
3. Read `assets/onboarding/artifacts/cheatsheet.md` and write it to `{docs_path}/tasks/TASK-000/artifacts/cheatsheet.md`
4. Read `assets/onboarding/artifacts/first-steps-guide.md` and write it to `{docs_path}/tasks/TASK-000/artifacts/first-steps-guide.md`
5. Add TASK-000 row to PROJEKT.md task table (BEFORE TASK-001):
   ```
   | **TASK-000** | Onboarding Tutorial | 📋 pending | None | 2h | Setup + Session-Continuity | [Details](tasks/TASK-000-onboarding.md) |
   ```

**If user says NO:**
- Do nothing. No TASK-000 files, no row in PROJEKT.md.

**If the onboarding assets do NOT exist** (e.g., user has older Knowledge Hub version):
- Skip silently. Do not ask the user.

### Phase 2: Load Global Workflow

The skill checks:
- `~/.claude/CLAUDE.md` has "Session-Continuous Projects" section ✅
- `${CLAUDE_PLUGIN_ROOT}/skills/session-refresh/` exists ✅
- `${CLAUDE_PLUGIN_ROOT}/skills/task-scheduler/` exists ✅

**Result:** Global infrastructure ready to support your project

### Phase 3: Validate & Report

The skill:
1. Verifies CLAUDE.md + PROJEKT.md <8K chars each ✅
2. Checks all required files exist
3. Shows validation report with status + next steps

**Example output:**
```
✓ CLAUDE.md: 4,250 bytes (under limit)
✓ PROJEKT.md: 3,850 bytes (under limit)
✓ Task structure: 5 files created
✓ Global workflow: Ready

Next: Customize CLAUDE.md, then /session-refresh
```

### Phase 4: Windows Quickstart (Optional)

**Trigger:** Only on Windows with Windows Terminal installed. Silent skip on Linux/Mac/missing wt.exe (`scripts/quickstart-orchestrator.sh` exits 10 or 11 — non-error).

**What it does:** After CLAUDE.md + PROJEKT.md are created (Phases 1-3), this phase produces three convenience artifacts to make `claude` start instantly from the desktop:

1. **Project icon** at `<PWD>\.claude-icon.ico` (multi-resolution 16/32/48/256, V2-squircle variant with project-themed symbol)
2. **Windows Terminal profile** in `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` with `commandline` (`pwsh -NoExit -Command "Set-Location ...; claude"`), `tabColor` (matches icon accent color), `tabTitle`, `icon`, and UUID v4 `guid`
3. **Desktop shortcut** `<Desktop>\<project-name>.lnk` targeting `wt.exe -p "<project-name>"` with the project icon

#### User Interaction (LLM-Skill-Layer)

Before delegating to `quickstart-orchestrator.sh`, ask via AskUserQuestion:

> "Windows Quickstart erstellen? (Desktop-Verknuepfung + WT-Profil + Icon)"
> — Default: "Ja, erstellen" / Alternative: "Ueberspringen"

If accepted, derive **SYMBOL** + **ACCENT_HEX** from the freshly created `CLAUDE.md`:

- **SYMBOL** — one of: `sparkle`, `code`, `search`, `shield`, `gear`, `diamond`, `layers`, `lightning`, `compass`, `pen`, `book`, `puzzle`, `brain`, `cloud`, `terminal`. Pick the symbol that best represents the project's purpose.
- **ACCENT_HEX** — hex color that harmonizes with Claude Orange (`#D4724A`). Use a complementary or analogous tone derived from the project theme.

Fallback if CLAUDE.md analysis is inconclusive: `sparkle` + `#D4724A`.

#### Invocation

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/project-init/scripts/quickstart-orchestrator.sh" \
  "$PWD" "$PROJECT_NAME" "$SYMBOL" "$ACCENT_HEX"
```

The orchestrator chains three helpers:

1. `quickstart-icon.py` — generates `.claude-icon.ico` + `.claude-icon.meta.json`, prints meta JSON to stdout (parsed via `jq` for the resolved accent color)
2. `quickstart-wt-profile.py` — inserts WT profile with UUID v4, creates `settings.json.bak.YYYYMMDD-HHMMSS`, validates JSON beidseitig
3. `quickstart-shortcut.ps1` — creates `.lnk` via `WScript.Shell` COM (invoked through `pwsh.exe -File`)

#### Exit Code Handling

| Exit | Meaning | Skill Response |
|------|---------|---------------|
| 0 | Success | Show summary + "Restart Windows Terminal once" hint |
| 10 | Not Windows | Silent skip (Linux/Mac/other) — no Phase 4 output |
| 11 | wt.exe not installed | Inform user: "Windows Terminal not installed — Phase 4 skipped" |
| 20 | settings.json not found | Error: Preview/Unpackaged WT installations not supported |
| 21 | pwsh.exe not found | Error: ask user to install PowerShell 7+ |
| 30 | Icon generation failed | Show stderr, suggest `pip install Pillow` if missing |
| 31 | WT profile insert failed | Show stderr, manual recovery from `.bak` if needed |
| 32 | Profile name already exists | AskUserQuestion: ueberschreiben (re-run with FORCE=true) / abbrechen |
| 33 | Shortcut creation failed | Show stderr, suggest manual `.lnk` creation |
| 34 | Shortcut already exists | AskUserQuestion: ueberschreiben (re-run with FORCE=true) / abbrechen |
| 40 | Missing dependency | Inform user: `python` or `jq` not in PATH |

#### Force-Retry Pattern

When exit code 32 or 34 returns "Profile/Shortcut already exists" and the user chooses to overwrite:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/project-init/scripts/quickstart-orchestrator.sh" \
  "$PWD" "$PROJECT_NAME" "$SYMBOL" "$ACCENT_HEX" true
```

The fifth argument `true` enables `--force` (passed to `quickstart-wt-profile.py`) and `-Force` (passed to `quickstart-shortcut.ps1`). Original GUID is preserved on profile overwrite (idempotent identity).

#### Output JSON

On success (exit 0), the orchestrator prints a machine-readable summary to stdout:

```json
{
  "status": "ok",
  "icon": "C:\\Development\\Projects\\Claude\\MyProject\\.claude-icon.ico",
  "wt_profile": {"name": "MyProject", "tab_color": "#D4724A", "guid": "{xxxxxxxx-xxxx-...}"},
  "shortcut": "C:\\Users\\Jonas\\Desktop\\MyProject.lnk"
}
```

#### Important Notes

- **Restart required:** Windows Terminal caches profiles at startup. After Phase 4 completes, the user must close + reopen Windows Terminal once for the new profile to appear in the dropdown.
- **Icon in PWD:** The `.claude-icon.ico` lives in the project root. Consider adding it to `.gitignore` if the project repo should stay icon-free; commit it if you want the icon to travel with the project.
- **Idempotency:** Re-running Phase 4 on an unchanged project is safe — icon overwrites in place (no suffix counter), profile/shortcut require FORCE=true to overwrite (deliberate guard).
- **Public Release Safety:** The OS-gate ensures Linux/Mac users never see Phase 4. The PowerShell helper is shipped in the public `claude-persist` repo but only executed on Windows.

---

## File Details & Constraints

### CLAUDE.md (Project)
- **Size:** ~5-6KB after Compact Block injection (well under 8KB limit)
  - Base template: ~1,500 chars (guidelines, conventions)
  - Vault-First Compact Block: ~4KB (Feature Detection + Dual-Path Workflow)
- **Content:** Architecture, conventions, development guidelines, **+ Session-Continuous Workflow (Compact)**
- **Auto-Injected Compact Block covers:**
  - Feature Detection (`obsidian.com version` → Vault-First or Local Fallback)
  - Session lifecycle (start, during, end)
  - Task structure + creation steps
  - Token budget thresholds
  - Commands reference (`/run-next-tasks`, `/session-refresh`)
  - Detail-Reference: `session-workflow` Skill (on-demand)
- **Update:** When architecture changes; edit Workflow section as developers learn patterns
- **How to customize:** Replace placeholders: `[Project Name]`, `[Description]`, etc.

### PROJEKT.md (Executive Summary + Active Phase)
- **Size:** <8,000 chars (hard limit)
- **Role depends on mode:**
  - **Vault-First:** Executive Summary + Known Issues + Phase Overview. Task-Status kommt aus Vault Base.
  - **Local Fallback:** Executive Summary + 7-Column Task Table als SSOT fuer task-scheduler.
- **Sections:** Executive Summary, Immediate Actions, Current Phase, Known Issues
- **Update:** After each task completion (or phase change)
- **How to customize:** Add project-specific goals, phase definitions, known issues

### Task Files (docs/tasks/TASK-NNN-name.md)
- **Format:** UUID: TASK-001, TASK-002, etc. (zero-padded)
- **Structure:**
  - `tasks/TASK-NNN-name.md` - Task documentation DIRECTLY under tasks/ (Objective, Steps, Criteria, Audit Trail)
  - `tasks/TASK-NNN/` - Output directory per task:
    - `execution-logs/` - Background agent output logs
    - `artifacts/` - Generated outputs (reports, exports, etc.)
- **Size:** No limit (can be verbose)
- **Created:** Skill creates TASK-001 with output directories; for new tasks use `assets/task-md-template.txt`
- **Usage:** `/run-next-tasks` parses PROJEKT.md to find ready tasks

---

## Auto-Injected Vault-First Compact Block (Key Feature)

### Why It's Important

Every new project gets a **"Session-Continuous Workflow"** section auto-injected into CLAUDE.md. This section:

✅ **Feature Detection** — Vault-First or Local Fallback, determined at runtime
✅ **Dual-Path Workflow** — Works with and without Obsidian CLI
✅ **Compact (~4KB)** — Well under 8KB limit, leaves room for project-specific content
✅ **Detail-Reference** — `session-workflow` Skill for advanced operations (on-demand)

### What's Included

The Compact Block covers:

```
├─ Feature Detection: obsidian.com version → mode selection
├─ At Session Start: Read docs, feature detect, /run-next-tasks
├─ During Work: Dual-path status updates (Vault / Local)
├─ At Session End: /session-refresh, auto-commit + handoff
├─ Task Structure: File layout + creation steps
├─ Token Budget: Thresholds + actions
└─ Commands: /run-next-tasks, /session-refresh
```

### Size Impact

| Component | Size | Notes |
|-----------|------|-------|
| Base CLAUDE.md template | ~1.5KB | Architecture, guidelines |
| Vault-First Compact Block | ~4KB | Workflow (injected from workflow-block.txt) |
| **Total** | **~5.5KB** | **Well under 8KB limit** |

**Verglichen mit frueher:** Old Full Injection war ~10KB → CLAUDE.md ueberschritt 8KB Limit.
Compact Block + session-workflow Skill = gleiche Information, ~60% weniger Token-Verbrauch.

---

## Integration with Global Skills

### session-refresh (Auto-Triggered)

```
Typical workflow:
1. Developer works on tasks (Phase 1, 2, 3, ...)
2. Token budget reaches 65%
3. Developer triggers: /session-refresh

session-refresh then:
- Guides CLAUDE.md update (learnings, architecture changes)
- Guides PROJEKT.md update (task status, phase progress)
- Auto-triggers /project-doc-restructure (optimize TTO)
- User reduziert Token-Budget manuell (CLI Built-in)

Result: Fresh context budget, docs up-to-date, ready for next phase
```

### task-scheduler (Via /run-next-tasks)

```
Usage:
$ /run-next-tasks

Scheduler parses PROJEKT.md task table:
├─ Extracts UUIDs (TASK-001, TASK-002, etc.)
├─ Extracts status (completed ✅, pending 📋, in_progress ⏳)
├─ Extracts dependencies (TASK-002 depends on TASK-001)
└─ Builds dependency graph

Output: Shows next ready task(s)
├─ TASK-003: Ready (TASK-002 completed)
├─ TASK-004: Ready (TASK-001 completed)
└─ TASK-005: Blocked (waiting for TASK-003 AND TASK-004)
```

### Task Schema Format (7-Column Standard)

This skill creates PROJEKT.md with a standardized **7-column task schema** for full compatibility with `/run-next-tasks` dependency resolution:

```
| UUID | Task | Status | Dependencies | Effort | Deliverable | Task-File |
|------|------|--------|--------------|--------|-------------|-----------|
| **TASK-001** | Project Setup | 📋 pending | None | 1h | docs | [Details](tasks/TASK-001-setup.md) |
| **TASK-002** | Feature XYZ | 📋 pending | TASK-001 | 2h | component | [Details](tasks/TASK-002-feature.md) |
```

**Column Definitions:**
- **UUID:** Unique identifier (TASK-001, TASK-002, etc.)
- **Task:** Short description of the work
- **Status:** Current state (📋 pending, ⏳ in_progress, ✅ completed)
- **Dependencies:** Prerequisite tasks (comma-separated if multiple)
- **Effort:** Estimated effort (1h, 2h, 4h, 1d, etc.)
- **Deliverable:** What this task produces
- **Task-File:** Link to detailed task documentation (docs/tasks/TASK-NNN-name.md)

**Why this schema?**
- **Dependencies column** enables `/run-next-tasks` to resolve which tasks are ready
- **Standardized format** ensures consistency across all projects
- **Synchronized with project-doc-restructure** - both skills use identical schema (SSOT principle)
- **task-scheduler compatible** - the skill recognizes this exact format

**Verification:**
```bash
# After project creation, verify schema:
grep "| UUID | Task | Status | Dependencies" docs/PROJEKT.md
# Expected: ✅ Found (confirms task-scheduler compatibility)

# Test dependency resolution:
/run-next-tasks
# Expected: ✅ Ready tasks identified correctly
```

---

## Common Workflows

### Workflow A: New Project from Scratch

```
1. cd /new/project
2. (optionally) Create README.md with project details
3. /project-init
4. Answer prompts: project name, description, tech stack
5. Files created: CLAUDE.md, PROJEKT.md, task structure
6. Edit files: Customize with project-specific details
7. /validate-setup (optional, verify everything)
8. /session-refresh (first session)
9. /run-next-tasks (start TASK-001)
```

**Time:** 15-20 min | **Result:** Production-ready setup

### Workflow B: Existing Project with CLAUDE.md

```
1. cd /existing/project
2. /project-init --from-claude-md ./CLAUDE.md
3. (skill copies CLAUDE.md, creates PROJEKT.md + task structure)
4. Edit PROJEKT.md: Add your 3-5 first tasks
5. /session-refresh
6. /run-next-tasks
```

**Time:** 10-15 min | **Result:** Existing project now has task tracking

### Workflow C: Adopt for Existing Project (Already Has Docs)

```
1. If project has existing CLAUDE.md:
   /project-init --from-claude-md ./CLAUDE.md
   → Uses your file, creates task infrastructure

2. If starting fresh:
   /project-init
   → Creates CLAUDE.md template, you fill in details
```

**Result:** Flexible - works with or without existing documentation

---

## Step-by-Step: First Session After Setup

```
Session 1: After running /project-init
├─ Read: CLAUDE.md (understand your project)
├─ Read: PROJEKT.md (see Phase 1 tasks)
├─ Run: /validate-setup (optional verification)
├─ Run: /session-refresh
│  └─ Guides: Update CLAUDE.md sections
│  └─ Guides: Verify PROJEKT.md tasks
│  └─ Auto-runs: /project-doc-restructure
│  └─ User reduziert Token-Budget manuell
├─ Run: /run-next-tasks
│  └─ Shows: "TASK-001 ready to execute"
└─ Start working on TASK-001

Session 2+ (after TASK-001 complete):
├─ Mark TASK-001 ✅ in PROJEKT.md
├─ /run-next-tasks
│  └─ Shows: "TASK-002, TASK-003 ready (no dependencies)"
├─ Start TASK-002 (or TASK-003 if parallel OK)
└─ Repeat pattern
```

---

## Assets & References

**All included in this skill:**

1. **Templates** (assets/)
   - `claude-md-template.txt` - CLAUDE.md starter
   - `projekt-md-template.txt` - PROJEKT.md starter
   - `task-md-template.txt` - Task file starter
   - Session-Handoff Template: siehe `${CLAUDE_PLUGIN_ROOT}/skills/session-refresh/assets/session-handoff-template.md` (SSOT)
   - `phase-template.txt` - Archived phase template (for completed phases)
   - `workflow-block.txt` - Session-Continuous workflow section (auto-injected)
   - `onboarding/TASK-000-onboarding.md` - Onboarding tutorial (optional, copied on user consent)
   - `onboarding/artifacts/cheatsheet.md` - Quick reference card
   - `onboarding/artifacts/first-steps-guide.md` - Companion guide with costs, troubleshooting

2. **Scripts** (scripts/)
   - `init-project.sh` - Main setup orchestration
   - `validate-setup.sh` - Verification script

3. **References** (references/)
   - `WORKFLOW.md` - Deep dive into session-continuous workflow
   - `ONBOARDING.md` (see: NEW-PROJECT-ONBOARDING.md in project)

---

## Frequently Asked Questions

**Q: Can I use a different folder name than `docs/`?**
A: Yes! Use the `--docs-path` parameter:
```bash
/project-init --docs-path 90_DOCS
```
This creates `90_DOCS/` instead of `docs/`. All templates and references automatically use the configured path.

**Q: Can I use this with an existing CLAUDE.md?**
A: Yes! Run: `/project-init --from-claude-md ./CLAUDE.md`

**Q: What if my project already has docs structure?**
A: The skill skips existing files (CLAUDE.md, PROJEKT.md). It only creates missing pieces.

**Q: Can I customize the templates?**
A: Absolutely! After skill runs, edit CLAUDE.md + PROJEKT.md directly. Templates are just starters.

**Q: Do I have to use all the files created?**
A: No. Minimum required: CLAUDE.md + PROJEKT.md. The rest (tasks/, templates) are optional but recommended.

**Q: What if CLAUDE.md or PROJEKT.md goes over 8K chars?**
A: The skill validates on creation. If you add too much content later:
- Move historical content to PROJEKT-ARCHIVE.md
- Compress/remove verbose sections
- `/session-refresh` can help reorganize

**Q: How does task-scheduler know what to run next?**
A: It parses PROJEKT.md task table: Looks for `📋 pending` status with no unsatisfied dependencies. Those become "ready tasks" shown by `/run-next-tasks`.

**Q: Can I have multiple sessions without re-running /project-init?**
A: Yes! After first setup, just run: `/session-refresh` → `/run-next-tasks` → work. No re-init needed.

---

## Troubleshooting

### Problem: Script fails: "Project directory not found"
**Fix:** Ensure you're in the right directory or provide full path:
```bash
/project-init /path/to/project
```

### Problem: "CLAUDE.md already exists - skipping"
**Fix:** This is expected! If you want to replace it:
```bash
rm CLAUDE.md
/project-init
```

Or use existing:
```bash
/project-init --from-claude-md ./CLAUDE.md
```

### Problem: `/validate-setup` shows warnings
**Severity:** Low - mostly optional (like session handoff not created yet)
**Action:** Create missing files as needed (can do after first session)

### Problem: PROJEKT.md is over 8K chars
**Cause:** Added too much content from multiple phases
**Fix:** Create PROJEKT-ARCHIVE.md, move completed phases there

See `references/WORKFLOW.md` for more patterns.

---

## Next Steps After Setup

1. **Customize:** Edit CLAUDE.md + PROJEKT.md with your details (5 min)
2. **First Session:** Run `/session-refresh` to test workflow (10 min)
3. **Start Working:** `/run-next-tasks` to begin TASK-001 (ongoing)
4. **Regular Pattern:** After each task, mark completed → `/run-next-tasks` → next task

---

## For Detailed Workflow Guide

See: `references/WORKFLOW.md` in this skill
- Deep dive into each mechanism
- Dependency resolution patterns
- Token budget tracking
- Phase transitions
- Best practices

---

*Powered by session-continuous project architecture*