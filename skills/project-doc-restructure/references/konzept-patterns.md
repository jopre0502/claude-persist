# Session-Continuous Documentation Patterns (Simplified)

Reference guide for core patterns. This is the **production version** – use this, not the extended version.

---

## Core Patterns (Must-Have)

### 1. Inverted Pyramid: Action → Context → Archive

**Structure:** Most urgent first, least urgent last.

```
LAYER 1: ACTION
  └─ Executive Summary (3-5 sentences)
  └─ Immediate Next Actions (2-5 actionable items)

LAYER 2: CONTEXT
  └─ Phase Status Overview (table: Phase | Progress | Status)
  └─ Active Phase Details (expanded)

LAYER 3: ARCHIVE
  └─ Completed Phases (collapsed)
  └─ Planned Phases (collapsed)
  └─ Decision Log (collapsed)
```

**Why:** New session understands focus in <1 minute. Past/future collapsed → low cognitive load.

---

### 2. Progressive Disclosure: Collapse by Lifecycle State

**Rule:**
- ✅ **Collapsed:** Completed, Planned, Cancelled, > 30 days old
- ✅ **Expanded:** In Progress, Blocked, recently updated (< 7 days)

**Markdown:**
```markdown
## Phase B: MVP (COMPLETED)

<details>
<summary>Click to expand completed work</summary>

[... task details, dates, outcomes ...]

</details>
```

**Why:** Reduces visible context while preserving audit trail.

---

### 3. Single Source of Truth (SSOT)

**Rule:** One authoritative place per fact. Reference elsewhere.

**Bad:**
```markdown
## Executive Summary
Phase D1 is 60% done (3/5 tasks).

## Phase Status
| D1 | 60% |

## Phase D1 Details
Status: 3/5 tasks done (60%)  ← DUPLICATION
```

**Good:**
```markdown
## Phase Status Overview
| D1 | 60% (3/5) | IN_PROGRESS |  ← SINGLE SOURCE

## Executive Summary
See Phase D1 details below.  ← REFERENCE
```

**Why:** Prevents merge conflicts, makes updates atomic.

---

### 4. 7±2 Chunks Rule (Miller's Law)

**Rule:** Max 5-7 items per list/category at any nesting level.

**Bad:**
- 15 phases listed at top level → overload
- 10+ immediate actions → unclear priority

**Good:**
- 3-5 top-level sections (Summary, Current Phase, Archive)
- Nested sub-items within each

**Why:** Cognitive load limits. Beyond 7 items = decision paralysis.

---

### 5. Minimal Emoji System (Visual Scanning)

**Use sparingly (not everywhere):**

| Purpose | Emoji | Usage |
|---------|-------|-------|
| Status summary | 📊 | Executive Summary, top-level overview |
| Immediate actions | 🎯 | Next Steps section |
| Phase progress | ⏳ | Active phase row in status table |
| Completed work | ✅ | Completed phase headers |
| Blocked/Alert | ⚠️ | Only for blockers/critical issues |

**Anti-pattern:** Don't emoji every bullet point or paragraph. Signal-to-noise ratio matters.

---

## Quality Metrics (Simplified)

### Health Checklist

Before closing a session, score PROJEKT.md on:

| Criterion | Target | Score |
|-----------|--------|-------|
| Executive Summary in top 20 lines | ✅ Yes | 25 pts |
| Immediate Actions present & clear | ✅ Yes | 25 pts |
| Last updated ≤ 7 days | ✅ Yes | 25 pts |
| Long sections collapsed | ✅ Yes | 15 pts |
| No duplicated status info | ✅ Yes | 10 pts |
| **TOTAL** | | **100 pts** |

**Health Status:**
- 🟢 ≥ 75 pts: Healthy → Proceed normal
- 🟡 50-74 pts: Needs refresh → Run `/session-refresh`
- 🔴 < 50 pts: Critical → Restructure immediately

### Key Metrics

- **TTO (Time-to-Orientation):** < 1 minute to understand what's next
- **SCI (Session Continuation):** New session picks correct task 80%+ of time
- **CLS (Cognitive Load):** Mental effort to parse PROJEKT.md is low

---

## Implementation Checklist (Use This)

When restructuring PROJEKT.md:

- [ ] **LAYER 1 (Action):**
  - [ ] Executive Summary in top 50 lines?
  - [ ] Clear "Immediate Next Actions"?
  - [ ] Decision points listed?

- [ ] **LAYER 2 (Context):**
  - [ ] Phase Status table (Phase | Progress | Status)?
  - [ ] Active phase expanded (not collapsed)?
  - [ ] Architecture/scope ref present?

- [ ] **LAYER 3 (Archive):**
  - [ ] Completed phases collapsed?
  - [ ] Planned phases collapsed?
  - [ ] Decision Log collapsed?

- [ ] **Quality Checks:**
  - [ ] No duplicated status info (SSOT)?
  - [ ] No orphaned task references?
  - [ ] Timestamps < 7 days old?
  - [ ] All 7-Column Task Rows complete?

---

## What NOT to Do

**These are Anti-Patterns – avoid them:**

1. **Chronicle Pattern** – Don't list updates chronologically (oldest first). Use Inverted Pyramid.
2. **Redundancy** – Don't repeat the same status in Executive Summary, Phase Overview, and Phase Details.
3. **Wall of Text** – Use tables, bullets, bold terms. Break up prose.
4. **Overkill Details** – Expand active phases only; collapse everything else.
5. **Unexplained Acronyms** – Define TASK-001, PROJ-X, etc. on first use.

---

## Integration with Task Scheduler

**Critical:** These patterns **must preserve**:
- 7-Column Task Schema: `UUID | Task | Status | Dependencies | Effort | Deliverable | Task-File`
- All task rows intact after restructuring
- Dependency links remain parseable

**Do NOT:**
- ❌ Change column order
- ❌ Delete or merge columns
- ❌ Add emoji inside table cells (breaks parsing)

---

**Document Status:** ✅ Production Version | **Created:** 2026-01-20 | **Replaces:** konzept-patterns.md (extended)
