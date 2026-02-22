# Action Budget Heuristics

> Konservative Token-Schaetzungen pro Action-Typ fuer SATE Session Planning.
> Diese Werte sind initiale Defaults und werden ueber Zeit kalibriert (TASK-041 Action 4).

## Token-Budget pro Action-Typ

| Action-Typ | Geschaetzte Tokens | Beispiel |
|------------|-------------------|----------|
| Dokumentation schreiben | 15K-25K | SKILL.md, HOW-TO, Template-Files |
| Code generieren (klein) | 20K-35K | Einzelnes Script, Hook, Config |
| Code generieren (mittel) | 35K-60K | Skill mit mehreren Files |
| Code Review / Analyse | 15K-25K | Bestehenden Code lesen + bewerten |
| Recherche + Design | 20K-40K | API-Research, Architektur-Entscheidung |
| Test + Validierung | 15K-30K | E2E-Test, Regressions-Check |
| Template-Update (additiv) | 10K-15K | Neue Section zu bestehendem Template |
| Git Operations | 5K-10K | Commit, Status-Updates, Audit Trail |
| Reine Text-Edits (SKILL.md, Hooks) | 8K-15K | Existing SKILL.md Erweiterung, Hook-Updates |

## Session-Budget Planung

**Annahmen:**
- Typisches Context Window: 200K Tokens
- Nutzbare Kapazitaet: ~70% (140K) - Rest fuer CLAUDE.md, PROJEKT.md, System-Prompts
- Reserve fuer Cleanup: 15K (Commit, Task-Update, Session-Refresh)
- Verfuegbar fuer Actions: ~125K

**Formel:**
```
Verfuegbar = (Context_Window * 0.70) - Reserve_Cleanup
Passt_Action = Verfuegbar - Σ(bisherige_Actions) >= Geschaetzte_Tokens(naechste_Action)
```

## Kalibrierungs-Log

| Datum | Action | Session | Typ | Geschaetzt | Tatsaechlich | Delta | Learnings |
|-------|--------|---------|-----|-----------|-------------|-------|-----------|
| 2026-02-17 | TASK-041 Action 1: Foundation (Hooks + Template + Budget-Heuristik) | S39 | Bash-Scripts + Prompt-Hook + Text-Edits | 20-25K | ~22K | +5% ✅ | Konservative Schaetzung war akkurat. Bash-Script-Komplexitaet ist vorhersehbar wenn Fehlerbehandlung einfach (4 Cases). |
| 2026-02-17 | TASK-041 Action 2: Budget Intelligence (Statusline Sidecar + SKILL.md Erweiterung + checkpoint.sh) | S40 | SKILL.md Erweiterung (Phasen) + Bash-Script | 18-22K | ~18K | -4% ✅ | Action ausserhalb Repo (Home-Verzeichnis) zaehlt nicht gegen Session-Budget. Subagent-Fehler zwangen zur Main-Session Arbeit (kein Nachteil). |
| 2026-02-17 | TASK-041 Action 3: Autonomous Flow (Decision Frontloading + Cross-Cycle + Phase Updates + SATE-Invarianten) | S41 | REINE Text-Edits SKILL.md (~200 Zeilen) | 15-20K | ~8K | -55% 🟢 | **GROSSE ABWEICHUNG, aber positiv:** Pure Text-Edits (kein Code, keine neuen Dateien) konsumieren deutlich weniger Tokens als Code-Generierung. Neue Kategorie: "Reine Text-Edits" hinzugefügt. |

## Kalibrierungs-Interpretation

### Gesamt-Delta
- Action 1: +5% (sehr akkurat)
- Action 2: -4% (sehr akkurat)
- Action 3: -55% (positiv überraschend)
- **Durchschnittliche Genauigkeit: ~18% (aber asymmetrisch — Text-Edits sind GÜNSTIGER)**

### Schlüssel-Erkenntnisse

1. **Text-Edits vs. Code-Generierung ist kritisch:**
   - Code-Generierung (Hooks, Scripts): 18-25K pro Action
   - Reine SKILL.md/Dokumentation Text-Edits: 8-15K pro Action
   - New Category "Reine Text-Edits" hinzugefügt für zukünftige Planung

2. **Konservative Schätzung ist korrekt:** Die Heuristik hat keinen Action abgelehnt, der dann nicht gepasst hätte → Sicherheitsmargin funktioniert

3. **Subagent-Context ist unabhängig:** Actions außerhalb des Repo (z.B. statusline.sh in ~/.claude/) zählen gegen globales Home-Budget, nicht gegen Projekt-Session-Budget

4. **Action-Decomposition zahlte sich aus:** Action 3 war ~1h statt 3-4h weil alles nur Text-Edits war. Das ist durch korrektes Task-Design (Acceptance Criteria früh definieren) möglich.

## Aktualisierte Faustregel (nach Kalibrierung)

| Deliverable-Typ | Geschätzter Token-Verbrauch |
|-----------------|---------------------------|
| Neues Bash-Script mit Fehlerbehandlung | 20-25K |
| Prompt-based Hook (settings.json) | 10-15K |
| Text-Edits zu existierendem SKILL.md (<500 Zeilen) | 8-12K |
| Template-Update (additiv) | 10-15K |
| Recherche + Design (API, Architektur) | 20-40K |
| Code Review | 15-25K |
| End-to-End Test | 15-30K |

**Neue Regel: Task-Designer sollte bei Action-Definition Deliverable-Typen auflisten, damit Orchestrator korrekt schätzen kann.**

## Regeln

1. **Konservativ schaetzen:** Lieber eine Action weniger pro Zyklus als eine halb-fertige
2. **Reserve einplanen:** Mindestens 15K fuer Cleanup (Commit + Task-Update + Handoff)
3. **Grenzfaelle:** Bei <20% verbleibend → User fragen statt automatisch entscheiden
4. **Parallelisierung:** Subagent-Actions zaehlen NICHT gegen das Main-Budget (eigener Context)
5. **Deliverable-Typ priorisieren:** Text-Edits sind billiger als Code. Task-Designer sollte BEFORE Action-Start kommunizieren: "nur SKILL.md Edits" vs. "neue Scripts"
6. **Action-Decomposition:** Wenn eine Action zu gross ist (>40K geschätzt), VOR Session-Start in kleinere Actions splitten
