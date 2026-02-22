---
name: refresh-reference
description: Generiert SETUP-REFERENCE.md aus dem Live-System (~/.claude/). Scannt Skills, Agents, Commands, Hooks, Permissions, Plugins und zeigt Inventar-Zusammenfassung.
---

Fuehre das Generator-Script aus und zeige das Ergebnis:

```bash
bash ~/.claude/skills/setup-reference/scripts/generate-reference.sh
```

Zeige nach erfolgreicher Ausfuehrung:
1. Die Inventar-Zusammenfassung (Skills, Agents, Commands, Hooks, Plugins Anzahl)
2. Den Timestamp der Generierung
3. Falls sich etwas gegenueber der vorherigen Version geaendert hat, zeige die Aenderungen kurz an

Die generierte Datei liegt unter: `~/.claude/skills/setup-reference/references/SETUP-REFERENCE.md`
