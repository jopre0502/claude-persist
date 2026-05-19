# Session-Continuous Workflow — Detailed Reference

## Detailed Task Creation

### Step-by-Step

1. **Naechste UUID bestimmen:**
   - **Vault-First:** `obsidian.com base:query path="<project-base-path>" format=json` → hoechste TASK-NNN
   - **Local Fallback:** Check PROJEKT.md fuer hoechste TASK-NNN

2. **Task-Dokument erstellen** - Nutze Skill-Template (SSOT):

   ```bash
   cat ${CLAUDE_PLUGIN_ROOT}/skills/project-init/assets/task-md-template.txt
   # → Inhalt nach docs/tasks/TASK-NNN-name.md kopieren
   # → Platzhalter ersetzen: {{TASK_ID}}, {{DOCS_PATH}}, {{DATE}}, etc.
   ```

3. **Vault-Dokument erstellen (wenn verfuegbar):**
   - Erstelle Vault-Dokument mit Fileclass `claude-task`
   - Properties: uuid, status (pending), effort, dependencies, tags
   - Vault-Dokument ist SSOT fuer Status ab Erstellung

4. **Output-Ordner anlegen:**

   ```bash
   mkdir -p docs/tasks/TASK-NNN/{execution-logs,artifacts}
   ```

5. **In PROJEKT.md eintragen:**
   - **Vault-First:** Nur erwaehnen wenn relevant fuer Executive Summary
   - **Local Fallback:** Neue Zeile im 7-Column Schema (siehe unten)

**Task-Template (SSOT):** `${CLAUDE_PLUGIN_ROOT}/skills/project-init/assets/task-md-template.txt`

---

## Phase Completion Workflow

**Wann:** Eine Phase ist vollstaendig abgeschlossen (alle Tasks completed, DoD erfuellt)

**Warum auslagern:**
- PROJEKT.md bleibt kompakt (<8K Zeichen)
- Historische Details erhalten, aber ausserhalb des aktiven Kontexts
- Schnellere Orientierung fuer neue Sessions

### Schritte

1. **Phase als abgeschlossen markieren**
   - Alle Tasks der Phase: Status → completed (Vault property:set + lokale Files)
   - Definition of Done: Alle Checkboxen → `[x]`

2. **Phase-Datei erstellen**

   ```
   docs/phases/Phase-NN-Name.md
   ```

   - Verwende Template: `${CLAUDE_PLUGIN_ROOT}/skills/project-init/assets/phase-template.txt`
   - Kopiere Phase-Content (Header, DoD, Tasks, Learnings)

3. **PROJEKT.md aktualisieren**

   ```markdown
   ## Abgeschlossene Phasen
   - [Phase 01: Foundation](phases/Phase-01-Foundation.md) - Completed (2025-01-15 - 2025-01-20)
   ```

4. **Verifizieren**
   - PROJEKT.md Groesse: `wc -c docs/PROJEKT.md` → <8000 Bytes
   - Phase-Datei existiert: `ls docs/phases/`
   - `/run-next-tasks` funktioniert noch

---

## 7-Column Task-Tabellen-Format (Local Fallback)

Wenn kein Vault verfuegbar ist, nutzt PROJEKT.md dieses Format fuer task-scheduler Parsing:

```markdown
| UUID | Task | Status | Dependencies | Effort | Deliverable | Task-File |
|------|------|--------|--------------|--------|-------------|-----------|
```

### Spalten-Definition

| Spalte | Format | Beispiel |
|--------|--------|---------|
| **UUID** | `**TASK-NNN**` | `**TASK-001**` |
| **Task** | Frei-form Text | `Project Setup` |
| **Status** | Emoji + Text | `✅ completed` |
| **Dependencies** | `None` oder `TASK-NNN` | `TASK-001` |
| **Effort** | Schaetzung | `2-3h` |
| **Deliverable** | Artefakt | `docs` |
| **Task-File** | Markdown Link | `[Details](tasks/TASK-001-setup.md)` |

### Beispiel

```markdown
| **TASK-001** | Setup | ✅ completed | None | 1h | docs | [Details](tasks/TASK-001-setup.md) |
| **TASK-002** | Feature | 📋 pending | TASK-001 | 2.5h | feature | [Details](tasks/TASK-002-feature.md) |
```

### Status-Werte (MECE)

`📋 pending` | `⏳ in_progress` | `📘 ongoing` | `✅ completed` | `🚫 blocked` | `❌ cancelled`

**Hinweis:** Im Vault-First-Modus entfaellt diese Tabelle aus PROJEKT.md. Task-Daten kommen aus Vault Base.

---

## Vault CLI Commands (wenn verfuegbar)

### Task Discovery

```bash
obsidian.com base:query path="<project-base-path>" format=json   # Alle Tasks mit Status
obsidian.com read file="TASK-NNN-name"                            # Task-Details lesen
obsidian.com search query="..." path="..."                        # Volltextsuche
```

### Status Updates

```bash
obsidian.com property:set name="status" value="in_progress" type=text file="TASK-NNN-name"
obsidian.com property:set name="status" value="completed" type=text file="TASK-NNN-name"
```

### Feature Detection

```bash
obsidian.com version   # Available → Vault-First, Error → Local Fallback
```

---

## Token Budget Details

| Budget | Status | Action |
|--------|--------|--------|
| <50% | ✅ Healthy | Continue working |
| 50-65% | ⏳ Monitor | Watch for next trigger |
| **65-70%** | **⚠️ TRIGGER** | **Run `/session-refresh`** |
| 70-85% | 🔴 Alert | Plan session end |
| 85%+ | 🚨 Emergency | Finish task, commit, end session |

**Autocompacting ist ein Fail-State.** Token-Budget proaktiv managen.

---

## Example Session Flow

```
Session Start (clean - previous session ended with /session-refresh)
├─ Read CLAUDE.md (2 min)
├─ Feature Detection: obsidian.com version
│  ├─ Available → base:query for task overview
│  └─ Not available → Read PROJEKT.md
├─ /run-next-tasks (1 min)
│  └─ Shows: "TASK-002, TASK-003 ready"
├─ Start TASK-002 (1-2 hours)
│  ├─ Work on implementation
│  ├─ Document in task file (local + Vault)
│  └─ Mark ✅ via property:set (or PROJEKT.md edit)
├─ /run-next-tasks → find newly-ready tasks
├─ Continue working... (token budget rising)
│
└─ Session End (or token >65%)
   ├─ Update task status (Vault + local)
   ├─ /session-refresh (15 min)
   │  ├─ Update CLAUDE.md learnings
   │  ├─ Verify task status
   │  ├─ Auto-restructure + compact
   │  └─ Ready for next session
   └─ Commit + Handoff (automatic)
```

---

## Session Handoff Pattern

- Dateiname: `docs/handoffs/SESSION-HANDOFF-YYYY-MM-DD-SNNN.md` (akkumulierend)
- YAML-Frontmatter: fileClass `claude-session`, tasks, tags, outcome, decisions
- Inhalt: Erreicht, Naechste Session, Learnings
- **NUR Main-Session** schreibt Handoffs (nicht Subagents)
- Loader (`session-handoff-loader.sh`) findet automatisch das neueste File

---

## Key Concepts

- **Vault-First:** Obsidian Base ist SSOT fuer Task-Status wenn verfuegbar. Graceful Degradation zu lokalen Files.
- **Dependency Resolution:** `/run-next-tasks` zeigt nur Tasks mit erfuellten Dependencies
- **Phase Transitions:** Abgeschlossene Phasen → `docs/phases/Phase-NN-Name.md`
- **Context Optimization:** `/session-refresh` reduziert Context-Bloat
- **Continuity:** Naechste Session liest neuestes `SESSION-HANDOFF-*.md`

---

## Related Skills

| Skill | Purpose |
|-------|---------|
| `/run-next-tasks` | Task-Discovery + Dependency Resolution |
| `/session-refresh` | Docs aktualisieren + Context optimieren |
| `/task-orchestrator` | Strukturierte Task-Ausfuehrung |
| `/project-doc-restructure` | PROJEKT.md Inverted Pyramid |
| `/claude-md-restructure` | CLAUDE.md optimieren (<8KB) |
