---
name: github-status
description: |
  Zeigt GitHub Sync-Status: letzter Commit, ausstehende Änderungen, Repo-Info.

  Use when: User wants to check sync status, see what's pending, or verify push success.

  Trigger: /github-status, "Sync-Status", "was ist noch nicht gepusht"

  Prerequisites: /github-init must have been run first (.claude/github.json exists).
allowed-tools: Bash, Read
disable-model-invocation: true
---

# GitHub-Status

Zeigt den aktuellen Sync-Status des Working Directory mit GitHub.

## Workflow

### Step 1: Config laden

```bash
source ~/.claude/skills/github-ops/lib/config-reader.sh
read_github_config
```

**Falls Config fehlt:** Stoppe mit "Bitte erst /github-init ausführen."

### Step 2: Repo-Informationen sammeln

```bash
git remote get-url origin 2>/dev/null
git branch --show-current
git log -1 --format="%h %s (%cr)" 2>/dev/null
```

### Step 3: Sync-Status prüfen

```bash
# WSL2/9P Fix: Git Stat-Cache refreshen (Timestamps unzuverlaessig auf 9P-Mounts)
git update-index --really-refresh 2>/dev/null || true
git status --short
git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null
```

**Interpretation:**
- `X 0` = X Commits ahead (nicht gepusht)
- `0 X` = X Commits behind (ungewöhnlich bei Push-only)
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

Pending Changes: [Anzahl] Dateien / Keine
Sync-Status:   ✅ Synchron / ⚠️ X Commits nicht gepusht

═══════════════════════════════════════════════
```

---

## Spezialfälle

### Kein Remote konfiguriert
Zeige: Config vs. Git Remote Diskrepanz. Empfehle `git remote add origin`.

### Remote nicht erreichbar
Zeige lokalen Status + Hinweis auf Netzwerk/Auth.
