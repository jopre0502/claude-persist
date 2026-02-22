---
name: setup-reference
description: >
  Generiert eine vollstaendige SETUP-REFERENCE.md aus dem Live-System
  (~/.claude/). Scannt Skills, Agents, Commands, Hooks, Permissions,
  Plugins und Secrets-Dateien deterministisch. Eliminiert manuelle
  Pflege und Staleness-Risiko. Primaerquelle fuer den my-setup-guide Agent.
  Trigger: /refresh-reference oder manuell.
disable-model-invocation: true
---

# Setup Reference Generator

Generiert `references/SETUP-REFERENCE.md` aus dem Live-System.

## Verwendung

Dieses Skill wird primaer ueber den Command `/refresh-reference` aufgerufen.
Der Command ruft `scripts/generate-reference.sh` auf und zeigt eine Zusammenfassung.

## Architektur

```
[Live-System: ~/.claude/]
    |
    v  generate-reference.sh
    |
[references/SETUP-REFERENCE.md]  <-- generiert, mit Timestamp
    + [references/static-sections.md]  <-- manuell (selten aendernd)
    |
    v
[my-setup-guide Agent]  <-- liest generierte Referenz
```

## Dateien

| Datei | Typ | Beschreibung |
|-------|-----|-------------|
| `scripts/generate-reference.sh` | Script | Scannt Live-System, generiert Referenz |
| `references/static-sections.md` | Manuell | Design-Regeln, Workflow, Config-Architektur |
| `references/SETUP-REFERENCE.md` | Generiert | Vollstaendige Setup-Referenz |

## Scan-Bereiche

1. Skills (`~/.claude/skills/*/SKILL.md`)
2. Agents (`~/.claude/agents/*.md`)
3. Commands (`~/.claude/commands/*.md`)
4. Hooks (`settings.json → .hooks`)
5. Permissions (`settings.json → .permissions`)
6. Plugins (`settings.json → .enabledPlugins`)
7. Global Settings (model, outputStyle, effortLevel)
8. Secrets (`~/.config/secrets/env.d/*.env` — nur Dateinamen)
9. Static Sections (Design-Regeln, Workflow, Config)

## Staleness

Generierte Referenz enthaelt Timestamp. Empfohlen: woechentlich `/refresh-reference`
oder nach Aenderungen an Skills/Plugins/Hooks.
