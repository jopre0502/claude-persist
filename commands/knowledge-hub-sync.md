---
description: "Knowledge Hub (~/.claude/) zu GitHub committen und pushen - von jedem Working Directory"
allowed-tools: Bash, Read, AskUserQuestion
---

# Knowledge Hub Sync Command

Committed und pusht Aenderungen in `~/.claude/` zum `my-claude-knowledge-hub` GitHub Repo.
Funktioniert von **jedem Working Directory** — kein `cd` noetig.

**Arguments:** $ARGUMENTS

## Workflow

### Step 1: Git-Repo pruefen

```bash
HUB_DIR="$HOME/.claude"
if [ ! -d "$HUB_DIR/.git" ]; then
  echo "ERROR: $HUB_DIR ist kein Git-Repository"
  exit 1
fi
git -C "$HUB_DIR" remote -v
```

**Falls kein Git-Repo:** Zeige Fehler und stoppe.

### Step 1b: Branch pruefen

```bash
HUB_DIR="$HOME/.claude"
current_branch=$(git -C "$HUB_DIR" branch --show-current)
if [ "$current_branch" != "main" ]; then
  echo "⚠️ Knowledge Hub ist auf Branch '$current_branch' statt 'main'."
  echo "Wechsle zu main..."
  git -C "$HUB_DIR" checkout main
fi
```

**Wichtig:** Knowledge Hub arbeitet immer auf `main`. Kein Feature-Branch-Workflow.

### Step 1c: SETUP-REFERENCE.md regenerieren

Stelle sicher, dass die Inventar-Referenz aktuell ist bevor wir syncen:

```bash
HUB_DIR="$HOME/.claude"
bash "$HUB_DIR/skills/setup-reference/scripts/generate-reference.sh"
```

Zeige die Inventar-Zusammenfassung aus dem Script-Output (Skills, Agents, Commands, Hooks, Plugins Anzahl).

### Step 2: Aenderungen pruefen

```bash
HUB_DIR="$HOME/.claude"
git -C "$HUB_DIR" status --short
```

**Falls keine Aenderungen:**
```
✅ Knowledge Hub ist synchron - keine Aenderungen.
Repo: my-claude-knowledge-hub
```
Stoppe hier.

### Step 2b: README Drift-Check

Pruefe ob die README.md "At a glance"-Tabelle noch zum tatsaechlichen Inhalt passt:

```bash
HUB_DIR="$HOME/.claude"
bash "$HUB_DIR/skills/setup-reference/scripts/readme-drift-check.sh"
```

**Exit-Code 0 (kein Drift):** Weiter mit Step 3.

**Exit-Code 2 (README nicht parsebar):** Hinweis ausgeben, weiter mit Step 3.

**Exit-Code 1 (Drift erkannt):** Zeige dem User die Drift-Details und frage via AskUserQuestion:

```
README Drift erkannt:
[Output des Scripts einfuegen]

Optionen:
1. README "At a glance" Zahlen jetzt aktualisieren, dann weiter mit Sync
2. Ignorieren und trotzdem syncen
3. Abbrechen
```

**Bei Option 1:** Aktualisiere NUR die Zahlen in der "At a glance"-Tabelle der README.md.
Verwende das Edit-Tool um die jeweiligen Zahlenwerte in den Tabellenzeilen zu ersetzen
(z.B. `| **Skills** | 18 |` → `| **Skills** | 17 |`). Keine anderen Bereiche aendern.

**Bei Option 2:** Weiter mit Step 3.
**Bei Option 3:** Abbrechen.

### Step 3: Aenderungen anzeigen und bestaetigen

Zaehle geaenderte Dateien nach Kategorie und zeige dem User via AskUserQuestion:

```
Knowledge Hub Sync → my-claude-knowledge-hub:

[Kategorisierte Zusammenfassung, z.B.:]
  Skills:   3 geaendert
  Agents:   1 geaendert
  Commands: 0
  CLAUDE.md: geaendert

Gesamt: [N] Dateien

Fortfahren?
1. Ja, committen und pushen
2. Nur committen (kein Push)
3. Abbrechen
```

**Bei Abbruch:** Stoppe mit "Abgebrochen."

### Step 4: Commit-Message generieren

**Falls `$ARGUMENTS` eine `--message "..."` oder `-m "..."` Option enthaelt:**
Verwende die Custom-Message.

**Sonst: Auto-Generate basierend auf geaenderten Kategorien.**

Zaehle Dateien per Kategorie mit reinem Bash (keine Pipes in Loops — Windows Performance):

```bash
HUB_DIR="$HOME/.claude"
status_output=$(git -C "$HUB_DIR" status --short)

skills=0 agents=0 commands=0 hooks=0 other=0 claude_md=0

while IFS= read -r line; do
  file="${line:3}"
  case "$file" in
    skills/*) ((skills++)) ;;
    agents/*) ((agents++)) ;;
    commands/*) ((commands++)) ;;
    hooks/*) ((hooks++)) ;;
    CLAUDE.md) claude_md=1 ;;
    *) ((other++)) ;;
  esac
done <<< "$status_output"

# Message bauen
parts=()
((skills > 0)) && parts+=("${skills} skills")
((agents > 0)) && parts+=("${agents} agents")
((commands > 0)) && parts+=("${commands} commands")
((hooks > 0)) && parts+=("${hooks} hooks")
((claude_md > 0)) && parts+=("CLAUDE.md")
((other > 0)) && parts+=("${other} other")

IFS=', '; COMMIT_MSG="sync: ${parts[*]}"
```

### Step 5: Commit + Push

```bash
HUB_DIR="$HOME/.claude"

git -C "$HUB_DIR" add -A
git -C "$HUB_DIR" commit -m "$COMMIT_MSG"

# Push nur wenn in Step 3 "Ja, committen und pushen" gewaehlt
git -C "$HUB_DIR" push
```

### Step 6: Bestaetigung

```
✅ Knowledge Hub erfolgreich synchronisiert

Repo:    my-claude-knowledge-hub
Commit:  $COMMIT_MSG
Dateien: [N] geaendert
Push:    [Ja/Nein]
```

---

## Error Handling

### Push fehlgeschlagen
```
❌ Push fehlgeschlagen

Moegliche Ursachen:
1. Netzwerk nicht erreichbar
2. Auth abgelaufen → gh auth refresh
3. Remote-Konflikte → git -C ~/.claude pull --rebase

Commit wurde lokal erstellt. Erneut versuchen: /knowledge-hub-sync
```

### Merge-Konflikte
```
⚠️ Remote hat neuere Aenderungen.

Empfehlung:
  git -C ~/.claude pull --rebase
  /knowledge-hub-sync
```
