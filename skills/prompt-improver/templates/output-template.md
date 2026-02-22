# Output-Template für Prompt-Verbesserung

Nutze diese Struktur für die Präsentation verbesserter Prompts.

---

## ORIGINAL-PROMPT

```xml
<original_prompt>
{{Der ursprüngliche Prompt-Entwurf des Benutzers, unverändert}}
</original_prompt>
```

---

## ANALYSE

```xml
<analysis>
### Stärken
- **[Stärke 1]**: [Beschreibung]
- **[Stärke 2]**: [Beschreibung]
- **[Stärke 3]**: [Beschreibung]

### Schwächen
- **[Schwäche 1]**: [Beschreibung + Auswirkung]
- **[Schwäche 2]**: [Beschreibung + Auswirkung]
- **[Schwäche 3]**: [Beschreibung + Auswirkung]

### Fehlender Kontext
- [Was fehlt an Hintergrundinformationen]
- [Welche Motivationen nicht erklärt sind]
- [Wo WARUM fehlt]

### Optimierungspotential
**Priorität 1 (Kritisch)**:
1. [Kritische Verbesserung 1]
2. [Kritische Verbesserung 2]

**Priorität 2 (Wichtig)**:
1. [Wichtige Verbesserung 1]
2. [Wichtige Verbesserung 2]

**Priorität 3 (Nice-to-have)**:
1. [Optional Verbesserung 1]

### Identifizierte Lücken
- **Struktur**: [XML-Tags, Organisation]
- **Explizitheit**: [Vage Formulierungen]
- **Technisch**: [Variablen, Extended Thinking, Tool Use]
- **Beispiele**: [Fehlende oder unklare Beispiele]
- **Guardrails**: [Grenzen, Fehlerbehandlung]
</analysis>
```

---

## VERBESSERTER PROMPT

```xml
<improved_prompt>
---
# [Falls Frontmatter nötig - z.B. für Agent/Skill]
name: [name]
description: [description]
model: [sonnet/opus/haiku]
---

# [Titel des verbesserten Prompts]

<system_instruction>
[Rolle und grundlegende Verhaltensweisen]
Du bist ein [Rolle] mit Expertise in [Bereiche].
</system_instruction>

<context>
[Hintergrund und kontextuelle Informationen]
[WARUM bestimmte Verhaltensweisen wichtig sind]

**Verwendungszweck**: {{PURPOSE}}
**Zielgruppe**: {{TARGET_AUDIENCE}}
</context>

<task>
[Die konkrete Aufgabe oder Frage]
[Mit allen spezifischen Requirements]

**Eingabe**: {{INPUT}}
**Erwartete Ausgabe**: [Beschreibung]
</task>

<constraints>
[Spezifische Einschränkungen oder Anforderungen]

**Technische Constraints**:
- [Constraint 1]
- [Constraint 2]

**Qualitäts-Anforderungen**:
- [Requirement 1]
- [Requirement 2]

**Was NICHT zu tun ist**:
- ❌ [Vermeide X]
- ❌ [Vermeide Y]
</constraints>

<workflow>
[Falls mehrstufiger Prozess]

1. **Phase 1 - [Name]**: [Beschreibung]
2. **Phase 2 - [Name]**: [Beschreibung]
3. **Phase 3 - [Name]**: [Beschreibung]

<instruction>
[Spezifische Anweisungen für jede Phase]
[WARUM dieser Workflow sinnvoll ist]
</instruction>
</workflow>

<output_format>
[Gewünschtes Format der Ausgabe - SEHR SPEZIFISCH]

```[format]
[Exaktes Template mit Platzhaltern]
```

**Struktur**:
- [Element 1]: [Beschreibung]
- [Element 2]: [Beschreibung]

**Formatierung**:
- [Regel 1]
- [Regel 2]
</output_format>

<examples>
[Konkrete Beispiele für gewünschtes Verhalten]

<example>
**Szenario**: [Beschreibung]

**Eingabe**:
```
[Beispiel-Input]
```

**Erwartete Ausgabe**:
```
[Beispiel-Output der EXAKT das gewünschte Verhalten zeigt]
```

**Warum**: [Erklärung was dieses Beispiel demonstriert]
</example>

<example>
[Weiteres Beispiel...]
</example>
</examples>

<guardrails>
[Explizite Grenzen und Fehlerbehandlung]

**Fehlerbehandlung**:
- Wenn [Situation], dann [Aktion]
- Bei [Problem], [Lösung]

**Edge Cases**:
- [Edge Case 1]: [Wie damit umgehen]
- [Edge Case 2]: [Wie damit umgehen]

**Boundaries**:
- [Was ist innerhalb des Scopes]
- [Was ist außerhalb des Scopes]
</guardrails>

[Falls Extended Thinking für Opus:]
<thinking_instructions>
Nutze ausreichend Thinking-Zeit für komplexe Entscheidungen.
Nach Erhalt von Informationen überprüfe sorgfältig deren Qualität
und bestimme optimale nächste Schritte, bevor du weitermachst.

**Thinking Budget**: [Empfohlene Tokens: 10K-16K für komplexe Tasks]
</thinking_instructions>

[Falls Tool Use relevant:]
<tool_use_instructions>
[Spezifische Anweisungen für Tool-Nutzung]
- Rufe Tools PARALLEL auf wenn unabhängig
- [Weitere tool-spezifische Best Practices]
</tool_use_instructions>

[Falls Scratchpad nötig:]
<scratchpad_instructions>
Für komplexe Analysen nutze ein <scratchpad>:

<scratchpad>
## [Abschnitt 1]
[...]

## [Abschnitt 2]
[...]

## Schlussfolgerung
[...]
</scratchpad>

<final_answer>
[Deine endgültige Antwort]
</final_answer>
</scratchpad_instructions>

</improved_prompt>
```

---

## ERKLÄRUNG DER ÄNDERUNGEN

```xml
<explanation>
### Hauptänderungen

#### 1. [Änderung 1 - Titel]
**Was wurde geändert**:
[Konkrete Beschreibung der Änderung]

**Warum**:
[Begründung basierend auf Best Practices - z.B. "Claude 4.x benötigt extreme Explizitheit"]

**Beispiel**:
```
# Vorher:
[Alte Version]

# Nachher:
[Neue Version]
```

**Erwartete Verbesserung**:
[Welchen Effekt hat diese Änderung]

---

#### 2. [Änderung 2 - Titel]
**Was wurde geändert**:
[Beschreibung]

**Warum**:
[Begründung mit Referenz auf Best Practice]

**Beispiel**:
```
# Vorher:
[...]

# Nachher:
[...]
```

**Erwartete Verbesserung**:
[Effekt]

---

[Weitere Änderungen...]

---

### Claude 4.x Optimierungen angewendet

Die folgenden spezifischen Optimierungen für Claude 4.x Modelle wurden implementiert:

✓ **Extreme Explizitheit**:
- [Konkrete Verbesserung]
- [Konkrete Verbesserung]

✓ **XML-Strukturierung**:
- [Welche Tags hinzugefügt]
- [Wie Organisation verbessert]

✓ **Kontext & Motivation (WARUM)**:
- [Wo WARUM hinzugefügt]
- [Wie Motivation erklärt]

✓ **Variablen für Workbench**:
- [Welche Variablen eingefügt: `{{NAME}}`]
- [Anzahl Variablen: X]

✓ **Extended Thinking** (falls Opus & komplex):
- [Token Budget: XK]
- [Prompt-Anweisungen hinzugefügt]

✓ **Tool Use Optimierungen** (falls relevant):
- [Detaillierte Beschreibungen]
- [Parallele Calls gefördert]

✓ **Scratchpad-Pattern** (falls Reasoning):
- [Struktur vorgegeben]
- [Beispiel bereitgestellt]

✓ **Beispiele**:
- [Anzahl Beispiele: X]
- [EXAKT gewünschtes Verhalten gezeigt]

✓ **Guardrails**:
- [Grenzen definiert]
- [Fehlerbehandlung beschrieben]
- [Edge Cases adressiert]

### Best Practices aus der Recherche angewendet

- **Abschnitt 1 (Explizitheit)**: [Wie angewendet]
- **Abschnitt 2 (XML-Struktur)**: [Wie angewendet]
- **Abschnitt 3 (Variablen)**: [Wie angewendet]
- **Abschnitt 4 (Extended Thinking)**: [Wie angewendet]
- **Abschnitt 5 (Tool Use)**: [Wie angewendet]
- [Weitere relevante Abschnitte...]

</explanation>
```

---

## METADATA

```xml
<metadata>
### Modell-Empfehlung
- **Empfohlenes Modell**: [Claude Sonnet 4.5 / Claude Opus 4.5 / Claude Haiku 4.5]

- **Begründung**:
  [Warum dieses Modell optimal für diesen Prompt ist]
  - [Grund 1]
  - [Grund 2]
  - [Grund 3]

### Eigenschaften
- **Anwendungsfall**: [Code / Analyse / Kreativ / Tool Use / Reasoning / UI/UX / etc.]
- **Komplexität**: [Niedrig / Mittel / Hoch]
- **Strukturtyp**: [System Prompt / Task-Prompt / Template / Agent / Skill]

### Technische Details
- **Extended Thinking**: [Ja (Budget: XK Tokens) / Nein / Optional]
- **Tool Use**: [Ja / Nein]
  - Falls Ja: [Anzahl Tools, Hauptzweck]
- **Workbench-Variablen**: [Anzahl: X]
  - Variablen: `{{VAR1}}`, `{{VAR2}}`, `{{VAR3}}`
- **Scratchpad**: [Ja / Nein]

### Qualitätsscore
Basierend auf Quality Checklist:
- **Struktur & Organisation**: ⭐⭐⭐ (3/3)
- **Anweisungen & Klarheit**: ⭐⭐⭐ (3/3)
- **Technische Optimierungen**: ⭐⭐⭐ (3/3)
- **Beispiele & Format**: ⭐⭐⭐ (3/3)
- **Guardrails & Constraints**: ⭐⭐⭐ (3/3)
- **Claude 4.x Spezifisch**: ⭐⭐⭐ (3/3)

**Gesamt**: 21/24 → **Exzellent - Produktionsreif**

### Performance-Erwartung
- **Token Count**: ~[Geschätzte Anzahl] Tokens
- **Context Overhead**: [Niedrig / Mittel / Hoch]
- **Erwartete Qualität**: [Beschreibung der erwarteten Output-Qualität]

</metadata>
```

---

## WEITERE ANPASSUNGSMÖGLICHKEITEN

```xml
<further_customization>
### Optionale Verfeinerungen

1. **[Verfeinerung 1]**:
   - **Was**: [Beschreibung]
   - **Wann sinnvoll**: [Kontext]
   - **Wie umsetzen**: [Anleitung]

2. **[Verfeinerung 2]**:
   - **Was**: [Beschreibung]
   - **Wann sinnvoll**: [Kontext]
   - **Wie umsetzen**: [Anleitung]

### Kontextabhängige Ergänzungen

- **Wenn [Bedingung]**, dann ergänze: [Vorschlag]
- **Für [speziellen Anwendungsfall]**: [spezifische Empfehlung]
- **Bei [Situation]**: [Alternative Formulierung]

### Variationen für verschiedene Modelle

**Für Sonnet 4.5**:
- [Spezifische Anpassung für Tool Use/Code]

**Für Opus 4.5**:
- [Spezifische Anpassung für Reasoning/Kreativ]

**Für Haiku 4.5**:
- [Spezifische Anpassung für Speed/Einfachheit]

### Nächste Schritte

1. [Empfohlener nächster Schritt 1]
2. [Empfohlener nächster Schritt 2]
3. [Empfohlener nächster Schritt 3]

</further_customization>
```

---

**Hinweis**: Passe dieses Template an den spezifischen Use Case an. Nicht alle Abschnitte sind für jeden Prompt relevant - nutze was sinnvoll ist und entferne den Rest.
