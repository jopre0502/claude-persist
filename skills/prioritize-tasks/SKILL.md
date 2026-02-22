---
name: prioritize-tasks
description: |
  Analysiert und priorisiert Tasks in PROJEKT.md basierend auf Dependencies,
  Effort und Known Issues. Berechnet Priority-Scores und schlägt optimale
  Reihenfolge vor.

  Use this skill when you want to:
  - Re-prioritize tasks based on current blockers
  - Integrate Known Issues into task planning
  - Find quick wins (low effort, no dependencies)
  - Optimize task execution order

  Triggered via /prioritize-tasks command.

model: sonnet
---

# Task-Priorisierung Skill

Analysiert PROJEKT.md und berechnet Priority-Scores für alle Tasks basierend auf Dependencies, Effort und Known Issues.

## Unterschied zu /run-next-tasks

| Feature | `/run-next-tasks` | `/prioritize-tasks` |
|---------|-------------------|---------------------|
| Dependency-Resolution | ✅ | ✅ |
| Ready/Blocked Kategorisierung | ✅ | ✅ |
| **Priority Scoring** | ❌ | ✅ |
| **Sortierung nach Score** | ❌ | ✅ |
| **Known Issues Integration** | ❌ | ✅ |
| **Neue Task-Vorschläge** | ❌ | ✅ |

**Empfehlung:** `/prioritize-tasks` zuerst aufrufen (Analyse + Sortierung), dann `/run-next-tasks` (Execution).

## Funktionalität

### 1. Parse Phase

**Input:** `docs/PROJEKT.md`

**Process:**
1. Task-Tabelle extrahieren (7-Column Schema)
2. Known Issues / Blockers Section extrahieren
3. Dependencies in Graph-Struktur konvertieren

### 2. Analyze Phase (Think Harder)

**Scoring-Faktoren:**

| Faktor | Gewicht | Rationale |
|--------|---------|-----------|
| Effort (invertiert) | 3x | Quick Wins zuerst |
| Dependencies (invertiert) | 1x | Unabhängige Tasks flexibler |
| Unblocks (positiv) | 0.5x | Freischaltende Tasks wichtiger |
| Known Issues (negativ) | -2x | Blockierte Tasks deprioritisieren |

**Formel:**
```
Priority-Score =
    (1 / effort_hours) * 3           # Kleine Tasks zuerst
  + (1 / (dependencies_count + 1))   # Weniger Dependencies besser
  + (unblocks_count * 0.5)           # Tasks die andere freischalten
  - (known_issue_impact * 2)         # Known Issues reduzieren Score
```

### 3. Integrate Phase

**Known Issues Strategie:**
- Falls Issue in bestehenden Task passt → Integration-Empfehlung
- Falls SoC sinnvoller → Neuen Task vorschlagen (TASK-NNN+1)

### 4. Sort Phase

- Tasks nach Priority-Score absteigend sortieren
- Ergebnis: Optimale Execution-Reihenfolge

### 5. Output Phase

Generiert Report mit:
- Sortierte Task-Liste mit Scores
- Empfehlung: Top 3 Tasks für nächste Session
- Geblockte Tasks mit Begründung
- Vorgeschlagene neue Tasks (aus Known Issues)

## Usage

### Standard-Aufruf (Analyse only)
```bash
/prioritize-tasks
```

### Mit PROJEKT.md Aktualisierung
```bash
/prioritize-tasks --reorder
```
Sortiert Task-Tabelle in PROJEKT.md nach Priority-Score um.

### Spezifischer Pfad
```bash
/prioritize-tasks /path/to/PROJEKT.md
```

## Output-Format

```markdown
## Task-Priorität Analyse

### 🚀 Empfohlene Reihenfolge

| Rang | Task | Score | Begründung |
|------|------|-------|------------|
| 1 | TASK-024 | 8.5 | Low effort (2h), keine Dependencies |
| 2 | TASK-023 | 6.2 | Medium effort, unblocks TASK-025 |
| 3 | TASK-025 | 4.1 | High effort, wartet auf TASK-023 |

### ⚠️ Geblockt durch Known Issues

| Task | Known Issue | Empfehlung |
|------|-------------|------------|
| TASK-026 | API-Key fehlt | User-Input erforderlich |

### 💡 Vorgeschlagene neue Tasks (aus Known Issues)

- **TASK-027:** API-Credentials Setup (abgeleitet aus Known Issue #2)

### 📊 Scoring-Details

| Task | Effort | Deps | Unblocks | Issues | Score |
|------|--------|------|----------|--------|-------|
| TASK-024 | 2h | 0 | 1 | 0 | 8.5 |
| TASK-023 | 4h | 1 | 2 | 0 | 6.2 |
...
```

## Integration mit anderen Skills

| Skill | Integration |
|-------|-------------|
| `/run-next-tasks` | Nutzt Priorität für Execution-Reihenfolge (optional) |
| `/session-refresh` | Kann `/prioritize-tasks` vor Restructuring aufrufen |
| `/task-orchestrator` | Priorisierte Reihenfolge für Execution |

## Scripts

### prioritize.sh

**Hauptscript:** `~/.claude/skills/prioritize-tasks/scripts/prioritize.sh`

```bash
prioritize.sh [PROJEKT_PATH] [--reorder]
```

**Funktionen:**
- `extract_task_table()`: Parse Task-Tabelle (wiederverwendet von task-scheduler)
- `extract_known_issues()`: Parse Known Issues Section
- `build_dependency_graph()`: Adjacency-Liste für Dependencies
- `calculate_unblocks()`: Welche Tasks werden durch diesen Task freigeschaltet?
- `calculate_priority_score()`: Scoring-Algorithmus
- `sort_by_priority()`: Sortierung via jq
- `generate_report()`: Output-Formatierung
- `reorder_projekt_md()`: PROJEKT.md Task-Tabelle updaten (optional)

## Error Handling

### Keine Tasks gefunden
**Resolution:** Hinweis auf PROJEKT.md Format + Link zu 7-Column Schema

### Known Issues Section fehlt
**Resolution:** Graceful degradation - Scoring ohne Known Issues Impact

### Ungültiger Effort-Wert
**Resolution:** Default zu 4h (Medium), Warnung ausgeben

### Zirkuläre Dependencies
**Resolution:** Warnung, betroffene Tasks mit Score 0

## Configuration

### Environment Variables

```bash
PRIORITIZE_EFFORT_WEIGHT=3        # Gewicht für Effort-Faktor
PRIORITIZE_DEPS_WEIGHT=1          # Gewicht für Dependency-Faktor
PRIORITIZE_UNBLOCKS_WEIGHT=0.5    # Gewicht für Unblocks-Faktor
PRIORITIZE_ISSUES_WEIGHT=2        # Gewicht für Known Issues (negativ)
```

## Known Issues Section Format (in PROJEKT.md)

Unterstützte Formate:

```markdown
## Known Issues / Blockers

- **Issue 1:** Beschreibung (Affects: TASK-001, TASK-002)
- **Issue 2:** Beschreibung ohne Task-Referenz
```

oder:

```markdown
### Known Issues

| # | Issue | Betroffene Tasks | Status |
|---|-------|------------------|--------|
| 1 | API-Key fehlt | TASK-026 | Open |
```

## Effort-Parsing

| Input | Parsed Hours |
|-------|-------------|
| `1h` | 1 |
| `2h` | 2 |
| `4h` | 4 |
| `1d` | 8 |
| `2d` | 16 |
| `3d+` | 24 |
| (leer/invalid) | 4 (default) |

---

## Execution Instructions for Claude

Wenn dieser Skill getriggert wird (`/prioritize-tasks`), führe folgende Schritte aus:

### Schritt 1: Script ausführen

```bash
~/.claude/skills/prioritize-tasks/scripts/prioritize.sh [PROJEKT_PATH]
```

Das Script gibt einen vollständigen Report aus mit:
- Kritischer Pfad (Tasks die andere freischalten)
- Empfohlene Reihenfolge (sortiert nach Score)
- Known Issues Impact
- Scoring-Details
- **JSON-Block** mit sortierten UUIDs

### Schritt 2: Report dem User zeigen

Präsentiere den Report dem User. Erkläre kurz:
- Warum diese Reihenfolge empfohlen wird
- Welche Tasks auf dem kritischen Pfad liegen
- Ob Known Issues die Priorisierung beeinflussen

### Schritt 3: User fragen (WICHTIG!)

Nutze `AskUserQuestion` Tool:

```
Soll ich die Task-Tabelle in PROJEKT.md entsprechend dieser Reihenfolge umsortieren?
- Ja, sortiere um
- Nein, nur anzeigen
```

### Schritt 4: Bei "Ja" - PROJEKT.md aktualisieren

**Wenn User "Ja" wählt:**

1. Extrahiere aus dem JSON-Block die `sorted_uuids` Liste
2. Lese aktuelle PROJEKT.md
3. Finde die Task-Tabelle(n) - erkennbar am 7-Column Header:
   ```
   | UUID | Task | Status | Dependencies | Effort | Deliverable | Task-File |
   ```
4. Sortiere die Tabellenzeilen entsprechend der `sorted_uuids` Reihenfolge:
   - **Pending/In-Progress Tasks:** Nach Score-Reihenfolge (wie in `sorted_uuids`)
   - **Completed/Cancelled Tasks:** Am Ende der Tabelle
   - **Blocked Tasks:** Nach den Pending, vor den Completed
5. Verwende `Edit` Tool um die Tabelle zu aktualisieren
6. Bestätige: "✅ Task-Tabelle in PROJEKT.md wurde nach Priorität sortiert."

**Sortier-Reihenfolge innerhalb der Tabelle:**
```
1. Pending/In-Progress (nach Score absteigend)
2. Blocked (nach Score absteigend)
3. Completed/Cancelled (chronologisch oder alphabetisch)
```

### Schritt 5: Zusammenfassung

Zeige dem User:
- Was geändert wurde (oder nicht)
- Nächster empfohlener Task: "**Nächster Schritt:** TASK-XXX (Score: Y.YY)"
- Optional: Link zu `/run-next-tasks` für Dependency-Check

---

## Beispiel-Workflow

```
User: /prioritize-tasks

Claude:
1. Führt prioritize.sh aus
2. Zeigt Report mit kritischem Pfad und Scoring
3. Fragt: "Soll ich PROJEKT.md umsortieren?"

User: "Ja"

Claude:
4. Liest PROJEKT.md
5. Findet Task-Tabelle
6. Sortiert Zeilen nach Score
7. Speichert mit Edit-Tool
8. Bestätigt: "✅ Sortierung abgeschlossen. Nächster Task: TASK-024"
```

---

**Autor:** Claude Opus 4.5
**Erstellt:** 2026-01-23
**Aktualisiert:** 2026-01-23 (User-Prompt + Edit-Workflow hinzugefügt)
**Status:** ✅ Implementiert
