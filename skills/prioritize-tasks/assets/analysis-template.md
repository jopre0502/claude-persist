# Task-Priorität Analyse Template

Dieses Template zeigt das erwartete Output-Format des `/prioritize-tasks` Skills.

---

## Task-Priorität Analyse

**Datum:** {{DATE}}
**PROJEKT:** {{PROJEKT_PATH}}
**Tasks analysiert:** {{TASK_COUNT}}
**Known Issues gefunden:** {{ISSUE_COUNT}}

---

### 🚀 Empfohlene Reihenfolge

| Rang | Task | Score | Begründung |
|------|------|-------|------------|
| 1 | **TASK-XXX** - Task Name | 8.50 | Quick win (2h), keine Dependencies |
| 2 | **TASK-YYY** - Task Name | 6.20 | Unblocks 2 tasks |
| 3 | **TASK-ZZZ** - Task Name | 4.10 | Standard |

---

### ⚠️ Beeinflusst durch Known Issues

| Task | Known Issue | Empfehlung |
|------|-------------|------------|
| TASK-ABC - Name | Issue-Beschreibung | Review required |

---

### 💡 Vorgeschlagene neue Tasks (aus Known Issues)

- **Neuer Task vorgeschlagen:** Issue ohne Task-Zuordnung

---

### 📊 Scoring-Details

| Task | Effort | Deps | Unblocks | Issues | Score |
|------|--------|------|----------|--------|-------|
| TASK-XXX | 2h | 0 | 1 | 0 | 8.50 |
| TASK-YYY | 4h | 1 | 2 | 0 | 6.20 |
| TASK-ZZZ | 8h | 2 | 0 | 1 | 4.10 |

---

*Scoring-Formel: (1/effort)×3 + (1/(deps+1))×1 + (unblocks×0.5) - (issues×2)*

---

## Interpretation

### Hoher Score (> 6.0)
- **Quick Wins:** Geringer Effort, wenig Dependencies
- **Kritischer Pfad:** Tasks die viele andere freischalten
- **Empfehlung:** Zuerst bearbeiten

### Mittlerer Score (3.0 - 6.0)
- **Standard-Tasks:** Ausgewogenes Verhältnis
- **Empfehlung:** Nach Quick Wins bearbeiten

### Niedriger Score (< 3.0)
- **Blockiert:** Wartet auf Dependencies
- **Hoher Effort:** Zeitaufwändige Tasks
- **Known Issues:** Externe Blocker
- **Empfehlung:** Später oder nach Issue-Klärung

### Score 0 oder negativ
- **Blocked Status:** Task explizit blockiert
- **Completed:** Bereits abgeschlossen (Score -1)
