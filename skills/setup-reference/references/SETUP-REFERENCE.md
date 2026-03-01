# SETUP-REFERENCE — Auto-generated: 2026-03-01 17:37

Generiert aus Live-System (`~/.claude/`). Nicht manuell bearbeiten.

---

## 1. Installierte Skills

| Skill | Beschreibung |
|-------|-------------|
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
| `secrets-blueprint` | (keine Beschreibung) |
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
| `/obsidian-sync` | (keine Beschreibung) |
| `/refresh-reference` | (keine Beschreibung) |
| `/run-next-tasks` | (keine Beschreibung) |
| `/vault-export` | (keine Beschreibung) |
| `/vault-work` | (keine Beschreibung) |

**Gesamt:** 5 Commands

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

---

## 5. Permissions

### Allow-Rules

- `Edit`
- `Write`
- `Skill(*)`
- `Task(*)`
- `mcp__obsidian__*`
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
- `Bash(secret-run *)`
- `Bash(./run-headless-test.sh *)`
- `Bash(mount *)`
- `Bash(wsl.exe *)`
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

## Bekannte Design-Regeln

1. **NIEMALS `cd "$OBSIDIAN_VAULT"`** in Command-Templates (CWD Cross-Over Bug)
2. **NIEMALS Secrets in Shell-Init** (`.bashrc`, `.zshrc`) — nur in `env.d/*.env`
3. **NIEMALS `vault:` Referenzen an Subagents** weiterreichen (Environment-Isolation)
4. **IMMER `git update-index --really-refresh`** vor `git status` auf 9P/WSL2-Mounts
5. **IMMER Obsidian Installer + App synchron halten** (Shim-Inkompatibilitaet)
6. **SSOT fuer Tasks ist PROJEKT.md** — nicht die Built-in Task API (deaktiviert)
7. **Skills < 500 Zeilen** — Details in `references/` Unterordner
8. **Phase 6 (MCP/RAG) ist obsolet** — CLI+Bash Hybrid deckt alle Usecases ab

---

## Config-Architektur (4 Layers)

```
Layer 1: SECRETS    -> ~/.config/secrets/env.d/*.env (vault.env, n8n.env, obsidian.env)
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
- Oder: `secret-run <profil> -- <command>` im Bash-Befehl

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

*Generiert: 2026-03-01 17:37 | Script: generate-reference.sh*
*Naechste Aktualisierung: /refresh-reference ausfuehren*
