# BLUEPRINT - Modularer Secrets‑ und MCP‑Setup (WSL2 Ubuntu) – KISS & robust


__Ziel:__ Du startest einfach **`claude`**. Alle MCP‑Server sind *konfiguriert* und können bei Bedarf gestartet werden – ohne dass du vorher Secrets in die Shell laden oder entscheiden musst, welche Server du brauchst.

Dieses Dokument ist so aufgebaut, dass du es **Schritt für Schritt** abarbeiten kannst und danach ein **wiederverwendbares Muster** für *jede Art von Secrets* (nicht nur MCP) hast.

  

---

  

## 0) Design‑Prinzipien (damit’s konsistent bleibt)

  

**Wir vermeiden:**

- Secrets global in `.bashrc` / `.zshrc` zu `source`n

- “Alles in einer Shell‑Session verfügbar”

- Secrets in Tool‑Config‑Dateien wie `~/.claude.json`

  

**Wir machen stattdessen:**

- Secrets **at rest** in klar getrennten **dotenv‑Dateien pro Profil** (z. B. `github.env`, `obsidian.env`)

- Zugriff auf Secrets **nur beim Start** eines konkreten Prozesses (MCP‑Server oder beliebiges anderes Tool)

- Ein **generisches** Start‑Tool:

  - `secret-run <profil> -- <cmd> ...`  → für **lokale Prozesse**

  - `mcp-server <name>` liest eine `.conf` und startet **docker oder lokal** korrekt

  

**WSL2 Hinweis (wichtig):**

- Lege Secrets **im Linux‑Dateisystem** ab (z. B. unter `~/.config/...`), nicht unter `/mnt/c/...`, weil Windows‑Mounts Linux‑Permissions nicht zuverlässig abbilden.

  

---

  

## 1) Ordnerstruktur (klare Ansage: was wohin gehört)

  

Wir nutzen zwei Bereiche:

  

### A) Secrets (für alles – MCP und nicht MCP)

```

~/.config/secrets/

└── env.d/

    ├── obsidian.env

    ├── github.env

    └── notion.env

```

  

### B) MCP‑Server Definitionen (nur Start‑Konfig, keine Secrets)

```

~/.config/mcp/

└── servers.d/

    ├── obsidian.conf

    ├── github.conf

    └── notion.conf

```

  

### C) Executables (Start‑Tools)

```

~/.local/bin/

├── secret-run      (lokale Prozesse mit Secrets starten)

└── mcp-server      (MCP‑Server nach .conf starten; docker oder lokal)

```

  

---

  

## 2) One‑time Setup

  

### 2.1 Verzeichnisse anlegen + Rechte setzen

```bash

mkdir -p ~/.config/secrets/env.d ~/.config/mcp/servers.d ~/.local/bin

chmod 700 ~/.config/secrets ~/.config/secrets/env.d ~/.config/mcp ~/.config/mcp/servers.d

```

  

### 2.2 Sicherstellen, dass `~/.local/bin` im PATH ist

Das ist **kein Secret‑Handling**, sondern nur Komfort.

  

Prüfen:

```bash

echo $PATH | tr ':' '\n' | grep -x "$HOME/.local/bin" || echo "nicht im PATH"

```

  

Falls nicht drin, füge **nur diese PATH‑Zeile** (ohne Secrets!) in `~/.bashrc` hinzu:

```bash

export PATH="$HOME/.local/bin:$PATH"

```

  

---

  

## 3) Tool 1: `secret-run` (lokal starten, ohne Secrets in die Shell zu leaken)

  

### 3.1 Datei `~/.local/bin/secret-run` erstellen

```bash

cat > ~/.local/bin/secret-run <<'PY'

#!/usr/bin/env python3

import os, sys

from pathlib import Path

  

def parse_dotenv(path: Path) -> dict:

    # Minimaler, sicherer dotenv-Parser:

    # - KEY=VALUE

    # - Kommentare (# ...) und leere Zeilen werden ignoriert

    # - Werte dürfen in einfachen oder doppelten Quotes stehen

    # - Kein eval, kein source, keine Command Substitution

    env = {}

    for raw in path.read_text(encoding="utf-8").splitlines():

        line = raw.strip()

        if not line or line.startswith("#"):

            continue

        if "=" not in line:

            raise ValueError(f"Ungültige Zeile (kein '='): {raw!r}")

        key, val = line.split("=", 1)

        key = key.strip()

        val = val.strip()

  

        if not key or not key.replace("_", "").isalnum() or key[0].isdigit():

            raise ValueError(f"Ungültiger KEY: {key!r} in {path}")

  

        # Strip surrounding quotes (simple)

        if len(val) >= 2 and ((val[0] == val[-1] == '"') or (val[0] == val[-1] == "'")):

            val = val[1:-1]

  

        env[key] = val

    return env

  

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

  

    st = env_file.stat()

    # Warnung bei zu offenen Rechten (kein Hard-Fail)

    if (st.st_mode & 0o077) != 0:

        print(f"[secret-run] WARN: Rechte sind zu offen (empfohlen 600): {env_file}", file=sys.stderr)

  

    extra = parse_dotenv(env_file)

  

    # Child-Env = aktuelles Env + extra; nur für diesen Prozess

    child_env = os.environ.copy()

    child_env.update(extra)

  

    # exec -> ersetzt Prozess, nichts bleibt in der Parent-Shell hängen

    os.execvpe(cmd[0], cmd, child_env)

  

if __name__ == "__main__":

    main()

PY

  

chmod 755 ~/.local/bin/secret-run

```

  

### 3.2 Kurztest

```bash

# Beispielprofil anlegen

cat > ~/.config/secrets/env.d/test.env <<'EOF'

HELLO=world

EOF

chmod 600 ~/.config/secrets/env.d/test.env

  

# Test: startet env nur für diesen Prozess

secret-run test -- env | grep HELLO

```

  

Erwartung: Ausgabe enthält `HELLO=world`.

  

---

  

## 4) Tool 2: `mcp-server` (ein Einstiegspunkt für *alle* MCP‑Server)

  

Du willst **nicht** pro MCP‑Server ein eigenes Script pflegen. Daher:

- pro Server eine `.conf`

- ein generischer Starter `mcp-server <name>`

  

### 4.1 Datei `~/.local/bin/mcp-server` erstellen

```bash

cat > ~/.local/bin/mcp-server <<'PY'

#!/usr/bin/env python3

import os, sys, shlex

from pathlib import Path

  

ALLOWED_KEYS = {

    "MODE",          # docker | local

    "ENV_PROFILE",   # z.B. obsidian

    "WORKDIR",       # optional

    "DOCKER_IMAGE",

    "DOCKER_ARGS",   # string -> shlex.split

    "LOCAL_CMD",

    "LOCAL_ARGS",    # string -> shlex.split

}

  

def parse_kv_conf(path: Path) -> dict:

    cfg = {}

    for raw in path.read_text(encoding="utf-8").splitlines():

        line = raw.strip()

        if not line or line.startswith("#"):

            continue

        if "=" not in line:

            raise ValueError(f"Ungültige Zeile (kein '='): {raw!r}")

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

  

    else:  # local

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

PY

  

chmod 755 ~/.local/bin/mcp-server

```

  

---

  

## 5) Ein neues Secret‑Profil anlegen (gilt für MCP *und* alles andere)

  

Beispiel: Profil `obsidian`

  

```bash

cat > ~/.config/secrets/env.d/obsidian.env <<'EOF'

# nur KEY=VALUE, keine Shell-Logik

OBSIDIAN_HOST=127.0.0.1

OBSIDIAN_API_KEY=...

EOF

  

chmod 600 ~/.config/secrets/env.d/obsidian.env

```

  

**Regeln (wichtig):**

- keine `export ...` Zeilen, nur `KEY=VALUE`

- keine `$(...)`, keine Backticks, keine Shell‑Funktionen

- Pro Profil klare Prefixe (z. B. `GITHUB_...`, `NOTION_...`) → verhindert Kollisionen

  

---

  

## 6) Einen MCP‑Server hinzufügen (docker ODER lokal)

  

Du erstellst **nur** eine `.conf`. Mehr nicht.

  

### 6.1 Docker‑Variante (Beispiel `obsidian`)

`~/.config/mcp/servers.d/obsidian.conf`

```bash

cat > ~/.config/mcp/servers.d/obsidian.conf <<'EOF'

MODE=docker

ENV_PROFILE=obsidian

DOCKER_IMAGE=mcp/obsidian

# Typisch für MCP: über stdio, interaktiv, rm nach exit

DOCKER_ARGS=--rm -i

EOF

chmod 600 ~/.config/mcp/servers.d/obsidian.conf

```

  

Test:

```bash

mcp-server obsidian

```

  

### 6.2 Lokale Variante (Beispiel `github` als Node‑MCP)

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

  

Die Idee: Du trägst **alle** MCP‑Server in `~/.claude.json` ein. Claude kann sie bei Bedarf starten.

Du musst dich vorher nicht entscheiden – die Server sind verfügbar.

  

Beispiel (Schema – passe Pfade/Servernamen an):

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

- Claude startet später `mcp-server <name>` → der liest `.conf` → lädt `.env` nur pro Prozess

  

Workflow:

```bash

claude

```

  

---

  

## 8) Übertragbar auf jede Art von Secrets (nicht nur MCP)

  

Du kannst `secret-run` für alles nutzen:

  

### 8.1 Beispiel: Curl mit API‑Token

`~/.config/secrets/env.d/myapi.env`

```bash

MYAPI_TOKEN=...

```

  

Aufruf:

```bash

secret-run myapi -- env | grep MYAPI_TOKEN

```

  

Wenn du das Token in einem Command verwendest, lass Expansion im Child‑Prozess passieren:

```bash

secret-run myapi -- bash -lc 'curl -H "Authorization: Bearer $MYAPI_TOKEN" https://example.com'

```

  

### 8.2 Beispiel: Docker (allgemein)

Für Docker‑Workflows ist `--env-file` sauber:

- Secrets bleiben außerhalb deiner Shell

- der Container bekommt sie nur für diesen Lauf

  

---

  

## 9) Security‑Checkliste (minimal, aber ernst gemeint)

  

1) **Rechte**

```bash

chmod 700 ~/.config/secrets ~/.config/secrets/env.d

chmod 600 ~/.config/secrets/env.d/*.env

chmod 700 ~/.config/mcp ~/.config/mcp/servers.d

chmod 600 ~/.config/mcp/servers.d/*.conf

```

  

2) **Kein Git**

- Stelle sicher, dass diese Pfade nie in Repos landen.

  

3) **Backups**

- Wenn du Backups machst: prüfe, dass sie nicht unverschlüsselt auf Cloud‑Drives landen.

- Wenn “unsicher absolut nicht akzeptabel” heißt: nutze OS‑Disk‑Verschlüsselung (Windows BitLocker) und sichere Zugriffe.

  

4) **Logging**

- Vermeide, Secrets in Logs auszugeben (`set -x`, Debug‑Flags, etc.).

  

---

  

## 10) Troubleshooting

  

### “Claude findet mcp-server nicht”

- Nutze absolute Pfade in `~/.claude.json` (empfohlen).

  

### “docker run bekommt keine Variablen”

- Prüfe, ob `.env` im Linux‑FS liegt, nicht `/mnt/c`

- Prüfe `chmod 600`

- Prüfe, ob `KEY=VALUE` korrekt ist (kein `export`, keine Sonderzeichen ohne Quotes)

  

### “lokaler MCP Server startet, aber bekommt keine Variablen”

- Teste:

```bash

secret-run <profil> -- env | head

```

- Prüfe `LOCAL_CMD`/`LOCAL_ARGS`

  

---

  

## 11) Quick‑Template zum Kopieren (neuer MCP‑Server)

  

### 11.1 Secret‑Profil

```bash

cat > ~/.config/secrets/env.d/NAME.env <<'EOF'

# KEY=VALUE

EOF

chmod 600 ~/.config/secrets/env.d/NAME.env

```

  

### 11.2 MCP‑Config (docker)

```bash

cat > ~/.config/mcp/servers.d/NAME.conf <<'EOF'

MODE=docker

ENV_PROFILE=NAME

DOCKER_IMAGE=IMAGE

DOCKER_ARGS=--rm -i

EOF

chmod 600 ~/.config/mcp/servers.d/NAME.conf

```

  

### 11.3 MCP‑Config (local)

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

  

### 11.4 In `~/.claude.json` eintragen

```json

"NAME": { "command": "/home/DEINUSER/.local/bin/mcp-server", "args": ["NAME"] }

```

  

---

  

## 12) Konsistenz‑Check (warum das logisch zusammenpasst)

  

- **Secrets** liegen zentral unter `~/.config/secrets/env.d/` und werden nie “global” geladen.

- **MCP‑Server** werden einheitlich über `mcp-server <name>` gestartet.

- `mcp-server` entscheidet anhand einer simplen `.conf`, ob **docker** oder **local**.

- Bei **docker**: Secrets gehen über `--env-file` direkt in den Container → keine Shell‑Exports.

- Bei **local**: `secret-run` injiziert Env nur in den Child‑Prozess via `execvpe` → Parent‑Shell bleibt sauber.

- Claude braucht nur die Startkommandos. Du startest nur **`claude`**.

  

---

  

Wenn du später stärkere "at rest" Security willst (ohne die Struktur zu ändern),

kannst du `~/.config/secrets/env.d/*.env` durch verschlüsselte Dateien ersetzen

und `secret-run`/`mcp-server` minimal anpassen (Decrypt → in‑memory → exec).



---



## 13) Claude Code Integration (SessionStart Hook)



Claude Code Sessions haben keinen Zugriff auf `secret-run` oder `.bashrc` Exports.
Der offizielle Weg: **`CLAUDE_ENV_FILE`** in SessionStart Hooks.



### Wie es funktioniert

1. Claude Code Session startet
2. SessionStart Hook (`~/.claude/hooks/session-env-loader.sh`) laeuft
3. Hook liest **alle** `~/.config/secrets/env.d/*.env`
4. Hook schreibt `export KEY=VALUE` in `$CLAUDE_ENV_FILE`
5. Alle nachfolgenden Bash-Commands sehen die Variablen



### Rollenverteilung

| Tool | Wann | Wie |
|------|------|-----|
| `secret-run` | Terminal (ausserhalb Claude Code) | `secret-run vault -- <cmd>` |
| `mcp-server` | MCP Server starten (Docker/lokal) | `mcp-server obsidian` |
| `session-env-loader.sh` | Claude Code Sessions (automatisch) | SessionStart Hook → CLAUDE_ENV_FILE |



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
- Referenz: ADR-003 in `projekt-automation-hub/docs/decisions/`