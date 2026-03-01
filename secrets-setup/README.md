# Secrets Setup Guide

Dieses Verzeichnis dokumentiert die erwartete Secrets-Ordnerstruktur fuer Claude Code.
Nach `git clone` des Knowledge Hub fehlt die Secrets-Infrastruktur — diese Beispieldateien
zeigen was wohin gehoert.

**Architektur:** Siehe ADR-003 (4-Layer Config-Modell) + ADR-004 (SOPS + age Encryption)

---

## Zielstruktur (auf dem Rechner)

```
~/.config/secrets/                    # Layer 1: Secrets at Rest
├── .sops.yaml                        # SOPS Config mit age Public Key
├── age-key.txt                       # age Private Key (chmod 600!)
└── env.d/                            # Verschluesselte .env Dateien
    ├── n8n.env                       # n8n Workflow Automation
    ├── obsidian.env                  # Obsidian REST API
    └── vault.env                     # Pfade + allgemeine Config
```

---

## Setup-Anleitung (Neue Installation)

### 1. Verzeichnis + Permissions erstellen

```bash
mkdir -p ~/.config/secrets/env.d
chmod 700 ~/.config/secrets
```

### 2. age + SOPS installieren

```bash
# Ubuntu/WSL2:
sudo apt install age
# SOPS: https://github.com/getsops/sops/releases
sudo dpkg -i sops_<version>_amd64.deb

# Windows (Scoop):
scoop install age sops

# macOS:
brew install age sops
```

### 3. age Keypair generieren

```bash
age-keygen -o ~/.config/secrets/age-key.txt
chmod 600 ~/.config/secrets/age-key.txt

# Public Key notieren (fuer .sops.yaml):
grep "public key:" ~/.config/secrets/age-key.txt
```

**WICHTIG:** age Private Key in 1Password (oder aehnlichem) als Backup sichern!

### 4. .sops.yaml erstellen

Kopiere `sops.yaml.example` nach `~/.config/secrets/.sops.yaml` und ersetze
den Public Key durch deinen eigenen:

```bash
cp secrets-setup/.sops.yaml.example ~/.config/secrets/.sops.yaml
# Dann: Public Key aus Schritt 3 einsetzen
```

### 5. .env Dateien erstellen und verschluesseln

```bash
# 1. Beispieldateien als Vorlage kopieren
cp secrets-setup/env.d/*.example ~/.config/secrets/env.d/

# 2. .example Extension entfernen und echte Werte eintragen
cd ~/.config/secrets/env.d
for f in *.example; do mv "$f" "${f%.example}"; done

# 3. Echte Werte eintragen
vim vault.env    # Pfade anpassen
vim n8n.env      # API Key eintragen
vim obsidian.env # API Key eintragen

# 4. Verschluesseln
export SOPS_AGE_KEY_FILE=~/.config/secrets/age-key.txt
for f in env.d/*.env; do
  sops --encrypt --in-place --config .sops.yaml "$f"
done
```

### 6. Verifizieren

```bash
# Entschluesselung testen
sops -d ~/.config/secrets/env.d/vault.env

# Claude Code Session testen (nach Neustart)
# session-env-loader.sh laedt automatisch via CLAUDE_ENV_FILE
```

---

## Alltags-Befehle

```bash
# Secret editieren (entschluesselt → Editor → verschluesselt)
SOPS_AGE_KEY_FILE=~/.config/secrets/age-key.txt sops edit env.d/vault.env

# Klartext anzeigen
sops -d env.d/vault.env

# Neues Secret-File anlegen
echo "NEW_KEY=new_value" > env.d/new-service.env
sops --encrypt --in-place --config .sops.yaml env.d/new-service.env
```

---

## Hinweise

- Echte Secrets werden NIEMALS in Git getrackt (.gitignore schuetzt)
- `session-env-loader.sh` laedt alle `env.d/*.env` automatisch in Claude Code Sessions
- Fallback: Falls SOPS nicht installiert, werden Klartext-Files gelesen
- Plattform: Funktioniert unter WSL2, Windows Native und macOS
