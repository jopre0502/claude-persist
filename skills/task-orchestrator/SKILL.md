---
name: task-orchestrator
description: |
  Orchestriert strukturierte Task-Ausführung mit Subagent Delegation.

  Trigger-Patterns (automatisch aktivieren bei):
  - "Arbeite TASK-XXX ab"
  - "Führe TASK-XXX aus"
  - "Starte TASK-XXX"
  - "TASK-XXX umsetzen"
  - "Mach TASK-XXX"
  - "Lass uns TASK-XXX machen"

  Funktionen:
  - Main-Session als Orchestrator (koordiniert, delegiert, konsolidiert)
  - Parallelisierbare Actions → Subagents (mit Bestätigung)
  - Bei Unsicherheiten → User einbinden (keine Annahmen)
  - Automatische DoD-Prüfung und Status-Updates

  Ergänzt /run-next-tasks: Discovery (task-scheduler) → Execution (task-orchestrator)
---

# Task Orchestrator Skill

Orchestriert Task-Ausführung mit klarem Workflow: Main-Session koordiniert, Subagents für unabhängige Arbeit, User-Einbindung bei Unsicherheiten.

## Workflow: 5 Phasen

### Phase 1: Task Laden

**Aktion:** Lade und verstehe den Task vollständig.

```
1. Finde Task-Datei: docs/tasks/TASK-XXX-*.md
2. Extrahiere:
   - Objective (Was soll erreicht werden?)
   - Implementation Steps (Wie?)
   - Acceptance Criteria (Wann fertig?)
   - Dependencies (Voraussetzungen erfüllt?)
3. Prüfe Dependencies via PROJEKT.md
   - Falls Dependency nicht ✅ completed → Abbruch mit Meldung
4. DECISION FRONTLOADING (Pre-Flight Decisions):
   - Suche Section "## Pre-Flight Decisions" im Task-File
   - Falls vorhanden:
     a) Parse alle Decision-Bloecke (### D1, ### D2, ...)
     b) Pruefe "Antwort:"-Zeile in jedem Block
     c) Sammle ALLE unbeantworteten Decisions (kein "Antwort:"-Eintrag)
     d) Falls unbeantwortete Decisions existieren:
        → Stelle ALLE auf einmal via AskUserQuestion (max 4 pro Aufruf)
        → Jede Frage: header=Decision-ID, options=aus "Optionen" im Block
        → Schreibe Antworten zurueck ins Task-File (Edit: "Antwort:" Zeile)
     e) Falls alle beantwortet → weiter (keine User-Interaktion noetig)
   - Falls Section fehlt → ueberspringen (kein Fehler)
5. Identifiziere Output Location (falls vorhanden):
   - Suche Section "## Output Location" im Task-File
   - Notiere Pfade für execution-logs/ und artifacts/
   - Falls Ordner nicht existiert → Warnung an User
```

**SATE-Invariante:** Alle Decisions MUESSEN vor Phase 2 beantwortet sein. Keine Unterbrechungen waehrend Ausfuehrung.

**Output:** Task-Kontext verstanden, Dependencies erfüllt, Decisions geklaert, Output-Pfade bekannt.

---

### Phase 1.5: Cross-Cycle Continuation (SATE)

**Aktion:** Erkenne ob dieser Task bereits in einem vorherigen Zyklus bearbeitet wurde und setze an der richtigen Stelle fort.

```
1. CONTINUATION ERKENNEN:
   Pruefe "Action Tracking" Tabelle im Task-File:
   ├─ Gibt es Actions mit Status "✅ completed"?
   │   ├─ NEIN → Neuer Task, weiter mit Phase 2 (normal)
   │   └─ JA → Cross-Cycle Continuation aktiv
   │
   └─ Gibt es Actions mit Status "📋 pending"?
       ├─ JA → Fortsetzen ab erster pending Action
       └─ NEIN (alle completed) → Task abschliessen (Phase 5)

2. BEI CONTINUATION:
   a) Zeige User Continuation-Summary:
      "TASK-XXX: Fortsetzung aus Zyklus [N].
       ✅ Erledigt: Action 1 (Name), Action 2 (Name)
       📋 Offen: Action 3 (Name), Action 4 (Name)
       Decisions: Alle beantwortet (aus Phase 1 Schritt 4)"
   b) Ueberspringe erledigte Actions in Phase 2 (Actions Identifizieren)
   c) Decisions aus Task-File sind bereits persistent → kein erneutes Fragen

3. VALIDIERUNG:
   - Git-Log pruefen: Existieren Commits fuer erledigte Actions?
     Format: "feat: TASK-XXX Action N/M - ..."
   - Falls Commit fehlt fuer "completed" Action → Warnung an User
     "Action N als completed markiert, aber kein Git-Commit gefunden.
      Bitte verifizieren."
```

**SATE-Invariante:** Erledigte Actions werden NIEMALS wiederholt. Die Action Tracking Tabelle ist SSOT.

**Output:** Continuation-State bekannt, Startpunkt fuer diesen Zyklus klar.

---

### Phase 2: Actions Identifizieren

**Aktion:** Analysiere Implementation Steps und kategorisiere.

```
Für jeden Step, evaluiere:

1. MODE-HINT PRÜFEN (Vorrang vor Heuristik):
   Suche Backtick-Tag am Zeilenende: `[subagent:model]` oder `[main]`
   Regex: \`\[(subagent|main)(?::(\w+))?\]\`\s*$
   ├─ Tag gefunden → Mode + Modell aus Tag verwenden
   └─ Kein Tag → weiter mit Heuristik (Schritt 2)

2. HEURISTIK (nur wenn kein Mode-Hint):
   ├─ Ist dieser Step unabhängig von anderen?
   │   ├─ JA + keine shared state → Kandidat für Subagent
   │   └─ NEIN (braucht Ergebnis von vorherigem Step) → Main Session
   │
   ├─ Gibt es Unsicherheiten/Fragen?
   │   └─ JA → In "Klärungsbedarf"-Liste aufnehmen
   │
   └─ Erfordert dieser Step User-Entscheidung?
       └─ JA → Markiere als "User-Approval Required"

3. MODELL-ZUWEISUNG (nur für Subagents):
   ├─ Modell im Hint angegeben (z.B. :haiku) → verwende dieses Modell
   └─ Kein Modell im Hint → Parent-Session-Modell (kein model Parameter)
```

**Delegation-Heuristik:** Siehe `references/delegation-patterns.md`

**Output:** Kategorisierte Action-Liste mit Mode + Modell pro Step.

---

### Phase 2.5: Session Planning (SATE Budget Intelligence)

**Aktion:** Berechne Budget Envelopes und erstelle einen Session Plan.

**Voraussetzung:** Task-File hat eine "Action Tracking" Tabelle (Format aus SATE Task-Template).

```
1. BUDGET-DATEN LESEN:
   Lese /tmp/claude-token-budget.json (geschrieben von statusline.sh)
   → Extrahiere: pct (aktuelle Nutzung %), available_k (verfuegbare K-Tokens)
   → Falls Datei fehlt: Warnung, dann mit konservativer Schaetzung (50% verbraucht) arbeiten

2. PENDING ACTIONS IDENTIFIZIEREN:
   Lese "Action Tracking" Tabelle aus Task-File
   → Filtere: nur Actions mit Status "pending" oder "📋 pending"
   → Notiere Action-Nummer, Name, geschaetzten Effort

3. BUDGET ENVELOPES BERECHNEN:
   Fuer jede pending Action:
   ├─ Lookup Action-Typ in references/action-budget-heuristics.md
   ├─ Weise Token-Schaetzung zu (Mittelwert des Ranges)
   └─ Berechne kumulatives Budget (Σ)

   Reserve = 15K (fuer Cleanup: Commit + Task-Update + Session-Refresh)
   Verfuegbar = available_k * 1000

4. SESSION PLAN ERSTELLEN:
   Markiere jede Action als:
   ├─ ✅ PASST: Σ + Reserve < Verfuegbar
   ├─ ⚠️ GRENZFALL: Σ + Reserve ist 80-100% von Verfuegbar
   └─ 🔴 PASST NICHT: Σ + Reserve > Verfuegbar
```

**Session Plan Template:**
```
## Session Plan (Budget Intelligence)

**Budget:** [curr_k]K / [size_k]K ([pct]%) verbraucht | ~[available_k]K verfuegbar
**Reserve:** 15K (Cleanup)

| # | Action | Typ | Geschaetzt | Σ kumulativ | Status |
|---|--------|-----|-----------|-------------|--------|
| 2 | Budget Intelligence | Code (mittel) | ~47K | 47K | ✅ PASST |
| 3 | Autonomous Flow | Code (mittel) | ~47K | 94K | ⚠️ GRENZFALL |
| 4 | E2E Test | Test | ~22K | 116K | 🔴 PASST NICHT |

**Empfehlung:** Actions 2-3 in diesem Zyklus ausfuehren. Action 4 → naechster Zyklus.
```

**Entscheidungslogik:**
- Alle ✅: Weiter mit Plan Praesentation (Phase 3)
- Mix ✅/⚠️: User informieren, Empfehlung geben, Bestaetigung holen
- Erste Action bereits 🔴: Session zu weit verbraucht → `/session-refresh` + `/clear` empfehlen

**Output:** Session Plan mit Budget-Empfehlung, User-bestaetigter Action-Scope.

---

### Phase 3: Plan Präsentieren + Bestätigung

**Aktion:** Zeige dem User den Ausführungsplan und hole Bestätigung.

**Template:**
```
## Ausführungsplan für TASK-XXX

**Objective:** [1-Satz-Zusammenfassung]

### Geplante Ausführung:

**Main Session (sequentiell):**
1. [Step X]: [Beschreibung]
2. [Step Y]: [Beschreibung]

**Subagents (parallel möglich):**
- [Step Z]: [Beschreibung] → Modell: [haiku|sonnet|opus|parent]
  Quelle: [hint|heuristik]

**Klärungsbedarf vor Start:**
- [Frage 1]
- [Frage 2]

---
Soll ich starten? [Ja] / [Anpassungen]
```

**Hinweis:** Modell-Zuweisung im Plan transparent machen. User kann vor Start anpassen.

**Wichtig:** IMMER User-Bestätigung einholen, bevor Subagents starten.

---

### Phase 4: Ausführung Orchestrieren

**Aktion:** Führe Plan aus, koordiniere Subagents, pruefe Budget zwischen Actions.

```
1. Kläre offene Fragen zuerst (AskUserQuestion)
2. Starte genehmigte Subagents (Task tool, run_in_background=true)
3. Führe Main-Session Actions sequentiell aus
4. === NACH JEDER ACTION: Checkpoint + Budget-Check (siehe unten) ===
5. Bei neuen Unsicherheiten während Ausführung:
   → Pause + User einbinden (siehe references/uncertainty-handling.md)
6. Monitore Subagent Completion (TaskOutput / Read output file)
7. Konsolidiere Ergebnisse
```

#### 4a: Checkpoint nach jeder Action

Nach Abschluss einer Action → automatischer Checkpoint:

```
1. Rufe scripts/checkpoint.sh auf:
   Bash: ~/.claude/skills/task-orchestrator/scripts/checkpoint.sh \
         TASK-XXX <ACTION_NR> <ACTION_TOTAL> "<ACTION_NAME>" <PROJECT_ROOT>

   → Commit-Format: feat: TASK-XXX Action N/M - Action-Name
   → Audit Trail im Task-File wird automatisch ergaenzt

2. Falls checkpoint.sh Exit Code 2 (nichts zu committen):
   → OK, weiter (Action hatte keine Datei-Aenderungen)

3. Falls checkpoint.sh Exit Code 1 (Fehler):
   → Warnung an User, manuellen Commit empfehlen
```

#### 4b: Budget-Check zwischen Actions

Nach jedem Checkpoint → Budget fuer naechste Action pruefen:

```
1. BUDGET LESEN:
   Lese /tmp/claude-token-budget.json
   → Extrahiere: pct, available_k

2. NAECHSTE ACTION PRUEFEN:
   Naechste pending Action aus Session Plan (Phase 2.5)
   → Geschaetzte Tokens der naechsten Action
   → Reserve = 15K

3. ENTSCHEIDUNG:
   ├─ available_k > geschaetzt + 15K  → ✅ Weiter mit naechster Action
   ├─ available_k > geschaetzt         → ⚠️ GRENZFALL: User fragen
   │   "Naechste Action (XK) passt knapp. Reserve waere aufgebraucht.
   │    Weiter oder Zyklus beenden?"
   └─ available_k < geschaetzt         → 🔴 STOP: Zyklus-Ende einleiten
       "Budget reicht nicht fuer naechste Action.
        → Empfehlung: /session-refresh, dann /clear fuer naechsten Zyklus."

4. BEI ZYKLUS-ENDE:
   ├─ Alle ausstehenden Subagents abwarten oder abbrechen
   ├─ Task-Status bleibt "in_progress" (nicht completed)
   ├─ Action Tracking Tabelle ist durch Checkpoints aktuell
   └─ Empfehle User: /session-refresh → /clear → weiter
```

**SATE-Invariante:** Keine Action ueber Zyklus-Grenzen starten. Lieber eine Action weniger als eine halb-fertige.

#### Subagent-Steuerung (unveraendert)

**Subagent Start mit Modell-Hint:**
```
# Subagent starten MIT Modell-Hint (aus Task-File):
Task tool:
  run_in_background=true
  model="haiku"          ← aus `[subagent:haiku]` Tag
  → gibt output_file zurück

# Subagent starten OHNE Modell-Hint:
Task tool:
  run_in_background=true
  (kein model Parameter)  ← erbt Parent-Session-Modell
  → gibt output_file zurück
```

**Subagent Monitoring:**
```bash
# Status prüfen (nicht-blockierend)
TaskOutput: task_id=X, block=false

# Oder output_file lesen
Read: output_file path
```

**Output-Ablage (aus Phase 1 "Output Location"):**
- Subagent Logs → `docs/tasks/TASK-XXX/execution-logs/`
- Generierte Artifacts → `docs/tasks/TASK-XXX/artifacts/`
- Falls Ordner fehlt → User warnen, NICHT selbst erstellen (SoC: Task-Erstellung ≠ Task-Ausführung)

---

### Phase 5: Abschluss + Dokumentation

**Aktion:** Prüfe DoD, aktualisiere Dokumentation.

```
1. Prüfe Acceptance Criteria
   - Gehe jeden Punkt durch
   - Markiere als ✅ oder 🔴
   - Bei 🔴: Notiere was fehlt

2. Update PROJEKT.md
   - Status: ⏳ in_progress → ✅ completed (oder 🚫 blocked)
   - Falls blocked: Grund dokumentieren

3. Update Task-File (docs/tasks/TASK-XXX-*.md)
   - Audit Trail: Datum | Aktion | Ergebnis
   - Metadaten: Updated-Datum

4. Zeige Completion Summary:
   "✅ TASK-XXX abgeschlossen
    - [Deliverable]: [Was produziert wurde]
    - [Dauer]: ~Xh
    - [Nächste Tasks]: TASK-YYY jetzt ready"

5. SESSION-REFRESH INTEGRATION (SATE):
   Unterscheide zwei Szenarien:

   A) TASK VOLLSTAENDIG ABGESCHLOSSEN (alle Actions done):
      → Trigger /session-refresh automatisch
      → Empfehle User: "/clear fuer frischen Kontext, dann naechster Task"

   B) ZYKLUS-ENDE MITTEN IM TASK (Budget erschoepft, nicht alle Actions done):
      → Task-Status bleibt ⏳ in_progress in PROJEKT.md
      → Action Tracking Tabelle ist durch Checkpoints (Phase 4a) aktuell
      → Trigger /session-refresh
      → Empfehle User:
        "Zyklus-Ende: Actions 1-N erledigt, Actions N+1-M offen.
         → /clear → 'Arbeite TASK-XXX ab' → Continuation setzt bei Action N+1 fort."
```

---

## Regeln

### Orchestrator-Rolle

- **Main Session = Koordinator** (nicht Worker für alles)
- Delegiere parallelisierbare Arbeit
- Konsolidiere Ergebnisse
- Behalte Gesamtübersicht

### Unsicherheits-Handling

Bei folgenden Situationen → User einbinden (AskUserQuestion):

1. **Unklare Anforderungen** - Task-Objective interpretierbar
2. **Widersprüche** - Bestehender Code/Docs widerspricht Task
3. **Wegweisende Entscheidungen** - Architektur, Patterns, Breaking Changes
4. **Fehlende Informationen** - Credentials, Config, externe Ressourcen

**NIEMALS:**
- Annahmen machen bei unklaren Anforderungen
- Eigenmächtig Scope erweitern
- Breaking Changes ohne Bestätigung

Details: `references/uncertainty-handling.md`

### DoD-Awareness

- Lese Definition of Done aus PROJEKT.md (Phase-Level)
- Prüfe Acceptance Criteria aus Task-File (Task-Level)
- Markiere erledigte Criteria automatisch
- Bei unvollständiger DoD → Task bleibt in_progress

### Task-File Metablock Guardrail (TASK-057)

Wenn der Orchestrator ein Task-File **erstellt oder aktualisiert**, MUSS der Metablock vollstaendig sein:

**Pflicht-Felder (Metablock):**
```
**UUID:** TASK-NNN
**Status:** [📋 pending | ⏳ in_progress | 📘 ongoing | ✅ completed | 🚫 blocked | ❌ cancelled]
**Created:** YYYY-MM-DD
**Updated:** YYYY-MM-DD
**Effort:** [1h | 2h | 4h | 1d | 2d | 3d+]
**Dependencies:** [None | TASK-NNN, TASK-MMM]
```

**Pflicht-Sections:**
- `## Objective`
- `## Acceptance Criteria`
- `## Audit Trail`

**Erlaubte Status-Werte (SSOT: task-scheduler/SKILL.md):**
`pending`, `in_progress`, `ongoing`, `completed`, `blocked`, `cancelled`

**Validierung:** Pre-Commit Hook (`scripts/task-lint.sh --staged`) blockiert Commits mit fehlerhaften Task-Files. Der Orchestrator stellt sicher, dass es gar nicht erst dazu kommt.

---

### SATE-Invarianten (Session-Autonomous Task Execution)

Harte Regeln, die NIEMALS verletzt werden duerfen:

1. **Keine Action ueber Zyklus-Grenzen:** Eine Action wird entweder komplett in einem Zyklus abgeschlossen oder gar nicht gestartet. `/clear` ist die bevorzugte Zyklus-Grenze.
2. **1 Task pro Zyklus:** Der Orchestrator arbeitet genau einen Task ab. Mehrere Actions innerhalb eines Tasks sind erlaubt.
3. **Decision Frontloading:** Alle strategischen Entscheidungen (Pre-Flight Decisions) MUESSEN vor Phase 2 geklaert sein. Waehrend der Ausfuehrung (Phase 4) keine User-Unterbrechungen fuer Decisions.
4. **Checkpoint nach jeder Action:** Git-Commit + Audit Trail Update via `scripts/checkpoint.sh`. Kein Ueberspringen.
5. **Budget vor Action pruefen:** Vor jeder neuen Action: Budget-Check (Phase 4b). Lieber eine Action weniger als eine halb-fertige.
6. **Action Tracking Tabelle = SSOT:** Die Tabelle im Task-File ist die einzige Wahrheit ueber Action-Status. Erledigte Actions werden NIEMALS wiederholt.
7. **Session-Refresh bei Zyklus-Ende:** Egal ob Task completed oder Zyklus-Ende mitten im Task — immer `/session-refresh` triggern.

### Automatische Dokumentation

Nach jeder Task-Completion:
- ✅ PROJEKT.md Status-Update
- ✅ Task-File Audit Trail
- ✅ Metadaten (Updated-Datum)

**NICHT automatisch:**
- CLAUDE.md (nur bei Architectural Decisions)
- Session-Handoff (nur bei Session-Ende)

---

## Integration

### Ergänzt task-scheduler (/run-next-tasks)

```
/run-next-tasks  →  Zeigt: TASK-007 ready, TASK-008 blocked
                            ↓
User: "Arbeite TASK-007 ab"
                            ↓
task-orchestrator  →  Orchestriert Ausführung mit diesem Workflow
```

### Kombination mit /prioritize-tasks (optional)

Wenn mehrere Ready-Tasks existieren:

```
/run-next-tasks    →  TASK-007 ready, TASK-009 ready, TASK-010 ready
                              ↓
/prioritize-tasks  →  Empfehlung: TASK-009 (Score 8.5), TASK-007 (6.2), TASK-010 (4.1)
                              ↓
User: "Arbeite TASK-009 ab"  (höchste Priorität)
                              ↓
task-orchestrator  →  Führt TASK-009 aus
```

**Workflow:** Discovery (`/run-next-tasks`) → Priorisierung (`/prioritize-tasks`) → Execution (`task-orchestrator`)

### Kompatibilität

- **7-Column Task Schema** in PROJEKT.md (unverändert)
- **Task-File Format** in docs/tasks/ (Standard)
- **Subagent API** (Claude Code Task tool)

---

## Referenzen

- `references/delegation-patterns.md` - Wann Background vs. Main Session
- `references/uncertainty-handling.md` - Wann User einbinden
- `references/action-budget-heuristics.md` - Token-Schaetzungen pro Action-Typ (SATE)
- `scripts/checkpoint.sh` - Automatischer Git-Commit + Audit Trail nach Actions (SATE)

---

*Erstellt: 2026-01-22 | SATE Autonomous Flow: 2026-02-17*
