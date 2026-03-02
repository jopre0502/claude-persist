---
name: secrets-blueprint
description: KISS-Blueprint für robustes Secrets-Handling (WSL2 Ubuntu) + MCP (docker & lokal) + Claude Code Integration (CLAUDE_ENV_FILE SessionStart Hook). Keine Secrets in Shell-Init. Keine Secrets in Tool-Konfigs. Nutze für Setup/Erweiterung/Review.
context: fork
user-invocable: true
---

# Secrets/MCP Blueprint (Operator-Regeln)

## Nicht verhandelbar
- Keine Secrets in `.bashrc`/`.zshrc` (kein globales `source`).
- Keine Secrets in `~/.claude.json` / Repo-Konfigs.
- Secrets nur pro Prozess (docker `--env-file` oder `secret-run` Wrapper).
- Keine Ausgabe/Logs mit Tokens.

## Vorgehen
1) Nutze `BLUEPRINT.md` in diesem Ordner als Schritt-für-Schritt Quelle der Wahrheit.
2) Erzeuge nur Templates/Platzhalter, setze passende Rechte (600/700).
3) Wenn Nutzer echte Werte einfügt: nur als Hinweis “hier eintragen”, niemals im Chat wiederholen.

## Ressourcen
- Lies bei Bedarf: `BLUEPRINT.md`