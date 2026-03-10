# SETUP-REFERENCE — Auto-generated: 2026-03-10 17:26

Generiert aus Live-System (`~/.claude/`). Nicht manuell bearbeiten.

---

## 1. Installierte Skills

| Skill | Beschreibung |
|-------|-------------|
| `claude-md-restructure` | Optimize CLAUDE.md files for size (<8KB target) while preserving workflow-block.txt injection and Session-Continuous ... |
| `end-of-day` | (keine Beschreibung) |
| `env-init` | This skill should be used when the user wants to initialize .env and .env.example files with 1Password op:// secret references. Covers setting up secrets, configuring environment variables, adding 1Password integration to a project, or generating op:// reference templates. Relevant for: 'set up .env', 'initialize secrets', 'add 1Password to project', 'configure environment variables', 'create op:// references'. |
| `generate-pwd-howto` | (keine Beschreibung) |
| `github-init` | Verknüpft aktuelles Working Directory mit GitHub-Repo und erstellt Pro-Projekt Config (.claude/github.json). Use whe... |
| `github-ops` | Shared Library für GitHub-Operations Skills. Enthält lib/, assets/, references/. NICHT direkt aufrufen. Nutze statt... |
| `github-push` | Committed und pusht alle Änderungen zum konfigurierten GitHub-Repo mit Sync-Message (Sync YYYY-MM-DD-NN). Use when: ... |
| `github-status` | Zeigt GitHub Sync-Status: letzter Commit, ausstehende Änderungen, Repo-Info. Use when: User wants to check sync stat... |
| `granola-export` | TODO: Complete and informative explanation of what the skill does and when to use it. Include WHEN to use this skill - specific scenarios, file types, or tasks that trigger it. |
| `permission-audit` | Analysiert Tool-Call-Logs gegen Permission Allow/Deny-Regeln. Zeigt welche Calls nicht von Allow-Rules gedeckt waren.... |
| `prioritize-tasks` | Analysiert und priorisiert Tasks in PROJEKT.md basierend auf Dependencies, Effort und Known Issues. Berechnet Priorit... |
| `project-doc-restructure` | Transform project documentation to follow session-continuous patterns with Inverted Pyramid structure. Use when worki... |
| `project-init` | Complete session-continuous project initialization infrastructure. Creates CLAUDE.md, PROJEKT.md, task tracking syste... |
| `prompt-improver` | Analysiert und verbessert Prompt-Entwürfe für Claude 4.x Modelle (Sonnet, Opus, Haiku). Wendet offizielle Anthropic Best Practices an: XML-Strukturierung, explizite Anweisungen, Kontext/Motivation (WARUM), Variablen {{NAME}}, Extended Thinking Konfiguration, Tool Use Optimierungen und modell-spezifische Empfehlungen. Nutze diesen Skill wenn du einen Prompt siehst der verbessert werden sollte, oder wenn explizit nach Prompt-Optimierung gefragt wird. |
| `session-refresh` | **SESSION END / HIGH TOKEN BUDGET** - Use when token budget >65% or before ending a session. Complete session refresh... |
| `setup-reference` | Generiert eine vollstaendige SETUP-REFERENCE.md aus dem Live-System (~/.claude/). Scannt Skills, Agents, Commands, Ru... |
| `skill-creator` | Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an existing skill) that extends Claude's capabilities with specialized knowledge, workflows, or tool integrations. |
| `task-orchestrator` | Orchestriert strukturierte Task-Ausführung mit Subagent Delegation. Trigger-Patterns (automatisch aktivieren bei): -... |
| `task-scheduler` | Automatically orchestrate and execute project tasks from PROJEKT.md. Use this skill when you want to analyze pending ... |
| `vault-manager` | Use this skill when the user references Vault documents via vault: prefix notation (e.g., "vault:ai-workflows"), requ... |

**Gesamt:** 20 Skills

---

## 2. Agents

| Agent | Beschreibung |
|-------|-------------|
| `my-setup-guide` | Beantwortet Fragen zur persoenlichen Claude Code Installation, Konfiguration, Skills, Workflows und Conventions. Kenn... |

**Gesamt:** 1 Agents

---

## 3. Commands (Slash-Commands)

| Command | Beschreibung |
|---------|-------------|
| `/knowledge-hub-sync` | Knowledge Hub (~/.claude/) zu GitHub committen und pushen - von jedem Working Directory |
| `/obsidian-sync` | Obsidian Vault zu GitHub pushen - funktioniert von jedem Working Directory |
| `/refresh-reference` | Generiert SETUP-REFERENCE.md aus dem Live-System (~/.claude/). Scannt Skills, Agents, Commands, Hooks, Permissions, Plugins und zeigt Inventar-Zusammenfassung. |
| `/run-next-tasks` | Manually trigger the task scheduler to identify and start ready tasks |
| `/vault-export` | Export content to Obsidian Vault with Fileclass-based templates |
| `/vault-work` | Load a Vault document for editing, work with it in session, then save changes back with diff preview |

**Gesamt:** 6 Commands

---

## 3b. Rules (~/.claude/rules/)

Rules werden automatisch in den Kontext geladen. Optional mit `paths:` Frontmatter fuer dateityp-spezifische Aktivierung.

| Rule | Scope | Beschreibung |
|------|-------|-------------|
| `vault-access` | Global | Vault Access via Obsidian CLI |

**Gesamt:** 1 Rules

---

## 4. Hooks (settings.json)

| Event | Hook-Script | Timeout |
|-------|-------------|---------|
| PreToolUse | `tool-call-logger.sh` | 5s |
| PreToolUse | `auto-approve-readonly.sh` | 5s |
| SessionStart | `session-handoff-loader.sh` | 15s |
| Notification | `notify.sh` | defaults |

**Gesamt:** 4 Hooks

---

## 5. Permissions

### Allow-Rules

- `Edit`
- `Write`
- `Skill(*)`
- `Task(*)`
- `Agent(*)`
- `Bash(~/.claude/*)`
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
- `Bash(op *)`
- `Bash(grep:*)`
- `Bash(head:*)`
- `Bash(curl:*)`
- `Bash(git add:*)`

### Deny-Rules

- `Read(.env)`
- `Read(.env.*)`
- `Read(./secrets/**)`
- `Bash(rm -rf *)`
- `Bash(rm -r *)`
- `Bash(git push --force *)`
- `Bash(git push -f *)`
- `Bash(git reset --hard *)`
- `Bash(git add -f *)`
- `Bash(git add --force *)`
- `Bash(git add * -f *)`
- `Bash(git add * --force *)`
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
| `auto-task` | local-plugins |
| `ai-visualisation` | local-plugins |

**Gesamt:** 14 Plugins

---

## 7. Globale Einstellungen

| Setting | Wert |
|---------|------|
| `model` | default |
| `outputStyle` | Executive Communication |
| `effortLevel` | default |
| `preferredNotifChannel` | terminal_bell |

---

## 8. Secrets-Dateien (nur Namen)

| Datei | Groesse |
|-------|---------|
| `n8n.env` | 1204B |
| `vault.env` | 1637B |

---

## 9. Workflow-Dokumentation (Knowledge Hub)

| Dokument | Pfad | Groesse |
|----------|------|---------|
| `HOW-TO-OBSIDIANCLAUDE.md` | `~/.claude/skills/setup-reference/references/` | 8KB |
| `HOW-TO-PROJEKT-AUTOMATION-HUB.md` | `~/.claude/skills/setup-reference/references/` | 8KB |
| `HOW-TO-PROJEKT-AUTOMATION.md` | `~/.claude/skills/setup-reference/references/` | 28KB |
| `PKM-WORKFLOW-VAULT-MANAGER.md` | `~/.claude/skills/setup-reference/references/` | 13KB |

---

## 9b. Hook Details

(session-env-loader.sh nicht gefunden)

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

*Generiert: 2026-03-10 17:26 | Script: generate-reference.sh*
*Naechste Aktualisierung: /refresh-reference ausfuehren*
