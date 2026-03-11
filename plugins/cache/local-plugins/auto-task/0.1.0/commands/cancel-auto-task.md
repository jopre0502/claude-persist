---
name: cancel-auto-task
description: Cancel a running auto-task loop by removing the state file. Use when you want to stop autonomous task execution immediately.
---

# Cancel Auto-Task Loop

Der User moechte den laufenden Auto-Task-Loop abbrechen.

## Anweisungen

1. Suche nach aktiven Auto-Task State-Files im aktuellen Projekt:
   - Suche nach `docs/tasks/*/auto-task.state` im Projekt-Root
2. Wenn ein State-File gefunden wird:
   - Zeige den aktuellen Status (Task-ID, Iteration, gestartet um)
   - Loesche das State-File
   - Bestaetige: "Auto-Task Loop fuer TASK-NNN abgebrochen."
3. Wenn kein State-File gefunden wird:
   - Melde: "Kein aktiver Auto-Task Loop gefunden."
