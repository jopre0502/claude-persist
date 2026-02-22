---
description: "Obsidian Vault zu GitHub pushen - funktioniert von jedem Working Directory"
allowed-tools: Bash, Read, AskUserQuestion
---

# Obsidian Vault Sync Command

Pusht den Obsidian Vault zu GitHub. Kann von **jedem Working Directory** aufgerufen werden.

**Arguments:** "$ARGUMENTS"

## Workflow

### Step 1: OBSIDIAN_VAULT ermitteln

```bash
echo "OBSIDIAN_VAULT=${OBSIDIAN_VAULT:-nicht gesetzt}"
```

**Falls `OBSIDIAN_VAULT` nicht gesetzt:**
```
❌ OBSIDIAN_VAULT Environment Variable nicht gesetzt.

Setup (SessionStart Hook — automatisch bei jeder Session):
  1. echo 'OBSIDIAN_VAULT="/pfad/zum/vault"' >> ~/.config/secrets/env.d/vault.env
  2. chmod 600 ~/.config/secrets/env.d/vault.env
  3. Neue Claude Code Session starten (Hook laedt vault.env automatisch)

Alternativ (einmalig): export OBSIDIAN_VAULT="/pfad/zum/vault"
Siehe: ADR-003 (Config-Architektur)
```
Stoppe hier.

### Step 2: Vault-Verzeichnis prüfen

```bash
# Guard: Ist es wirklich ein Obsidian Vault?
if [ ! -d "$OBSIDIAN_VAULT/.obsidian" ]; then
  echo "ERROR: $OBSIDIAN_VAULT ist kein Obsidian Vault (.obsidian/ fehlt)"
  exit 1
fi
ls -la "$OBSIDIAN_VAULT/.claude/github.json" 2>/dev/null
ls -la "$OBSIDIAN_VAULT/.git" 2>/dev/null
```

**Falls Config fehlt (`.claude/github.json` nicht vorhanden):**
```
❌ Keine GitHub-Config im Vault gefunden.

Bitte erst im Vault-Verzeichnis /github-init --vault ausführen:
  cd $OBSIDIAN_VAULT
  /github-init --vault
```
Stoppe hier.

**Falls kein Git-Repo:**
```
❌ Vault ist kein Git-Repository.

Bitte im Vault-Verzeichnis initialisieren:
  cd $OBSIDIAN_VAULT
  git init
  gh repo create vault-name --private --source=. --push
  /github-init --vault
```
Stoppe hier.

### Step 3: Config laden

```bash
GITHUB_CONFIG="$OBSIDIAN_VAULT/.claude/github.json" source ~/.claude/skills/github-ops/lib/config-reader.sh && read_github_config
```

**Bei Fehler:** Zeige Fehlermeldung und stoppe.

### Step 4: Änderungen prüfen

```bash
# WSL2/9P Fix: Git Stat-Cache refreshen (Timestamps unzuverlaessig auf 9P-Mounts)
git -C "$OBSIDIAN_VAULT" update-index --really-refresh 2>/dev/null || true
git -C "$OBSIDIAN_VAULT" status --short
```

**Falls keine Änderungen:**
```
ℹ️ Vault ist synchron - keine Änderungen.

Vault: $OBSIDIAN_VAULT
Repo:  $GITHUB_REPO
```
Stoppe hier.

### Step 5: Änderungen anzeigen und bestätigen

Zeige dem User via AskUserQuestion:

```
Obsidian Vault Sync zu GITHUB_REPO:

[Anzahl] Dateien geändert/hinzugefügt/gelöscht

Fortfahren?
1. Ja, Vault pushen
2. Nein, abbrechen
```

**Bei Abbruch:** Stoppe mit "Abgebrochen."

### Step 6: Commit + Push

```bash
# Commit-Message generieren (git -C fuer korrektes Repo)
GIT_WORK_DIR="$OBSIDIAN_VAULT" source ~/.claude/skills/github-ops/lib/commit-counter.sh
COMMIT_MSG=$(get_sync_message)

# Falls --message Argument: Custom Message verwenden
# Sonst: Default Sync-Message

git -C "$OBSIDIAN_VAULT" add -A
git -C "$OBSIDIAN_VAULT" commit -m "$COMMIT_MSG"
git -C "$OBSIDIAN_VAULT" push
```

### Step 7: Bestätigung

```
✅ Vault erfolgreich gepusht

Vault:   $OBSIDIAN_VAULT
Repo:    $GITHUB_REPO
Commit:  $COMMIT_MSG
Dateien: [Anzahl] geändert
```

---

## Error Handling

### OBSIDIAN_VAULT nicht gesetzt
Zeige Anleitung zum Setzen der Environment Variable.

### Push fehlgeschlagen
```
❌ Push fehlgeschlagen

Mögliche Ursachen:
1. Netzwerk nicht erreichbar
2. Auth abgelaufen → gh auth refresh
3. Remote-Branch geschützt

Commit wurde lokal im Vault erstellt. Erneut versuchen: /obsidian-sync
```
