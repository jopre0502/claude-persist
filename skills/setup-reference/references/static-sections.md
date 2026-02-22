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
- Oder: `source ~/.config/secrets/env.d/<file>.env && ...` im Bash-Befehl

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
