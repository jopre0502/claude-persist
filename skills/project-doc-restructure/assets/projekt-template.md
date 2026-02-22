# {{PROJECT_NAME}} - Projektmanagement

> **Letzte Aktualisierung:** {{CURRENT_DATE}} ({{STATUS}})

---

## 📊 Executive Summary

**Aktueller Status:** Phase {{CURRENT_PHASE}} ({{PHASE_STATUS}}) - {{PROGRESS}}% erledigt

**Was funktioniert:**
- ✅ {{COMPLETED_ITEM_1}}
- ✅ {{COMPLETED_ITEM_2}}
- ⚠️ {{KNOWN_ISSUE}}

**Aktueller Fokus:**
- {{PRIMARY_FOCUS}}
- Dann Entscheidung: {{DECISION_POINT}}

**Nächste Session kann starten mit:**
1. {{ACTION_1}}
2. Oder: {{ACTION_2}}
3. Oder: {{ACTION_3}}

---

## 🎯 Immediate Next Actions

**Offen in Phase {{CURRENT_PHASE}}:**
- [ ] **{{TASK_ID_1}}:** {{TASK_DESCRIPTION_1}} ({{CONTEXT_1}})
- [ ] **{{TASK_ID_2}}:** {{TASK_DESCRIPTION_2}} ({{CONTEXT_2}})

**Entscheidungspunkt (danach):**
- **Option A:** {{OPTION_A}} ({{IMPACT_A}}, {{EFFORT_A}})
- **Option B:** {{OPTION_B}} ({{IMPACT_B}}, {{EFFORT_B}})
- **Option C:** {{OPTION_C}} ({{IMPACT_C}}, {{EFFORT_C}})

---

## 🔄 Session Execution Model

### Session-Start Checklist
- [ ] Read CLAUDE.md (architecture + project goals)
- [ ] Read PROJEKT.md (current task status)
- [ ] Check token budget (>65%? Plan `/session-refresh` at end)
- [ ] Identify 2-3 high-priority tasks to work on

### Session-End (10-15 min)
1. Update task status in PROJEKT.md (Status column)
2. Commit changes with German message (e.g., `[feat]: Description`)
3. If token budget >65%: Trigger `/session-refresh`
4. Optional: Write SESSION-HANDOFF-YYYY-MM-DD.md with learnings

---

## ⚙️ Configuration Status

| Component | Status | Details |
|-----------|--------|---------|
| **CLAUDE.md** | {{CLAUDE_STATUS}} | {{CLAUDE_DETAILS}} |
| **PROJEKT.md** | {{PROJEKT_STATUS}} | {{PROJEKT_DETAILS}} |
| **Task-Scheduler** | {{SCHEDULER_STATUS}} | {{SCHEDULER_DETAILS}} |
| **Session-Refresh** | {{REFRESH_STATUS}} | {{REFRESH_DETAILS}} |

---

## 📈 Phase Status Overview

| Phase | Beschreibung | Status | Progress | Priorität |
|-------|--------------|--------|----------|-----------|
| **{{PHASE_ID_1}}** | {{PHASE_DESC_1}} | {{PHASE_STATUS_1}} | {{PHASE_PROGRESS_1}} | {{PHASE_PRIORITY_1}} |
| **{{PHASE_ID_2}}** | {{PHASE_DESC_2}} | {{PHASE_STATUS_2}} | {{PHASE_PROGRESS_2}} | {{PHASE_PRIORITY_2}} |
| **{{PHASE_ID_3}}** | {{PHASE_DESC_3}} | {{PHASE_STATUS_3}} | {{PHASE_PROGRESS_3}} | {{PHASE_PRIORITY_3}} |

**Status-Legende:**
- ✅ Abgeschlossen
- 🔄 In Arbeit
- ⏳ Geplant
- ⚠️ Blockiert

---

## 🔄 Phase {{ACTIVE_PHASE}}: {{ACTIVE_PHASE_NAME}} (AKTIV)

**Ziel:** {{PHASE_GOAL}}

**Status:** {{COMPLETED_TASKS}}/{{TOTAL_TASKS}} Tasks erledigt

### ✅ Abgeschlossen:
- {{TASK_DONE_1}}
- {{TASK_DONE_2}}

### ⏳ Offen:
- {{TASK_TODO_1}}
- {{TASK_TODO_2}}

### Details:

| UUID | Task | Status | Dependencies | Effort | Deliverable | Task-File |
|------|------|--------|--------------|--------|-------------|-----------|
| **{{TASK_ID}}** | {{TASK_DESC}} | {{TASK_STATUS}} | {{DEPENDENCIES}} | {{EFFORT}} | {{DELIVERABLE}} | [Details](tasks/{{TASK_ID}}/{{TASK_ID}}-{{TASK_NAME}}.md) |

---

## 🚀 Phase {{PLANNED_PHASE}}: {{PLANNED_PHASE_NAME}} (GEPLANT)

<details>
<summary>{{PLANNED_SUMMARY}} - Klick für Details</summary>

**Ziel:** {{PLANNED_GOAL}}

**Geplante Tasks:**
- [ ] {{PLANNED_TASK_1}}
- [ ] {{PLANNED_TASK_2}}
- [ ] {{PLANNED_TASK_3}}

**Abhängigkeiten:**
- Benötigt Abschluss von Phase {{DEPENDENCY}}

**Geschätzter Aufwand:** {{ESTIMATED_EFFORT}}

</details>

---

## 📋 Phase {{COMPLETED_PHASE}}: {{COMPLETED_PHASE_NAME}} (ABGESCHLOSSEN)

> Ausgelagert: [Details](phases/Phase-{{COMPLETED_PHASE}}-{{COMPLETED_PHASE_NAME}}.md)

<!--
MIGRATION NOTE: Abgeschlossene Phasen werden in docs/phases/ ausgelagert.
Dies reduziert die PROJEKT.md Groesse und verbessert die Session-Kontinuitaet.

Automatische Migration:
  python3 migrate_completed_phases.py PROJEKT.md --dry-run
  python3 migrate_completed_phases.py PROJEKT.md --auto

ALTERNATIVE: Inline-Version (wenn Phase klein genug ist):

<details>
<summary>Alle Tasks abgeschlossen (100%) - Klick fuer Details</summary>

**Abschlussdatum:** {{COMPLETION_DATE}}

**Ergebnisse:**
- ✅ {{DELIVERABLE_1}}
- ✅ {{DELIVERABLE_2}}

**Tasks:**

| UUID | Task | Status | Dependencies | Effort | Deliverable | Task-File |
|------|------|--------|--------------|--------|-------------|-----------|
| {{TASK_ID_1}} | {{COMPLETED_TASK_1}} | ✅ Erledigt | {{DEPENDENCIES_1}} | {{EFFORT_1}} | {{DELIVERABLE_1}} | [Details](tasks/{{TASK_ID_1}}/{{TASK_ID_1}}.md) |

</details>
-->

---

## 🏗️ System Architecture (Quick Reference)

**Komponenten:**
1. {{COMPONENT_1}} - {{COMPONENT_1_DESC}}
2. {{COMPONENT_2}} - {{COMPONENT_2_DESC}}
3. {{COMPONENT_3}} - {{COMPONENT_3_DESC}}

**Technologie-Stack:**
- {{TECH_1}}
- {{TECH_2}}
- {{TECH_3}}

→ **Details:** Siehe {{ARCHITECTURE_DOC}}

---

## 📚 Reference Information

<details>
<summary>Entscheidungslog</summary>

| Datum | Entscheidung | Begründung | Phase |
|-------|--------------|------------|-------|
| {{DATE_1}} | {{DECISION_1}} | {{RATIONALE_1}} | {{PHASE_1}} |
| {{DATE_2}} | {{DECISION_2}} | {{RATIONALE_2}} | {{PHASE_2}} |

</details>

<details>
<summary>Offene Fragen</summary>

| # | Frage | Status | Verantwortlich |
|---|-------|--------|----------------|
| {{Q_ID_1}} | {{QUESTION_1}} | {{Q_STATUS_1}} | {{Q_OWNER_1}} |
| {{Q_ID_2}} | {{QUESTION_2}} | {{Q_STATUS_2}} | {{Q_OWNER_2}} |

</details>

---

**Ende des Dokuments** | Für neue Session: Starte bei "Executive Summary"
