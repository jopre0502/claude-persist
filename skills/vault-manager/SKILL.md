---
name: vault-manager
description: |
  Use this skill when the user references Vault documents via vault: prefix notation (e.g., "vault:ai-workflows"),
  requests searching the Vault, needs to work with Obsidian documents,
  asks about backlinks or related documents, or requests vault health information.
  Triggered on vault:document references for read-only context loading (UC1).
  Supports read-only access, document discovery, metadata extraction, backlinks, and vault health analysis.
  Keywords: vault, obsidian, vault-lookup, vault-read, vault-search, backlinks, related, orphans, deadends, unresolved, vault-health
model: sonnet
---

# Vault Manager — CLI-First

**One skill, one entry point.** Obsidian CLI (`obsidian.com`) ist Primary fuer alle Vault-Operationen. Filesystem (Glob + Read) ist Fallback wenn CLI nicht verfuegbar.

---

## Command Routing

| User Intent | CLI Command | Fallback |
|-------------|-------------|----------|
| `vault:name` | `search query="<name>"` → `read file="<path>"` | Glob + Read Tool |
| "suche im vault" | `search query="<text>"` | Glob |
| "zeige tags" | `tags all counts` | grep |
| "tag X finden" | `tag name="<tag>" verbose` | grep |
| "backlinks zu X" | `backlinks file="<name>"` | nicht verfuegbar |
| "base Bewerbungen" | `base:query path=<path>` | vault-base.sh |
| "daily note" | `daily:read` | Glob + Read |
| "property lesen" | `property:read name=<n> file=<path>` | YAML parse |
| "exportiere als Werk" | `create name=<n> template=<t>` + `append` | vault-export.sh |
| "bearbeite" | vault-edit.sh | — |
| "vault health" | `orphans`, `deadends`, `unresolved`, `vault info` | nicht verfuegbar |
| unbekannter command | `help` → retry | User informieren |

---

## Workflow

### 1. CLI Health Check (einmal pro Session)

```bash
obsidian.com version 2>&1; echo "EXIT:$?"
```
- Exit 0 + sinnvoller Output → **CLI verfuegbar**
- Exit != 0 → **Fallback-Modus** (kein weiterer CLI-Versuch in dieser Session)
- Meldung: "CLI nicht verfuegbar, nutze Filesystem-Fallback"

### 2. Document Discovery + Loading

**CLI-Pfad:**
```bash
obsidian.com search query="<name>"       # Discovery
obsidian.com read file="<path>"          # Content
obsidian.com properties file="<path>"    # Metadata (optional)
```

**Fallback-Pfad (CLI nicht verfuegbar):**
- Vault-Pfad via `$OBSIDIAN_VAULT` (Offline-Fallback, optional)
- Glob Tool: `<vault-path>/**/*<name>*.md` (nur Dateinamen-Match)
- Read Tool: Direkt auf `<vault-path>/<path>`
- Frontmatter: Manuell aus YAML-Block parsen

### 3. Fehlerbehandlung

Bei CLI-Fehlern: `obsidian.com help <command>` konsultieren, Syntax pruefen, retry.
Erst wenn help keine Loesung liefert → User den Fehler + help-Output melden.

**NIEMALS:** Parameter-Kombinationen raten oder experimentell ausprobieren.

---

## CLI Command Reference

Alle Commands mit Prefix `obsidian.com`. Obsidian App muss laufen (Named Pipe).

### Read & Search
```
read file=<name> | path=<path>
search query=<text> [path= limit= format=]
file file=<name> | path=<path>
files [folder= ext= total]
outline file=<name> [format=tree|md|json]
```

### Properties & Tags
```
properties [file= counts sort= format=]
tags [file= counts sort= format=]
tag name=<tag> [total verbose]
property:read name=<n> [file=<path>]
property:set name=<n> value=<v> file=<path>
property:remove name=<n> file=<path>
```

### Links & Vault Health
```
backlinks file=<name> [counts format=]
links file=<name> [total]
orphans [total all]
deadends [total all]
unresolved [total counts verbose format=]
aliases [file= format=]
```

### Bases
```
bases                                    — list all .base files
base:query path=<base-path> [view=<name>] [format=json]
base:views                               — views of currently active base
base:create file=<base-path> [name= content=]
```
**Hinweis:** `base:query path=...` arbeitet im Hintergrund (Base wird NICHT als Tab geoeffnet).

### Daily Notes
```
daily                                    — open daily note
daily:read                               — read today's content
daily:path                               — get file path
daily:append content=<text>
daily:prepend content=<text>
```

### Write Operations
```
create name=<n> [content= template= overwrite]
append file=<n> content=<text>
prepend file=<n> content=<text>
move file=<n> to=<path>
rename file=<n> name=<new>
delete file=<n> [permanent]
```

### Tasks
```
tasks [file= done todo status= verbose format=]
task ref=<path:line> [toggle done todo]
```

### System & Navigation
```
vault [info=name|path|files|size]
folders [folder= total]
open path=<path> [newtab]
version
plugins
bookmarks
recents
workspace
```

### Developer Tools
```
eval code="<javascript>"               — JS in Obsidian context
diff file=<path>
history / history:list / history:read / history:restore
sync / sync:status / sync:history
web url=<url>
```

---

## Bash Scripts (Write-Ops + Complex Filters)

Scripts unter `~/.claude/skills/vault-manager/scripts/`:

| Script | Zweck | Wann nutzen |
|--------|-------|-------------|
| `vault-export.sh <fileclass> <title>` | Export zu Vault (7 Fileclass-Typen) | Session-Output exportieren |
| `vault-edit.sh <name> [content]` | Edit mit Diff + Backup | Vault-Dokument bearbeiten |
| `vault-edit.sh --path <path>` | Edit mit bekanntem Pfad (Warm-Path) | Dokument bereits im Kontext |
| `vault-base.sh <name>` | Obsidian Base Query ausfuehren | Komplexe Filter-Queries |
| `vault-base.sh --list` | Alle .base Dateien listen | Discovery |
| `vault-date.sh --last <dur>` | Date-Range Filter | Dokumente nach Datum finden |
| `vault-copy.sh <source> [target]` | Copy/Move in Vault | Dateien verschieben |

---

## Configuration

### Prerequisites
- `obsidian.com` im PATH
- Obsidian App muss laufen (CLI kommuniziert via Named Pipe)
- `OBSIDIAN_VAULT` — Optional, Offline-Fallback (auto via SessionStart Hook aus `~/.config/secrets/env.d/vault.env`)

### Sub-Agent-Nutzung
Sub-Agents koennen CLI direkt nutzen (Named Pipe ist OS-Level, kein env var noetig).
Kein Bootstrap oder env-Prefixing erforderlich.

### Vault-Pfad-Resolution (Scripts)
Bash-Scripts nutzen `vault-lib.sh` mit `get_vault_path()`:
1. **CLI primary:** `obsidian.com vault` → Pfad (funktioniert auch in Sub-Agents)
2. **Env fallback:** `$OBSIDIAN_VAULT` (wenn CLI nicht verfuegbar)

### Setup-Pruefung
```bash
obsidian.com vault           # CLI + App OK? (liefert auch Vault-Pfad)
ls ~/.claude/skills/vault-manager/scripts/*.sh  # Scripts vorhanden?
```

---

## Triggering

| Pattern | Aktion |
|---------|--------|
| `vault:document-name` | Document lookup + context loading |
| `vault`, `obsidian` keywords | Skill activation |
| `backlinks`, `related`, `verlinkt` | Backlink analysis |
| `orphans`, `deadends`, `vault health` | Vault-wide graph analysis |
| `tags`, `tag suche` | Tag operations |

**Wichtig:** Kein `@` Symbol — `vault:` Prefix vermeidet Kollision mit Claude Code native `@file` Completion.

---

## Nicht verfuegbar im Fallback-Modus

Folgende Features funktionieren NUR mit laufender Obsidian App:
- Backlinks / Links (Incoming/Outgoing)
- Orphans / Deadends / Unresolved (Vault Health)
- Vault Info (Statistiken)
- Content-Search (Volltext innerhalb von Dokumenten)

Meldung: "Diese Funktion erfordert eine laufende Obsidian App."

---

## Status

- Read: ✅ CLI search + read + properties
- Export: ✅ vault-export.sh (7 Fileclass-Typen)
- Edit: ✅ vault-edit.sh + /vault-work Command
- Search: ✅ CLI tags/tag + vault-date.sh + vault-base.sh
- Links: ✅ CLI backlinks + links
- Health: ✅ CLI orphans + deadends + unresolved + vault stats

**Strategy:** CLI+Bash Hybrid (ADR-005). CLI fuer Read/Search/Tags, Bash fuer Export/Edit/Base/Date.

Last Updated: 2026-03-03
