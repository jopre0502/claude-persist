# TASK-000: Onboarding — Claude Code + Knowledge Hub Setup

**UUID:** TASK-000
**Status:** 📋 pending
**Created:** 2026-03-02
**Updated:** 2026-03-02
**Effort:** 2h
**Dependencies:** None

---

## Objective

Dieses Tutorial fuehrt Sie durch die komplette Einrichtung von Claude Code und dem Knowledge Hub. Am Ende koennen Sie eigenstaendig Projekte aufsetzen, Session-Continuity nutzen und sich mit dem `my-setup-guide` Agent selbst helfen.

> **Hinweis:** Dieser Task wird automatisch bei `/project-init` angeboten, wenn das Knowledge Hub frisch installiert wurde. Falls Sie ihn ueberspringen, wird er auf `completed` gesetzt — Sie koennen ihn jederzeit manuell nachholen.

---

## Artifacts

| Artifact | Zweck |
|----------|-------|
| [Cheatsheet](TASK-000/artifacts/cheatsheet.md) | 1-Seiter zum Ausdrucken — Wichtigste Befehle + Workflow |
| [First-Steps-Guide](TASK-000/artifacts/first-steps-guide.md) | Companion — Kosten, Accounts, Troubleshooting, Trainer-Notizen |

---

## Actions

### Phase 1: Prerequisites

#### Action A1: System-Check + PowerShell 7

**Schritte:**
1. Windows-Version pruefen: `Win + R` → `winver` → mind. Win 10 22H2 oder Win 11
2. PowerShell 7 installieren:
   ```powershell
   winget install Microsoft.PowerShell
   ```
3. Pruefen:
   ```powershell
   pwsh --version
   ```

**DoD:**
- [ ] `pwsh --version` → 7.x.x

---

#### Action A2: Node.js + Git

**Schritte:**
1. Installieren:
   ```powershell
   winget install OpenJS.NodeJS.LTS
   winget install Git.Git
   ```
2. **Neues Terminal oeffnen** (PATH wird erst dann geladen)
3. Pruefen:
   ```powershell
   node --version   # v20+ oder v22+
   git --version    # 2.x.x
   ```

**DoD:**
- [ ] `node --version` → v20+ oder v22+
- [ ] `git --version` → 2.x.x

---

#### Action A3: VS Code + Terminal-Setup

**Schritte:**
1. Installieren:
   ```powershell
   winget install Microsoft.VisualStudioCode
   ```
2. VS Code oeffnen → Terminal: `Ctrl + Backtick`
3. Default-Terminal setzen: Dropdown → "Select Default Profile" → **"PowerShell"** (nicht "Windows PowerShell")
4. Pruefen:
   ```powershell
   $PSVersionTable.PSVersion   # Major = 7
   ```

**DoD:**
- [ ] VS Code Terminal zeigt PowerShell 7

---

#### Action A4: Claude Code + Authentifizierung

**Voraussetzung:** Bezahlter Anthropic-Account (Pro $20/Mo, Max $100/Mo, oder Team $30/User/Mo)

**Schritte:**
1. Installieren:
   ```powershell
   npm install -g @anthropic-ai/claude-code
   ```
2. Starten:
   ```powershell
   mkdir ~/Projekte && cd ~/Projekte
   claude
   ```
3. Auth: "Log in with Anthropic" → Browser → Einloggen → Bestaetigen
4. Smoke Test:
   ```
   Sage "Hallo" auf Deutsch und nenne dein Modell.
   ```
5. Beenden: `/exit`

**DoD:**
- [ ] `claude --version` → Versionsnummer
- [ ] Claude antwortet auf Deutsch
- [ ] Auth funktioniert

---

### Phase 2: Knowledge Hub

#### Action A5: Repository klonen

**Schritte:**
1. Bestehendes pruefen:
   ```powershell
   ls ~/.claude/ 2>$null
   ```
2. Falls vorhanden — Backup:
   ```powershell
   cp -r ~/.claude/ ~/claude-backup-$(Get-Date -Format "yyyy-MM-dd")
   ```
3. Klonen:
   ```powershell
   git clone https://github.com/jopre0502/claude-persist.git ~/.claude/
   ```
4. Pruefen:
   ```powershell
   ls ~/.claude/skills/
   ```

**DoD:**
- [ ] `~/.claude/skills/` existiert mit Unterordnern
- [ ] `~/.claude/CLAUDE.md` existiert
- [ ] `~/.claude/settings.json` existiert

---

#### Action A6: CLAUDE.md personalisieren

**Schritte:**
1. Oeffnen: `code ~/.claude/CLAUDE.md`
2. Sprache bestaetigen (Deutsch als Default)
3. Eigene Regeln ergaenzen:
   ```markdown
   ## Meine Praeferenzen
   - [Du/Sie]-Form
   - Erklaere technische Begriffe einfach
   - Frage nach, bevor du grosse Aenderungen machst
   ```
4. Speichern

**DoD:**
- [ ] Mindestens eine persoenliche Regel ergaenzt
- [ ] Datei gespeichert

---

#### Action A7: Smoke Test — Skills + Agent

**Schritte:**
1. Claude starten: `claude` (in beliebigem Ordner)
2. Test 1 — Slash-Commands:
   ```
   /help
   ```
3. Test 2 — Skill-Erkennung:
   ```
   Welche Skills habe ich installiert?
   ```
4. Test 3 — Agent:
   ```
   Frage den my-setup-guide: Wo ist meine CLAUDE.md?
   ```
5. `/exit`

**DoD:**
- [ ] `/help` zeigt Commands
- [ ] Claude listet mindestens 5 Skills auf
- [ ] `my-setup-guide` antwortet korrekt

---

### Phase 3: Erstes Projekt + Session-Continuity

#### Action A8: Projekt mit /project-init

**Schritte:**
1. Ordner + Git:
   ```powershell
   mkdir ~/Projekte/mein-erstes-projekt
   cd ~/Projekte/mein-erstes-projekt
   git init
   ```
2. Claude starten + Skill ausfuehren:
   ```
   claude
   /project-init
   ```
3. Projektname + Beschreibung eingeben
4. Generierte Struktur pruefen:
   ```
   Zeige mir die Struktur, die du erstellt hast.
   ```
5. Eigenen Task hinzufuegen:
   ```
   Erstelle einen neuen Task TASK-002: "Startseite erstellen". Effort: 1h.
   ```

**DoD:**
- [ ] `CLAUDE.md` im Projektordner existiert
- [ ] `docs/PROJEKT.md` mit 7-Spalten-Tabelle existiert
- [ ] Mindestens 2 Tasks in der Tabelle

---

#### Action A9: Session-Continuity erleben

**Schritte:**
1. In laufender Session — Arbeit machen:
   ```
   Erstelle eine einfache index.html mit "Willkommen zu meinem Projekt".
   ```
2. Session beenden: `/exit`
3. **Pause** (mindestens 10 Sekunden)
4. Claude NEU starten (gleicher Ordner!): `claude`
5. **Der entscheidende Test:**
   ```
   Was haben wir in der letzten Session gemacht? Was ist der naechste Schritt?
   ```
6. Bonus:
   ```
   /run-next-tasks
   ```

**DoD:**
- [ ] Session beendet und neu gestartet
- [ ] Claude weiss, was vorher passiert ist
- [ ] `/run-next-tasks` zeigt korrekten Status

---

#### Action A10: Eigenstaendig navigieren

**Schritte:** 3 Pflichtfragen + 1 eigene Frage an `my-setup-guide`:

1. **"Welche Skills sind installiert und was macht jeder?"**
2. **"Was mache ich am Ende einer Session?"**
3. **"Wo finde ich meine settings.json und was steht drin?"**
4. **Eigene Frage** formulieren und stellen

**DoD:**
- [ ] 3 Pflichtfragen beantwortet
- [ ] Eigene Frage gestellt und Antwort erhalten
- [ ] Kann erklaeren: "Was ist der Unterschied zwischen CLAUDE.md und PROJEKT.md?"

---

## Acceptance Criteria

- [ ] Tools installiert (pwsh, node, git, VS Code, claude)
- [ ] Knowledge Hub in `~/.claude/` aktiv
- [ ] CLAUDE.md personalisiert
- [ ] Eigenes Projekt mit `/project-init` aufgesetzt
- [ ] Session-Continuity funktioniert (Neustart-Test)
- [ ] 3+ Slash-Commands eigenstaendig ausgefuehrt
- [ ] `my-setup-guide` eigenstaendig genutzt
- [ ] Kann erklaeren: CLAUDE.md vs. PROJEKT.md

---

## Task Completion — Abnahme

| # | Kriterium | Status |
|---|-----------|--------|
| 1 | Tools installiert (pwsh, node, git, VS Code, claude) | [ ] |
| 2 | Knowledge Hub in `~/.claude/` aktiv | [ ] |
| 3 | CLAUDE.md personalisiert | [ ] |
| 4 | Eigenes Projekt mit `/project-init` aufgesetzt | [ ] |
| 5 | Session-Continuity funktioniert (Neustart-Test) | [ ] |
| 6 | 3+ Slash-Commands eigenstaendig ausgefuehrt | [ ] |
| 7 | `my-setup-guide` eigenstaendig genutzt | [ ] |
| 8 | Kann erklaeren: CLAUDE.md vs. PROJEKT.md | [ ] |

**Alle Haken → Status: completed**

---

## Naechste Schritte nach TASK-000

| Prio | Was | Wie | Wann |
|------|-----|-----|------|
| 1 | Eigenes Projekt aufsetzen | `/project-init` im echten Projektordner | Diese Woche |
| 2 | Erste echte Session | Task anlegen, bearbeiten, sauber beenden | Diese Woche |
| 3 | CLAUDE.md verfeinern | Regeln nach 3–5 Sessions anpassen | Laufend |
| 4 | Skills erkunden | Jeden Tag einen neuen Command testen | Laufend |

---

## Audit Trail

| Datum | Aktion | Ergebnis |
|-------|--------|----------|
| | A1: System-Check | |
| | A2: Node.js + Git | |
| | A3: VS Code Setup | |
| | A4: Claude Code Install | |
| | A5: Knowledge Hub Clone | |
| | A6: CLAUDE.md Personalisierung | |
| | A7: Smoke Test Skills | |
| | A8: /project-init | |
| | A9: Session-Continuity Test | |
| | A10: Eigenstaendige Navigation | |
| | **Task Abnahme** | |
