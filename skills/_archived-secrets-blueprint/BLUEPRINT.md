# BLUEPRINT - Modularer Secrets- und MCP-Setup (WSL2 Ubuntu) - KISS & robust

__Ziel:__ Du startest einfach **`claude`**. Alle MCP-Server sind *konfiguriert* und koennen bei Bedarf gestartet werden - ohne dass du vorher Secrets in die Shell laden oder entscheiden musst, welche Server du brauchst.

Dieses Dokument ist so aufgebaut, dass du es **Schritt fuer Schritt** abarbeiten kannst und danach ein **wiederverwendbares Muster** fuer *jede Art von Secrets* (nicht nur MCP) hast.

---

## 0) Design-Prinzipien (damit's konsistent bleibt)

**Wir vermeiden:**

- Secrets global in `.bashrc` / `.zshrc` zu `source`n
- "Alles in einer Shell-Session verfuegbar"
- Secrets in Tool-Config-Dateien wie `~/.claude.json`
- Klartext-Secrets auf Disk (seit SOPS+age Migration, 2026-02-23)

**Wir machen stattdessen:**

- Secrets **at rest verschluesselt** mit **SOPS + age** in getrennten **dotenv-Dateien pro Profil** (z.B. `vault.env`, `obsidian.env`)
- Entschluesselung **nur zur Laufzeit** (in-memory, nie als Klartext auf Disk)
- Zugriff auf Secrets **nur beim Start** eines konkreten Prozesses (MCP-Server oder beliebiges anderes Tool)
- Ein **generisches** Start-Tool:
  - `secret-run <profil> -- <cmd> ...` -> fuer **lokale Prozesse**
  - `mcp-server <name>` liest eine `.conf` und startet **docker oder lokal** korrekt

**WSL2 Hinweis (wichtig):**

- Lege Secrets **im Linux-Dateisystem** ab (z.B. unter `~/.config/...`), nicht unter `/mnt/c/...`, weil Windows-Mounts Linux-Permissions nicht zuverlaessig abbilden.

---

## 1) Ordnerstruktur (klare Ansage: was wohin gehoert)

Wir nutzen zwei Bereiche:

### A) Secrets + Encryption (fuer alles - MCP und nicht MCP)

```
~/.config/secrets/
├── age-key.txt          # age Private Key (chmod 600) - BACKUP in 1Password!
├── .sops.yaml           # SOPS Config (creation rules mit age Public Key)
└── env.d/
    ├── obsidian.env     # SOPS-verschluesselt (KEY=VALUE, age-encrypted)
    ├── n8n.env          # SOPS-verschluesselt
    └── vault.env        # SOPS-verschluesselt
```

### B) MCP-Server Definitionen (nur Start-Konfig, keine Secrets)

```
~/.config/mcp/
└── servers.d/
    ├── obsidian.conf
    ├── github.conf
    └── notion.conf
```

### C) Executables (Start-Tools)

```
~/.local/bin/
├── secret-run      (lokale Prozesse mit Secrets starten, SOPS-aware)
└── mcp-server      (MCP-Server nach .conf starten; docker oder lokal)
```

---

## 2) One-time Setup

### 2.1 Verzeichnisse anlegen + Rechte setzen

```bash
mkdir -p ~/.config/secrets/env.d ~/.config/mcp/servers.d ~/.local/bin
chmod 700 ~/.config/secrets ~/.config/secrets/env.d ~/.config/mcp ~/.config/mcp/servers.d
```

### 2.2 Sicherstellen, dass `~/.local/bin` im PATH ist

Das ist **kein Secret-Handling**, sondern nur Komfort.

Pruefen:
```bash
echo $PATH | tr ':' '\n' | grep -x "$HOME/.local/bin" || echo "nicht im PATH"
```

Falls nicht drin, fuege **nur diese PATH-Zeile** (ohne Secrets!) in `~/.bashrc` hinzu:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

### 2.3 SOPS + age installieren (Encryption at Rest)

```bash
# age installieren
sudo apt install age

# SOPS installieren (aktuellste Version von GitHub Releases pruefen)
# https://github.com/getsops/sops/releases
curl -LO https://github.com/getsops/sops/releases/download/v3.9.4/sops_3.9.4_amd64.deb
sudo dpkg -i sops_3.9.4_amd64.deb

# Versionen verifizieren
age --version    # z.B. v1.1.1
sops --version   # z.B. 3.9.4
```

### 2.4 age Key-Pair generieren + SOPS konfigurieren

```bash
# Key-Pair generieren
age-keygen -o ~/.config/secrets/age-key.txt
chmod 600 ~/.config/secrets/age-key.txt

# Public Key notieren (wird in .sops.yaml benutzt)
grep "public key:" ~/.config/secrets/age-key.txt

# .sops.yaml erstellen
cat > ~/.config/secrets/.sops.yaml <<'EOF'
creation_rules:
  - path_regex: \.env$
    age: >-
      <PUBLIC_KEY_HIER_EINSETZEN>
EOF
```

**WICHTIG:** age Private Key (`age-key.txt`) in 1Password als Backup speichern (manuell, ausserhalb Claude).

---

## 3) Tool 1: `secret-run` (lokal starten, SOPS-aware)

### 3.1 Datei `~/.local/bin/secret-run` erstellen

```python
#!/usr/bin/env python3
import os, sys, subprocess
from pathlib import Path

AGE_KEY_FILE = Path.home() / ".config" / "secrets" / "age-key.txt"

def parse_dotenv_string(text: str) -> dict:
    env = {}
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            raise ValueError(f"Ungueltige Zeile (kein '='): {raw!r}")
        key, val = line.split("=", 1)
        key = key.strip()
        val = val.strip()
        if not key or not key.replace("_", "").isalnum() or key[0].isdigit():
            raise ValueError(f"Ungueltiger KEY: {key!r}")
        if len(val) >= 2 and ((val[0] == val[-1] == '"') or (val[0] == val[-1] == "'")):
            val = val[1:-1]
        env[key] = val
    return env

def load_env(env_file: Path) -> dict:
    # Try SOPS decryption first
    try:
        sops_env = {**os.environ, "SOPS_AGE_KEY_FILE": str(AGE_KEY_FILE)}
        result = subprocess.run(
            ["sops", "-d", str(env_file)],
            capture_output=True, text=True, env=sops_env
        )
        if result.returncode == 0:
            return parse_dotenv_string(result.stdout)
    except FileNotFoundError:
        pass  # sops not installed
    # Fallback: plaintext
    return parse_dotenv_string(env_file.read_text(encoding="utf-8"))

def main():
    if len(sys.argv) < 4 or sys.argv[2] != "--":
        print("Usage: secret-run <profile> -- <command> [args...]", file=sys.stderr)
        sys.exit(2)
    profile = sys.argv[1]
    cmd = sys.argv[3:]
    base = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    env_file = base / "secrets" / "env.d" / f"{profile}.env"
    if not env_file.exists():
        print(f"[secret-run] Env file nicht gefunden: {env_file}", file=sys.stderr)
        sys.exit(1)
    extra = load_env(env_file)
    child_env = os.environ.copy()
    child_env.update(extra)
    # exec -> ersetzt Prozess, nichts bleibt in der Parent-Shell haengen
    os.execvpe(cmd[0], cmd, child_env)

if __name__ == "__main__":
    main()
```

```bash
chmod 755 ~/.local/bin/secret-run
```

### 3.2 Kurztest

```bash
secret-run vault -- env | grep OBSIDIAN
# Erwartung: OBSIDIAN_VAULT=..., OBSIDIAN_API_KEY=...
```

---

## 4) Tool 2: `mcp-server` (ein Einstiegspunkt fuer *alle* MCP-Server)

Du willst **nicht** pro MCP-Server ein eigenes Script pflegen. Daher:
- pro Server eine `.conf`
- ein generischer Starter `mcp-server <name>`

### 4.1 Datei `~/.local/bin/mcp-server` erstellen

```python
#!/usr/bin/env python3
import os, sys, shlex
from pathlib import Path

ALLOWED_KEYS = {
    "MODE",          # docker | local
    "ENV_PROFILE",   # z.B. obsidian
    "WORKDIR",       # optional
    "DOCKER_IMAGE",
    "DOCKER_ARGS",   # string -> shlex.split
    "LOCAL_CMD",
    "LOCAL_ARGS",    # string -> shlex.split
}

def parse_kv_conf(path: Path) -> dict:
    cfg = {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            raise ValueError(f"Ungueltige Zeile (kein '='): {raw!r}")
        key, val = line.split("=", 1)
        key = key.strip()
        val = val.strip()
        if key not in ALLOWED_KEYS:
            raise ValueError(f"Unbekannter Key {key!r} in {path} (erlaubt: {sorted(ALLOWED_KEYS)})")
        if len(val) >= 2 and ((val[0] == val[-1] == '"') or (val[0] == val[-1] == "'")):
            val = val[1:-1]
        cfg[key] = val
    return cfg

def main():
    if len(sys.argv) != 2:
        print("Usage: mcp-server <name>", file=sys.stderr)
        sys.exit(2)
    name = sys.argv[1]
    base = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    conf = base / "mcp" / "servers.d" / f"{name}.conf"
    if not conf.exists():
        print(f"[mcp-server] Config nicht gefunden: {conf}", file=sys.stderr)
        sys.exit(1)
    cfg = parse_kv_conf(conf)
    mode = cfg.get("MODE", "").lower().strip()
    env_profile = cfg.get("ENV_PROFILE", "").strip()
    workdir = cfg.get("WORKDIR", "").strip() or None
    if mode not in ("docker", "local"):
        print(f"[mcp-server] MODE muss 'docker' oder 'local' sein (ist: {mode!r})", file=sys.stderr)
        sys.exit(1)
    if not env_profile:
        print("[mcp-server] ENV_PROFILE fehlt (z.B. 'obsidian')", file=sys.stderr)
        sys.exit(1)
    if mode == "docker":
        image = cfg.get("DOCKER_IMAGE", "").strip()
        if not image:
            print("[mcp-server] DOCKER_IMAGE fehlt", file=sys.stderr)
            sys.exit(1)
        docker_args = shlex.split(cfg.get("DOCKER_ARGS", ""))
        env_file = base / "secrets" / "env.d" / f"{env_profile}.env"
        if not env_file.exists():
            print(f"[mcp-server] Env file nicht gefunden: {env_file}", file=sys.stderr)
            sys.exit(1)
        cmd = ["docker", "run", "--env-file", str(env_file), *docker_args, image]
        if workdir:
            os.chdir(workdir)
        os.execvp(cmd[0], cmd)
    else:  # local
        local_cmd = cfg.get("LOCAL_CMD", "").strip()
        if not local_cmd:
            print("[mcp-server] LOCAL_CMD fehlt", file=sys.stderr)
            sys.exit(1)
        local_args = shlex.split(cfg.get("LOCAL_ARGS", ""))
        cmd = ["secret-run", env_profile, "--", local_cmd, *local_args]
        if workdir:
            os.chdir(workdir)
        os.execvp(cmd[0], cmd)

if __name__ == "__main__":
    main()
```

```bash
chmod 755 ~/.local/bin/mcp-server
```

---

## 5) Ein neues Secret-Profil anlegen (gilt fuer MCP *und* alles andere)

Beispiel: Profil `obsidian`

```bash
# 1. Klartext-Datei erstellen (temporaer)
cat > ~/.config/secrets/env.d/obsidian.env <<'EOF'
# nur KEY=VALUE, keine Shell-Logik
OBSIDIAN_HOST=127.0.0.1
OBSIDIAN_API_KEY=...
EOF
chmod 600 ~/.config/secrets/env.d/obsidian.env

# 2. Mit SOPS verschluesseln (in-place)
export SOPS_AGE_KEY_FILE=~/.config/secrets/age-key.txt
cd ~/.config/secrets
sops --encrypt --in-place --config .sops.yaml env.d/obsidian.env

# 3. Verifizieren
sops -d env.d/obsidian.env   # Sollte KEY=VALUE Klartext zeigen
```

**Regeln (wichtig):**
- keine `export ...` Zeilen, nur `KEY=VALUE`
- keine `$(...)`, keine Backticks, keine Shell-Funktionen
- Pro Profil klare Prefixe (z.B. `GITHUB_...`, `NOTION_...`) -> verhindert Kollisionen

---

## 6) Einen MCP-Server hinzufuegen (docker ODER lokal)

Du erstellst **nur** eine `.conf`. Mehr nicht.

### 6.1 Docker-Variante (Beispiel `obsidian`)

`~/.config/mcp/servers.d/obsidian.conf`

```bash
cat > ~/.config/mcp/servers.d/obsidian.conf <<'EOF'
MODE=docker
ENV_PROFILE=obsidian
DOCKER_IMAGE=mcp/obsidian
# Typisch fuer MCP: ueber stdio, interaktiv, rm nach exit
DOCKER_ARGS=--rm -i
EOF
chmod 600 ~/.config/mcp/servers.d/obsidian.conf
```

Test:
```bash
mcp-server obsidian
```

### 6.2 Lokale Variante (Beispiel `github` als Node-MCP)

`~/.config/mcp/servers.d/github.conf`

```bash
cat > ~/.config/mcp/servers.d/github.conf <<'EOF'
MODE=local
ENV_PROFILE=github
WORKDIR=/home/DEINUSER/mcp/github-mcp
LOCAL_CMD=node
LOCAL_ARGS=server.js --stdio
EOF
chmod 600 ~/.config/mcp/servers.d/github.conf
```

Test:
```bash
mcp-server github
```

---

## 7) Claude / MCP so konfigurieren, dass du nur noch `claude` startest

Die Idee: Du traegst **alle** MCP-Server in `~/.claude.json` ein. Claude kann sie bei Bedarf starten.
Du musst dich vorher nicht entscheiden - die Server sind verfuegbar.

Beispiel (Schema - passe Pfade/Servernamen an):

```json
{
  "mcpServers": {
    "obsidian": {
      "command": "/home/DEINUSER/.local/bin/mcp-server",
      "args": ["obsidian"]
    },
    "github": {
      "command": "/home/DEINUSER/.local/bin/mcp-server",
      "args": ["github"]
    }
  }
}
```

**Wichtig:**
- In `~/.claude.json` stehen **keine Secrets**
- Claude startet spaeter `mcp-server <name>` -> der liest `.conf` -> laedt `.env` nur pro Prozess

---

## 8) Uebertragbar auf jede Art von Secrets (nicht nur MCP)

Du kannst `secret-run` fuer alles nutzen:

### 8.1 Beispiel: Curl mit API-Token

`~/.config/secrets/env.d/myapi.env`

```bash
MYAPI_TOKEN=...
```

Aufruf:
```bash
secret-run myapi -- env | grep MYAPI_TOKEN
```

Wenn du das Token in einem Command verwendest, lass Expansion im Child-Prozess passieren:

```bash
secret-run myapi -- bash -lc 'curl -H "Authorization: Bearer $MYAPI_TOKEN" https://example.com'
```

### 8.2 Beispiel: Docker (allgemein)

Fuer Docker-Workflows ist `--env-file` sauber:
- Secrets bleiben ausserhalb deiner Shell
- der Container bekommt sie nur fuer diesen Lauf

---

## 9) Security-Checkliste (minimal, aber ernst gemeint)

1) **Rechte**
```bash
chmod 700 ~/.config/secrets ~/.config/secrets/env.d
chmod 600 ~/.config/secrets/env.d/*.env
chmod 600 ~/.config/secrets/age-key.txt
chmod 700 ~/.config/mcp ~/.config/mcp/servers.d
chmod 600 ~/.config/mcp/servers.d/*.conf
```

2) **Encryption at Rest (SOPS + age)**
- Alle `.env` Dateien MUESSEN SOPS-verschluesselt sein
- `age-key.txt` ist der einzige Klartext-Schluessel -> Backup in 1Password
- `sops -d` entschluesselt nur in-memory (stdout), nie auf Disk
- Bei Key-Verlust: Secrets aus 1Password manuell neu anlegen + verschluesseln

3) **Kein Git**
- Stelle sicher, dass `~/.config/secrets/` nie in Repos landet

4) **Backups**
- age Private Key in 1Password (manuell)
- Verschluesselte `.env` Dateien koennen sicher in Git versioniert werden (Out of Scope fuer jetzt)

5) **Logging**
- Vermeide, Secrets in Logs auszugeben (`set -x`, Debug-Flags, etc.)

---

## 10) Troubleshooting

### "Claude findet mcp-server nicht"
- Nutze absolute Pfade in `~/.claude.json` (empfohlen)

### "docker run bekommt keine Variablen"
- Pruefe, ob `.env` im Linux-FS liegt, nicht `/mnt/c`
- Pruefe `chmod 600`
- Pruefe, ob `KEY=VALUE` korrekt ist (kein `export`, keine Sonderzeichen ohne Quotes)

### "lokaler MCP Server startet, aber bekommt keine Variablen"
- Teste: `secret-run <profil> -- env | head`
- Pruefe `LOCAL_CMD`/`LOCAL_ARGS`

### "sops -d schlaegt fehl"
- Pruefe `SOPS_AGE_KEY_FILE`: `ls -la ~/.config/secrets/age-key.txt`
- Pruefe ob Datei SOPS-verschluesselt ist: `head -1 ~/.config/secrets/env.d/vault.env` (sollte JSON/YAML mit `sops` Metadaten zeigen)
- Pruefe `.sops.yaml`: `cat ~/.config/secrets/.sops.yaml`
- Fallback: secret-run und session-env-loader fallen automatisch auf Klartext zurueck

### "Session-Variablen fehlen nach Claude-Start"
- Pruefe Hook-Output: Starte `claude` und suche nach `env-loader: X vars loaded`
- Pruefe `CLAUDE_ENV_FILE` ist gesetzt (nur in SessionStart Hooks verfuegbar)
- Manueller Test: `SOPS_AGE_KEY_FILE=~/.config/secrets/age-key.txt sops -d ~/.config/secrets/env.d/vault.env`

---

## 11) SOPS + age Alltag (Secrets verwalten)

### Bestehendes Secret editieren

```bash
export SOPS_AGE_KEY_FILE=~/.config/secrets/age-key.txt
sops edit ~/.config/secrets/env.d/vault.env
# -> Oeffnet $EDITOR mit Klartext, verschluesselt beim Speichern automatisch
```

### Neues Secret-Profil anlegen

```bash
# 1. Klartext-Datei erstellen
cat > ~/.config/secrets/env.d/neues-profil.env <<'EOF'
SERVICE_API_KEY=...
SERVICE_URL=https://...
EOF
chmod 600 ~/.config/secrets/env.d/neues-profil.env

# 2. Verschluesseln
cd ~/.config/secrets
sops --encrypt --in-place --config .sops.yaml env.d/neues-profil.env

# 3. Verifizieren
sops -d env.d/neues-profil.env
```

Das neue Profil wird **automatisch** in der naechsten Claude-Session geladen (session-env-loader.sh liest alle `*.env`).

### Klartext anzeigen (ohne zu editieren)

```bash
export SOPS_AGE_KEY_FILE=~/.config/secrets/age-key.txt
sops -d ~/.config/secrets/env.d/vault.env
```

### Key Rotation (bei Kompromittierung)

1. Neuen age Key generieren: `age-keygen -o ~/.config/secrets/age-key-new.txt`
2. `.sops.yaml` mit neuem Public Key aktualisieren
3. Alle Dateien re-encrypten: `sops updatekeys env.d/vault.env` (pro Datei)
4. Alten Key loeschen, neuen Key in 1Password sichern
5. `age-key.txt` mit neuem Key ersetzen

**Hinweis:** Detaillierte Key-Rotation-Automatisierung ist ein spaeterer Task.

---

## 12) Quick-Template zum Kopieren (neuer MCP-Server)

### 12.1 Secret-Profil (SOPS-verschluesselt)

```bash
# Klartext erstellen
cat > ~/.config/secrets/env.d/NAME.env <<'EOF'
# KEY=VALUE
EOF
chmod 600 ~/.config/secrets/env.d/NAME.env

# Verschluesseln
cd ~/.config/secrets
sops --encrypt --in-place --config .sops.yaml env.d/NAME.env
```

### 12.2 MCP-Config (docker)

```bash
cat > ~/.config/mcp/servers.d/NAME.conf <<'EOF'
MODE=docker
ENV_PROFILE=NAME
DOCKER_IMAGE=IMAGE
DOCKER_ARGS=--rm -i
EOF
chmod 600 ~/.config/mcp/servers.d/NAME.conf
```

### 12.3 MCP-Config (local)

```bash
cat > ~/.config/mcp/servers.d/NAME.conf <<'EOF'
MODE=local
ENV_PROFILE=NAME
WORKDIR=/abs/path/to/project
LOCAL_CMD=COMMAND
LOCAL_ARGS=ARGS --stdio
EOF
chmod 600 ~/.config/mcp/servers.d/NAME.conf
```

### 12.4 In `~/.claude.json` eintragen

```json
"NAME": { "command": "/home/DEINUSER/.local/bin/mcp-server", "args": ["NAME"] }
```

---

## 13) Konsistenz-Check (warum das logisch zusammenpasst)

- **Secrets** liegen zentral unter `~/.config/secrets/env.d/`, **SOPS-verschluesselt** und werden nie "global" geladen
- **Entschluesselung** erfolgt nur in-memory zur Laufzeit (sops -d -> stdout -> parse)
- **MCP-Server** werden einheitlich ueber `mcp-server <name>` gestartet
- `mcp-server` entscheidet anhand einer simplen `.conf`, ob **docker** oder **local**
- Bei **docker**: Secrets gehen ueber `--env-file` direkt in den Container -> keine Shell-Exports
- Bei **local**: `secret-run` entschluesselt via SOPS, injiziert Env nur in den Child-Prozess via `execvpe` -> Parent-Shell bleibt sauber
- Claude braucht nur die Startkommandos. Du startest nur **`claude`**

---

## 14) Claude Code Integration (SessionStart Hook)

Claude Code Sessions haben keinen Zugriff auf `secret-run` oder `.bashrc` Exports.
Der offizielle Weg: **`CLAUDE_ENV_FILE`** in SessionStart Hooks.

### Wie es funktioniert

1. Claude Code Session startet
2. SessionStart Hook (`~/.claude/hooks/session-env-loader.sh`) laeuft
3. Hook setzt `SOPS_AGE_KEY_FILE` (hardcoded, kein Chicken-and-Egg)
4. Hook entschluesselt **alle** `~/.config/secrets/env.d/*.env` via `sops -d`
5. Hook schreibt `export KEY=VALUE` in `$CLAUDE_ENV_FILE`
6. Fallback: Falls `sops -d` fehlschlaegt (z.B. Klartext-Datei), wird Datei direkt gelesen
7. Alle nachfolgenden Bash-Commands sehen die Variablen

### Rollenverteilung

| Tool | Wann | Wie |
|------|------|-----|
| `secret-run` | Terminal (ausserhalb Claude Code) | `secret-run vault -- <cmd>` |
| `mcp-server` | MCP Server starten (Docker/lokal) | `mcp-server obsidian` |
| `session-env-loader.sh` | Claude Code Sessions (automatisch) | SessionStart Hook -> CLAUDE_ENV_FILE |

### Konfiguration

Hook registriert in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/home/jopre/.claude/hooks/session-env-loader.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

### Wichtig

- `CLAUDE_ENV_FILE` ist **nur in SessionStart Hooks** verfuegbar (nicht PreToolUse etc.)
- Alle `env.d/*.env` werden geladen (KISS, Verzeichnis ist 700-protected)
- Neue `.env` Dateien werden automatisch in der naechsten Session verfuegbar
- SOPS-Entschluesselung dauert ~100ms fuer 3 Dateien (vernachlaessigbar)
- Referenz: ADR-003 in `projekt-automation-hub/docs/decisions/`
