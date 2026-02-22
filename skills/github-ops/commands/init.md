---
description: "Verknüpft aktuelles Projekt mit GitHub-Repo und erstellt Config"
argument-hint: "[--vault]"
allowed-tools: Bash, Read, Write, AskUserQuestion
---

# GitHub-Init Command

Initialisiert GitHub-Integration für das aktuelle Working Directory.

**Arguments:** "$ARGUMENTS"

## Workflow

### Step 1: Prerequisites prüfen

```bash
# Prüfe gh CLI
source ~/.claude/skills/github-ops/lib/prerequisites.sh
check_prerequisites
```

**Bei Fehler:** Zeige Installationsanleitung und stoppe.

### Step 2: Git-Status prüfen

```bash
# Ist dies ein Git-Repository?
git rev-parse --is-inside-work-tree 2>/dev/null

# Falls nicht: Initialisieren anbieten
```

**Falls kein Git-Repo:**
- Frage User: "Soll ich `git init` ausführen?"
- Bei JA: `git init` ausführen
- Bei NEIN: Stoppe mit Hinweis

### Step 3: Repo-Typ bestimmen

**Falls `--vault` Argument:**
- Type = "vault"
- Überspringe User-Frage

**Sonst:**
Frage User via AskUserQuestion:

```
Welchen Repo-Typ einrichten?

1. Projekt (Standard) - Für Code-Projekte mit CLAUDE.md/PROJEKT.md
2. Vault - Für Obsidian Vault oder Wissenssammlung
```

### Step 4: GitHub-Remote prüfen

```bash
# Prüfe existierende Remotes
git remote -v | grep -E "(github\.com|github:)" | head -1
```

**Falls Remote existiert:**
- Extrahiere Repo-URL
- Zeige: "Gefunden: github.com/user/repo-name"
- Weiter zu Step 5

**Falls KEIN Remote:**
- Zeige Anleitung aus `references/github-setup-guide.md`
- Konkret empfehlen:
  ```bash
  gh repo create $(basename "$PWD") --private --source=. --push
  ```
- Stoppe mit: "Bitte Repo erstellen, dann erneut /github-init ausführen."

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
- Erstelle mit passendem Template (Projekt oder Vault)
- Siehe `assets/gitignore-project.txt` oder `assets/gitignore-vault.txt`

**Falls `.gitignore` existiert:**
- Prüfe ob `.claude/github.json` bereits excluded
- Falls nicht: Füge hinzu

**Immer sicherstellen (für BEIDE Typen):**
```gitignore
# Claude local config (nicht committen)
.claude/github.json
```

### Step 8: Bestätigung ausgeben

```
✅ GitHub-Integration eingerichtet

Repo:   github.com/USER/REPO-NAME
Type:   project
Config: .claude/github.json

Nächste Schritte:
1. Änderungen committen: git add . && git commit -m "Initial commit"
2. Pushen: /github-push
3. Status prüfen: /github-status
```

---

## Error Handling

### gh CLI nicht installiert
```
❌ gh CLI nicht gefunden

Installation:
  Ubuntu/WSL: sudo apt install gh
  macOS:      brew install gh

Nach Installation: /github-init erneut ausführen
```

### gh nicht authentifiziert
```
❌ gh CLI nicht authentifiziert

Authentifizierung:
  gh auth login

Nach Login: /github-init erneut ausführen
```

### Kein GitHub-Remote
```
⚠️ Kein GitHub-Remote konfiguriert

Repo erstellen:
  gh repo create PROJEKT-NAME --private --source=. --push

Nach Erstellung: /github-init erneut ausführen
```

### Config existiert bereits
```
⚠️ Config existiert bereits: .claude/github.json

Optionen:
1. Überschreiben (aktuelle Config löschen)
2. Abbrechen

Aktuelle Config:
  Repo: github.com/user/existing-repo
  Type: project
```

---

## Beispiel-Output

```
$ /github-init

🔍 Prüfe Prerequisites...
✅ gh CLI installiert (v2.40.1)
✅ Authentifiziert als: username

🔍 Prüfe Git-Repository...
✅ Git-Repository gefunden

❓ Welchen Repo-Typ einrichten?
   [1] Projekt (Standard)
   [2] Vault

> 1

🔍 Prüfe GitHub-Remote...
✅ Remote gefunden: github.com/username/projekt-name

📁 Erstelle Config...
✅ .claude/github.json erstellt

📝 Aktualisiere .gitignore...
✅ .claude/github.json zu .gitignore hinzugefügt

═══════════════════════════════════════════════
✅ GitHub-Integration eingerichtet

Repo:   github.com/username/projekt-name
Type:   project
Config: .claude/github.json

Nächste Schritte:
  /github-push    - Änderungen pushen
  /github-status  - Sync-Status anzeigen
═══════════════════════════════════════════════
```
