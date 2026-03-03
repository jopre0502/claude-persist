---
description: "Obsidian Vault zu GitHub pushen - funktioniert von jedem Working Directory"
allowed-tools: Bash, Read, AskUserQuestion
---

# Obsidian Vault Sync Command

Pusht den Obsidian Vault zu GitHub. Kann von **jedem Working Directory** aufgerufen werden.

**Arguments:** "$ARGUMENTS"

## Workflow

### Step 1: Vault-Pfad ermitteln (CLI-first)

```bash
# Primary: CLI (funktioniert auch ohne env var)
VAULT_PATH=$(obsidian.com vault 2>/dev/null | awk -F'\t' '/^path/{print $2}' | tr -d '\r')
# Fallback: Environment variable
if [ -z "$VAULT_PATH" ] || [ ! -d "$VAULT_PATH" ]; then
  VAULT_PATH="${OBSIDIAN_VAULT:-}"
fi
echo "VAULT_PATH=${VAULT_PATH:-nicht ermittelt}"
```

**Falls Vault-Pfad nicht ermittelt werden konnte:**
```
❌ Vault-Pfad nicht ermittelt. Obsidian App starten oder OBSIDIAN_VAULT setzen.

Option A (empfohlen): Obsidian App starten — CLI liefert Pfad automatisch
Option B (Offline-Fallback): export OBSIDIAN_VAULT="/pfad/zum/vault"
```
Stoppe hier.

### Step 2: Vault-Verzeichnis prüfen

```bash
# Guard: Ist es wirklich ein Obsidian Vault?
if [ ! -d "$VAULT_PATH/.obsidian" ]; then
  echo "ERROR: $VAULT_PATH ist kein Obsidian Vault (.obsidian/ fehlt)"
  exit 1
fi
ls -la "$VAULT_PATH/.claude/github.json" 2>/dev/null
ls -la "$VAULT_PATH/.git" 2>/dev/null
```

**Falls Config fehlt (`.claude/github.json` nicht vorhanden):**
```
❌ Keine GitHub-Config im Vault gefunden.

Bitte erst im Vault-Verzeichnis /github-init --vault ausführen:
  cd $VAULT_PATH
  /github-init --vault
```
Stoppe hier.

**Falls kein Git-Repo:**
```
❌ Vault ist kein Git-Repository.

Bitte im Vault-Verzeichnis initialisieren:
  cd $VAULT_PATH
  git init
  gh repo create vault-name --private --source=. --push
  /github-init --vault
```
Stoppe hier.

### Step 3: Config laden

```bash
GITHUB_CONFIG="$VAULT_PATH/.claude/github.json" source ~/.claude/skills/github-ops/lib/config-reader.sh && read_github_config
```

**Bei Fehler:** Zeige Fehlermeldung und stoppe.

### Step 4: Änderungen prüfen

```bash
# WSL2/9P Fix: Git Stat-Cache refreshen (Timestamps unzuverlaessig auf 9P-Mounts)
git -C "$VAULT_PATH" update-index --really-refresh 2>/dev/null || true
git -C "$VAULT_PATH" status --short
```

**Falls keine Änderungen:**
```
ℹ️ Vault ist synchron - keine Änderungen.

Vault: $VAULT_PATH
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
GIT_WORK_DIR="$VAULT_PATH" source ~/.claude/skills/github-ops/lib/commit-counter.sh
COMMIT_MSG=$(get_sync_message)

# Falls --message Argument: Custom Message verwenden
# Sonst: Default Sync-Message

git -C "$VAULT_PATH" add -A
git -C "$VAULT_PATH" commit -m "$COMMIT_MSG"
git -C "$VAULT_PATH" push
```

### Step 7: Bestätigung

```
✅ Vault erfolgreich gepusht

Vault:   $VAULT_PATH
Repo:    $GITHUB_REPO
Commit:  $COMMIT_MSG
Dateien: [Anzahl] geändert
```

---

## Error Handling

### Vault-Pfad nicht ermittelt
Zeige Anleitung: Obsidian App starten (CLI-first) oder OBSIDIAN_VAULT setzen (Offline-Fallback).

### Push fehlgeschlagen
```
❌ Push fehlgeschlagen

Mögliche Ursachen:
1. Netzwerk nicht erreichbar
2. Auth abgelaufen → gh auth refresh
3. Remote-Branch geschützt

Commit wurde lokal im Vault erstellt. Erneut versuchen: /obsidian-sync
```
