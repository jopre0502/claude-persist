# PKM-WORKFLOW - Obsidian Vault Integration

**SSOT für Claude Code Integration mit User's Obsidian Vault**

*Erstellt: 2026-02-04 | Aktualisiert: 2026-03-03 (TASK-041 CLI-first Vault Path)*

---

## Quick Reference: Verfügbare Tools

### CLI Commands (Obsidian 1.12+, Obsidian App muss laufen)

| Operation | Command | Status |
|-----------|---------|--------|
| **Vault durchsuchen** | `obsidian.com search query="<name>" format=json` | ✅ Phase 5b |
| **Dokument lesen** | `obsidian.com read file="<path>"` | ✅ Phase 5b |
| **Metadata lesen** | `obsidian.com properties file="<path>" format=yaml` | ✅ Phase 5b |
| **Alle Tags auflisten** | `obsidian.com tags all counts` | ✅ Phase 5b |
| **Tag-Suche** | `obsidian.com tag name="<tag>" verbose` | ✅ Phase 5b |
| **Backlinks (eingehend)** | `obsidian.com backlinks path="<path>" [counts\|total]` | ✅ Phase 5b |
| **Links (ausgehend)** | `obsidian.com links path="<path>" [total]` | ✅ Phase 5b |
| **Orphans** | `obsidian.com orphans [total\|all]` | ✅ Phase 5b |
| **Deadends** | `obsidian.com deadends [total\|all]` | ✅ Phase 5b |
| **Unresolved Links** | `obsidian.com unresolved [total\|counts\|verbose]` | ✅ Phase 5b |
| **Vault Stats** | `obsidian.com vault [info=name\|path\|files\|folders\|size]` | ✅ Phase 5b |

**Hinweis:** CLI nutzt Obsidians internen Index (schnell, keine Filesystem-Scans). Bei großen Outputs File-Redirect verwenden: `obsidian.com search query="X" > /tmp/out.txt 2>&1; cat /tmp/out.txt`

### Bash Scripts (`~/.claude/skills/vault-manager/scripts/`)

| Operation | Script | Status |
|-----------|--------|--------|
| **Datum-Filter** | `vault-date.sh --last 7d` | ✅ Phase 4 |
| **Base Query** | `vault-base.sh <name>` | ✅ Phase 4 |
| **Dokument exportieren** | `vault-export.sh <Fileclass> <Titel>` | ✅ UC2 |
| **Datei kopieren/verschieben** | `vault-copy.sh <source> [target]` | ✅ Phase 5b (CLI Discovery) |
| **Dokument bearbeiten** | `vault-edit.sh <name> [content]` | ✅ UC3 |

**Skill:** `vault-manager` (auto-triggered via `vault:` Prefix)
**Vault-Pfad:** CLI-first (`obsidian.com vault`), `$OBSIDIAN_VAULT` nur Offline-Fallback. Scripts nutzen `vault-lib.sh`.

### Claude Code Commands

| Command | Funktion | Trigger |
|---------|----------|---------|
| `/vault-export` | Interaktiver Export in Vault | Manuell oder "exportiere in Vault" |
| `/vault-work` | Dokument laden + bearbeiten + speichern | Manuell oder "bearbeite vault:name" |
| `/obsidian-sync` | Vault Push-only Backup zu GitHub | Manuell |

**Usage:** `/vault-export [Fileclass] [Titel]` oder interaktiv ohne Parameter

---

## Vault-Struktur (PARA-basiert)

```
$OBSIDIAN_VAULT/
├── 00-Inbox/           # Quick Notes (zu kategorisieren)
├── 01-Dashboard/       # Übersichten, keine Inhalte (Base-Dokumente)
├── 02-Projekte/        # Projekt-Index (KEINE Claude/Software-Projekte!)
├── 03-Spaces/          # Feste Kategorien (Gesundheit, Familie, Finanzen)
├── 04-RESSOURCEN/      # ⭐ HAUPTORDNER für alle Inhalte
│   ├── Memos_Learnings/
│   ├── Bewerbungen/
│   └── ... (weitere Unterordner)
└── 09-System/          # Konfiguration + Templates
    └── Plugins/Templater/Templates/
```

### Ordner-Zweck

| Ordner | Zweck | Claude-Relevant? |
|--------|-------|------------------|
| `00-Inbox` | Unsortierte Quick Notes | ❌ Nicht für Claude-Output |
| `01-Dashboard` | Übersichten, MOCs | ❌ Nicht für Claude-Output |
| `02-Projekte` | Projekt-Indizes | ❌ Explizit ausgeschlossen |
| `03-Spaces` | Feste Lebensbereiche | ❌ Referenzierend, keine Inhalte |
| **`04-RESSOURCEN`** | **Alle inhaltlichen Dokumente** | ✅ **Claude-Output-Ziel** |
| `09-System` | Templates, Konfiguration | 📖 Lesen (Templates) |

---

## Fileclass-System

Der Vault nutzt das **Fileclass-Plugin** für strukturierte Kategorisierung.

### Verfügbare Typen

| Fileclass | Beschreibung | Trigger-Phrasen |
|-----------|--------------|-----------------|
| **Werk** | Fertige Inhalte, Zusammenfassungen | "Fasse zusammen", "als Werk", "Artikel" |
| **Memo** | Gedanken, Notizen, Learnings | "Notiere", "Memo", "halte fest" |
| **Bewerbung** | CRM für Job-Bewerbungen | "Bewerbung anlegen", "Stelle erfassen" |
| **Person** | Kontakte, Netzwerk | "Person anlegen", "Kontakt" |
| **Unternehmen** | Firmen, Arbeitgeber | "Unternehmen dokumentieren" |
| **Produkt** | Produkte, Reviews | "Produkt dokumentieren" |
| **Ort** | Locations, Adressen | "Ort anlegen" |

### Frontmatter-Schema

Alle Dokumente starten mit YAML-Frontmatter:

```yaml
---
fileClass: <Typ>           # Pflicht: Exakter Fileclass-Name
erstellt: YYYY-MM-DD       # Pflicht: Erstellungsdatum
tags: <typ_lowercase>      # Pflicht: Haupt-Tag
space:                     # Optional: ["[[Space-Name]]"]
projekt:                   # Optional: ["[[Projekt-Name]]"]
aliases:                   # Optional: Alternative Namen

# Cross-Links (optional)
person:                    # ["[[Person-Name]]"]
unternehmen:               # ["[[Unternehmen-Name]]"]
werk:                      # ["[[Werk-Name]]"]
memo:                      # ["[[Memo-Name]]"]
ref_ressource:             # ["[[Ressource-Name]]"]

# Typ-spezifische Properties...
---
```

**Link-Format:** `["[[Name]]"]` (Array mit Obsidian-Wiki-Links)

---

## Claude-Workflow: Dokument erstellen

### Ablauf

```
1. User: "Fasse das als Werk zusammen für meinen Vault"
           ↓
2. Claude: Erkennt Typ "Werk" aus Kontext
           ↓
3. Claude: Lädt Schema aus fileclass-mapping.json
           ↓
4. Claude: Generiert YAML-Frontmatter + Content
           ↓
5. Claude: Schreibt nach $OBSIDIAN_VAULT/04 RESSOURCEN/{name}.md
```

### Beispiel: Werk erstellen

**User-Input:**
> "Fasse unsere Diskussion über PKM-Workflows als Werk für meinen Vault zusammen."

**Claude-Output:**

```markdown
---
fileClass: Werk
erstellt: 2026-02-04
tags: werk
space:
projekt: ["[[ObsidianClaude]]"]
aliases:
person:
memo:
unternehmen:
werk:
ref_ressource:

status: zusammengefasst
url:
typ: Zusammenfassung
jahr_gelesen: 2026

---
# [[PKM-Workflows mit Claude Code]]

## Zusammenfassung

{Inhalt der Zusammenfassung}

---
## Referenzen

```

**Dateiname:** `PKM-Workflows mit Claude Code.md`
**Speicherort:** `$OBSIDIAN_VAULT/04 RESSOURCEN/`

---

## Was Claude NICHT generiert

| Element | Grund |
|---------|-------|
| Templater-Syntax (`<%* ... %>`) | Nur für Obsidian-interne Nutzung |
| DataviewJS-Blöcke | Existieren bereits in Templates, Claude dupliziert nicht |
| Obsidian-Plugin-Syntax | Inkompatibel mit externer Generierung |

---

## Konfiguration

### Environment Variable

```bash
# In ~/.config/secrets/env.d/vault.env
OBSIDIAN_VAULT="/mnt/c/Users/Jonas/Google Drive/01. Prechtel_Documents/250_Obsidian/PKM"
```

### Fileclass-Mapping

**Pfad:** `docs/tasks/TASK-012/artifacts/fileclass-mapping.json`

Enthält vollständige Schemas für alle Fileclass-Typen mit:
- Properties (required/optional)
- Content-Sections
- Trigger-Phrasen

---

## Integration mit UC1-3

| Use Case | Vault-Interaktion |
|----------|-------------------|
| **UC1** (Read) | Liest via CLI (`obsidian.com search` + `read`) oder Glob/Read Fallback |
| **UC2** (Export) | Schreibt nach `04 RESSOURCEN/` mit Fileclass-Schema (vault-export.sh) |
| **UC3** (Edit) | Lädt via CLI + aktualisiert via vault-edit.sh |

---

## Operative Workflows

### UC1: Vault-Dokument lesen (Read-Only)

**Trigger:** User nutzt `vault:` Prefix (z.B. `vault:ai-workflows`) oder sagt "aus meinem Vault"

**Workflow (CLI — Obsidian muss laufen):**
```bash
# 1. Dokument suchen (via Obsidian Index)
obsidian.com search query="projektname" format=json
# Output: Matches mit Pfad + Context-Snippets

# 2. Dokument lesen
obsidian.com read file="04 RESSOURCEN/projektname.md"
# Output: Vollständiger Dateiinhalt

# 3. Metadata lesen (optional)
obsidian.com properties file="04 RESSOURCEN/projektname.md" format=yaml
# Output: YAML Frontmatter (tags, status, created, etc.)
```

**Fallback (wenn Obsidian nicht läuft):**
```bash
# Glob Tool direkt auf $OBSIDIAN_VAULT
Glob: **/*projektname*.md
Read: <gefundener Pfad>
```

**Beispiel-Session:**
```
User: "Nutze vault:ai-workflows als Kontext für diese Diskussion"
Claude: [obsidian.com search query="ai-workflows"] → findet Dokument
Claude: [obsidian.com read file="<path>"] → lädt Inhalt
Claude: "Ich habe das Dokument 'AI Workflows' geladen. Es enthält..."
```

---

### UC2: Dokument in Vault exportieren

**Trigger:** User sagt "Fasse als {Typ} zusammen für meinen Vault"

**Tool:** `vault-export.sh`

**Syntax:**
```bash
vault-export.sh [--dry-run] <Fileclass> <Titel> [Content]

# Fileclasses: Werk, Memo, Bewerbung, Person, Unternehmen, Produkt, Ort
```

**Beispiele:**

```bash
# Werk erstellen (Zusammenfassung)
vault-export.sh Werk "PKM-Workflows mit Claude" "## Zusammenfassung\n\nInhalt..."

# Memo erstellen (Learning)
vault-export.sh Memo "Session-Learning 2026-02-04" "Wichtiges Learning..."

# Person anlegen (Kontakt)
vault-export.sh Person "Max Mustermann" "Kontext zum Kontakt..."

# Dry-Run (nur anzeigen, nicht schreiben)
vault-export.sh --dry-run Werk "Test" "Test-Content"
```

**Vollständiger Workflow:**
```
User: "Fasse unsere Diskussion als Werk für meinen Vault zusammen"

Claude:
1. Erkennt Fileclass "Werk" aus Kontext
2. Generiert Titel aus Diskussionsthema
3. Erstellt Zusammenfassung
4. Ruft auf: vault-export.sh Werk "Titel" "Zusammenfassung..."
5. Bestätigt: "Dokument erstellt: $OBSIDIAN_VAULT/04-RESSOURCEN/Titel.md"
```

**Output-Struktur (Werk):**
```markdown
---
fileClass: Werk
erstellt: 2026-02-04
tags: werk
space:
projekt:
aliases:
person:
memo:
unternehmen:
werk:
ref_ressource:
status: zusammengefasst
url:
typ: Zusammenfassung
jahr_gelesen: 2026
---
# [[Titel]]

## Zusammenfassung

{Generierter Inhalt}

---
## Referenzen

```

---

### UC3: Vault-Dokument bearbeiten

**Status:** ✅ Complete (E2E-Test bestanden 2026-02-11)

**Command:** `/vault-work <dokumentname>`

**Workflow:**
```bash
# 1. Dokument laden (via CLI obsidian.com search + obsidian.com read)
/vault-work "projektname"
# → Findet Dokument, lädt Content in Session

# 2. User bearbeitet in der Session
# → Claude hilft beim Überarbeiten, Ergänzen, Umstrukturieren

# 3. Änderungen zurückschreiben
vault-edit.sh "dokumentname" "Neuer Inhalt..."
# → Zeigt Diff (alt vs. neu)
# → Erstellt Backup (.bak)
# → Aktualisiert 'modified' Frontmatter
# → Schreibt nach User-Bestätigung
```

**Script-Features (vault-edit.sh):**
- `--dry-run`: Nur Diff anzeigen, nicht schreiben
- Automatisches Backup vor Überschreiben (`.bak`)
- YAML Frontmatter `modified:` wird automatisch aktualisiert
- Cold-Start: CLI search + find Fallback für Document Discovery
- Warm-Path: `--path` für direkte Pfadangabe (spart CLI-Aufrufe)

---

## Referenzen

### Projektdateien
- `docs/My_PARA_workflow.md` - User-Beschreibung (Transkript)
- `docs/tasks/TASK-012/artifacts/fileclass-mapping.json` - Vollständiges Fileclass-Schema

### CLI (Obsidian 1.12+)
- `obsidian.com search` - Dokument-Suche (via Obsidian Index)
- `obsidian.com read` - Dokument lesen
- `obsidian.com properties` - Metadata/Frontmatter
- `obsidian.com tags` / `obsidian.com tag` - Tag-Suche
- `obsidian.com backlinks` / `obsidian.com links` - Eingehende/ausgehende Links
- `obsidian.com orphans` / `obsidian.com deadends` / `obsidian.com unresolved` - Vault Health
- `obsidian.com vault` - Vault-Statistiken (Files, Folders, Size)

### Scripts (Global)
- `~/.claude/skills/vault-manager/scripts/vault-export.sh` - Dokument exportieren
- `~/.claude/skills/vault-manager/scripts/vault-edit.sh` - Dokument bearbeiten
- `~/.claude/skills/vault-manager/scripts/vault-date.sh` - Datum-Filter
- `~/.claude/skills/vault-manager/scripts/vault-base.sh` - Base Query Engine
- `~/.claude/skills/vault-manager/scripts/vault-copy.sh` - Datei kopieren/verschieben

### Vault-Ressourcen
- `$OBSIDIAN_VAULT/09 SYSTEM/Plugins/Templater/Templates/` - Original-Templates

---

## Change Log

| Datum | TASK | Änderung |
|-------|------|----------|
| 2026-02-04 | TASK-012 | Initial: Vault-Struktur, Fileclass-System, Konzept |
| 2026-02-04 | TASK-009 | vault-export.sh, Operative Workflows UC1/UC2 |
| 2026-02-04 | TASK-010 | /vault-export Command, Commands-Tabelle |
| 2026-02-10 | Phase 3 | vault: Prefix Migration (@notation → vault:), UC3 Sektion konkretisiert, /vault-work + /obsidian-sync in Commands-Tabelle |
| 2026-02-11 | TASK-017 | UC3 Status → Complete (E2E-Test bestanden) |
| 2026-02-11 | TASK-018 | vault-tags.sh (search + list), Quick Reference erweitert |
| 2026-02-11 | TASK-019 | vault-date.sh (--last/--from/--to, 4 Felder: erstellt/modified/datum/file.mtime) |
| 2026-02-12 | TASK-023 | vault-base.sh (Base Query Engine: .base Parsing + Filter-Execution, 19 Bases, MVP-Filter) |
| 2026-02-19 | TASK-027 | CLI Migration (ADR-005): vault-find.sh/vault-read.sh/vault-tags.sh durch CLI ersetzt, Quick Reference + UC1 Workflow auf CLI+Bash Hybrid aktualisiert |
| 2026-02-19 | TASK-028 | vault-copy.sh Hybrid: CLI Discovery + find Fallback fuer vault: Prefix + Document-Name Source-Resolution |
| 2026-02-19 | TASK-029 | Backlinks + Vault Health: 7 neue CLI-Commands in Quick Reference (backlinks, links, orphans, deadends, unresolved, vault stats), SKILL.md Trigger-Keywords erweitert |

---

*Last updated: 2026-02-19*
