---
description: "Committed und pusht Änderungen mit Sync-Message (Sync YYYY-MM-DD-NN)"
argument-hint: "[--message 'Custom message']"
allowed-tools: Bash, Read, AskUserQuestion
---

# GitHub-Push Command

Committed alle Änderungen und pusht zum konfigurierten GitHub-Repo.

**Arguments:** "$ARGUMENTS"

## Workflow

### Step 1: Prerequisites prüfen

```bash
source ~/.claude/skills/github-ops/lib/prerequisites.sh
check_prerequisites
```

**Bei Fehler:** Zeige Fehlermeldung und stoppe.

### Step 2: Config laden

```bash
source ~/.claude/skills/github-ops/lib/config-reader.sh
read_github_config
```

**Falls Config fehlt:**
```
❌ Keine GitHub-Config gefunden.
Bitte erst /github-init ausführen.
```

### Step 3: Änderungen prüfen (lokal + unpushed)

```bash
# WSL2/9P Fix: Git Stat-Cache refreshen (Timestamps unzuverlaessig auf 9P-Mounts)
git update-index --really-refresh 2>/dev/null || true
git status --short
git log @{u}..HEAD --oneline 2>/dev/null
```

Zwei Prüfungen:
1. **`git status --short`** → Uncommitted Änderungen im Working Directory
2. **`git log @{u}..HEAD`** → Lokale Commits die noch nicht gepusht wurden

**Entscheidungslogik:**

| Lokale Änderungen | Unpushed Commits | Aktion |
|--------------------|------------------|--------|
| Ja | egal | → Weiter mit Step 4 (Stage + Commit + Push) |
| Nein | Ja | → Direkt zu Step 7 (nur Push) |
| Nein | Nein | → Stoppe: "Alles synchron" |

**Falls weder Änderungen noch unpushed Commits:**
```
ℹ️ Keine Änderungen zum Pushen.

Repo:        github.com/user/repo-name
Letzter Sync: [letzter Commit-Zeitpunkt]
```
Stoppe hier.

**Falls nur unpushed Commits (kein neues Staging nötig):**
```
ℹ️ Keine neuen Änderungen, aber [Anzahl] Commit(s) noch nicht gepusht.
```
Frage User via AskUserQuestion:
```
[Anzahl] lokale(r) Commit(s) noch nicht gepusht zu GITHUB_REPO:

[git log @{u}..HEAD --oneline Ausgabe]

Jetzt pushen?
1. Ja, pushen
2. Nein, abbrechen
```
Bei "Ja" → Springe direkt zu Step 7 (Push).

### Step 4: Änderungen anzeigen und bestätigen

Zeige dem User eine Zusammenfassung:

```bash
# Anzahl geänderter Dateien
git status --short | wc -l

# Übersicht der Änderungen
git status --short
```

Frage User via AskUserQuestion:

```
Folgende Änderungen werden gepusht zu GITHUB_REPO:

[Anzahl] Dateien geändert/hinzugefügt/gelöscht

Fortfahren?
1. Ja, alle Änderungen pushen
2. Nein, abbrechen
```

**Bei Abbruch:** Stoppe mit "Abgebrochen. Keine Änderungen gepusht."

### Step 5: Commit-Message bestimmen

**Falls `--message` Argument vorhanden:**
- Nutze die übergebene Message

**Sonst (Default):**
```bash
source ~/.claude/skills/github-ops/lib/commit-counter.sh
get_sync_message
# Ergebnis: "Sync 2026-02-06-01"
```

### Step 6: Commit erstellen

```bash
git add -A
git commit -m "COMMIT_MESSAGE"
```

**Wichtig:**
- `git add -A` fügt ALLE Änderungen hinzu (new, modified, deleted)
- .gitignore wird respektiert (github.json ist excluded)

### Step 7: Push zu Remote

```bash
git push
```

**Falls Push fehlschlägt:**
- Zeige Fehlermeldung
- Häufige Ursache: Remote nicht erreichbar, Auth abgelaufen
- Empfehle: `gh auth refresh` bei Auth-Problemen

### Step 8: Bestätigung ausgeben

```
✅ Erfolgreich gepusht

Repo:    github.com/user/repo-name
Commit:  [Commit-Message oder "N Commits gepusht"]
Dateien: [Anzahl] geändert
```

---

## Error Handling

### Keine Änderungen vorhanden
```
ℹ️ Alles synchron – keine lokalen Änderungen, keine unpushed Commits.
```

### Push fehlgeschlagen
```
❌ Push fehlgeschlagen

Mögliche Ursachen:
1. Netzwerk nicht erreichbar
2. Auth abgelaufen → gh auth refresh
3. Remote-Branch geschützt

Commit wurde lokal erstellt. Erneut versuchen mit /github-push
(erkennt unpushed Commits automatisch).
```

### Config nicht gefunden
```
❌ Keine GitHub-Config in: PWD/.claude/github.json

Bitte erst /github-init ausführen.
```
