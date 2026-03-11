---
name: auto-task
description: Autonomous task execution via hook-based in-session loop. Executes all pending actions in a task file sequentially with git checkpoints. Use when tasks have clearly defined action tracking tables and all pre-flight decisions are answered.
arguments:
  - name: task_id
    description: Task UUID (e.g., TASK-073). If omitted, will prompt interactively.
    required: false
---

# Auto-Task: Autonomous Task Execution

Fuehrt alle pending Actions eines Tasks autonom aus — ohne manuelle Bestaetigung pro Action.
Der Stop-Hook (`auto-task-loop-hook.sh`) blockiert das Session-Ende und re-injiziert den naechsten Action-Prompt, bis alle Actions complete sind.

**Ablauf:** Phase 1 (interaktiv, dieser Skill) → Phase 2 (autonom, Stop-Hook uebernimmt)

---

## Phase 1: Pre-Flight (Interaktiv)

Fuehre die folgenden Schritte der Reihe nach aus. Bei Fehlern in einem Schritt: stoppe und informiere den User.

### Schritt 1: Task-ID ermitteln

- Wenn ein `task_id` Argument uebergeben wurde: verwende dieses
- Sonst: Frage den User nach der Task-ID (z.B. "TASK-073")
- Normalisiere: Stelle sicher, dass das Format `TASK-NNN` ist (mit fuehrendem "TASK-")

### Schritt 2: Task-File finden und laden

Suche die Task-Datei im Projekt:

```bash
# Pattern: docs/tasks/TASK-NNN-*.md
ls docs/tasks/${TASK_ID}-*.md 2>/dev/null
```

- Wenn KEINE Datei gefunden: Fehler melden und abbrechen
- Wenn gefunden: Lies das gesamte Task-File mit dem Read Tool
- Merke dir den **absoluten Pfad** zur Task-Datei (wird im State-File benoetigt)

### Schritt 3: Action Tracking Table validieren

Pruefe, ob das Task-File eine Action Tracking Table enthaelt:

- Die Tabelle hat das Format: `| # | Action | Status | ... |`
- Zeilen mit `| N |` (N = Zahl) sind Action-Eintraege
- Wenn KEINE Action-Tabelle gefunden: Fehler melden — "Dieses Task-File hat keine Action Tracking Table. Auto-Task benoetigt klar definierte Actions."

Nutze das parse-next-action.sh Script zur Validierung:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/parse-next-action.sh" "<absoluter-pfad-zum-task-file>"
```

- Exit 0 + JSON mit `"status":"pending"` = Es gibt pending Actions → weiter
- Exit 1 + JSON mit `"status":"all_complete"` = Alle Actions bereits erledigt → informiere User, abbrechen
- Exit 2 = Parse-Error → Fehler melden, abbrechen

### Schritt 4: Pending Actions anzeigen

Zeige dem User eine Uebersicht:

```
Auto-Task fuer TASK-NNN: [Task-Titel]

Actions:
  #1: [Name] — complete
  #2: [Name] — complete
  #3: [Name] — PENDING  ← naechste
  #4: [Name] — pending
  #5: [Name] — pending

3 pending Actions, 2 bereits abgeschlossen.
```

Lies die Action-Tabelle aus dem Task-File und formatiere sie entsprechend.

### Schritt 5: Pre-Flight Decisions pruefen

Pruefe im Task-File, ob es einen Abschnitt "Pre-Flight Decisions" gibt:
- Wenn ja: Pruefe ob alle Decisions beantwortet sind (nicht "TBD", "offen", "pending")
- Wenn unbeantwortete Decisions existieren: Zeige sie dem User und frage nach Antworten
- Wenn keine Pre-Flight Section existiert oder alle beantwortet: weiter

### Schritt 6: Konfiguration

Berechne und zeige die Loop-Konfiguration:

- **Pending Actions:** Anzahl aus Schritt 4
- **Max Iterations:** `pending_count + 2` (2 Extra als Buffer fuer Retries)
- Zeige dem User die Konfiguration:

```
Loop-Konfiguration:
  Pending Actions: 3
  Max Iterations:  5 (3 + 2 Buffer)
  Safety Guards:   Permission-System aktiv, Git-Commits nach jeder Action
  Abbrechen:       /cancel-auto-task jederzeit
```

Frage den User: **"Auto-Task Loop starten?"**

- Wenn der User ablehnt: abbrechen, kein State-File erstellen
- Wenn der User zustimmt: weiter

### Schritt 7: State-File erstellen

Erstelle das State-File im Task-Output-Ordner. Stelle zuerst sicher, dass der Ordner existiert:

```bash
mkdir -p "docs/tasks/${TASK_ID}"
```

Erstelle die Datei `docs/tasks/${TASK_ID}/auto-task.state` mit folgendem Inhalt:

```text
task_id=TASK-NNN
task_file=/absoluter/pfad/zum/task-file.md
project_root=/absoluter/pfad/zum/projekt/
iteration=0
max_iterations=N
session_id=SESSION_ID
started_at=TIMESTAMP
```

Werte:
- `task_id`: Die Task-ID (z.B. TASK-073)
- `task_file`: Absoluter Pfad zur Task-Datei (Unix-Format mit Forward Slashes)
- `project_root`: Absoluter Pfad zum Projekt-Root (CWD, Unix-Format)
- `iteration`: Immer `0` (Hook inkrementiert)
- `max_iterations`: Berechneter Wert aus Schritt 6
- `session_id`: Leer lassen (Session-Isolation ist optional)
- `started_at`: Aktueller Timestamp im ISO-Format

**WICHTIG:** Nutze das Write Tool, um die Datei zu erstellen. Nutze NICHT echo/heredoc im Bash Tool.

### Schritt 8: Erste Action ausfuehren

Lies das Task-File nochmal komplett neu (fuer vollen Context) und fuehre die erste pending Action aus:

1. Lies das Task-File
2. Lies den "Action Details" Abschnitt fuer die erste pending Action
3. Fuehre die Action aus wie im Task-File beschrieben
4. Nach Abschluss: Aktualisiere den Action-Status in der Action Tracking Table auf `complete` (mit aktuellem Session-Zyklus)
5. Erstelle einen Git-Commit:
   - Stage nur die geaenderten Dateien (NICHT `git add .` oder `git add -A`)
   - Commit-Message: `docs: S[NNN] TASK-[NNN] Action [N] — [Action-Name]`

**Ab hier uebernimmt der Stop-Hook.** Wenn du nach dem Commit die Session beenden willst, wird der Stop-Hook pruefen, ob noch pending Actions existieren, und dich ggf. weiterschicken.

---

## Kritische Constraints

### Scope-Lock
- Fuehre NUR Actions aus dem angegebenen Task aus
- Keine "Verbesserungen" oder "Aufraeum-Arbeiten" nebenbei
- Jede Iteration = genau EINE Action

### Git Safety
- NIEMALS `git add .`, `git add -A`, oder `git add -f`
- Nur explizit geaenderte Dateien stagen
- Ein Commit pro Action

### State-File Integrität
- Das State-File wird NUR in Schritt 7 erstellt
- Der Stop-Hook liest und aktualisiert es
- Wenn du das State-File manuell loeschen willst: nutze `/cancel-auto-task`

### Compaction-Resilience
- Nach Compaction ist der bisherige Context weg
- Der Stop-Hook re-injiziert immer "Lies das Task-File NEU"
- Verlasse dich NICHT auf Context aus vorherigen Actions

### Action-Pacing
- In diesem Skill (Phase 1) wird NUR die ERSTE Action ausgefuehrt
- Der Stop-Hook uebernimmt ab Action 2
- Versuche NICHT, mehrere Actions in einer Iteration auszufuehren
