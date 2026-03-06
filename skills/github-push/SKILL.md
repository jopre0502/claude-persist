---
name: github-push
description: |
  Committed und pusht alle Änderungen zum konfigurierten GitHub-Repo mit Sync-Message (Sync YYYY-MM-DD-NN).

  Use when: User wants to push changes, at session end, or when /session-refresh offers push.

  Trigger: /github-push, "pushen", "GitHub push", "Änderungen hochladen"

  Prerequisites: /github-init must have been run first (.claude/github.json exists).
allowed-tools: Bash, Read, AskUserQuestion
disable-model-invocation: true
---

# GitHub-Push

Committed alle Änderungen und pusht zum konfigurierten GitHub-Repo.

**Arguments:** $ARGUMENTS

## Workflow

### Step 1: Prerequisites prüfen

```bash
source ~/.claude/skills/github-ops/lib/prerequisites.sh
check_prerequisites
```

### Step 2: Config laden

```bash
source ~/.claude/skills/github-ops/lib/config-reader.sh
read_github_config
```

**Falls Config fehlt:** Stoppe mit "Bitte erst /github-init ausführen."

### Step 3: Änderungen prüfen (lokal + unpushed)

```bash
# WSL2/9P Fix: Git Stat-Cache refreshen (Timestamps unzuverlaessig auf 9P-Mounts)
git update-index --really-refresh 2>/dev/null || true
git status --short
git log @{u}..HEAD --oneline 2>/dev/null
```

| Lokale Änderungen | Unpushed Commits | Aktion |
|--------------------|------------------|--------|
| Ja | egal | → Stage + Commit + Push (Step 4-8) |
| Nein | Ja | → Nur Push (Step 7) |
| Nein | Nein | → Stoppe: "Alles synchron" |

**Falls nur unpushed Commits:** Frage User ob jetzt pushen.

### Step 4: Änderungen anzeigen und bestätigen

```bash
git update-index --really-refresh 2>/dev/null || true
git status --short | wc -l
git status --short
```

Frage User via AskUserQuestion: "[Anzahl] Dateien pushen zu $GITHUB_REPO?"

### Step 5: Commit-Message bestimmen

**Falls `--message` Argument:** Nutze Custom-Message.

**Sonst (Default):**
```bash
source ~/.claude/skills/github-ops/lib/commit-counter.sh
get_sync_message
# → "Sync 2026-02-06-01"
```

### Step 6: Commit erstellen

**NIEMALS `git add -f` oder `git add --force` verwenden. .gitignore ist unantastbar.**

```bash
# git add -A respektiert .gitignore. Falls Fehler: nur nicht-ignorierte Dateien einzeln adden.
git add -A
git commit -m "COMMIT_MESSAGE"
```

Falls `git add` Dateien wegen .gitignore ablehnt: Diese Dateien gehoeren NICHT ins Repo. Nur die nicht-ignorierten Dateien einzeln stagen.

### Step 7: Push zu Remote

```bash
git push
```

### Step 8: Bestätigung

```
✅ Erfolgreich gepusht

Repo:    github.com/user/repo-name
Commit:  [Message]
Dateien: [Anzahl] geändert
```

---

## Error Handling

### Keine Änderungen
```
ℹ️ Alles synchron – keine lokalen Änderungen, keine unpushed Commits.
```

### Push fehlgeschlagen
Zeige: Mögliche Ursachen (Netzwerk, Auth, Branch-Schutz). Commit bleibt lokal, `/github-push` erkennt unpushed Commits beim nächsten Aufruf.

### Config nicht gefunden
Zeige: "Bitte erst /github-init ausführen."
