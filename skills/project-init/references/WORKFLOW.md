# Session-Continuous Workflow Reference

Complete guide to the workflow architecture enabled by project-init.

---

## Core Workflow Loop

```
Session Start
    ↓
[Global CLAUDE.md loads] → Shows: "Read project CLAUDE.md + PROJEKT.md"
    ↓
[Developer reads CLAUDE.md] → Understands: Architecture, conventions
    ↓
[Developer reads PROJEKT.md] → Knows: Current phase, next tasks
    ↓
[Developer triggers: /session-refresh] → Interactive workflow:
    ├─ Update CLAUDE.md sections (guided checklist)
    ├─ Verify PROJEKT.md tasks (guided checklist)
    ├─ Auto-trigger: /project-doc-restructure (optimize TTO)
    └─ User reduziert Token-Budget manuell (CLI Built-in)
    ↓
[Fresh Context] → Ready to work with optimized documentation
    ↓
[Developer works on tasks]
    ├─ /run-next-tasks → Shows ready tasks
    ├─ Update PROJEKT.md after each task (mark completed)
    └─ Session-end: Write SESSION-HANDOFF-YYYY-MM-DD.md
    ↓
[Next session starts] → Loop repeats with updated docs
```

---

## Execution Certainty Mechanisms

### Mechanism 1: Global CLAUDE.md Meta-Instruction
- **Trigger:** Every session start (automatic)
- **Certainty:** 98% (always loads)
- **Output:** "Read project CLAUDE.md + PROJEKT.md, then /session-refresh"
- **File:** `~/.claude/CLAUDE.md` Section: "Session-Continuous Projects"

### Mechanism 2: Semantic Auto-Discovery
- **Trigger:** User input keywords: "session start", "session refresh", "new session", "phase transition"
- **Certainty:** 60-80% (semantic matching)
- **Mechanism:** session-refresh SKILL.md description
- **Fallback:** Global CLAUDE.md instruction still visible

### Combined Certainty
- **Both mechanisms:** >99% probability workflow triggers correctly
- **Failure scenario:** Very rare (would need both mechanisms to fail)

---

## File Structure & Constraints

### Critical Files

**1. CLAUDE.md (Project)**
- **Location:** `/your-project/CLAUDE.md`
- **Size limit:** <8,000 chars (hard constraint)
- **Content:** Architecture, conventions, development guidelines
- **Update frequency:** When architecture changes (infrequent)
- **Sections:**
  - Project Overview
  - Architecture & Tech Stack
  - Development Guidelines
  - Project Management (link to PROJEKT.md)

**2. PROJEKT.md (Active Phase)**
- **Location:** `/your-project/docs/PROJEKT.md`
- **Size limit:** <8,000 chars (hard constraint)
- **Content:** Current phase, tasks, immediate actions
- **Update frequency:** After each task completion
- **Sections:**
  - Executive Summary
  - Current Phase
  - Tasks (UUID-based table)
  - Session Execution Model
  - Configuration Status
  - Known Issues/Blockers

**3. PROJEKT-ARCHIVE.md (Historical - created after Phase 1)**
- **Location:** `/your-project/docs/PROJEKT-ARCHIVE.md`
- **Size limit:** <8,000 chars per file
- **Content:** Completed phases, learnings, ADRs
- **Update frequency:** Only when PROJEKT.md gets too large

**4. Task Files**
- **Location:** `/your-project/docs/tasks/TASK-NNN-name.md`
- **UUID format:** `TASK-001`, `TASK-002` (zero-padded, sortable)
- **Size:** No limit (can be verbose)
- **Content:** Detailed task audit trails, implementation steps, acceptance criteria
- **Update frequency:** During task execution

**5. Session Handoff**
- **Location:** `/your-project/docs/SESSION-HANDOFF-YYYY-MM-DD.md`
- **Frequency:** Created at each session end (optional but recommended)
- **Content:** What was done, what's open, blockers, learnings, next steps

---

## Task-Scheduler Coordination

### UUID-Based Task Parsing

```
PROJEKT.md contains:
| UUID | Task | Status | Dependencies | Effort |
|------|------|--------|--------------|--------|
| TASK-001 | Setup | ✅ completed | None | 1h |
| TASK-002 | Feature | 📋 pending | TASK-001 | 2h |
| TASK-003 | Feature | 📋 pending | TASK-002 | 1.5h |
```

**Scheduler parsing logic:**
1. Extract UUIDs: `TASK-001`, `TASK-002`, `TASK-003`
2. Extract status: `completed`, `pending`, etc.
3. Extract dependencies: `TASK-001` blocks `TASK-002`
4. Build dependency graph
5. Execute ready tasks (no unsatisfied dependencies)
6. Output: Next ready task(s) to work on

### `/run-next-tasks` Behavior

```bash
$ /run-next-tasks

Found 2 pending tasks:
├─ TASK-004: Ready (all dependencies met)
└─ TASK-005: Ready (all dependencies met)

Recommended: Start TASK-004 first (appears earlier in queue)

To start: See PROJEKT.md or docs/tasks/TASK-004-*.md
```

---

## Session-Refresh Deep Dive

### Phase 1: CLAUDE.md Update
Guided checklist presents sections to review/update:

```
1. Architecture Changes? (Updated architecture patterns)
   → Edit if needed, skip if no changes

2. Development Guidelines Updated? (New conventions)
   → Edit if needed, skip if no changes

3. Learnings to Document? (Session insights)
   → Add to Strategic Insights section
   → Skip if nothing new
```

**Result:** CLAUDE.md stays current, learnings captured

### Phase 2: PROJEKT.md Verification
Guided checklist verifies/updates:

```
1. Current Phase Still Correct? (Phase 1 vs Phase 1b vs Phase 2)
   → Edit if moving to next phase

2. Task Statuses Accurate? (TASK-001 ✅ vs 📋 vs ⏳)
   → Update completed/in_progress tasks

3. Definition of Done Complete? (All checkboxes checked?)
   → Update DoD for current phase

4. Blockers Updated? (Any new blockers? Any resolved?)
   → Update Known Issues section
```

**Result:** PROJEKT.md always reflects ground truth

### Phase 3: Auto-Restructure
Triggered automatically by session-refresh:

```
/project-doc-restructure
  ├─ Calculates: TTO (Time-to-Orientation)
  ├─ Calculates: DocDebt (Documentation debt %)
  ├─ Calculates: SCI (Session Continuity Index)
  ├─ Optimizes: Moves completed content → PROJEKT-ARCHIVE.md
  ├─ Compresses: Removes redundancy
  └─ Output: "TTO: 4min, DocDebt: 8%, SCI: 92/100"
```

**When needed:** If PROJEKT.md approaches 6-7K chars

### Phase 4: Auto-Compact
Triggered if token budget >65%:

```
Token-Budget reduzieren (CLI Built-in)
  ├─ Reduziert: Chat history
  ├─ Behält: CLAUDE.md, PROJEKT.md (immer verfügbar)
  ├─ Freigabe: 50-100k tokens
  └─ Output: "Before: 120k tokens. After: 45k tokens."
```

**Result:** Fresh context budget for next tasks

---

## Dependency Resolution Example

### Scenario: 5 Tasks, Complex Dependencies

```
PROJEKT.md:
| TASK | Status | Dependencies |
|------|--------|--------------|
| 001 | ✅ completed | None |
| 002 | ✅ completed | 001 |
| 003 | 📋 pending | 002 |
| 004 | 📋 pending | 002 |
| 005 | 📋 pending | 003, 004 |
```

### Dependency Graph

```
001 (done)
  ↓
002 (done)
  ↓
├─ 003 (ready - only dependency is 002)
└─ 004 (ready - only dependency is 002)
  ↓
005 (blocked - waits for 003 AND 004)
```

### Scheduler Output

```
/run-next-tasks

Ready tasks (no unsatisfied dependencies):
- TASK-003 ✓
- TASK-004 ✓

Blocked tasks:
- TASK-005 (waiting for: TASK-003, TASK-004)

Next: Start TASK-003 and/or TASK-004 (can run in parallel)
```

---

## Token Budget Tracking

### Trigger Points

| Budget | Action | Recommended |
|--------|--------|-------------|
| <50% | Work normally | Continue |
| 50-65% | Monitor | Keep working |
| 65-70% | **TRIGGER** | Run `/session-refresh` |
| 70-85% | Alert | Plan session end soon |
| 85%+ | Emergency | Finish current task, then commit + end session |

### Session-Refresh Token Impact

```
Before session-refresh:
├─ CLAUDE.md: 7.7K chars
├─ PROJEKT.md: 5.6K chars
├─ Chat history: 45K chars (old, with earlier context)
└─ Total context: ~120K tokens (60% budget)

After session-refresh:
├─ CLAUDE.md: 7.7K chars (updated)
├─ PROJEKT.md: 5.6K chars (updated, cleaner)
├─ PROJEKT-ARCHIVE.md: 7K chars (historical, loaded on demand)
├─ Chat history: ~15K chars (compressed, only recent relevant context)
└─ Total context: ~45K tokens (22% budget)
    Result: +155K tokens available! (77% budget freed)
```

---

## Best Practices

### At Session Start
1. Read CLAUDE.md (understand architecture)
2. Read PROJEKT.md (know current phase + next tasks)
3. Check `/run-next-tasks` (see what's ready)
4. If >2 tasks available: prioritize by effort + importance

### During Work
1. Update task in PROJEKT.md when moved to in_progress
2. Update task in PROJEKT.md when completed (mark ✅)
3. Watch token budget (restructure at >65%)
4. Document learnings as you go (easier than writing at end)

### At Session End (10-15 min)
1. Mark all completed tasks ✅ in PROJEKT.md
2. Update blockers/learnings in PROJEKT.md
3. Write SESSION-HANDOFF-YYYY-MM-DD.md (2-3 min)
4. If token budget >65%: Trigger `/session-refresh`
5. Commit changes to git

### Between Sessions
1. Next developer reads SESSION-HANDOFF from previous session
2. Next developer reads CLAUDE.md + PROJEKT.md (should take <5 min)
3. Next developer runs `/session-refresh` → fresh context
4. Ready to continue with clear state

---

## Common Patterns

### Pattern 1: Adding New Tasks Mid-Project
```
When: You realize new task is needed (e.g., bug fix, refactor)

Steps:
1. Edit PROJEKT.md
2. Add new row to task table: TASK-NNN
3. Set Status: 📋 pending
4. Set Dependencies: (which task(s) must complete first?)
5. Create docs/tasks/TASK-NNN-name.md
6. Update PROJEKT.md at next session-refresh

Scheduler will automatically include in next `/run-next-tasks` call
```

### Pattern 2: Handling Blockers
```
When: Task blocked by external dependency (API, dependency, etc.)

Steps:
1. Leave task as 📋 pending in PROJEKT.md
2. Add to PROJEKT.md "Known Issues / Blockers" section
3. Note: "TASK-005 blocked by: AWS credentials setup"
4. Plan: "Fix blocker in TASK-999 (new task)"
5. Continue with other ready tasks (e.g., TASK-003, TASK-004)

Scheduler skips blocked task, shows others as ready
```

### Pattern 3: Phase Transition
```
When: Phase 1 complete, ready for Phase 1b

Steps:
1. Trigger `/session-refresh` (important!)
2. Update CLAUDE.md → add new learnings
3. Update PROJEKT.md:
   - Mark Phase 1 tasks as ✅ completed
   - Update Phase header: "### Phase 1b: Complex Queries"
   - Add Phase 1b tasks (TASK-005, TASK-006, etc.)
   - Update Definition of Done for Phase 1b
4. If PROJEKT.md now >6K chars: Move Phase 1 stuff to PROJEKT-ARCHIVE.md
5. Commit: `git commit -m "feat: Phase 1 complete, start Phase 1b"`

New session starts with clean context, PROJEKT.md still <8K
```

---

## Troubleshooting

### Problem: `/run-next-tasks` shows no tasks
**Cause:** All tasks completed or dependencies blocking everything

**Fix:**
1. Check PROJEKT.md task table (status column)
2. If all ✅: Write new tasks! (add new rows to table)
3. If some 📋 pending: Check dependencies (blocked by something?)
4. If dependencies circular: Fix PROJEKT.md (cyclic deps invalid)

### Problem: Token budget >85% but `/session-refresh` didn't trigger
**Cause:** Manual trigger required (not automatic)

**Fix:**
1. Explicitly run `/session-refresh` NOW
2. Or end session + start new one (fresh context budget)
3. Session-refresh is not automatic, user must trigger

### Problem: CLAUDE.md or PROJEKT.md >8K chars
**Cause:** Accumulated content from multiple phases

**Fix:**
1. Create PROJEKT-ARCHIVE.md
2. Move completed phase sections from PROJEKT.md → PROJEKT-ARCHIVE.md
3. Leave only current phase + next phase in PROJEKT.md
4. Verify both files now <8K chars

---

*For step-by-step onboarding, see ONBOARDING.md*
