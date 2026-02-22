# Uncertainty Handling

Wann und wie den User einbinden? Regeln für den Orchestrator.

## Grundprinzip

**"Keine Annahmen bei Unsicherheit."**

Lieber einmal zu viel fragen als falsche Richtung einschlagen.

---

## Wann User einbinden?

### 🔴 IMMER einbinden (Stopp-Situationen)

| Situation | Beispiel | Aktion |
|-----------|----------|--------|
| **Unklares Objective** | "Verbessere Performance" ohne Metriken | Frage: "Welche Metriken? Welches Ziel?" |
| **Widersprüche** | Docs sagen A, Code macht B | Frage: "Docs oder Code korrekt?" |
| **Breaking Changes** | API-Signatur ändern, Schema migrieren | Frage: "Bestätigung für Breaking Change?" |
| **Architektur-Entscheidungen** | Neues Pattern, Framework-Wahl | Frage: "Welcher Ansatz?" |
| **Fehlende Ressourcen** | Credentials, externe APIs, Configs | Frage: "Bitte bereitstellen" |
| **Scope Creep** | Task erfordert mehr als beschrieben | Frage: "Scope erweitern oder Task splitten?" |

### 🟡 OPTIONAL einbinden (Judgment Call)

| Situation | Empfehlung |
|-----------|------------|
| **Mehrere valide Lösungen** | Wenn ähnlich gut: wähle einfachste. Wenn signifikant unterschiedlich: fragen |
| **Stylistische Entscheidungen** | Folge bestehenden Patterns im Projekt |
| **Performance vs. Readability** | Defaults: Readability first, außer explizit anders |

### ✅ NICHT einbinden (selbst entscheiden)

| Situation | Aktion |
|-----------|--------|
| **Triviale Implementation Details** | Variablennamen, Formatierung |
| **Offensichtliche Fehler** | Typos, Syntax-Errors |
| **Standard-Patterns** | Bekannte Best Practices anwenden |

---

## Wie einbinden?

### AskUserQuestion Format

```
Für TASK-XXX benötige ich eine Klärung:

**Situation:** [Was ist unklar/widersprüchlich]
**Kontext:** [Relevante Infos]

**Optionen:**
A) [Option mit Trade-offs]
B) [Option mit Trade-offs]

**Meine Empfehlung:** [Falls vorhanden, mit Begründung]
```

### Beispiele

**Gutes Beispiel:**
```
Für TASK-007 (Template-Refactor):

Das Template enthält Bash-Variablen ({{NAME}}) die sed-Substitution erschweren.

Optionen:
A) sed mit anderem Delimiter (%% statt {{}})
B) Python-Script für Substitution
C) Envsubst-basierte Lösung

Empfehlung: Option B - robuster, bereits Python im Stack.
```

**Schlechtes Beispiel:**
```
Soll ich weitermachen?
```
→ Zu unspezifisch, keine Optionen, keine Kontext.

---

## Eskalations-Stufen

```
Level 1: Informieren
  → "Ich habe X gemacht weil Y"
  → Kein Stopp, aber User weiß Bescheid

Level 2: Bestätigen
  → "Ich plane X. OK?"
  → Wartet auf Bestätigung vor Fortfahren

Level 3: Entscheiden lassen
  → "Option A, B oder C?"
  → User trifft Entscheidung

Level 4: Stopp + Hilfe anfordern
  → "Ich kann nicht weitermachen ohne X"
  → Blockiert bis User liefert
```

---

## Timing

- **VOR Ausführung:** Architektur, Scope, Breaking Changes
- **WÄHREND Ausführung:** Neue Widersprüche, fehlende Infos
- **NACH Ausführung:** Nur bei Fehlern oder unerwarteten Ergebnissen

---

*Referenz für task-orchestrator Phase 4*
