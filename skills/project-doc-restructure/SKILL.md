---
name: project-doc-restructure
description: >
  Transform project documentation to follow session-continuous patterns with Inverted
  Pyramid structure. Use when working with PROJECT.md, PROJEKT.md, or similar project
  management documents that need restructuring for better session continuity, or when
  users mention reducing Time-to-Orientation, improving documentation health scores, or
  following session-continuous principles. Validates metrics (TTO, SCI, CLS, DocDebt),
  detects anti-patterns (chronicle, redundancy, wall-of-text), and automatically
  restructures documents into three layers: ACTION (Executive Summary, Immediate Actions)
  then CONTEXT (Phase Status, Active Work) then ARCHIVE (Completed and Planned phases collapsed).
context: fork
agent: general-purpose
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Project Documentation Restructuring

Transform traditional project documentation into session-continuous format following the "Inverted Pyramid" pattern for optimal Time-to-Orientation (TTO < 1min) and cognitive load reduction.

## Quick Start

**Most common workflow:**

1. **Validate current document:**
   ```bash
   python3 scripts/validate_doc_metrics.py <project-file>
   ```

2. **Detect anti-patterns:**
   ```bash
   python3 scripts/detect_anti_patterns.py <project-file>
   ```

3. **Automatically restructure:**
   ```bash
   python3 scripts/restructure_document.py <project-file>
   ```

The restructure script automatically backs up the original to `<file>.backup`.

## Core Principles

This skill applies patterns from "Konzept Session-kontinuierliche Projektdokumentation":

### 1. Inverted Pyramid Structure

Documents are organized by urgency, not chronology:

```
LAYER 1: ACTION LAYER (What NOW?)
├─ 📊 Executive Summary (3-5 sentences)
├─ 🎯 Immediate Next Actions (2-5 tasks)
└─ Quick Decision Points

LAYER 2: CONTEXT LAYER (What's the status?)
├─ 📈 Phase Status Overview (table)
└─ 🔄 Active Phase Details (expanded)

LAYER 3: ARCHIVE LAYER (What was/comes?)
├─ 🚀 Planned Phases (summary inline, details on demand)
├─ 📋 Completed Phases (migrated to docs/phases/)
└─ 📚 Reference Information (separate files with links)
```

### 2. Progressive Disclosure

- **Expanded:** Active work, blocked items
- **Migrated (separate file with link):** Completed, planned, archived content
- **Criterion:** Status + recency determines visibility

### 3. Quality Metrics

**Target scores:**
- **TTO < 1min:** New session orients in under 1 minute
- **SCI > 0.8:** 80% of sessions continue correct task
- **CLS < 3:** Low cognitive load (1-10 scale)
- **DocDebt < 0.2:** Less than 20% outdated
- **Health Score ≥ 75:** Overall document health

## Detailed Workflows

### Validation Workflow

Use when you need to assess document quality before restructuring:

```bash
python3 scripts/validate_doc_metrics.py PROJECT.md
```

**Checks performed:**
- Executive Summary exists in top 100 lines (ideally top 20)
- Immediate Actions section present
- Timestamp exists and is recent (< 30 days optimal)
- Appropriate use of collapsed sections (for docs > 500 lines)
- Signal-to-noise ratio in top 50 lines
- Overall health score (0-100)

**Exit codes:**
- `0`: Health score ≥ 75 (healthy)
- `1`: Health score 50-74 (needs improvement)
- `2`: Health score < 50 (critical)

### Anti-Pattern Detection

Use when investigating specific documentation issues:

```bash
python3 scripts/detect_anti_patterns.py PROJECT.md
```

**Detects:**
1. **Chronicle Pattern:** Chronological organization (oldest first)
2. **Redundancy:** Duplicate information across sections
3. **Wall of Text:** Lack of visual hierarchy (long unstructured paragraphs)
4. **Premature Optimization:** Future planning before current status
5. **Assumed Context:** Unexplained acronyms, task IDs without context
6. **HTML Details Blocks:** `<details>` tags hiding content inline instead of migrating to separate files

**Exit codes:**
- `0`: No anti-patterns
- `1`: Medium-severity issues
- `2`: High-severity issues

### Restructuring Workflow

Use when fully automating the transformation:

```bash
# Restructure in place (creates .backup):
python3 scripts/restructure_document.py PROJECT.md

# Or specify output file:
python3 scripts/restructure_document.py PROJECT.md PROJECT_NEW.md
```

**What it does:**
1. Parse document sections and classify (ACTIVE, COMPLETED, PLANNED, ARCHIVE)
2. Generate Executive Summary with extracted status
3. Extract Immediate Actions from uncompleted checkboxes
4. Build Phase Status Overview table
5. Apply emoji system (📊🎯📈🔄📋🚀📚)
6. Migrate non-active sections to `docs/phases/` (with inline link)
7. Add Decision Log and Reference sections

**Post-restructure tasks:**
The automated restructuring provides an 80% solution. Manual review needed for:
- Executive Summary: Update with actual project context
- Immediate Actions: Add specific task context (why, what, how)
- Phase descriptions: Verify auto-detected classifications
- Decision points: Add meaningful options

## Reference Material

### Pattern Reference

See `references/konzept-patterns.md` for complete pattern catalog including:
- Inverted Pyramid implementation details
- Progressive Disclosure rules
- Single Source of Truth (SSOT) pattern
- Temporal Layering strategy
- F-Pattern reading optimization
- 7±2 Chunks Rule (Miller's Law)
- Visual hierarchy with emoji system
- Complete anti-pattern catalog

**When to read:** When you need detailed guidance on applying specific patterns or resolving edge cases.

### Template Asset & Task Schema Compatibility

See `assets/projekt-template.md` for a complete PROJECT.md template with placeholders.

**Usage:** Copy template for new projects, replace `{{PLACEHOLDERS}}` with actual content.

#### ⚡ Task Schema Compatibility (Critical)

This skill maintains **7-column task schema compatibility** with `task-scheduler`:

```
| UUID | Task | Status | Dependencies | Effort | Deliverable | Task-File |
|------|------|--------|--------------|--------|-------------|-----------|
```

**Why this matters:**
- **Dependencies column** enables `/run-next-tasks` dependency resolution
- **task-scheduler** parses this exact schema to find ready tasks
- **Restructuring preserves functionality** - no breaking changes after document restructure
- **Synchronized with project-init** (Single Source of Truth principle)

**Verification (after restructuring):**
```bash
# Verify 7-column schema is present:
grep -A1 "| UUID | Task | Status | Dependencies" PROJECT.md
# Expected: ✅ Found (confirms task-scheduler compatibility)

# Test task-scheduler still works:
/run-next-tasks
# Expected: ✅ Ready tasks identified correctly
```

**When did this align?** 2026-01-20 (synchronized both templates to prevent breaking changes)

## Emoji System

Apply consistently for visual hierarchy:

| Emoji | Usage | Placement |
|-------|-------|-----------|
| 📊 | Status, Overview | Executive Summary, metrics |
| 🎯 | Actions, To-Do | Immediate Actions |
| 📈 | Progress, Status | Phase Status Overview |
| 🔄 | Active Work | In-progress phases |
| ✅ | Completed | Checkboxes, finished items |
| 📋 | Completed Phase | Completed phase headers |
| 🚀 | Planned | Future work |
| ⏳ | Waiting | Pending tasks |
| 🧪 | Testing | QA phases |
| 🏗️ | Architecture | System design sections |
| 📚 | Reference | Documentation, lookup |
| ⚠️ | Warning | Problems, blockers |

## Common Scenarios

### Scenario 1: New Project Documentation

**User says:** "I need to create project documentation for [project name]"

**Workflow:**
1. Use template: `cp assets/projekt-template.md PROJECT.md`
2. Fill placeholders with project details
3. Validate: `python3 scripts/validate_doc_metrics.py PROJECT.md`

### Scenario 2: Existing Document Needs Improvement

**User says:** "My PROJECT.md is messy and hard to navigate"

**Workflow:**
1. Validate: `python3 scripts/validate_doc_metrics.py PROJECT.md`
2. Detect issues: `python3 scripts/detect_anti_patterns.py PROJECT.md`
3. If health score < 50: Restructure automatically
4. If health score 50-75: Fix specific anti-patterns manually
5. Revalidate after changes

### Scenario 3: Review Before Team Handoff

**User says:** "Can you check if this documentation is ready for the team?"

**Workflow:**
1. Run both validation and anti-pattern detection
2. Report health score and critical issues
3. If score < 75: Recommend restructuring
4. If anti-patterns found: Explain impacts on TTO and SCI

### Scenario 4: Apply Konzept Principles

**User references:** "@Konzept_Session-kontinuierliche_Projektdokumentation.md" or mentions "session-continuous"

**Workflow:**
1. Recognize this triggers full restructuring
2. Explain Inverted Pyramid rationale
3. Run automatic restructure
4. Highlight manual review areas (Executive Summary, Actions)
5. Validate final result

## Decision Logic for Automation Level

**Fully automate (restructure script) when:**
- Health score < 50 (critical)
- Multiple high-severity anti-patterns (including `<details>` blocks)
- Document > 16 KB (regardless of health score)
- User explicitly requests "restructure" or "apply Konzept patterns"

**Semi-automate (guided fixes) when:**
- Health score 50-75 (needs improvement)
- 1-2 medium-severity anti-patterns
- Document 12-16 KB (size reduction needed, even if health score > 75)
- `<details>` blocks detected (migrate to separate files)

**Manual only (provide guidance) when:**
- Health score > 75 AND document < 12 KB AND no `<details>` blocks
- User wants to understand patterns first
- Document has unique structure not fitting standard patterns

**Size Override Rule:** Document size >= 12 KB triggers at minimum semi-automated action, regardless of health score. A document can be structurally sound but too large for efficient session orientation.

## Validation After Changes

Always run validation after restructuring:

```bash
# After restructuring:
python3 scripts/validate_doc_metrics.py PROJECT.md

# Should show improved scores:
# [   OK   ] Executive Summary (line 7)
# [   OK   ] Immediate Actions section found
# [   OK   ] Document fresh (updated 0 days ago)
# 🟢 HEALTHY - Overall health: 85/100
```

## Troubleshooting

**Issue:** "Executive Summary too far down (line 150)"
**Fix:** Move or create Executive Summary at top (after header)

**Issue:** "Chronological organization detected"
**Fix:** Reorder sections: Current Status → Future → Past (use restructure script)

**Issue:** "Wall of text detected"
**Fix:** Break paragraphs into bullets, tables, add bold key terms, use emojis

**Issue:** "Redundant status information"
**Fix:** Consolidate in Phase Status Overview table, remove duplicates, use SSOT pattern

**Issue:** "Low signal-to-noise ratio (0.3)"
**Fix:** Remove outdated content (~~strikethrough~~), delete TODOs, focus top 50 lines on actionable info

## Advanced: Custom Patterns

For project-specific patterns not covered by the standard restructuring:

1. Run standard restructure as baseline
2. Manually adjust for domain-specific needs (e.g., sprint cycles, release cadence)
3. Document custom patterns in Decision Log
4. Consider contributing back as reference material

## Phase Migration (NEW)

For projects with multiple completed phases, inline content can bloat PROJEKT.md beyond the recommended 8-12K character target. The phase migration feature automatically detects and migrates completed phases to `docs/phases/`.

### Quick Start

```bash
# Check for migratable phases (dry run):
python3 scripts/migrate_completed_phases.py PROJECT.md --dry-run

# Migrate all completed phases automatically:
python3 scripts/migrate_completed_phases.py PROJECT.md --auto

# Interactive migration (prompts for each phase):
python3 scripts/migrate_completed_phases.py PROJECT.md
```

### How It Works

1. **Detection:** Scans PROJEKT.md for completed phases (status indicators: `ABGESCHLOSSEN`, `COMPLETED`, `completed`)
2. **Migration:** Creates `docs/phases/Phase-NN-Name.md` for each completed phase
3. **Link Update:** Replaces inline content with a link reference in PROJEKT.md
4. **Backup:** Creates `.pre-migration.backup` before modifying PROJEKT.md
5. **Vault-Sync** (wenn `obsidian.com version` erfolgreich): `obsidian.com property:set name="phase" value="..." type=text file="PROJECT-xxx"` — aktualisiert Phase/Status im Vault-Projekt-Dokument. Fallback: Nur PROJEKT.md (bisheriges Verhalten).

### Detection Patterns

The script recognizes completed phases via:
- Header patterns: `## Phase 1: Name (ABGESCHLOSSEN)`, `## Phase 01: Name (completed)`
- Status emojis: `📋`, `✅`
- Content indicators: `100%`, `all tasks completed`

### Example: Before Migration

```markdown
## 📋 Phase 1: Foundation (ABGESCHLOSSEN)

> Ausgelagert: [Details](docs/phases/Phase-01-Foundation.md) | Abgeschlossen: 2026-01-15
```

### Example: After Migration

**PROJEKT.md:**
```markdown
## 📋 Phase 1: Foundation (ABGESCHLOSSEN)

> Ausgelagert: [Details](phases/Phase-01-Foundation.md)
```

**docs/phases/Phase-01-Foundation.md:**
```markdown
# Phase 1: Foundation

> **Status:** Abgeschlossen
> **Migrated from PROJEKT.md:** 2026-01-21

---

**Abschlussdatum:** 2026-01-15
... full content preserved ...
```

### Integration with Restructuring

After running `restructure_document.py`, the script automatically checks for migratable phases and displays a hint:

```
==================================================
PHASE MIGRATION AVAILABLE
Found 2 completed phase(s) that could be migrated to docs/phases/
This can reduce PROJEKT.md size and improve session continuity.

To migrate, run:
  python3 migrate_completed_phases.py PROJECT.md --dry-run
  python3 migrate_completed_phases.py PROJECT.md --auto
```

### Edge Cases

| Scenario | Behavior |
|----------|----------|
| Phase without number | Warning issued, uses "XX" as placeholder |
| Phase already migrated | Skipped (detected via link presence) |
| Multiple phases | All migratable phases processed |
| Phase with legacy `<details>` wrapper | Content extracted, wrapper stripped |

### Best Practices

1. **Always run `--dry-run` first** to preview changes
2. **Verify `/run-next-tasks` still works** after migration (7-column schema preserved)
3. **Use for historical phases only** - keep active and planned phases inline
4. **Target:** PROJEKT.md < 12K characters after migration

---

## Success Criteria

A successfully restructured document has:
- ✅ Health score ≥ 75
- ✅ TTO < 1 minute (test: close doc, wait 1 week, reopen, time to first action)
- ✅ Executive Summary in top 20 lines
- ✅ No high-severity anti-patterns
- ✅ Active work visible, past/future migrated to separate files
- ✅ Actionable "Immediate Next Actions" section
- ✅ Current timestamp (< 7 days for active projects)
- ✅ Completed phases migrated to `docs/phases/` (for multi-phase projects)
