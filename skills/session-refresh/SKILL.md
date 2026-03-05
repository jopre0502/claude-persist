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
- IF no new decisions to log → **Skip DECISION-LOG.md read**
- ALWAYS run Health-Check (Bash, token-efficient)

This eliminates ~3.000-4.500 Token redundanter Reads.

### 1. Read Current State (nur wenn noetig)

- Read CLAUDE.md (project root) — **only if not already in context**
- Read PROJEKT.md (usually docs/PROJEKT.md) — **only if not already in context**
- Analyze conversation context for session learnings

### 1.5. Run PROJEKT Health-Check

```bash
~/.claude/skills/session-refresh/bin/projekt-health-check.sh ./docs/PROJEKT.md
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
- Update: Task status, Decision Log, timestamps, Executive Summary

### 4. Show Compact Summary to User

Present changes concisely (max 5 Zeilen):
```
Session-Refresh: X Tasks aktualisiert, Y Decisions geloggt.
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

- `git add -A && git commit -m "$COMMIT_MSG" && git push`
- Falls kein Remote konfiguriert: nur lokaler Commit
- Commit-Message: Deutsche Sprache, Format `[Typ]: Kurzbeschreibung`

### 7. Session-Handoff (automatisch, ohne Rueckfrage)

**Default: Automatisch erstellen. Nur ueberspringen wenn User explizit "kein Handoff" sagt.**

- Erstelle `docs/handoffs/SESSION-HANDOFF-YYYY-MM-DD.md` (oder Projekt-Root falls kein docs/)
  - Template: `assets/session-handoff-template.md`
  - Inhalt: Erreichte Tasks, Blocker, Learnings, Empfehlungen, Token-Trend

### 8. Final Report (Compact)

3-5 Zeilen Zusammenfassung:
```
Session-Refresh abgeschlossen. X Tasks, Y Decisions.
Restructure: [status]. Token-Budget: manuell reduzieren.
→ Naechster Task: TASK-XXX | Tipp: /prioritize-tasks (bei >=3 pending)
```

**Kein Execution-Log** ausser bei Fehlern. Audit Trail nur in Task-File dokumentieren.
