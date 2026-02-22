---
name: github-init
description: |
  Verknüpft aktuelles Working Directory mit GitHub-Repo und erstellt Pro-Projekt Config (.claude/github.json).

  Use when: User wants to connect a project or vault to GitHub for push-based backup/archival.

  Trigger: /github-init, "GitHub einrichten", "Repo verknüpfen"

  Prerequisites: gh CLI installed + authenticated, git repository initialized.
allowed-tools: Bash, Read, Write, AskUserQuestion
disable-model-invocation: true
---

# GitHub-Init

Initialisiert GitHub-Integration für das aktuelle Working Directory.

**Arguments:** $ARGUMENTS

## Workflow

### Step 1: Prerequisites prüfen

```bash
source ~/.claude/skills/github-ops/lib/prerequisites.sh
check_prerequisites
```

**Bei Fehler:** Zeige Installationsanleitung und stoppe.

### Step 2: Git-Status prüfen

```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```

**Falls kein Git-Repo:**
- Frage User: "Soll ich `git init` ausführen?"
- Bei JA: `git init` ausführen
- Bei NEIN: Stoppe mit Hinweis

### Step 3: Repo-Typ bestimmen

**Falls `--vault` Argument:**
- Type = "vault"
- Überspringe User-Frage

**Sonst:** Frage User via AskUserQuestion:
```
Welchen Repo-Typ einrichten?
1. Projekt (Standard) - Für Code-Projekte mit CLAUDE.md/PROJEKT.md
2. Vault - Für Obsidian Vault oder Wissenssammlung
```

### Step 4: GitHub-Remote prüfen

```bash
git remote -v | grep -E "(github\.com|github:)" | head -1
```

**Falls Remote existiert:**
- Extrahiere Repo-URL → Weiter zu Step 5

**Falls KEIN Remote:**
- Zeige Anleitung aus `~/.claude/skills/github-ops/references/github-setup-guide.md`
- Empfehle: `gh repo create $(basename "$PWD") --private --source=. --push`
- Stoppe: "Bitte Repo erstellen, dann erneut /github-init ausführen."

### Step 5: .claude/ Verzeichnis erstellen

```bash
mkdir -p .claude
```

### Step 6: Config schreiben

Erstelle `.claude/github.json`:
```json
{
  "repo": "github.com/USER/REPO-NAME",
  "type": "project",
  "created": "YYYY-MM-DD"
}
```

**Wichtig:**
- `repo`: Ohne `https://` Prefix (nur `github.com/user/repo`)
- `type`: "project" oder "vault" (aus Step 3)
- `created`: Aktuelles Datum

### Step 7: .gitignore prüfen/erweitern

**Falls `.gitignore` nicht existiert:**
- Erstelle mit passendem Template:
  - Projekt: `~/.claude/skills/github-ops/assets/gitignore-project.txt`
  - Vault: `~/.claude/skills/github-ops/assets/gitignore-vault.txt`

**Falls `.gitignore` existiert:**
- Prüfe ob `.claude/github.json` bereits excluded
- Falls nicht: Füge hinzu

### Step 8: Bestätigung ausgeben

```
✅ GitHub-Integration eingerichtet

Repo:   github.com/USER/REPO-NAME
Type:   project
Config: .claude/github.json

Nächste Schritte:
  /github-push    - Änderungen pushen
  /github-status  - Sync-Status anzeigen
```

---

## Error Handling

### gh CLI nicht installiert
Zeige: `sudo apt install gh` (Ubuntu/WSL), `brew install gh` (macOS)

### gh nicht authentifiziert
Zeige: `gh auth login`. WSL2-Hinweis: URL ggf. manuell im Windows-Browser öffnen.

### Kein GitHub-Remote
Empfehle: `gh repo create PROJEKT-NAME --private --source=. --push`

### Config existiert bereits
Frage: Überschreiben oder Abbrechen? Zeige aktuelle Config.
