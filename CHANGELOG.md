# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.0] - 2026-05-21

### Added

- **`skills/project-init` Phase 4 (Windows Quickstart)** — Optionaler vierter Schritt im `/project-init` Workflow. Nur auf Windows mit installiertem Windows Terminal aktiv (silent skip auf Linux/Mac via OS-Gate). Erzeugt drei Convenience-Artefakte:
  - **Projekt-Icon** `<PWD>\.claude-icon.ico` (multi-resolution 16/32/48/256, V2-squircle-Variante mit projekt-themed Symbol)
  - **Windows Terminal Profil** in `settings.json` mit UUID v4 `guid`, `tabColor` (matches Icon-Accent), `tabTitle`, `icon`, `commandline` (`pwsh -NoExit -Command "Set-Location ...; claude"`)
  - **Desktop-Verknuepfung** `<Desktop>\<project>.lnk` mit Target `wt.exe -p "<project>"` und Projekt-Icon
- **4 neue Helper-Skripte** unter `skills/project-init/scripts/`:
  - `quickstart-icon.py` — Pillow-basierter `.ico` Generator mit Meta-JSON Sidecar (`<PWD>\.claude-icon.meta.json`)
  - `quickstart-wt-profile.py` — WT `settings.json` Profile-Editor (UUID v4, Timestamped Backup `.bak.YYYYMMDD-HHMMSS`, JSON-Validierung beidseitig)
  - `quickstart-shortcut.ps1` — Desktop `.lnk` Creator via `WScript.Shell` COM
  - `quickstart-orchestrator.sh` — OS-gated Orchestrator mit strukturierten Exit-Codes (0/10-11/20-21/30-34/40), Force-Retry-Pattern, Stdout-JSON-Summary

### Changed

- **`skills/project-init/SKILL.md`** — Phase 4 dokumentiert: Trigger-Bedingungen, User-Interaction-Pattern (AskUserQuestion), Exit-Code-Tabelle mit Skill-Responses, Force-Retry-Pattern, Restart-Hinweis. Header "Three-Phase" -> "Multi-Phase" Execution.

### Notes

- **Public-Release-Safety:** OS-Gate macht Phase 4 fuer Linux/Mac-User unsichtbar. PowerShell-Helper wird im Snapshot mit-released, aber nur auf Windows ausgefuehrt.
- **Idempotenz:** Re-Run im selben PWD bricht bei Profil/`.lnk`-Konflikten mit Exit 32/34 ab (Skill-Layer prompt FORCE-Retry). FORCE-Retry erhaelt GUID-Identitaet beim Profile-Overwrite.
- **PowerShell-Lesson (aus Bug-Fix waehrend Entwicklung):** `Write-Error` unter `$ErrorActionPreference = 'Stop'` wirft terminating Exception VOR `exit N` Statement — alle expliziten Exit-Codes unreachable. Fix mittels `[Console]::Error.WriteLine()` fuer non-fatal stderr, `'Stop'` nur innerhalb COM-`try/catch`.

---

## [1.4.0] - 2026-05-19

### Added

- **`hooks/git-safety-guard.sh`** — Deterministischer PreToolUse-Hook auf Matcher `Bash` (5s Timeout). Drei Pattern-Checks via Bash-Regex auf tokenisierte Sub-Commands (Pipeline-Split bei `&&`, `||`, `;`, `|`):
  - **Hook A:** `git add` mit `-f` oder `--force` blockiert (`.gitignore` als Sicherheitsgrenze)
  - **Hook B:** `--no-verify` oder `--no-gpg-sign` auf `commit`/`push` blockiert (Hook-/Signatur-Skip)
  - **Hook C:** `git push --force`/`-f` auf `main`/`master` blockiert (`--force-with-lease` explizit erlaubt — modernes Best-Practice mit Upstream-Hash-Check)
- **Override-Mechanismus:** Inline-Marker `# CLAUDE-ALLOW-DESTRUCTIVE` am Command-Ende fuer dokumentierte Notfall-Bypaesse. Voller Audit-Trail in Bash-History.

### Changed

- **`.claude-plugin/plugin.json`** — Neuer PreToolUse-Hook-Eintrag (Matcher `Bash`). Plugin-Description erweitert um "deterministic git-safety guards".

### Notes

- **Test-Matrix:** 8/8 passing. A1/B1/C1 blocken korrekt, C4 (`--force-with-lease`) + C5 (Feature-Branch) + O1 (Override) erlaubt.
- **Silent-Allow bei Parse-Errors:** Hook darf nie selbst Tool-Use blockieren (Anti-Pattern: Hook-Bug blockt User).
- **API-Limitierung:** PreToolUse-Hook bekommt nur `tool_name` + `tool_input` (kein User-Prompt-Zugriff) — Override muss im Tool-Input kodiert sein.

---

## [1.3.0] - 2026-05-19

### Added

- **`scripts/detect-claude-vault.sh`** — Cache-First Vault-Detection mit 4 Modi (default/--global/--in-vault/--refresh). TTL-24h Cache in `~/.cache/claude-persist/vault-claude-root.txt`, ~3ms warm
- **`scripts/vault-handoff-backfill.sh`** — Idempotenter Backfill lokaler Session-Handoffs ins zentrale Vault-Verzeichnis (`_claude-pm/`). Collision-safe via size-diff Detection. Flags: `--dry-run`, `--all-projects`, `--force-newer`, `--quiet`
- **`commands/vault-backfill.md`** — Slash-Command `/persist:vault-backfill` fuer Notfall-Recovery oder Drift-Reconciliation
- **PROJECT-Doku Staleness-Check** in `session-refresh` Step 7b — Warnung bei `updated > 30 Tage` (kein Hard-Stop)

### Changed

- **`session-handoff-loader.sh`** — Vault-First-Read mit Local-Fallback. Liest Handoff-Content aus `<vault-root>/_claude-pm/<basename>` wenn PWD im Claude-Vault, sonst aus lokalem `docs/handoffs/`. Source-Hint `[Vault-SSOT: _claude-pm/]` im Output bei Vault-Hit
- **`session-refresh/SKILL.md` Step 7b** — Robust gegen Multi-Vault-Setups via Detection-Skript-Call. Vault-Write nutzt `cp` statt `obsidian.com create content=` (eliminiert LLM-Re-Render-Drift mechanisch). Hinweis zu CWD-Switch fuer Cross-Vault-Operationen ergaenzt
- **SSOT-Convention:** `_claude-pm/` ist SSOT fuer Handoffs (zentrale Konsultation), lokale `docs/handoffs/` bleiben Git-Audit-Trail

### Notes

- **Performance:** Detection ~3ms warm / ~560ms cold (Bash-Startup dominiert). Loader-Overhead durch Vault-Check: ~500ms
- **Backward-Compatibility:** Non-Vault-Projekte funktionieren unveraendert (Loader faellt zurueck auf lokale Files)
- **Empirie aus Hub-Reverse-Engineering:** Walk-up-Detection (`.obsidian/` + Pfad-Suffix `*/Claude`) schlaegt CLI-Check um ~500× (3ms vs 1.7s)

---

## [1.2.0] - 2026-05-19

### Changed

- **Repo-Aera:** Plugin-only Distribution (kein Knowledge-Hub mehr) — persoenliche Infrastruktur entfernt
- **Plugin-Layout:** Anthropic-Standard via `.claude-plugin/plugin.json` (statt Root-`plugin.json`)
- **Release-Workflow:** Kuratierter Snapshot-Release via `/pt:release-persist-public` Skill — kein Auto-Sync mehr
- **Tag-Konvention:** `persist-v<X.Y.Z>` mit Plugin-Prefix (zukunftssicher fuer Multi-Plugin-Repos)
- **`.gitignore`:** Whitelist-Strategie auf Plugin-Aera angepasst (pauschal `!skills/**` statt granular per Skill)

### Added

- **`skills/auto-task`** — Autonomous task execution via hook-based in-session loop mit Git-Checkpoints
- **`skills/session-workflow`** — Detailed session-continuous workflow reference (task management, phase completion, token budget)
- **`hooks/auto-task-loop-hook.sh`** — Hook fuer Auto-Task-Continuation
- **`scripts/`** — parse-next-action.sh, session-handoff-loader.sh, session-start-scheduler.sh (vorher in hooks/)
- **`commands/cancel-auto-task.md`** — Slash-Command zum Auto-Task-Stop

### Removed

- **Skills (gehoeren in andere Plugins):** github-init, github-ops, github-push, github-status, permission-audit, prompt-improver (alle ins `pt`-Plugin migriert)
- **Skills (deprecated):** skill-creator (ersetzt durch `plugin-dev:skill-development`)
- **Agents:** my-setup-guide (ins `pt`-Plugin migriert)
- **Hooks:** auto-approve-readonly, notify (ins `pt`-Plugin migriert), statusline.sh (gehoert nicht zu persist)
- **Top-Level:** `agents/`, `assets/`, `docs/`, `secrets-setup/`, `plugins/cache/**`, alte `CLAUDE.md`
- **Cache-Pollution:** `plugins/cache/local-plugins/**` (85+ Files Hub-Plugin-Cache-Reste)

### Fixed

- **Hooks → Scripts:** session-handoff-loader und session-start-scheduler waren faelschlicherweise in `hooks/` — jetzt in `scripts/` (referenziert via `${CLAUDE_PLUGIN_ROOT}/scripts/...` aus Plugin-Manifest)

## [1.1.0] - 2026-03-11

### Changed

- **Repository renamed** from `my-claude-knowledge-hub` to `claude-persist`
- **README rewritten** with Painpoint-First structure (Problem → Solution → What's Inside)
- **Tagline updated** to "Make Claude Code remember. Sessions that persist, tasks that finish, context that never dies."
- All internal URLs updated in CONTRIBUTING.md, SECURITY.md, CODE_OF_CONDUCT.md

### Added

- New skills: env-init, end-of-day, auto-task plugin
- GitHub Topics optimized for discoverability

## [1.0.0] - 2026-03-05

### Added

- **18 Skills** for session-continuous development (session-refresh, vault-manager, task-orchestrator, prompt-improver, project-init, skill-creator, and more)
- **2 Agents** (my-setup-guide, prompt-architect) for specialized autonomous tasks
- **6 Commands** (obsidian-sync, vault-export, run-next-tasks, sync-claude-persist, and more)
- **5 Hooks** (session-env-loader, notify, session-handoff-loader, tool-call-logger, startup)
- **1 Output Style** (Executive communication mode with German language preference)
- **10 Plugins** (code-review, commit-commands, hookify, pr-review-toolkit, feature-dev, frontend-design, plugin-dev, and more)
- Session-continuous workflow with automatic handoffs and token budget awareness
- Task orchestration with UUID-based tracking and dependency resolution
- Obsidian Vault integration (read, search, export) via CLI
- Secrets management via CLAUDE_ENV_FILE and env.d structure
- Community standard files: README, LICENSE (MIT), CONTRIBUTING, CODE_OF_CONDUCT, SECURITY
- GitHub Issue Templates (bug report, feature request)
- Secret scanning and push protection enabled

[1.2.0]: https://github.com/jopre0502/claude-persist/releases/tag/persist-v1.2.0
[1.1.0]: https://github.com/jopre0502/claude-persist/releases/tag/v1.1.0
[1.0.0]: https://github.com/jopre0502/claude-persist/releases/tag/v1.0.0
