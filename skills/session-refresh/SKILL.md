---
name: session-refresh
description: |
  **SESSION END / HIGH TOKEN BUDGET** - Use when token budget >65% or before ending a session.

  Complete session refresh: Updates CLAUDE.md + PROJEKT.md → conditional restructure → Token-Budget hint.

  Trigger keywords: "session refresh", "update docs", "phase transition", "token budget high"

  Use when: (1) token budget >65%, (2) before session end, (3) phase transitions, (4) consolidating learnings.
  Conditional /project-doc-restructure (only when NEEDS_RESTRUCTURE). Danach Token-Budget manuell reduzieren (CLI Built-in).

  NOT needed at session start if previous session ended with /session-refresh.

model: opus
allowed-tools: Read, Edit, Bash
---

# Session Refresh - Execution Instructions

Human-facing docs (FAQ, features, workflow): `references/README.md`

## Instructions for Claude

When this skill is triggered:

### 0. Context-Check (Token-Spar-Logik)

**BEFORE reading any files, check conversation context:**
- IF CLAUDE.md was already read in this session AND no structural changes expected → **Skip CLAUDE.md read**
- IF PROJEKT.md was already read in this session → **Skip PROJEKT.md read**
- ALWAYS run Health-Check (Bash, token-efficient)

This eliminates ~3.000-10.000 Token redundanter Reads.

### 1. Read Current State (nur wenn noetig)

- Read CLAUDE.md (project root) — **only if not already in context**
- Read PROJEKT.md (usually docs/PROJEKT.md) — **only if not already in context**
- Analyze conversation context for session learnings

### 1.5. Run PROJEKT Health-Check

```bash
${CLAUDE_PLUGIN_ROOT}/skills/session-refresh/bin/projekt-health-check.sh ./docs/PROJEKT.md
```

- Parses Task-Table (7-Column Schema)
- Validates: File existence, Status consistency, Dependencies
- Output includes `NEEDS_RESTRUCTURE` flag (see exit codes + stdout)
- Exit Codes: `0` = Healthy, `1` = Warnings, `2` = Critical, `3` = Error

**Bei Exit 2 (Critical):** Zeige Report, frage User ob vor Updates korrigieren.

### 2. Identify Updates

- What was learned this session? (patterns, decisions, insights)
- What tasks were completed or progressed?
- What blockers were resolved or discovered?
- What architectural decisions were made?

### 3. Make Targeted Edits

- Use Edit tool for specific sections
- Keep changes minimal, preserve structure
- Update: Task status, timestamps, Executive Summary

### 4. Show Compact Summary to User

Present changes concisely (max 5 Zeilen):
```
Session-Refresh: X Tasks aktualisiert.
CLAUDE.md: [sections changed]. PROJEKT.md: [tasks changed].
Restructure: [triggered/skipped (reason)].
→ Naechste Session: TASK-XXX ready.
```

Ask for confirmation or adjustments.

### 5. Conditional Restructure

**CHECK Health-Check output for NEEDS_RESTRUCTURE flag:**
- IF `NEEDS_RESTRUCTURE=true` (PROJEKT.md >10K chars OR >5 status changes OR structural issues):
  → Run `/project-doc-restructure`
- IF `NEEDS_RESTRUCTURE=false`:
  → **Skip restructure** (log: "Restructure uebersprungen - Health-Score OK")

**WICHTIG:** CLI Built-in zur Kontextreduktion kann NICHT programmatisch aufgerufen werden.
Weise User an: "Token-Budget manuell reduzieren (CLI Built-in)"

### 6. Commit + Push (automatisch, ohne Rueckfrage)

**Default: Automatisch committen + pushen. Nur stoppen wenn User explizit "nicht committen" sagt.**

#### KRITISCH: .gitignore ist UNANTASTBAR

- **NIEMALS** `git add -f`, `git add --force` oder sonstige Flags zum Umgehen von .gitignore verwenden
- Wenn `git add` einen Pfad wegen .gitignore ablehnt: **Das ist korrekt.** Der Pfad gehoert NICHT ins Repository.
- Stattdessen nur trackbare Dateien einzeln adden oder .gitignore-konforme Patterns nutzen
- Bei Unsicherheit: User fragen, NIEMALS force-adden

#### Workflow

```bash
# 1. Pruefen was ueberhaupt stageable ist (respektiert .gitignore)
git add -A

# 2. Falls git add fehlschlaegt: STOPPEN. Dateien einzeln adden die NICHT in .gitignore sind.
#    NIEMALS -f oder --force nutzen!

# 3. Commit + Push
git commit -m "$COMMIT_MSG" && git push
```

- Falls `git add` Fehler meldet ("ignored by .gitignore"): **NUR die nicht-ignorierten Dateien einzeln adden**
- Falls kein Remote konfiguriert: nur lokaler Commit
- Commit-Message: Deutsche Sprache, Format `[Typ]: Kurzbeschreibung`

### 7. Session-Handoff (automatisch, ohne Rueckfrage)

**Default: Automatisch erstellen. Nur ueberspringen wenn User explizit "kein Handoff" sagt.**

- Erstelle akkumulierende Handoff-Datei: `docs/handoffs/SESSION-HANDOFF-YYYY-MM-DD-SNNN.md`
  - **Dateiname-Pattern:** `SESSION-HANDOFF-{Datum}-S{Session-Nr}.md` (z.B. `SESSION-HANDOFF-2026-03-18-S192.md`)
  - Template: `assets/session-handoff-template.md` (mit YAML-Frontmatter)
  - Inhalt: YAML-Properties (fileClass, tasks, tags, outcome) + Erreichte Tasks, Naechste Session, Learnings
  - **WICHTIG:** Jede Session erstellt eine NEUE Datei (kein Ueberschreiben). Handoffs akkumulieren.
  - **PARALLELITAET:** NUR die Main-Session schreibt Handoff-Dateien. Subagents und parallele Tasks schreiben NICHT.

### 7b. Vault-Write (wenn Obsidian CLI verfuegbar)

**Feature-Detection:** Fuehre `obsidian.com version` aus. Wenn erfolgreich → Vault-Write ausfuehren. Wenn nicht → diesen Schritt ueberspringen (kein Fehler).

```bash
# Feature-Detection (einmal pro Session)
obsidian.com version 2>/dev/null
```

**Wenn verfuegbar, NACH dem File-Write (Step 7):**

1. **Handoff im Vault erstellen** (Dual-Write — File + Vault):

```bash
obsidian.com create name="SESSION-HANDOFF-YYYY-MM-DD-SNNN" path="_claude-pm" content="<YAML-Frontmatter + Body>"
```

- Gleicher Inhalt wie die .md-Datei aus Step 7
- `path="_claude-pm"` legt die Datei im PM-Ordner ab
- Frontmatter muss `fileClass: claude-session` enthalten (Template aus `assets/`)

2. **Task-Status im Vault aktualisieren** (fuer jeden geaenderten Task):

```bash
obsidian.com property:set name="status" value="completed" type=text file="TASK-NNN-name"
```

3. **Projekt-Status aktualisieren** (wenn Phase/Status sich geaendert hat):

```bash
obsidian.com property:set name="phase" value="Phase X: ..." type=text file="PROJECT-xxx"
```

**WICHTIG:**
- File-Write (Step 7) hat Vorrang — Vault-Write ist Bonus, kein Ersatz
- Bei Vault-Fehlern: Warnung loggen, nicht abbrechen
- `file=` Parameter nutzt Wikilink-Aufloesung (Dateiname ohne Pfad/Extension)
- CWD muss im Claude Vault liegen (oder cd dahin) — `vault=` wird von CLI ignoriert

### 8. Final Report (Compact)

3-5 Zeilen Zusammenfassung:
```
Session-Refresh abgeschlossen. X Tasks aktualisiert.
Restructure: [status]. Token-Budget: manuell reduzieren.
→ Naechster Task: TASK-XXX | Tipp: /prioritize-tasks (bei >=3 pending)
```

**Kein Execution-Log** ausser bei Fehlern. Audit Trail nur in Task-File dokumentieren.
