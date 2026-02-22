---
name: vault-export
description: Export content to Obsidian Vault with Fileclass-based templates
model: sonnet
---

# /vault-export Command

Exportiert Session-Output oder beliebigen Content als strukturiertes Dokument in den Obsidian Vault.

## Usage

```
/vault-export [Fileclass] [Titel]
```

**Beispiele:**
```
/vault-export Werk "PKM-Workflows mit Claude"
/vault-export Memo "Session-Learning 2026-02-04"
/vault-export Person "Max Mustermann"
```

## Verfügbare Fileclasses

| Fileclass | Beschreibung | Trigger-Phrasen |
|-----------|--------------|-----------------|
| **Werk** | Fertige Inhalte, Zusammenfassungen | "Fasse zusammen", "als Werk", "Artikel" |
| **Memo** | Gedanken, Notizen, Learnings | "Notiere", "Memo", "halte fest" |
| **Bewerbung** | CRM für Job-Bewerbungen | "Bewerbung anlegen", "Stelle erfassen" |
| **Person** | Kontakte, Netzwerk | "Person anlegen", "Kontakt" |
| **Unternehmen** | Firmen, Arbeitgeber | "Unternehmen dokumentieren" |
| **Produkt** | Produkte, Reviews | "Produkt dokumentieren" |
| **Ort** | Locations, Adressen | "Ort anlegen" |

## Workflow

Wenn der User `/vault-export` aufruft:

### 1. Parameter sammeln

Falls Fileclass oder Titel fehlen, frage interaktiv nach:

```
Fileclass nicht angegeben. Welchen Typ möchten Sie erstellen?
- Werk (Zusammenfassung, Artikel)
- Memo (Notiz, Learning)
- Bewerbung
- Person
- Unternehmen
- Produkt
- Ort
```

### 2. Content bestimmen

Der Content kann aus verschiedenen Quellen kommen:
- **Explizit:** User gibt Content im Command oder danach an
- **Kontext:** Claude fasst relevanten Session-Inhalt zusammen
- **Leer:** Nur Struktur wird erstellt (User füllt später aus)

Frage den User: "Soll ich den Session-Inhalt zu [Thema] als Content verwenden?"

### 3. Dokument generieren

Rufe das Bash-Script auf:

```bash
# Guard: Vault-Pfad verifizieren
if [ ! -d "$OBSIDIAN_VAULT/.obsidian" ]; then
  echo "ERROR: $OBSIDIAN_VAULT ist kein Obsidian Vault (.obsidian/ fehlt)"; exit 1
fi

# Dry-run zuerst zeigen
~/.claude/skills/vault-manager/scripts/vault-export.sh --dry-run "<Fileclass>" "<Titel>" "<Content>"

# Nach Bestätigung: Echtes Schreiben
~/.claude/skills/vault-manager/scripts/vault-export.sh "<Fileclass>" "<Titel>" "<Content>"
```

### 4. Bestätigung

Zeige dem User:
- Erstellten Dateipfad
- Zusammenfassung des Frontmatters
- Hinweis: "Dokument in Obsidian öffnen"

## Fehlerbehandlung

### OBSIDIAN_VAULT nicht gesetzt

```
⚠️ OBSIDIAN_VAULT Umgebungsvariable nicht gesetzt.

Setup:
1. Erstelle ~/.config/secrets/env.d/vault.env
2. Inhalt: OBSIDIAN_VAULT="/pfad/zu/deinem/vault"
3. Führe /vault-export erneut aus
```

### Datei existiert bereits

```
⚠️ Datei existiert bereits: $OBSIDIAN_VAULT/04-RESSOURCEN/Titel.md

Optionen:
1. Anderen Titel wählen
2. Bestehende Datei überschreiben (mit Bestätigung)
3. Abbrechen
```

## Beispiel-Session

```
User: /vault-export

Claude: Welchen Dokumenttyp möchten Sie erstellen?
        [Werk] [Memo] [Person] [Andere...]

User: Werk

Claude: Titel für das Werk?

User: PKM-Workflows mit Claude Code

Claude: Soll ich unsere Diskussion über PKM-Workflows als Content zusammenfassen?
        [Ja, zusammenfassen] [Nein, leer erstellen] [Eigenen Content eingeben]

User: Ja, zusammenfassen

Claude:
=== VORSCHAU (Dry-Run) ===
Fileclass: Werk
Titel: PKM-Workflows mit Claude Code
Ziel: $OBSIDIAN_VAULT/04-RESSOURCEN/PKM-Workflows mit Claude Code.md

---
fileClass: Werk
erstellt: 2026-02-04
tags: werk
status: zusammengefasst
...
---
# [[PKM-Workflows mit Claude Code]]

## Zusammenfassung
[Zusammenfassung der Session]

---
## Referenzen

=== ENDE VORSCHAU ===

Dokument erstellen? [Ja] [Nein, anpassen]

User: Ja

Claude: ✅ Dokument erstellt: /pfad/zum/vault/04-RESSOURCEN/PKM-Workflows mit Claude Code.md
```

## Technische Details

- **Script:** `~/.claude/skills/vault-manager/scripts/vault-export.sh`
- **Zielordner:** `$OBSIDIAN_VAULT/04-RESSOURCEN/`
- **Frontmatter:** Dynamisch basierend auf Fileclass (siehe fileclass-mapping.json)
- **Encoding:** UTF-8

## Referenzen

- `docs/PKM-WORKFLOW.md` - Vollständige Vault-Integration-Dokumentation
- `docs/tasks/TASK-012/artifacts/fileclass-mapping.json` - Fileclass-Schemas
- `~/.claude/skills/vault-manager/scripts/vault-export.sh` - Export-Script

---

**Erstellt:** 2026-02-04 (TASK-010)
