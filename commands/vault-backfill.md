---
description: Synchronisiert lokale SESSION-HANDOFF Dateien in den Claude-Vault (_claude-pm/). Idempotent + collision-safe. Optional Cross-Project-Scope und Force-Newer-Reconciliation.
---

# /persist:vault-backfill

Manual-Override-Command fuer Notfall-Recovery oder periodische Pruefung der Vault-Konsistenz.

## Was es macht

Scannt das aktuelle Projekt (oder optional alle Vault-Subprojekte) nach lokalen
`SESSION-HANDOFF-*.md` Dateien und kopiert fehlende Dateien ins zentrale
`_claude-pm/` Verzeichnis im Claude-Vault.

## Wann verwenden

- **Notfall-Recovery:** Vault-Restore aus Backup hat Handoffs verloren
- **Drift-Pruefung:** Nach laengerer Offline-Phase oder Multi-Device-Sync-Issues
- **Migration:** Neue Projekte erstmalig in den Vault einbinden

Im Normalbetrieb ist `/persist:vault-backfill` **NICHT noetig** — `session-refresh`
Step 7b haelt den Vault automatisch synchron (Drift-Free `cp`-basiert).

## Usage

```bash
# Pruefen was kopiert wuerde (Dry-Run, sicher)
/persist:vault-backfill --dry-run

# Aktuelles Projekt synchronisieren (idempotent)
/persist:vault-backfill

# Alle Vault-Subprojekte (Vorsicht: Namespace-Kollisionen moeglich)
/persist:vault-backfill --all-projects --dry-run

# Reconcile von Drift: lokal-neuer ueberschreibt Vault
/persist:vault-backfill --force-newer
```

## Verhalten

| Szenario | Aktion |
|----------|--------|
| Vault-Datei fehlt | `cp` lokal → `_claude-pm/` |
| Vault-Datei existiert, gleicher Size | Skip (idempotent) |
| Vault-Datei existiert, anderer Size | Collision-Warning, Skip — `--force-newer` zum Override |
| PWD ausserhalb Claude-Vault | Exit 1 mit Hinweis |

## Execution

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/vault-handoff-backfill.sh "$@"
```

## Output-Beispiel

```text
=== Vault-Handoff-Backfill ===
Vault-Root:  /c/Development/Projects/Claude
Target-Dir:  /c/Development/Projects/Claude/_claude-pm
Mode:        LIVE
Scope:       CURRENT PWD

  COPY: projekt-automation-hub/SESSION-HANDOFF-2026-05-19-S240.md -> _claude-pm/
  projekt-automation-hub: copied=1 existing=40 collision=0

=== Backfill abgeschlossen ===
```

## Exit-Codes

- `0` — Success (auch wenn nichts zu kopieren war)
- `1` — Vault nicht detektierbar (kein Claude-Vault-Registriert oder PWD ausserhalb)
- `2` — `_claude-pm/` existiert nicht im Vault
- `3` — Collisions skipped (manuelle Pruefung empfohlen oder `--force-newer`)
