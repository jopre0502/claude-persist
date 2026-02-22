---
name: claude-md-restructure
description: >
  Optimize CLAUDE.md files for size (<8KB target) while preserving workflow-block.txt
  injection and Session-Continuous patterns. Use when CLAUDE.md exceeds 8KB, when
  Decision Log has >10 entries, or when users mention "CLAUDE.md too large",
  "optimize CLAUDE.md", "reduce CLAUDE.md size", or "Decision Log auslagern".
  Migrates Decision Log to docs/DECISION-LOG.md, applies Progressive Disclosure,
  and maintains injection markers for project-init compatibility.
context: fork
agent: general-purpose
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# CLAUDE.md Restructure

Optimize CLAUDE.md files for session-continuous projects. Target: <8KB while preserving workflow-block.txt injection.

## Quick Start

**Most common workflow:**

1. **Analyze current state:**
   ```bash
   python3 scripts/analyze_claude_md.py CLAUDE.md
   ```

2. **Externalize Workflow (biggest impact, ~8KB savings):**
   ```bash
   python3 scripts/externalize_workflow.py CLAUDE.md --dry-run
   python3 scripts/externalize_workflow.py CLAUDE.md
   ```

3. **Migrate Decision Log (if >10 entries):**
   ```bash
   python3 scripts/migrate_decision_log.py CLAUDE.md --dry-run
   python3 scripts/migrate_decision_log.py CLAUDE.md
   ```

4. **Apply Progressive Disclosure:**
   ```bash
   python3 scripts/apply_progressive_disclosure.py CLAUDE.md
   ```

5. **Verify result:**
   ```bash
   python3 scripts/analyze_claude_md.py CLAUDE.md
   # Expected: Exit code 0 (Healthy <8KB)
   ```

## When to Use

| Trigger | Action |
|---------|--------|
| CLAUDE.md > 8KB | Run full workflow |
| Decision Log > 10 entries | Migrate Decision Log |
| "CLAUDE.md too large" | Analyze + recommend |
| Session-refresh token budget high | Consider optimization |
| New project from project-init | Check injection markers |

## Core Principles

### 1. Workflow Reference (nicht Inline-Injection)

**Best Practice (seit TASK-026):** Workflow-Dokumentation wird **referenziert**, nicht inline eingebettet.

> "❌ Don't: @-file docs (embeds entire file on every run)"
> "✅ Do: 'For complex usage, see path/to/docs.md'"
> — [Claude Code Best Practices](https://rosmur.github.io/claudecode-best-practices/)

**Vorher (Inline, ~10KB):**
```markdown
## Session-Continuous Workflow
[246 Zeilen vollständige Dokumentation]
```

**Nachher (Reference, ~1.5KB):**
```markdown
## Session-Continuous Workflow
**Detaillierte Workflow-Dokumentation:** `~/.claude/skills/project-init/references/WORKFLOW.md`
[Quick-Reference Tabellen]
```

**Migration bestehender Projekte:**
```bash
python3 scripts/externalize_workflow.py CLAUDE.md --dry-run
python3 scripts/externalize_workflow.py CLAUDE.md
```

**Why:** Claude liest die externe Datei nur bei Bedarf (via Read-Tool), nicht bei jedem Session-Start.

### 2. Decision Log Externalization

Decision Logs grow with project maturity. When >10 entries (~2KB), externalize to `docs/DECISION-LOG.md`.

**Before:**
```markdown
## Decision Log

| Decision | Rationale | Impact | Status |
|----------|-----------|--------|--------|
... 20 rows ...
```

**After:**
```markdown
## Decision Log

> Vollstaendiger Decision Log: [docs/DECISION-LOG.md](docs/DECISION-LOG.md)

**Letzte Entscheidungen:**
- ✅ Last decision summary...
- ✅ Second last...
- ✅ Third last...

*20 Eintraege insgesamt.*
```

### 3. Progressive Disclosure

Use `<details>` tags for historical/resolved content:

- Resolved Open Questions
- Solved Challenges (Bekannte Herausforderungen gelöst)
- Reference sections (Referenzen, Häufige Tasks)
- Large tables (>8 rows)

## Detailed Workflows

### Analysis Workflow

```bash
python3 scripts/analyze_claude_md.py CLAUDE.md
```

**Output includes:**
- Total size in bytes
- Section breakdown with visual bars
- Decision Log entry count
- Workflow injection status
- Specific recommendations

**Exit codes:**
- `0`: Healthy (<8KB)
- `1`: Needs optimization (8-15KB)
- `2`: Critical (>15KB)

### Decision Log Migration

```bash
# Preview changes:
python3 scripts/migrate_decision_log.py CLAUDE.md --dry-run

# Execute migration:
python3 scripts/migrate_decision_log.py CLAUDE.md
```

**Creates:**
- `docs/DECISION-LOG.md` with full history
- Backup: `CLAUDE.md.pre-decision-migration.backup`

**Updates CLAUDE.md:**
- Replaces inline table with link
- Keeps last 3 decisions as summary

### Progressive Disclosure

```bash
# Preview:
python3 scripts/apply_progressive_disclosure.py CLAUDE.md --dry-run

# Apply:
python3 scripts/apply_progressive_disclosure.py CLAUDE.md
```

**Wraps in `<details>`:**
- Resolved Open Questions
- Solved Challenges
- Reference sections
- Large tables (>8 rows, excluding task tables)

## Template Reference

See `assets/claude-md-template.txt` for the optimized CLAUDE.md structure with:

- Size-targeted sections
- Injection markers
- Decision Log link pattern
- Placeholder variables

**Variables:**
- `{{PROJECT_NAME}}`, `{{PROJECT_PURPOSE}}`
- `{{TECH_STACK}}`, `{{ARCHITECTURE_OVERVIEW}}`
- `{{WORKFLOW_BLOCK}}` - workflow-block.txt content
- `{{RECENT_DECISIONS}}` - last 3 decisions
- `{{DATE}}`

## Common Scenarios

### Scenario 1: CLAUDE.md Over 15KB

**User says:** "My CLAUDE.md is 18KB, Claude loses focus"

**Workflow:**
1. Analyze: `python3 scripts/analyze_claude_md.py CLAUDE.md`
2. Migrate Decision Log (saves ~3-5KB)
3. Apply Progressive Disclosure
4. Verify: Exit code 0

### Scenario 2: Many Decision Log Entries

**User says:** "Decision Log has 25 entries"

**Workflow:**
1. Migrate: `python3 scripts/migrate_decision_log.py CLAUDE.md`
2. Result: docs/DECISION-LOG.md created, CLAUDE.md reduced

### Scenario 3: After project-init

**User says:** "Just ran /project-init, CLAUDE.md already 10KB"

**Workflow:**
1. This is expected (workflow-block.txt is ~8KB)
2. Check Decision Log size
3. If Decision Log empty: No action needed
4. Monitor as project grows

### Scenario 4: Workflow Injection Missing

**User says:** "Session-Continuous Workflow section missing"

**Workflow:**
1. Check for injection markers in CLAUDE.md
2. If missing: Re-run `/project-init` or manually inject
3. Source: `~/.claude/skills/project-init/assets/workflow-block.txt`

## Guardrails

| Rule | Reason |
|------|--------|
| Never delete workflow-block content | project-init dependency |
| Keep "Session-Continuous Workflow" string | Marker for project-init |
| Maintain injection markers | Safe re-injection on updates |
| Backup before modifications | Recovery option |
| Test /run-next-tasks after changes | Verify task-scheduler compatibility |

## Integration

### With project-init
- project-init injects workflow-block.txt
- This skill preserves injection markers
- Re-injection safe after optimization

### With session-refresh
- session-refresh triggers context optimization
- Consider running this skill when CLAUDE.md > 8KB
- Not auto-triggered (manual decision)

### With project-doc-restructure
- project-doc-restructure handles PROJEKT.md
- This skill handles CLAUDE.md
- Different algorithms for different content types

## Size Targets

| Component | Target | Notes |
|-----------|--------|-------|
| **Total CLAUDE.md** | <8KB | Jetzt erreichbar mit External Reference |
| Workflow Reference | ~1.5KB | Compact (statt ~10KB inline) |
| Project-specific | <4KB | Mehr Budget verfügbar |
| Decision Log inline | <500B | Link + 3 summaries |
| Other sections | Minimal | Use Progressive Disclosure |

**Mit External Reference:** Das 8KB-Ziel ist jetzt realistisch erreichbar:
- Workflow Reference: ~1.5KB (statt ~10KB inline)
- Decision Log externalized: ~500B
- Project-specific: ~4-5KB Budget verfügbar

## Troubleshooting

**Issue:** "Exit code 2 after optimization"
**Cause:** workflow-block.txt alone is ~8KB
**Fix:** Accept 10-12KB as realistic target for projects with full workflow injection

**Issue:** "Decision Log not found"
**Cause:** Non-standard heading format
**Fix:** Ensure heading is `## Decision Log` (exact)

**Issue:** "Injection markers missing after optimization"
**Cause:** Manual editing removed markers
**Fix:** Re-add markers around Session-Continuous Workflow section

**Issue:** "/project-init fails after optimization"
**Cause:** "Session-Continuous Workflow" string removed
**Fix:** Ensure this exact string exists in CLAUDE.md (in heading or content)

## Success Criteria

After optimization:
- [ ] Size < 12KB (realistic) or < 8KB (ideal)
- [ ] Decision Log externalized to docs/DECISION-LOG.md
- [ ] Workflow injection markers present
- [ ] "Session-Continuous Workflow" string exists
- [ ] Progressive Disclosure applied to resolved sections
- [ ] /run-next-tasks still works
