# GitHub Repository Setup Guide

Diese Anleitung hilft bei der erstmaligen Einrichtung eines GitHub-Repos für dein Projekt.

## Voraussetzungen

### 1. gh CLI installieren

```bash
# Ubuntu/WSL
sudo apt install gh

# macOS
brew install gh

# Windows
winget install GitHub.cli
```

**Verifizieren:**
```bash
gh --version
# Erwartung: gh version 2.x.x
```

### 2. gh CLI authentifizieren

```bash
gh auth login
```

**Empfohlene Optionen:**
- Account: GitHub.com
- Protocol: HTTPS
- Authenticate: Login with a web browser

**WSL2-Hinweis:** In WSL2 kann `xdg-open` fehlen, sodass der Browser nicht automatisch öffnet. Falls die URL angezeigt wird:
1. URL manuell im Windows-Browser öffnen
2. Code eingeben (wird im Terminal angezeigt)
3. Terminal offen lassen bis Auth abgeschlossen

**Verifizieren:**
```bash
gh auth status
# Erwartung: "Logged in to github.com as USERNAME"
```

---

## Neues Repository erstellen

### Option A: Privates Repo (empfohlen)

```bash
cd /pfad/zu/deinem/projekt

# Repo erstellen + lokales Verzeichnis verknüpfen + erster Push
gh repo create $(basename "$PWD") --private --source=. --push
```

**Was passiert:**
1. Erstellt `github.com/dein-username/projekt-name` (privat)
2. Fügt Remote `origin` hinzu
3. Committed alle Dateien
4. Pusht zu GitHub

### Option B: Öffentliches Repo

```bash
gh repo create $(basename "$PWD") --public --source=. --push
```

### Option C: Repo unter Organisation

```bash
gh repo create meine-org/projekt-name --private --source=. --push
```

---

## Bestehendes Repo verknüpfen

Falls das Repo bereits auf GitHub existiert:

```bash
cd /pfad/zu/deinem/projekt

# Remote hinzufügen
git remote add origin https://github.com/username/repo-name.git

# Verifizieren
git remote -v
```

---

## Nach der Einrichtung

Führe `/github-init` erneut aus:

```bash
/github-init
```

Der Skill erkennt jetzt das verknüpfte Repo und erstellt die Config.

---

## Troubleshooting

### "Repository already exists"

Das Repo existiert bereits auf GitHub. Optionen:

1. **Verknüpfen statt neu erstellen:**
   ```bash
   git remote add origin https://github.com/username/repo-name.git
   ```

2. **Anderen Namen wählen:**
   ```bash
   gh repo create anderer-name --private --source=. --push
   ```

### "Permission denied"

Authentifizierung prüfen:
```bash
gh auth status
gh auth refresh
```

### "Not a git repository"

Git initialisieren:
```bash
git init
git add .
git commit -m "Initial commit"
```

Dann Repo erstellen.

### "Remote origin already exists"

Remote entfernen und neu setzen:
```bash
git remote remove origin
git remote add origin https://github.com/username/repo-name.git
```

---

## Vault-spezifische Hinweise

Für Obsidian Vaults:

1. **Sensible Daten ausschließen:**
   ```bash
   # .gitignore hinzufügen VOR erstem Commit
   echo "private/" >> .gitignore
   echo ".obsidian/workspace.json" >> .gitignore
   ```

2. **Dann Repo erstellen:**
   ```bash
   gh repo create vault-backup --private --source=. --push
   ```

---

## Weiterführende Ressourcen

- [gh CLI Manual](https://cli.github.com/manual/)
- [GitHub Docs: Creating a repo](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-new-repository)

---

*Nach erfolgreicher Einrichtung: `/github-init` ausführen*
