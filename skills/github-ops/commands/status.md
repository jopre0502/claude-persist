---
description: "Zeigt GitHub Sync-Status: letzter Commit, ausstehende Änderungen, Repo-Info"
allowed-tools: Bash, Read
---

# GitHub-Status Command

Zeigt den aktuellen Sync-Status des Working Directory mit GitHub.

## Workflow

### Step 1: Config laden

```bash
source ~/.claude/skills/github-ops/lib/config-reader.sh
read_github_config
```

**Falls Config fehlt:**
```
❌ Keine GitHub-Config gefunden.
Bitte erst /github-init ausführen.
```

### Step 2: Repo-Informationen sammeln

```bash
# Remote-URL
git remote get-url origin 2>/dev/null

# Aktueller Branch
git branch --show-current

# Letzter Commit
git log -1 --format="%h %s (%cr)" 2>/dev/null
```

### Step 3: Sync-Status prüfen

```bash
# WSL2/9P Fix: Git Stat-Cache refreshen (Timestamps unzuverlaessig auf 9P-Mounts)
git update-index --really-refresh 2>/dev/null || true
# Pending Changes (noch nicht committed)
git status --short

# Ahead/Behind Remote
git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null
```

**Interpretation:**
- `X 0` = X Commits lokal, die nicht gepusht sind (ahead)
- `0 X` = X Commits remote, die nicht gemergt sind (behind, ungewöhnlich bei Push-only)
- `0 0` = Synchron

### Step 4: Status-Report ausgeben

```
═══════════════════════════════════════════════
📊 GitHub Sync-Status
═══════════════════════════════════════════════

Repo:          github.com/user/repo-name
Type:          project
Branch:        main

Letzter Commit: abc1234 Sync 2026-02-06-01 (vor 2 Stunden)

Pending Changes: [Anzahl] Dateien
  M  src/main.ts
  A  docs/new-file.md
  D  old-file.txt

Sync-Status:   ✅ Synchron / ⚠️ X Commits nicht gepusht

═══════════════════════════════════════════════
```

**Falls keine Pending Changes:**
```
Pending Changes: Keine (Working Directory clean)
```

**Falls Commits nicht gepusht:**
```
Sync-Status:   ⚠️ 3 Commits nicht gepusht
               Nächster Schritt: /github-push
```

**Falls synchron und keine Changes:**
```
Sync-Status:   ✅ Vollständig synchron
```

---

## Spezialfälle

### Kein Remote konfiguriert
```
⚠️ Kein GitHub-Remote konfiguriert, aber Config existiert.

Config sagt: github.com/user/repo-name
Git Remote:  (nicht vorhanden)

Empfehlung: Remote manuell hinzufügen:
  git remote add origin https://github.com/user/repo-name.git
```

### Remote nicht erreichbar
```
⚠️ Remote-Status konnte nicht geprüft werden.

Lokaler Status:
  Letzter Commit: abc1234 Sync 2026-02-06-01
  Pending Changes: [Anzahl] Dateien

Netzwerk prüfen oder: gh auth status
```
