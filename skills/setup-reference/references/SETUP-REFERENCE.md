# SETUP-REFERENCE — Auto-generated: 2026-03-03 08:13

Generiert aus Live-System (`~/.claude/`). Nicht manuell bearbeiten.

---

## 1. Installierte Skills

| Skill | Beschreibung |
|-------|-------------|
| `_archived-secrets-blueprint` | (keine Beschreibung) |
| `claude-md-restructure` | (keine Beschreibung) |
| `github-init` | (keine Beschreibung) |
| `github-ops` | (keine Beschreibung) |
| `github-push` | (keine Beschreibung) |
| `github-status` | (keine Beschreibung) |
| `granola-export` | (keine Beschreibung) |
| `permission-audit` | (keine Beschreibung) |
| `prioritize-tasks` | (keine Beschreibung) |
| `project-doc-restructure` | (keine Beschreibung) |
| `project-init` | (keine Beschreibung) |
| `prompt-improver` | (keine Beschreibung) |
| `session-refresh` | (keine Beschreibung) |
| `setup-reference` | (keine Beschreibung) |
| `skill-creator` | (keine Beschreibung) |
| `task-orchestrator` | (keine Beschreibung) |
| `task-scheduler` | (keine Beschreibung) |
| `vault-manager` | (keine Beschreibung) |

**Gesamt:** 18 Skills

---

## 2. Agents

| Agent | Beschreibung |
|-------|-------------|
| `my-setup-guide` | (keine Beschreibung) |
| `obsidian-pilot` | (keine Beschreibung) |
| `prompt-architect` | (keine Beschreibung) |

**Gesamt:** 3 Agents

---

## 3. Commands (Slash-Commands)

| Command | Beschreibung |
|---------|-------------|
| `/knowledge-hub-sync` | (keine Beschreibung) |
| `/obsidian-sync` | (keine Beschreibung) |
| `/refresh-reference` | (keine Beschreibung) |
| `/run-next-tasks` | (keine Beschreibung) |
| `/vault-export` | (keine Beschreibung) |
| `/vault-work` | (keine Beschreibung) |

**Gesamt:** 6 Commands

---

## 4. Hooks (settings.json)

| Event | Hook-Script | Timeout |
|-------|-------------|---------|
| PreToolUse | `tool-call-logger.sh` | 5s |
| PreToolUse | `auto-approve-readonly.sh` | 5s |
| SessionStart | `session-env-loader.sh` | 10s |
| SessionStart | `session-handoff-loader.sh` | 15s |
| Notification | `notify.ps1` | defaults |

**Gesamt:** 5 Hooks

### Hook Details: session-env-loader.sh

| Feature | Erkannt |
|---------|---------|
| SOPS Decryption | ✅ |
| age Key-File | ✅ |
| MINGW/Windows Support | ✅ |
| .env-cache Fallback (Bug #15840) | ✅ |

**Secrets-Verzeichnis:** `${XDG_CONFIG_HOME:-~/.config}/secrets/env.d`

---

## 5. Permissions

### Allow-Rules

- `Edit`
- `Write`
- `Skill(*)`
- `Task(*)`
- `WebSearch`
- `WebFetch`
- `Bash(git *)`
- `Bash(gh *)`
- `Bash(source *)`
- `Bash(bash *)`
- `Bash(chmod *)`
- `Bash(echo *)`
- `Bash(env)`
- `Bash(env *)`
- `Bash(unset *)`
- `Bash(command *)`
- `Bash(which *)`
- `Bash(ls)`
- `Bash(ls *)`
- `Bash(tree *)`
- `Bash(find *)`
- `Bash(mkdir *)`
- `Bash(cp *)`
- `Bash(mv *)`
- `Bash(cat *)`
- `Bash(head *)`
- `Bash(tail *)`
- `Bash(wc *)`
- `Bash(wc)`
- `Bash(sort *)`
- `Bash(diff *)`
- `Bash(stat *)`
- `Bash(realpath *)`
- `Bash(readlink *)`
- `Bash(grep *)`
- `Bash(sed *)`
- `Bash(awk *)`
- `Bash(jq *)`
- `Bash(xargs *)`
- `Bash(python3 *)`
- `Bash(python *)`
- `Bash(date)`
- `Bash(date *)`
- `Bash(pwd)`
- `Bash(whoami)`
- `Bash(id)`
- `Bash(uname *)`
- `Bash(uname)`
- `Bash(npm *)`
- `Bash(npx *)`
- `Bash(node *)`
- `Bash(touch *)`
- `Bash(rm *)`
- `Bash(tee *)`
- `Bash(claude *)`
- `Bash($HOME/.claude/skills/*)`
- `Bash($HOME/.claude/hooks/*)`
- `Bash(cd *)`
- `Bash(test *)`
- `Bash(file *)`
- `Bash(xxd *)`
- `Bash(od *)`
- `Bash(export *)`
- `Bash(./run-headless-test.sh *)`
- `Bash(mount *)`
- `WebFetch(domain:blog.korny.info)`
- `WebFetch(domain:smartscope.blog)`
- `Bash(git commit:*)`
- `Bash(cat:*)`
- `Bash(echo NOT_INSTALLED:*)`
- `Bash(echo OP_EXE_NOT_FOUND:*)`
- `Bash(op:*)`
- `Bash(echo:*)`
- `Bash(age:*)`
- `Bash(sops:*)`
- `Bash(grep:*)`
- `Bash(head:*)`
- `Bash(curl:*)`
- `Bash(git add:*)`

### Deny-Rules

- `Read(./.env)`
- `Read(./.env.*)`
- `Read(./secrets/**)`
- `Bash(rm -rf *)`
- `Bash(rm -r *)`
- `Bash(git push --force *)`
- `Bash(git push -f *)`
- `Bash(git reset --hard *)`
- `TaskCreate`
- `TaskUpdate`
- `TaskList`
- `TaskGet`
- `TodoWrite`

---

## 6. Aktivierte Plugins

| Plugin | Quelle |
|--------|--------|
| `code-review` | claude-plugins-official |
| `commit-commands` | claude-plugins-official |
| `example-plugin` | claude-plugins-official |
| `explanatory-output-style` | claude-plugins-official |
| `feature-dev` | claude-plugins-official |
| `frontend-design` | claude-plugins-official |
| `hookify` | claude-plugins-official |
| `learning-output-style` | claude-plugins-official |
| `plugin-dev` | claude-plugins-official |
| `pr-review-toolkit` | claude-plugins-official |
| `ralph-wiggum` | claude-plugins-official |
| `security-guidance` | claude-plugins-official |
| `ai-visualisation` | local-plugins |

**Gesamt:** 13 Plugins

---

## 7. Globale Einstellungen

| Setting | Wert |
|---------|------|
| `model` | default |
| `outputStyle` | Executive Communication |
| `effortLevel` | medium |
| `preferredNotifChannel` | terminal_bell |

---

## 8. Secrets-Dateien (nur Namen)

| Datei | Groesse |
|-------|---------|
| `n8n.env` | 1204B |
| `obsidian.env` | 1883B |
| `vault.env` | 1637B |

---

## 9. Workflow-Dokumentation (Knowledge Hub)

| Dokument | Pfad | Groesse |
|----------|------|---------|
| `HOW-TO-PROJEKT-AUTOMATION.md` | `~/.claude/skills/setup-reference/references/` | 28KB |
| `PKM-WORKFLOW-VAULT-MANAGER.md` | `~/.claude/skills/setup-reference/references/` | 13KB |

---

## 9b. Hook Details

### session-env-loader.sh

| Feature | Erkannt |
|---------|---------|
| SOPS Decryption | ✅ |
| age Key-File | ✅ |
| MINGW/Windows-Kompatibilitaet | ✅ |

**Secrets-Verzeichnis:** `ENV_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/secrets/env.d"`
**Cache-Datei:** `CACHE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/secrets/.env-cache"`

---

## 9c. Erweiterte Dokumentation

Fuer detaillierte Anleitungen siehe:
- **HOW-TO-PROJEKT-AUTOMATION.md** (28KB) — Secrets Management, Session-Workflow, Skill-Nutzung
- Pfad: `~/.claude/skills/setup-reference/references/HOW-TO-PROJEKT-AUTOMATION.md`

---

## Bekannte Design-Regeln

1. **NIEMALS `cd "$OBSIDIAN_VAULT"`** in Command-Templates (CWD Cross-Over Bug)
2. **NIEMALS Secrets in Shell-Init** (`.bashrc`, `.zshrc`) — nur in `env.d/*.env` (SOPS+age verschluesselt)
3. **NIEMALS `vault:` Referenzen an Subagents** weiterreichen (Environment-Isolation)
4. **IMMER `git update-index --really-refresh`** vor `git status` auf 9P/WSL2-Mounts (WSL2-only, auf Native Windows nicht noetig)
5. **IMMER Obsidian Installer + App synchron halten** (Shim-Inkompatibilitaet)
6. **SSOT fuer Tasks ist PROJEKT.md** — nicht die Built-in Task API (deaktiviert)
7. **Skills < 500 Zeilen** — Details in `references/` Unterordner
8. **Phase 6 (MCP/RAG) ist obsolet** — CLI+Bash Hybrid deckt alle Usecases ab

---

## Config-Architektur (4 Layers)

```
Layer 1: SECRETS    -> ~/.config/secrets/env.d/*.env (SOPS+age verschluesselt: vault.env, n8n.env, obsidian.env)
Layer 2: GLOBAL     -> ~/.claude/skills/, ~/.claude/CLAUDE.md, ~/.claude/agents/
Layer 3: PROJECT    -> <PWD>/.claude/, <PWD>/CLAUDE.md, <PWD>/PROJEKT.md
Layer 4: SESSION    -> CLAUDE_ENV_FILE (SessionStart Hook, aktuell Bug #15840)
```

**Injection:** SessionStart Hook `session-env-loader.sh` liest `env.d/*.env` und schreibt in CLAUDE_ENV_FILE.
**Known Issue:** CLAUDE_ENV_FILE wird aktuell nicht von Claude Code bereitgestellt (Bug #15840). Workaround: manuelles `source`.

---

## Subagent-Isolation (Kritisch)

Sub-Agents (Task tool) erben KEINE Environment-Variablen aus dem SessionStart Hook.
- `vault:` Referenzen MUESSEN in der Main-Session aufgeloest werden
- Secrets in Main-Session lesen, Klartext an Subagent uebergeben
- Oder: `source ~/.config/secrets/.env-cache` in Bash (Workaround fuer Bug #15840)
- ~~`secret-run`~~ Deprecated (WSL2-Relikt, nie auf Windows portiert) — stattdessen SOPS+age + .env-cache

---

## Session-Continuous Workflow (Kurzreferenz)

```
START  -> Lese CLAUDE.md + PROJEKT.md -> /run-next-tasks -> Starte Ready Task
ARBEIT -> Update Task-Files + PROJEKT.md Status -> Token >65%? -> /session-refresh
ENDE   -> Commit -> /session-refresh -> Optional: Session-Handoff
```

---

## Dokumentations-Architektur (Drei Ebenen)

| Ebene | Datei | Inhalt |
|-------|-------|--------|
| Architecture | CLAUDE.md | Architektur, Decisions, Standards |
| Active State | PROJEKT.md | Task-Tabelle, Phase-Status, Known Issues |
| Audit Trail | docs/tasks/TASK-NNN-name.md | Detail pro Task, Acceptance Criteria |
| Handoffs | docs/handoffs/SESSION-HANDOFF-*.md | Session-Uebergabe (narrativ) |

---

## Secrets Management (SOPS+age)

**Verschluesselung:** Alle `env.d/*.env` Dateien sind mit [SOPS](https://github.com/getsops/sops) + [age](https://github.com/FiloSottile/age) verschluesselt.

**Key-Datei:** `~/.config/secrets/age-key.txt` (SOPS_AGE_KEY_FILE)

**Alltags-Befehle:**
```
sops edit ~/.config/secrets/env.d/vault.env    # Bearbeiten (entschluesselt in $EDITOR, verschluesselt beim Speichern)
sops -d ~/.config/secrets/env.d/vault.env      # Decrypt (stdout)
sops -e plaintext.env > encrypted.env          # Encrypt
```

**SessionStart-Workflow:**
```
Session startet → session-env-loader.sh Hook
  → Liest env.d/*.env → sops -d (decrypt)
  → Schreibt CLAUDE_ENV_FILE (ideal) ODER .env-cache (Fallback Bug #15840)
  → Ergebnis: Secrets als Env-Vars in Session verfuegbar
```

**Bash-Zugriff (Workaround Bug #15840):**
```bash
source ~/.config/secrets/.env-cache
```

**Erweiterte Dokumentation:** HOW-TO-PROJEKT-AUTOMATION.md (Section: Secrets Management)

---

## Windows/MINGW-Kompatibilitaet

**Erkennung:** `session-env-loader.sh` prueft `uname -s` auf `MINGW*` oder `MSYS*`.

**SOPS-Pfade:** SOPS unter MINGW/Git Bash versteht keine Unix-Pfade (`/c/Users/...`). Daher:
- `cygpath -w` konvertiert: `/c/Users/Jonas/.config/...` → `C:\Users\Jonas\.config\...`
- `SOPS_AGE_KEY_FILE` wird automatisch konvertiert
- Jeder `sops -d` Aufruf nutzt `sops_path()` Helper

**Pfad-Konventionen:**
| Kontext | Format | Beispiel |
|---------|--------|----------|
| Git Bash / MINGW | `/c/Users/...` | `/c/Users/Jonas/.config/secrets/` |
| SOPS / Windows-Tools | `C:\Users\...` | `C:\Users\Jonas\.config\secrets\` |
| WSL2 (alt) | `/mnt/c/Users/...` | `/mnt/c/Users/Jonas/.config/secrets/` |

**Automatische Translation:** `session-env-loader.sh` ersetzt `/mnt/c/` → `/c/` auf MINGW-Plattformen.

---

## Obsidian Vault-Integration

**Architektur:** CLI+Bash Hybrid (ADR-005)
- **CLI (Obsidian 1.12+)**: search, read, properties, tags, backlinks, vault health
- **Bash-Scripts**: vault-export.sh, vault-edit.sh, vault-base.sh, vault-date.sh, vault-copy.sh
- **Voraussetzung**: Obsidian App muss laufen (CLI kommuniziert via Named Pipe)

**Vault-Pfad:** `~/.config/secrets/env.d/vault.env` als `OBSIDIAN_VAULT="..."`.

**Use Cases:**
| UC | Funktion | Trigger |
|----|----------|---------|
| UC1 | Read-Only Vault-Referenz | `vault:dokumentname` |
| UC2 | Session-Export in Vault | `/vault-export` |
| UC3 | Vault-Dokument bearbeiten | `/vault-work` |

---

*Generiert: 2026-03-03 08:13 | Script: generate-reference.sh*
*Naechste Aktualisierung: /refresh-reference ausfuehren*
