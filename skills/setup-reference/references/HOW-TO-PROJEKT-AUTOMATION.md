# Session-Continuity Ecosystem für Claude Code

> **Framework für strukturiertes, session-übergreifendes Projektmanagement mit Claude.**

**Version:** 1.9 | **Stand:** 2026-02-17 | **Status:** ✅ Phase 1 Complete + Session-Refresh v2 + Handoff-Injection + Permission Optimization + Task-Glossar + Default-Verzeichnisstruktur + SATE

---

## Was ist das?

Ein **Skill-Ökosystem** für Claude Code, das Multi-Session-Projekte handhabbar macht.

**Kernproblem:** Bei komplexen Projekten wächst die Dokumentation unkontrolliert (>40K Zeichen). Claude verliert den Fokus, wiederholt sich, vergisst Kontext.

**Lösung:** Strukturierte Dokumentation + automatisierte Workflows + Token-Management.

---

## Für wen?

| Zielgruppe | Nutzen |
|------------|--------|
| **Power-User** | Strukturiertes Projektmanagement über Sessions hinweg |
| **Teams** | Konsistente Dokumentationsstandards |
| **Neugierige** | Inspiration für eigene Claude-Workflows |

**Voraussetzung:** Claude Code CLI installiert, Grundverständnis von Markdown.

---

## Die Skills

### Projekt-Management

| Skill | Zweck | Trigger |
|-------|-------|---------|
| `/project-init` | Neues Projekt aufsetzen | Projektstart |
| `/run-next-tasks` | Nächste Tasks identifizieren | Session-Start |
| `/prioritize-tasks` | Tasks nach Priorität sortieren | Session-Start (optional) |
| `/session-refresh` | Docs aktualisieren + komprimieren | Session-Ende, Token >65% |
| `/project-doc-restructure` | PROJEKT.md optimieren | Via session-refresh |
| `/task-orchestrator` | Task-Ausführung koordinieren | "Arbeite TASK-XXX ab" |

### Git/GitHub Operations

| Skill | Zweck | Trigger |
|-------|-------|---------|
| `/github-init` | PWD mit GitHub-Repo verknüpfen | Einmalig pro Projekt |
| `/github-push` | Commit + Push mit Sync-Message | Manuell, Session-Ende |
| `/github-status` | Sync-Status anzeigen | Jederzeit |
| `/obsidian-sync` | Vault pushen (von jedem PWD) | Manuell |

**Installation:** Skills liegen unter `~/.claude/skills/`

---

## Quick Start (5 Minuten)

### Neues Projekt

```bash
cd /dein/projekt
/project-init
```

**Ergebnis:**
```
projekt/
├── CLAUDE.md              # Architektur + Workflow (immer im Root)
├── 00_KONTEXT/            # Projektbriefing, Anforderungen, Scope
├── 10_INPUT/              # Rohdaten, Zulieferungen, Referenzmaterial
│   ├── Rohdaten/
│   ├── Zulieferungen/
│   ├── Referenzmaterial/
│   └── Vorlagen/
├── 20_OUTPUT/             # Deliverables, Reports, Exports
│   ├── Deliverables/
│   ├── Praesentationen/
│   ├── Reports/
│   └── Exports/
├── 90_DOCS/               # Projektsteuerung (Default seit v1.8)
│   ├── PROJEKT.md
│   ├── tasks/
│   │   └── TASK-001-setup.md
│   ├── handoffs/
│   ├── phases/
│   └── DECISION-LOG.md
└── 99_ARCHIV/             # Abgeschlossenes, alte Versionen
    ├── alte-versionen/
    ├── abgeschlossen/
    └── referenz/
```

**Hinweis:** `--docs-path` ist konfigurierbar. Default ist `90_DOCS`, bestehende Projekte mit `docs/` funktionieren weiterhin (Auto-Detection in Hooks).

### Session-Workflow

```
START:  Handoff wird automatisch injiziert (SessionStart Hook)
        → Direkt arbeiten oder /run-next-tasks für Details
ARBEIT: Task bearbeiten → Status in PROJEKT.md updaten
ENDE:   /session-refresh (wenn Token >65%)
```

**Neu ab v1.5:** Der SessionStart Hook `session-handoff-loader.sh` lädt automatisch das letzte Session-Handoff + Health-Check Status. CLAUDE.md und PROJEKT.md müssen nur noch bei Bedarf manuell gelesen werden.

### Token-Budget-Ampel

| Budget | Aktion |
|--------|--------|
| < 65% | Normal arbeiten |
| 65-85% | `/session-refresh` |
| > 85% | Session beenden |

---

## Bestehende Projekte upgraden

### Was `/project-init` bei existierenden Dateien macht

| Datei | Verhalten |
|-------|-----------|
| CLAUDE.md existiert | ⏭️ Skip |
| PROJEKT.md existiert | ⏭️ Skip |
| Task-Files existieren | ⏭️ Skip |
| Workflow-Block fehlt | ✅ Wird injiziert |

**Fazit:** Der Skill ist nicht-destruktiv. Sicher auszuführen, aber bringt bei existierenden Projekten wenig.

### Manuelles Upgrade (falls gewünscht)

**1. Workflow-Block prüfen:**
```bash
grep -q "Session-Continuous Workflow" CLAUDE.md && echo "✅ Vorhanden" || echo "❌ Fehlt"
```

**2. Falls fehlt - nachrüsten:**
```bash
cat ~/.claude/skills/project-init/assets/workflow-block.txt >> CLAUDE.md
```

**3. Für neue Tasks - aktuelles Template verwenden:**
```bash
cat ~/.claude/skills/project-init/assets/task-md-template.txt
```

### Wann kein Upgrade nötig ist

- Projekt funktioniert → Keine Aktion
- Skills sind rückwärtskompatibel
- Neue Features sind optional

---

## Architektur

### 3-Tier-Modell

```
CLAUDE.md (Architektur) ← immer im Projekt-Root
    │  - Technologie-Entscheidungen
    │  - Workflow-Definition
    │  - < 8K Zeichen
    ▼
<docs-path>/PROJEKT.md (Aktive Tasks) ← Default: 90_DOCS/
    │  - Task-Tabelle (7-Column)
    │  - Phase-Definition
    │  - < 8K Zeichen (Goldilocks Zone)
    ▼
<docs-path>/tasks/ (Audit Trail) ← Default: 90_DOCS/tasks/
    - TASK-NNN-name.md (Details)
    - TASK-NNN/execution-logs/
    - TASK-NNN/artifacts/
```

**Docs-Path:** Neue Projekte verwenden `90_DOCS/` (Default seit v1.8). Bestehende Projekte mit `docs/` funktionieren weiterhin - Hooks erkennen den Pfad automatisch (Auto-Detection).

### 7-Column Task Schema

```markdown
| UUID | Task | Status | Dependencies | Effort | Deliverable | Task-File |
|------|------|--------|--------------|--------|-------------|-----------|
| **TASK-001** | Setup | ✅ completed | None | 1h | docs | [Details](tasks/TASK-001.md) |
| **TASK-002** | Feature | 📋 pending | TASK-001 | 2h | component | [Details](tasks/TASK-002.md) |
```

**Status-Icons:** 📋 pending | ⏳ in_progress | 📘 ongoing | ✅ completed | 🚫 blocked | ❌ cancelled

---

## Skill-Referenz

### `/project-init`

**Zweck:** Session-Continuous Infrastruktur aufsetzen.

**Parameter:**
- `--docs-path PATH` - Alternativer Docs-Ordner (Default: `90_DOCS`)
- `--from-claude-md PATH` - Existierende CLAUDE.md kopieren

**Beispiel:**
```bash
/project-init --docs-path 90_DOCS
```

---

### `/run-next-tasks`

**Zweck:** Tasks mit erfüllten Dependencies identifizieren.

**Was passiert:**
1. Parst PROJEKT.md Task-Tabelle
2. Prüft Dependencies (sind Voraussetzungen ✅?)
3. Listet Ready vs. Blocked Tasks

**Beispiel-Output:**
```
Ready Tasks:
├─ TASK-003: Ready (TASK-002 completed)
└─ TASK-005: Blocked (waiting TASK-004)
```

---

### `/prioritize-tasks`

**Zweck:** Tasks analysieren und nach Priorität sortieren.

**Scoring-Faktoren:**
| Faktor | Gewicht | Logik |
|--------|---------|-------|
| Effort | 3x | Kleine Tasks (≤2h) höher |
| Dependencies | 1x | Weniger = flexibler |
| Unblocks | 0.5x | Freischaltende Tasks wichtiger |
| Known Issues | -2x | Betroffene Tasks niedriger |

**Was passiert:**
1. Analysiert Task-Tabelle + Known Issues
2. Berechnet Priority-Score pro Task
3. Zeigt kritischen Pfad (Tasks die andere freischalten)
4. **Fragt:** "Soll PROJEKT.md umsortiert werden?"
5. Bei "Ja": Sortiert Task-Tabelle automatisch

**Beispiel-Output:**
```
🚀 Empfohlene Reihenfolge:
| Rang | Task | Score | Begründung |
|------|------|-------|------------|
| 1 | TASK-024 | 2.50 | Quick win (2h), keine Dependencies |
| 2 | TASK-023 | 1.75 | Keine Dependencies |
```

**Wann nutzen:**
- Bei ≥3 pending Tasks ohne klare Präferenz
- Nach längerer Pause (Orientierung)
- Wenn Known Issues die Planung beeinflussen

---

### `/session-refresh`

**Zweck:** Session-State konsolidieren + Token-Budget freigeben.

**Wann nutzen:**
- Token >65%
- Vor Session-Ende
- Nach Phase-Abschluss

**v2 Workflow (ab TASK-035):**
1. **Context-Check:** Prüft ob CLAUDE.md/PROJEKT.md bereits im Kontext sind (vermeidet redundante Reads)
2. **CLAUDE.md Update:** Nur Änderungen, die Session-relevant sind
3. **PROJEKT.md Update:** Task-Status + Executive Summary
4. **Conditional Restructure:** `/project-doc-restructure` NUR wenn `NEEDS_RESTRUCTURE=true` (Health-Check)
5. **Compact Output:** 3-5 Zeilen Summary statt 15-20 Zeilen Tabelle
6. **Optional:** Session-Handoff erstellen (User-Prompt)

**Timing:** ~5-10 Minuten (v1: ~15-20 Minuten) | **Token-Einsparung:** ~60-76% gegenüber v1

---

### `/project-doc-restructure`

**Zweck:** PROJEKT.md in Inverted Pyramid transformieren.

**Struktur nach Restructuring:**
```
LAYER 1: ACTION
├─ Executive Summary
└─ Immediate Next Actions

LAYER 2: CONTEXT
├─ Phase Status
└─ Active Tasks

LAYER 3: ARCHIVE (collapsed)
├─ Completed Phases
└─ Planned Phases
```

**Wichtig:** Bewahrt 7-Column Schema (task-scheduler kompatibel).

---

### `/task-orchestrator`

**Zweck:** Strukturierte Task-Ausführung mit Background Delegation.

**Trigger-Patterns:**
- "Arbeite TASK-XXX ab"
- "Führe TASK-XXX aus"
- "Starte TASK-XXX"

**5-Phasen-Workflow:**
1. **Context Load:** Task-File lesen
2. **Planning:** Execution-Plan erstellen
3. **Execution:** Actions ausführen (parallel wenn möglich)
4. **DoD Check:** Acceptance Criteria prüfen
5. **Update:** PROJEKT.md Status aktualisieren

#### SATE: Session-Autonomous Task Execution

**Ab v1.9** arbeitet der task-orchestrator mit SATE — einem System fuer autonome Task-Ausfuehrung mit garantierter Action-Integritaet.

**Kernregel:** 1 Task pro Zyklus. Mehrere Actions pro Zyklus. Keine Action ueber Zyklus-Grenzen (`/clear` ist die bevorzugte Grenze).

**Die 6 Mechanismen:**

| # | Mechanismus | Was es tut |
|---|------------|-----------|
| 1 | **Decision Frontloading** | Alle strategischen Entscheidungen (Pre-Flight Decisions im Task-File) werden VOR der Ausfuehrung geklaert. Keine Unterbrechungen waehrend der Arbeit. |
| 2 | **Action Budget Envelopes** | Pro Action wird ein Token-Budget geschaetzt. Session Plan zeigt vorab, welche Actions in den aktuellen Zyklus passen. |
| 3 | **Checkpoint-System** | Automatischer Git-Commit + Audit Trail nach jeder abgeschlossenen Action (`scripts/checkpoint.sh`). Commit-Format: `feat: TASK-XXX Action N/M - Name`. |
| 4 | **Cycle-Boundary Protection** | PreCompact Guard warnt bei uncommitted Changes vor Auto-Compact. Stop Evaluator prueft ob die aktuelle Action sauber abgeschlossen ist. |
| 5 | **Cross-Cycle Continuation** | Bei Fortsetzung nach `/clear`: Erkennt erledigte Actions aus der Action Tracking Tabelle, setzt bei der richtigen Stelle fort, validiert per Git-Log. |
| 6 | **Autonome Session-Steuerung** | Budget-Check zwischen Actions. Bei erschoepftem Budget → automatischer Zyklus-Abschluss mit `/session-refresh` Empfehlung. |

**Erweiterter Workflow mit SATE:**

```
1. Task laden → Pre-Flight Decisions beantworten (einmalig)
2. Cross-Cycle Check → Erledigte Actions ueberspringen
3. Session Plan → Budget Envelopes berechnen, User bestaetigt
4. Ausfuehrung → Action → Checkpoint → Budget-Check → naechste Action
5. Abschluss → DoD pruefen → /session-refresh → /clear
```

**Task-File Erweiterungen fuer SATE:**

Das Task-Template unterstuetzt zwei optionale Sections:

- **Pre-Flight Decisions:** Strategische Fragen mit Optionen (D1, D2, ...). Werden in Phase 1 per AskUserQuestion abgefragt und persistent im Task-File gespeichert.
- **Action Tracking:** Tabelle mit Spalten `# | Action | Status | Zyklus | Commit | Effort`. Wird nach jeder Action via Checkpoint aktualisiert.

**Mode-Hints in Implementation Steps:**

Actions koennen per Backtick-Tag am Zeilenende annotiert werden:
- `` `[main]` `` — Ausfuehrung in der Main-Session (sequentiell)
- `` `[subagent:haiku]` `` — Delegation an Subagent mit Haiku-Modell
- `` `[subagent:sonnet]` `` — Delegation an Subagent mit Sonnet-Modell
- Ohne Tag → Heuristik entscheidet (unabhaengig = Subagent, abhaengig = Main)

**Budget-Heuristik (konservative Defaults):**

| Action-Typ | Token-Schaetzung |
|------------|-----------------|
| Dokumentation schreiben | 15K-25K |
| Code generieren (klein) | 20K-35K |
| Code generieren (mittel) | 35K-60K |
| Code Review / Analyse | 15K-25K |
| Template-Update (additiv) | 10K-15K |
| Git Operations | 5K-10K |

Reserve fuer Cleanup (Commit + Task-Update + Session-Refresh): **15K**.

**SATE-Invarianten (7 Regeln):**

1. Keine Action ueber Zyklus-Grenzen
2. 1 Task pro Zyklus
3. Decision Frontloading vor Ausfuehrung
4. Checkpoint nach jeder Action
5. Budget vor Action pruefen
6. Action Tracking Tabelle = SSOT
7. Session-Refresh bei Zyklus-Ende

**Referenz:** Vollstaendige technische Details in `~/.claude/skills/task-orchestrator/SKILL.md` (Phase 1-5 + Regeln-Section).

---

### `/github-init`

**Zweck:** Working Directory mit GitHub-Repo verknüpfen, Config erstellen.

**Voraussetzungen:**
- `gh` CLI installiert + authentifiziert (`gh auth status`)
- Git-Repository initialisiert (`git init`)
- GitHub-Remote vorhanden (`git remote -v`)

**Was passiert:**
1. Prüft Prerequisites (gh CLI, Auth)
2. Fragt: Projekt oder Vault?
3. Prüft GitHub-Remote (falls fehlend: Anleitung anzeigen)
4. Erstellt `.claude/github.json` (Pro-Projekt Config)
5. Aktualisiert `.gitignore`

**Parameter:**
- `--vault` - Direkt als Vault konfigurieren (überspringt Typ-Frage)

**Beispiel:**
```bash
cd /dein/projekt
/github-init
# → Erstellt: .claude/github.json
# → Aktualisiert: .gitignore
```

---

### `/github-push`

**Zweck:** Alle Änderungen committen und zum GitHub-Repo pushen.

**Commit-Message-Format:**
```
Sync YYYY-MM-DD-NN   (Default, Index pro Tag)
Custom message        (via --message)
```

**Was passiert:**
1. Prüft Config + Prerequisites
2. Zeigt Änderungen + fragt nach Bestätigung
3. `git add -A` → `git commit` → `git push`
4. Bestätigung mit Repo-URL

**Parameter:**
- `--message "Text"` - Eigene Commit-Message statt Sync-Default

**Beispiel:**
```bash
/github-push
# → "Sync 2026-02-06-01" gepusht zu github.com/user/repo

/github-push --message "feat: Neue Funktion"
# → Custom Message gepusht
```

---

### `/github-status`

**Zweck:** Aktuellen Sync-Status anzeigen.

**Was wird angezeigt:**
- Repo-URL + Typ (project/vault)
- Letzter Commit (Hash, Message, Zeitpunkt)
- Pending Changes (noch nicht committed)
- Sync-Status (Commits nicht gepusht)

**Beispiel:**
```bash
/github-status
# → Repo: github.com/user/repo
# → Letzter Commit: abc1234 Sync 2026-02-06-01 (vor 2h)
# → Pending Changes: 3 Dateien
# → Sync-Status: ✅ Synchron
```

---

### `/obsidian-sync`

**Zweck:** Obsidian Vault zu GitHub pushen – funktioniert von **jedem Working Directory**.

**Voraussetzungen:**
- `OBSIDIAN_VAULT` via SessionStart Hook verfügbar (siehe Config-Architektur unten)
- Vault als Git-Repo initialisiert + GitHub-Remote vorhanden
- `/github-init --vault` im Vault-Verzeichnis einmalig ausgeführt

**Was passiert:**
1. Liest `OBSIDIAN_VAULT` Environment Variable (automatisch via Hook)
2. Prüft Config + Git-Repo im Vault-Verzeichnis
3. Zeigt Änderungen + fragt nach Bestätigung
4. `git add -A` → `git commit` (Sync-Message) → `git push`

**Parameter:**
- `--message "Text"` - Eigene Commit-Message statt Sync-Default

**Beispiel:**
```bash
# Von beliebigem PWD aus:
/obsidian-sync
# → "Sync 2026-02-06-01" gepusht zu github.com/user/vault
```

**Setup (einmalig):**
```bash
# 1. Vault-Pfad in secrets env.d ablegen (SessionStart Hook laedt automatisch)
echo 'OBSIDIAN_VAULT="/pfad/zum/vault"' >> ~/.config/secrets/env.d/vault.env
chmod 600 ~/.config/secrets/env.d/vault.env

# 2. Im Vault-Verzeichnis GitHub einrichten
cd /pfad/zum/vault
git init && gh repo create vault-name --private --source=. --push
/github-init --vault
```

---

### `/permission-audit`

**Zweck:** Tool-Call-Logs gegen Permission Allow/Deny-Regeln analysieren.

**Wann nutzen:**
- Nach einer Session prüfen, welche Tool-Calls nicht von Allow-Rules gedeckt waren
- Permission-Konfiguration optimieren (neue Allow-Rules identifizieren)
- Nach Permission-Änderungen verifizieren

**Parameter:**
- Ohne Parameter: Analysiert aktuellen Tag
- `YYYY-MM-DD` - Bestimmtes Datum analysieren

**Beispiel:**
```bash
/permission-audit
# → Zeigt: 3 Tool-Calls ohne Allow-Rule (Bash: npm install, ...)

/permission-audit 2026-02-10
# → Analysiert Log vom 10. Februar
```

---

## Projekt starten (Windows-Verknüpfung)

### Wrapper-Script: `~/start-claude.sh`

Startet Claude Code mit aufgelöstem Symlink-Pfad. Verhindert, dass Claude denselben Ordner als Primary UND Additional Working Directory registriert (Symlink vs. realer Pfad), was den `@` File-Picker stört.

**Warum nötig:** `~/claude_projs` ist ein Symlink → `/mnt/c/Development/Projects/Claude`. Ohne Auflösung sieht Claude zwei Pfade für denselben Ordner, was zu fehlerhafter `@`-Dateisuche führt (bekannter Bug [#14399](https://github.com/anthropics/claude-code/issues/14399), [#21587](https://github.com/anthropics/claude-code/issues/21587)).

**Script:**
```bash
~/start-claude.sh <project-name>
# Beispiel: ~/start-claude.sh projekt-automation-hub
```

**Windows-Verknüpfung (Ziel):**
```
powershell.exe -ExecutionPolicy Bypass -Command "Start-Process wt.exe -ArgumentList 'wsl.exe -d ubuntu -e bash -lic \"~/start-claude.sh projekt-automation-hub\"'"
```

**Was das Script macht:**
1. `cd ~/claude_projs/<project>` (kurzer Symlink-Pfad)
2. `cd "$(readlink -f .)"` (auflösen zum realen Pfad)
3. `exec claude` (starten vom kanonischen Pfad)

---

## Config-Architektur

### 4-Layer Modell (ADR-003)

```
Layer 1: SECRETS         → ~/.config/secrets/env.d/*.env (SOPS+age verschluesselt)
Layer 2: GLOBAL SKILLS   → ~/.claude/skills/, ~/.claude/hooks/
Layer 3: PROJECT CONFIG  → <PWD>/.claude/, .mcp.json, CLAUDE.md
Layer 4: SESSION         → CLAUDE_ENV_FILE (via SessionStart Hook)
```

**SessionStart Hooks (Reihenfolge):**

| Hook | Funktion | Timeout |
|------|----------|---------|
| `session-env-loader.sh` | Secrets aus env.d (SOPS-entschluesselt) → CLAUDE_ENV_FILE | 10s |
| `session-handoff-loader.sh` | Letztes Handoff + Health-Check → additionalContext | 15s |
| `session-start-scheduler.sh` | Task-Scheduler auto-trigger (Ready Tasks erkennen) | 10s |

**Wie Env-Vars in die Session kommen:**
1. Secrets liegen in `~/.config/secrets/env.d/*.env` (SOPS+age verschluesselt)
2. SessionStart Hook (`session-env-loader.sh`) setzt `SOPS_AGE_KEY_FILE` und entschluesselt via `sops -d`
3. Hook schreibt `export KEY=VALUE` in `$CLAUDE_ENV_FILE` (Fallback auf Klartext falls sops fehlschlaegt)
4. Alle Bash-Commands der Session sehen die Variablen

**Wie Handoff-Injection funktioniert:**
1. `session-handoff-loader.sh` erkennt automatisch den Docs-Pfad (`90_DOCS/handoffs/` oder `docs/handoffs/`)
2. Neuestes `SESSION-HANDOFF-*.md` wird gelesen (max 2000 Zeichen, danach Truncation)
3. Optional: Health-Check Status wird angehängt (Tasks, Warnings, Ready Tasks)
4. Output als `additionalContext` → Claude hat sofort Session-Kontext

**Aktuell geladene Variablen:** OBSIDIAN_VAULT, OBSIDIAN_API_KEY, OBSIDIAN_HOST, OBSIDIAN_PORT, N8N_API_KEY, N8N_BASE_URL

**Referenzen:**
- ADR: `projekt-automation-hub/docs/decisions/ADR-003-config-architecture.md`
- Kurzreferenz: `projekt-automation-hub/docs/CONFIG-ARCHITECTURE.md`
- Blueprint: `~/.claude/skills/secrets-blueprint/BLUEPRINT.md` (Sektion 14)

### Secrets verwalten (SOPS + age)

Seit TASK-047 (2026-02-23) sind alle Secrets at rest mit **SOPS + age** verschluesselt. Die Entschluesselung erfolgt nur zur Laufzeit (in-memory).

**Dateien:**
```
~/.config/secrets/
├── age-key.txt          # age Private Key (chmod 600) - Backup in 1Password!
├── .sops.yaml           # SOPS Config (creation rules)
└── env.d/
    ├── vault.env        # SOPS-verschluesselt
    ├── n8n.env          # SOPS-verschluesselt
    └── obsidian.env     # SOPS-verschluesselt
```

**Alltags-Befehle:**

| Aktion | Befehl |
|--------|--------|
| Secret editieren | `SOPS_AGE_KEY_FILE=~/.config/secrets/age-key.txt sops edit ~/.config/secrets/env.d/vault.env` |
| Klartext anzeigen | `SOPS_AGE_KEY_FILE=~/.config/secrets/age-key.txt sops -d ~/.config/secrets/env.d/vault.env` |
| Neues Profil verschluesseln | `cd ~/.config/secrets && sops --encrypt --in-place --config .sops.yaml env.d/neues.env` |
| Verifizieren (Terminal) | `secret-run vault -- env \| grep OBSIDIAN` |

**Wie SOPS in die Toolchain integriert ist:**

| Tool | SOPS-Integration |
|------|-----------------|
| `session-env-loader.sh` | `sops -d` mit `SOPS_AGE_KEY_FILE` hardcoded, Fallback auf Klartext |
| `secret-run` | `load_env()` versucht zuerst `sops -d`, dann Klartext-Parse |
| MCP-Server | Nutzen `${VAR}` Substitution aus Session-Environment (kein eigenes Decrypt) |

**Neues Secret-Profil hinzufuegen:**
1. Klartext `.env` erstellen (`KEY=VALUE` Format, kein `export`)
2. `chmod 600` setzen
3. Mit SOPS verschluesseln (siehe Befehle oben)
4. Naechste Claude-Session laedt es automatisch

**Troubleshooting:**
- `sops -d` fehlschlaegt? → `SOPS_AGE_KEY_FILE` pruefen: `ls -la ~/.config/secrets/age-key.txt`
- Datei nicht verschluesselt? → `head -1 datei.env` pruefen (SOPS-Dateien zeigen JSON/YAML Metadaten)
- Vollstaendiges Troubleshooting: BLUEPRINT.md Sektion 10

---

## Utilities

### Health-Check Script

```bash
~/.claude/skills/session-refresh/bin/projekt-health-check.sh docs/PROJEKT.md
```

**Output:**
```
## PROJEKT Health-Check
📊 Summary: 7 Tasks | 0 Critical | 0 Warnings
✅ Ready Tasks: TASK-001 TASK-002 TASK-004
NEEDS_RESTRUCTURE=false
```

**NEEDS_RESTRUCTURE Flag:** Wird `true` wenn: Datei >10K Zeichen, >5 aktive Tasks, oder kritische Issues. Genutzt von `/session-refresh` v2 für Conditional Restructure.

### Phasen-Migration Script

```bash
python3 ~/.claude/skills/project-doc-restructure/scripts/migrate_completed_phases.py \
    docs/PROJEKT.md docs/phases/
```

Verschiebt abgeschlossene Phasen in Archiv-Ordner.

---

## Was wurde erreicht?

### Phase 1: Foundation (✅ Complete)

**21 Tasks abgeschlossen**, davon:

| Kategorie | Tasks | Kern-Ergebnis |
|-----------|-------|---------------|
| **Infrastruktur** | TASK-001, 002 | Projekt-Setup, Template-Sync |
| **Größen-Optimierung** | TASK-003, 016, 017 | Phasen-Auslagerung, <8K Ziel |
| **Skill-Entwicklung** | TASK-020, 022 | Health-Check, Task-Orchestrator |
| **Standards** | TASK-007, 010, 012 | Template SSOT, Output-Handling |
| **Dokumentation** | TASK-008, 014, 021 | Session-Handoff, Backup, HOW-TO |
| **Testing** | TASK-005 | Headless E2E Test |

### Architektur-Entscheidungen

| Decision | Rationale |
|----------|-----------|
| 7-Column Task Schema | Parsbar für task-scheduler |
| Inverted Pyramid | Minimales Time-to-Orientation |
| Goldilocks Zone (<8K) | Claude behält Fokus |
| Template SSOT im Skill | Verhindert Template-Drift |
| Session-Handoff (Mensch-first) | Narrative Übergabe, nicht maschinenlesbar |

---

## Orientierungswerte

| Metrik | Ziel | Bedeutung |
|--------|------|-----------|
| **Dokumentgröße** | < 8K Zeichen | CLAUDE.md + PROJEKT.md jeweils |
| **TTO** | < 1 Minute | Zeit bis "verstanden, was zu tun ist" |
| **Health-Score** | ≥ 75 | Ausgabe von Health-Check Script |

**Hinweis:** TTO, SCI, CLS, DocDebt sind Orientierungswerte, keine automatisch messbaren KPIs.

---

## Template-Locations (SSOT)

| Template | Pfad | Nutzer |
|----------|------|--------|
| Task-Template | `~/.claude/skills/project-init/assets/task-md-template.txt` | project-init |
| PROJEKT.md | `~/.claude/skills/project-init/assets/projekt-md-template.txt` | project-init |
| Verzeichnisstruktur | `~/.claude/skills/project-init/assets/directory-template.txt` | project-init |
| Session-Handoff (Init) | `~/.claude/skills/project-init/assets/session-handoff-template.txt` | project-init |
| Session-Handoff (Refresh) | `~/.claude/skills/session-refresh/assets/session-handoff-template.md` | session-refresh |
| Phase-Template | `~/.claude/skills/project-init/assets/phase-template.txt` | project-init |

---

## Glossar: Task-Begriffe & Trigger-Disambiguierung

In Claude Code existieren **drei unabhängige Systeme**, die alle das Wort "Task" verwenden. Dieses Glossar verhindert Fehlinterpretationen.

### Begriffstrennung

| Begriff | System | Bedeutung | Beispiel |
|---------|--------|-----------|----------|
| **TASK-XXX** | Unser Ecosystem | Projekt-Aufgabe in PROJEKT.md (7-Column Schema) | TASK-033 |
| **Task (TUI)** | Claude Code Tasks API | Checkbox-Item in der Terminal-Anzeige (`Ctrl+T`) | `TaskCreate`, `TaskUpdate` |
| **Subagent** | Claude Code Task Tool | Hintergrund-Prozess via `Task` tool (`run_in_background`) | Explore-Agent, Plan-Agent |

### Trigger-Zuordnung: Was löst was aus?

| User-Formulierung | Ziel-System | Tool/Skill |
|-------------------|-------------|------------|
| "Arbeite **TASK-033** ab" | Unser Ecosystem | `/task-orchestrator` |
| "Führe **TASK-XXX** aus" | Unser Ecosystem | `/task-orchestrator` |
| "Welche Tasks sind ready?" | Unser Ecosystem | `/run-next-tasks` |
| "Priorisiere die Tasks" | Unser Ecosystem | `/prioritize-tasks` |
| "Update PROJEKT.md Status" | Unser Ecosystem | Manuell (Edit PROJEKT.md) |
| "Erstelle ein Task-File" | Unser Ecosystem | Write → `docs/tasks/TASK-NNN-name.md` |
| "Starte einen Subagent für X" | Subagent-Launcher | `Task` tool (run_in_background) |
| "Recherchiere X im Hintergrund" | Subagent-Launcher | `Task` tool (Explore/general-purpose) |

### Tasks API (TUI) ist deaktiviert

Die Claude Code Tasks API (`TaskCreate`, `TaskUpdate`, `TaskList`, `TaskGet`, `TodoWrite`) ist **global via Deny-Rules blockiert** (`~/.claude/settings.json`). Grund: Claude bevorzugt Built-in-Tools über Custom Workflows, was zu SSOT-Verletzungen führt (Tasks werden in der TUI statt in PROJEKT.md erstellt).

**Aktive Architektur (ohne Tasks API):**
```
PROJEKT.md (TASK-033)     ← Source of Truth (persistent, Git-tracked)
    ↓ liest
/task-orchestrator        ← Execution Engine (5-Phasen-Workflow)
    ↓ delegiert via
Task tool (Subagent)      ← Background Worker (run_in_background)
```

**Falls Tasks API reaktiviert werden soll:** Deny-Rules für `TaskCreate`, `TaskUpdate`, `TaskList`, `TaskGet`, `TodoWrite` aus `~/.claude/settings.json` entfernen.

### Begriffe innerhalb einer TASK-Ausführung

| Begriff | Kontext | Bedeutung |
|---------|---------|-----------|
| **Action** | task-orchestrator Phase 2 | Einzelner Arbeitsschritt innerhalb einer TASK |
| **Deliverable** | PROJEKT.md 7-Column | Ergebnis einer TASK (z.B. "Plugin-Bundle") |
| **Acceptance Criteria** | Task-File | Checkboxen für Definition of Done |
| **Subagent** | task-orchestrator Phase 4 | Delegierter Hintergrund-Prozess für unabhängige Actions |

### Verwechslungsfallen vermeiden

**NICHT verwenden:**
- ~~"Erstelle eine Task-Liste"~~ → könnte `TaskCreate` (TUI) triggern
- ~~"Track den Fortschritt"~~ → könnte `TaskUpdate` (TUI) triggern
- ~~"Background Task starten"~~ → Mehrdeutig (Subagent ODER Tasks API)

**STATTDESSEN verwenden:**
- "Zeige ready Tasks" → `/run-next-tasks`
- "Arbeite TASK-033 ab" → `/task-orchestrator`
- "Starte einen Subagent für Recherche" → `Task` tool
- "Update den TASK-Status in PROJEKT.md" → Manueller Edit

---

## Bekannte Limitierungen

1. **Metriken nicht automatisiert:** TTO, SCI, CLS sind subjektive Einschätzungen
2. **Headless Mode erfordert Permission-Skip:** `--dangerously-skip-permissions` für Automation
3. **Token-Budget nicht exakt:** Schwellwerte (65%, 85%) sind Heuristiken

---

## Weiterentwicklung

Das Ecosystem ist **stabil und produktiv nutzbar**. Mögliche Erweiterungen:

- [ ] CI/CD-Integration (Pre-commit Hook für Schema-Validierung)
- [ ] Template-Sync-Checker (automatische Drift-Detection)
- [ ] Export als Plugin-Bundle für Marketplace (TASK-033)
- [x] ~~Permission Optimization~~ → Global Allowlist (TASK-034)
- [x] ~~Session-Refresh Token-Optimierung~~ → v2 mit ~60-76% Einsparung (TASK-035)
- [x] ~~Session-Start Handoff-Injection~~ → Automatischer Kontext-Load (TASK-036)
- [x] ~~Default-Verzeichnisstruktur~~ → 5-Ordner-Template + Auto-Detection (TASK-040)

---

## Quick Commands

| Aktion | Command |
|--------|---------|
| Neues Projekt | `/project-init` |
| Ready Tasks | `/run-next-tasks` |
| Tasks priorisieren | `/prioritize-tasks` |
| Session Ende | `/session-refresh` |
| Task ausführen | "Arbeite TASK-XXX ab" |
| Health prüfen | `projekt-health-check.sh docs/PROJEKT.md` |
| **GitHub: Repo verknüpfen** | `/github-init` |
| **GitHub: Pushen** | `/github-push` |
| **GitHub: Status** | `/github-status` |
| **Vault: Sync** | `/obsidian-sync` |

---

*Framework entwickelt im projekt-automation-hub (2026-01-20 bis 2026-02-16)*
