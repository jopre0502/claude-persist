---
name: github-ops
description: |
  Shared Library für GitHub-Operations Skills. Enthält lib/, assets/, references/.

  NICHT direkt aufrufen. Nutze stattdessen: /github-init, /github-push, /github-status

  Diese Skills verwenden die shared library unter github-ops/lib/ und github-ops/assets/.

model: sonnet
allowed-tools: Read
disable-model-invocation: true
---

# GitHub-Ops (Shared Library)

Dieses Verzeichnis enthält die **gemeinsam genutzten Ressourcen** für die GitHub-Skills.

**Direkt aufrufbare Skills:**
- **`/github-init`** → `~/.claude/skills/github-init/SKILL.md`
- **`/github-push`** → `~/.claude/skills/github-push/SKILL.md`
- **`/github-status`** → `~/.claude/skills/github-status/SKILL.md`

## Shared Resources

```
github-ops/
├── lib/
│   ├── prerequisites.sh    # gh CLI + Auth Check
│   ├── config-reader.sh    # Liest PWD/.claude/github.json
│   └── commit-counter.sh   # Sync-Message Index
├── assets/
│   ├── gitignore-project.txt
│   └── gitignore-vault.txt
├── references/
│   └── github-setup-guide.md
└── commands/               # (Legacy, nicht auto-discovered)
    ├── init.md
    ├── push.md
    └── status.md
```

## Wann diesen Skill nutzen

✅ **Passend für:**
- Projekt-Audit-Trail auf GitHub sichern
- Session-Ende: Änderungen pushen
- Status prüfen: Was ist noch nicht gepusht?

❌ **Nicht passend für:**
- Team-Collaboration (PRs, Reviews, Issues)
- Bidirektionaler Sync (Pull von Remote)
- Branch-Management (nur main/master)

---

## Quick Start

### 1. Repo initialisieren

```bash
cd /dein/projekt
/github-init
# Fragt: Projekt oder Vault?
# Prüft: GitHub-Remote vorhanden?
# Erstellt: .claude/github.json
```

### 2. Änderungen pushen

```bash
/github-push
# Commit-Message: "Sync 2026-02-06-01" (Index pro Tag)
# Pusht zu konfiguriertem Repo
```

### 3. Status prüfen

```bash
/github-status
# Zeigt: Letzter Commit, Pending Changes, Repo-URL
```

---

## Architektur

### Pro-Projekt Config

Jedes Projekt speichert seine GitHub-Verknüpfung in:
```
PWD/.claude/github.json
```

**Format:**
```json
{
  "repo": "github.com/user/projekt-name",
  "type": "project",
  "created": "2026-02-06"
}
```

### Guardrail: PWD → Repo Mapping

**Sicherheit:** Skill liest NUR Config aus aktuellem PWD.
- Verhindert versehentlichen Cross-Repo-Push
- Keine zentrale Mapping-Datei
- Jedes Projekt = eigene Config

### Commit-Message-Format

**Default für /github-push:**
```
Sync YYYY-MM-DD-NN
```
- `YYYY-MM-DD` = Aktuelles Datum
- `NN` = Index (01, 02, 03...) für Commits am gleichen Tag

**Custom Message:**
```bash
/github-push --message "feat: Neue Funktion"
```

---

## Prerequisites

Vor erster Nutzung:

1. **gh CLI installiert:**
   ```bash
   gh --version
   # Falls nicht: https://cli.github.com/
   ```

2. **gh authentifiziert:**
   ```bash
   gh auth status
   # Falls nicht: gh auth login
   ```

---

## Integration mit session-refresh

Nach TASK-028 Abschluss: `/session-refresh` bietet optional Push an.

```
session-refresh läuft...
├── CLAUDE.md Update ✅
├── PROJEKT.md Verification ✅
├── /project-doc-restructure ✅
│
└── Prüfe: PWD/.claude/github.json existiert?
    │
   Ja → User-Prompt: "Push zu github.com/user/repo? (y/n)"
    │
   Nein → Überspringe
```

---

## Vault-Sonderfall: /obsidian-sync

Für Obsidian Vault existiert ein separater Command:
```bash
/obsidian-sync
```

- Liest `OBSIDIAN_VAULT` Environment Variable
- Kann von JEDEM PWD aus aufgerufen werden
- Nutzt gleiche Push-Logik wie /github-push

**Setup:** Siehe `~/.claude/commands/obsidian-sync.md`

---

## Troubleshooting

### "gh CLI not found"
```bash
# Installation (Ubuntu/WSL)
sudo apt install gh

# Oder via GitHub
https://cli.github.com/
```

### "Not authenticated"
```bash
gh auth login
# Folge den Prompts (Browser oder Token)
```

### "No GitHub remote configured"
```bash
# Repo erstellen + verknüpfen
gh repo create projekt-name --private --source=. --push
# Dann erneut /github-init
```

### "Config not found"
```bash
# Erst initialisieren
/github-init
```

---

## Referenzen

- **Prerequisites Check:** `lib/prerequisites.sh`
- **Config Reader:** `lib/config-reader.sh`
- **Commit Counter:** `lib/commit-counter.sh`
- **Setup Guide:** `references/github-setup-guide.md`
- **TASK-028:** Implementierungsdetails in projekt-automation-hub

---

*Powered by session-continuous project architecture*
