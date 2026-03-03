---
name: vault-work
description: Load a Vault document for editing, work with it in session, then save changes back with diff preview
model: sonnet
---

# /vault-work Command

Laedt ein Vault-Dokument, stellt es in der Session bereit, und schreibt Aenderungen mit Diff-Preview zurueck.

## Usage

```
/vault-work <dokumentname>
```

**Beispiele:**
```
/vault-work ai-workflows
/vault-work "PKM-Workflows mit Claude"
```

## Workflow

Wenn der User `/vault-work` aufruft:

### 1. Dokument laden

Finde und lade das Dokument via Obsidian CLI (Voraussetzung: Obsidian App muss laufen):

1. Falls `$ARGUMENTS` leer ist, frage den User: "Welches Dokument moechten Sie bearbeiten?"

2. **Discovery:** Nutze Obsidian CLI fuer die Suche:
   ```bash
   obsidian.com search "$ARGUMENTS"
   ```
   - Ergebnis: Dateipfad(e) im Vault

3. **Content laden:** Nutze Obsidian CLI zum Lesen:
   ```bash
   obsidian.com read "Dokumentname"
   ```
   - Liest Inhalt inkl. Frontmatter
   - Zeigt Metadaten + Content an

**Fallback** (wenn Obsidian nicht laeuft): Vault-Pfad via `$OBSIDIAN_VAULT` (Offline-Fallback), dann Glob Tool mit Pattern `**/*$ARGUMENTS*.md`, dann Read Tool.

### 2. Dokument anzeigen

Zeige dem User:
- Dateiname und Pfad (relativ zum Vault)
- Frontmatter-Metadaten (fileClass, erstellt, tags)
- Aktuellen Content

Dann frage: "Was moechten Sie an diesem Dokument aendern?"

### 3. User bearbeitet

Der User beschreibt die gewuenschten Aenderungen. Claude hilft beim:
- Ueberarbeiten von Texten
- Ergaenzen von Sektionen
- Umstrukturieren von Inhalten
- Aktualisieren von Metadaten

### 4. Aenderungen speichern

Nachdem der User die Aenderungen beschrieben hat, nutze vault-edit.sh:

```bash
# Zuerst Dry-Run (Diff zeigen) — nutze --path mit dem bereits bekannten Pfad
echo "<neuer-content>" | ~/.claude/skills/vault-manager/scripts/vault-edit.sh --dry-run --path "$BEKANNTER_PFAD"

# Nach Bestaetigung: Real write
echo "<neuer-content>" | ~/.claude/skills/vault-manager/scripts/vault-edit.sh --path "$BEKANNTER_PFAD"
```

**Wichtig:**
- IMMER zuerst --dry-run zeigen (Diff-Preview)
- Erst nach User-Bestaetigung real schreiben
- Content als Body (nach Frontmatter) uebergeben — Frontmatter wird automatisch beibehalten
- vault-edit.sh aktualisiert `modified` Frontmatter automatisch

### 5. Bestaetigung

Zeige dem User:
- Zusammenfassung der Aenderungen
- Pfad zum aktualisierten Dokument
- Hinweis: "Backup erstellt als .bak"

## Warm-Path (Dokument bereits geladen)

Wenn das Vault-Dokument bereits in dieser Session geladen wurde (Pfad und Content bekannt):

1. **NICHT** erneut CLI Search oder Read aufrufen
2. Direkt vault-edit.sh mit `--path` Flag nutzen:

```bash
# Diff-Preview
echo "<neuer-content>" | ~/.claude/skills/vault-manager/scripts/vault-edit.sh --dry-run --path "$BEKANNTER_PFAD"

# Nach Bestaetigung: Real write
echo "<neuer-content>" | ~/.claude/skills/vault-manager/scripts/vault-edit.sh --path "$BEKANNTER_PFAD"
```

**Wann Warm-Path nutzen:**
- User hat `vault:dokument` geladen, Aenderungen diskutiert, und will jetzt speichern
- Pfad wurde schon von CLI Search zurueckgegeben (in dieser Session)
- Dokument wurde bereits gelesen und Content ist im Kontext

**Wann Cold-Start nutzen:**
- Neues Dokument, erstmalig in dieser Session
- Pfad ist nicht bekannt

## Fehlerbehandlung

### Vault nicht erreichbar

```
Vault-Pfad nicht ermittelt.

Loesung:
1. Obsidian App starten (CLI liefert Pfad automatisch)
2. Offline-Fallback: export OBSIDIAN_VAULT="/pfad/zu/deinem/vault"
```

### Dokument nicht gefunden

```
Dokument nicht gefunden: <name>

Tipps:
1. Pruefe die Schreibweise
2. Nutze `obsidian.com search` fuer die Suche
3. Das Dokument muss im Vault existieren
```

## Technische Details

- **Discovery:** `obsidian.com search` CLI (Obsidian muss laufen)
- **Read:** `obsidian.com read` CLI (Obsidian muss laufen)
- **Edit-Script:** `~/.claude/skills/vault-manager/scripts/vault-edit.sh`
- **Zielordner:** Bestehendes Dokument wird in-place aktualisiert
- **Backup:** Automatisch als `.bak` vor Ueberschreiben
- **Frontmatter:** `modified:` wird automatisch auf aktuelles Datum gesetzt

## Referenzen

- `~/.claude/skills/setup-reference/references/PKM-WORKFLOW-VAULT-MANAGER.md` - Vault-Integration-Dokumentation (Knowledge Hub)
- `~/.claude/skills/vault-manager/scripts/vault-edit.sh` - Edit-Script
- `~/.claude/commands/vault-export.md` - Export-Command (aehnliches Pattern)

---

**Erstellt:** 2026-02-10 (TASK-016)
**Aktualisiert:** 2026-03-02 (TASK-061 — MCP Tools → Obsidian CLI)
