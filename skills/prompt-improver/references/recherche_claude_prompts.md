# Recherche: Claude Prompt Engineering Best Practices

Umfassende Dokumentation zu Best Practices für das Schreiben optimierter Prompts für Claude und Claude Code.

**Datum:** 18. Dezember 2025
**Ziel:** Entwicklung eines Prompt-Improvers für Claude-optimierte Prompts

---

## 1. GRUNDLEGENDE PRINZIPIEN FÜR CLAUDE 4.X MODELLE

### 1.1 Explizite und klare Anweisungen

Claude 4.x-Modelle sind für präzises Instruction-Following trainiert. Wichtige Aspekte:

- **Sei spezifisch**: Vage Anweisungen führen zu generischen Ergebnissen
- **Explizit formulieren**: Gewünschtes Verhalten klar beschreiben
- **Details zählen**: Beispiele müssen exakt das gewünschte Verhalten zeigen

**Beispiel:**
```text
❌ Weniger effektiv:
"Erstelle ein Analytics-Dashboard"

✅ Besser:
"Erstelle ein Analytics-Dashboard. Binde so viele relevante Funktionen
wie möglich ein und gehe über die Basics hinaus, um eine vollständig
ausgestattete Implementierung zu schaffen."
```

### 1.2 Kontext und Motivation liefern

Erkläre WARUM ein bestimmtes Verhalten wichtig ist:

```xml
<context>
Deine Antwort wird von Text-to-Speech vorgelesen. Verwende daher
niemals Auslassungspunkte (...), da die TTS-Engine nicht weiß,
wie sie auszusprechen sind.
</context>
```

### 1.3 Step-by-Step Reasoning fördern

```text
Denke Schritt für Schritt nach und erkläre deinen Denkprozess.
```

---

## 2. PROMPT-STRUKTURIERUNG MIT XML-TAGS

### 2.1 Empfohlene XML-Struktur

Claude versteht und respektiert XML-Tags zur Strukturierung:

```xml
<system_instruction>
Rolle und grundlegende Verhaltensweisen
</system_instruction>

<context>
Hintergrund und kontextuelle Informationen
</context>

<task>
Die konkrete Aufgabe oder Frage
</task>

<constraints>
Spezifische Einschränkungen oder Anforderungen
</constraints>

<output_format>
Gewünschtes Format der Ausgabe
</output_format>

<examples>
Beispiele für gewünschtes Verhalten
</examples>
```

### 2.2 Scratchpad-Pattern

Für komplexe Reasoning-Aufgaben:

```xml
<instruction>
Bevor du antwortest, nutze <scratchpad> Tags, um:
1. Relevante Quotes aus dem Dokument zu extrahieren
2. Deine Überlegungen zu strukturieren
3. Die Antwort vorzubereiten
</instruction>

<scratchpad>
Relevante Zitate:
- "Quote 1..."
- "Quote 2..."

Analyse:
- Punkt 1
- Punkt 2

Schlussfolgerung:
...
</scratchpad>

<final_answer>
Die endgültige Antwort
</final_answer>
```

**Best Practice**: Wenn dein Prompt ein Scratchpad verwendet, gib Beispiele, wie es aussehen soll.

---

## 3. VARIABLEN UND WORKBENCH-FEATURES

### 3.1 Variablen-Syntax

In der Anthropic Workbench und für Prompt-Templates:

```text
{{VARIABLE_NAME}}
```

**Beispiele:**
```text
Benutzer: {{USER_NAME}}
Projekt: {{PROJECT_NAME}}
Kontext: {{CODEBASE_CONTEXT}}
Datei: {{FILE_PATH}}
Datum: {{CURRENT_DATE}}
```

**Workbench-Verhalten:**
- Nicht ausgefüllte Variablen werden ROT markiert
- Variablen ermöglichen wiederverwendbare Prompt-Templates
- Kunden-Daten werden zur Laufzeit eingefügt

### 3.2 Claude Code spezifische Features

#### CLAUDE.md Datei

Zentrale Projekt-Dokumentation in `.claude/CLAUDE.md`:

```markdown
# {{PROJECT_NAME}}

## Überblick
Kurze Beschreibung des Projekts und seiner Ziele.

## Architektur
### Stack
- Framework: {{FRAMEWORK}}
- Sprache: {{LANGUAGE}}
- Package Manager: {{PACKAGE_MANAGER}}

### Wichtige Dateien
- `/src/main.ts` - Haupteinstiegspunkt
- `/tests/` - Test-Suite
- `/docs/` - Dokumentation

## Konventionen
### Code-Style
- TypeScript mit ES Modules
- ESLint + Prettier für Formatierung
- Jest für Unit Tests

### Naming Conventions
- Dateien: kebab-case
- Komponenten: PascalCase
- Funktionen: camelCase

## Häufige Aufgaben
### Setup
```bash
npm install
npm run dev
```

### Tests ausführen
```bash
npm test
```

### Build
```bash
npm run build
```

## Troubleshooting
- Problem X → Lösung Y
```

#### Memory-System

```bash
# Memories bearbeiten
/memory

# Schnell Memory hinzufügen
# "Ich bevorzuge TypeScript über JavaScript"
```

---

## 4. EXTENDED THINKING (SCRATCHPAD-ÄQUIVALENT)

### 4.1 Extended Thinking aktivieren

Extended Thinking ermöglicht Claude, komplexe Probleme durch internes Reasoning zu lösen:

```python
response = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=16000,
    thinking={
        "type": "enabled",
        "budget_tokens": 10000  # Tokens für das Denken
    },
    messages=[{
        "role": "user",
        "content": "Löse diese komplexe Aufgabe..."
    }]
)
```

### 4.2 Thinking-Budgets

| Budget | Anwendungsfall |
|--------|----------------|
| 1,024 - 4,096 | Einfache Reasoning-Aufgaben |
| 4,096 - 16,000 | Mittlere Komplexität (empfohlen) |
| 16,000+ | Komplexe, multi-step Probleme |
| 32,000+ | Sehr komplex (Batch API nutzen) |

**Wichtig**: Das Budget ist ein Ziel, nicht eine strikte Grenze. Die tatsächliche Nutzung kann variieren.

### 4.3 Best Practices für Extended Thinking

1. **Prompt nach Denken anpassen**:
   ```text
   Nach Erhalt von Tool-Ergebnissen überprüfe sorgfältig deren
   Qualität und bestimme optimale nächste Schritte, bevor du weitermachst.
   ```

2. **State Tracking über mehrere Context-Fenster**:
   ```json
   // tests.json
   {
     "tests": [
       {"id": 1, "name": "auth_flow", "status": "passing"},
       {"id": 2, "name": "user_mgmt", "status": "failing", "error": "..."}
     ]
   }
   ```

3. **Für folgende Aufgaben nutzen**:
   - Mathematische Probleme
   - Code-Debugging
   - Komplexe Datenanalyse
   - Multi-Step-Reasoning

---

## 5. TOOL USE UND FUNCTION CALLING

### 5.1 Tool-Definitionen schreiben

**Wichtigster Faktor**: Extrem detaillierte Beschreibungen!

```json
{
  "name": "get_stock_price",
  "description": "Ruft den aktuellen Aktienkurs für ein Tickersymbol ab.
                  Das Tickersymbol muss ein gültiges Symbol für ein
                  börsennotiertes Unternehmen an einer großen US-Börse sein.
                  Gibt den neuesten Handelskurs in USD zurück. Sollte verwendet
                  werden, wenn der Benutzer nach dem aktuellen oder letzten
                  Aktienkurs fragt. Liefert KEINE anderen Informationen über
                  die Aktie oder das Unternehmen.",
  "input_schema": {
    "type": "object",
    "properties": {
      "ticker": {
        "type": "string",
        "description": "Das Aktien-Tickersymbol, z.B. AAPL für Apple Inc."
      }
    },
    "required": ["ticker"]
  }
}
```

### 5.2 Input Examples (Beta)

Für komplexe Tools können Input Examples helfen:

```json
{
  "name": "get_weather",
  "description": "...",
  "input_schema": { ... },
  "input_examples": [
    {
      "location": "San Francisco, CA",
      "unit": "fahrenheit"
    },
    {
      "location": "Tokyo, Japan",
      "unit": "celsius"
    },
    {
      "location": "New York, NY"
    }
  ]
}
```

### 5.3 Tool Choice erzwingen

```python
# Spezifisches Tool erzwingen
tool_choice = {"type": "tool", "name": "get_weather"}

# Irgendein Tool verwenden
tool_choice = {"type": "any"}

# Auto (Standard)
tool_choice = {"type": "auto"}
```

### 5.4 Parallele Tool-Calls

Für maximale Effizienz:

```xml
<use_parallel_tool_calls>
Rufe mehrere unabhängige Tools gleichzeitig auf.
Beim Lesen von 3 Dateien: führe 3 Read-Calls parallel aus.
Maximiere parallele Tool-Calls wo möglich.
</use_parallel_tool_calls>
```

### 5.5 Tool-Ergebnisse formatieren

**Wichtig**: `tool_result` muss ZUERST im Content-Array stehen:

```json
// ❌ FALSCH - Text vor tool_result
{
  "role": "user",
  "content": [
    {"type": "text", "text": "Hier sind die Ergebnisse:"},
    {"type": "tool_result", "tool_use_id": "toolu_01", ...}
  ]
}

// ✅ RICHTIG - tool_result zuerst
{
  "role": "user",
  "content": [
    {"type": "tool_result", "tool_use_id": "toolu_01", ...},
    {"type": "text", "text": "Was soll ich als nächstes tun?"}
  ]
}
```

---

## 6. CLAUDE CODE OPTIMIERUNGEN

### 6.1 Proaktive vs. Konservative Aktion

**Proaktiv** (macht Änderungen ohne zu fragen):
```xml
<default_to_action>
Implementiere Änderungen standardmäßig, anstatt sie nur vorzuschlagen.
Wenn die Absicht unklar ist, leite die wahrscheinlichste Aktion ab
und verwende Tools, um fehlende Details zu entdecken.
</default_to_action>
```

**Konservativ** (fragt vor Änderungen):
```xml
<do_not_act_before_instructions>
Springe nicht in Implementierung oder Dateiänderungen, es sei denn,
du wirst klar instruiert, Änderungen vorzunehmen. Bei mehrdeutiger
Absicht bevorzuge Information, Recherche und Empfehlungen.
</do_not_act_before_instructions>
```

### 6.2 Code-Exploration vor Änderungen

```xml
<investigate_before_answering>
Spekuliere nicht über Code, den du nicht geöffnet hast.
Wenn der Benutzer eine Datei referenziert, MUSST du sie lesen,
bevor du antwortest. Untersuche und lese relevante Dateien,
bevor du Fragen zum Codebase beantwortest.
</investigate_before_answering>
```

### 6.3 Überengineering vermeiden

```xml
<avoid_overengineering>
Vermeide Überengineering. Mache nur direkt angeforderte oder
klar notwendige Änderungen. Halte Lösungen einfach und fokussiert.

Füge keine Features hinzu, refaktoriere nicht und mache keine
"Verbesserungen" ohne Anfrage. Ein Bug-Fix benötigt kein Code-Cleanup
drumherum. Ein einfaches Feature benötigt keine Extra-Konfigurierbarkeit.
</avoid_overengineering>
```

---

## 7. AUSGABEFORMATIERUNG UND KOMMUNIKATION

### 7.1 Verbosity kontrollieren

Claude 4.5 ist knapper als Vorgänger. Für mehr Updates:

```xml
<provide_progress_updates>
Gib nach Abschluss von Tool-Aufgaben eine kurze Zusammenfassung
der geleisteten Arbeit. Halte den Benutzer über Fortschritte informiert.
</provide_progress_updates>
```

### 7.2 Markdown minimieren

Um übermäßiges Markdown zu reduzieren:

```xml
<avoid_excessive_markdown>
Schreibe längere Inhalte in klarer, fließender Prosa mit vollständigen
Absätzen und Sätzen. Verwende Markdown hauptsächlich für:
- `inline code`
- Codeblöcke
- Einfache Überschriften

Vermeide **bold** und *italics* außer wo absolut nötig.
Verwende Listen nur, wenn sie wirklich die Lesbarkeit verbessern.
</avoid_excessive_markdown>
```

### 7.3 Output-Styles (Claude Code)

Benutzerdefinierte Output-Styles erstellen:

```bash
/output-style custom-name
```

In `.claude/output-styles/custom-name.md`:
```markdown
# Custom Output Style

Verwende einen technischen, präzisen Ton.
Minimiere Erklärungen, maximiere Code-Beispiele.
Keine Emoji, keine übermäßige Formatierung.
```

---

## 8. LANGFRISTIGE AUFGABEN UND STATE MANAGEMENT

### 8.1 Multi-Context-Window Workflows

Für Aufgaben über mehrere Context-Fenster:

1. **Unterschiedliche Prompts für erste und folgende Fenster**
   - Erstes Fenster: Framework/Tests erstellen
   - Folgende Fenster: An Todo-Listen iterieren

2. **Tests vor Implementierung schreiben**
   ```json
   {
     "tests": [
       {"id": 1, "name": "feature_x", "status": "not_started"},
       {"id": 2, "name": "feature_y", "status": "in_progress"},
       {"id": 3, "name": "feature_z", "status": "completed"}
     ]
   }
   ```

3. **Git für State-Tracking**
   ```bash
   git log --oneline  # Claude kann Historie überprüfen
   git status         # Aktueller Stand
   ```

4. **Strukturierte Formate für State**
   - JSON für strukturierte Daten
   - Plain Text für Notizen
   - Git für Code-Checkpoints

### 8.2 Context Awareness

```xml
<unlimited_context_awareness>
Dein Context-Fenster wird automatisch komprimiert, wenn es sich
der Grenze nähert, sodass du unbegrenzt weitermachen kannst.
Daher stoppe Aufgaben nicht früh wegen Token-Budgets.
Sei so ausdauernd wie möglich und führe Aufgaben vollständig durch.
</unlimited_context_awareness>
```

---

## 9. MODEL-SPEZIFISCHE EMPFEHLUNGEN

### 9.1 Claude Sonnet 4.5
**Stärken:**
- Beste Performance für Tool Use
- Exzellente parallele Tool-Calls
- Präzises Instruction Following
- Schnell und kosteneffizient

**Ideal für:**
- Code-Generierung
- Automatisierte Workflows
- API-Integration
- Produktions-Anwendungen

### 9.2 Claude Opus 4.5
**Stärken:**
- Beste für komplexes Reasoning
- Erweiterte Thinking-Fähigkeiten
- Kreativere Problemlösungen
- Besseres Frontend-Design

**Ideal für:**
- Forschung und Analyse
- Komplexe Architektur-Entscheidungen
- UI/UX-Design
- Kreative Aufgaben

### 9.3 Claude Haiku 4.5
**Stärken:**
- Schnellster und günstigster
- Gut für einfache Aufgaben
- Niedrige Latenz

**Ideal für:**
- Einfache Transformationen
- Schnelle Queries
- Hohe Durchsatzraten
- Kosten-sensitive Anwendungen

**Wichtig:** Haiku benötigt explizites Prompting für parallele Tool-Calls.

---

## 10. SPEZIELLE OPTIMIERUNGEN

### 10.1 Frontend Design (Opus 4.5)

Für charaktervolles, nicht-generisches Design:

```xml
<frontend_aesthetics>
Vermeide generische "AI Slop" Ästhetik. Wähle stattdessen:

Typografie:
- Schöne, unique Fonts (nicht Inter, Roboto, Arial)
- Font-Paarungen mit Charakter
- Lesbarkeit über Trends

Farbgestaltung:
- Kohärente Farbpaletten
- Starke, durchdachte Akzentfarben
- Natürliche oder dramatische Kontraste

Interaktivität:
- Durchdachte Animationen
- Mikro-Interaktionen mit Zweck
- Smooth Transitions

Layout:
- Atmosphärische Hintergründe mit Tiefenwirkung
- Bewusster Weißraum
- Visuelles Gewicht und Balance
</frontend_aesthetics>
```

### 10.2 Lange Dokumente verarbeiten

Für 100K+ Token Dokumente:

```xml
<long_document_processing>
1. Lies das gesamte Dokument sorgfältig
2. Extrahiere relevante Quotes in <scratchpad>
3. Organisiere Informationen nach Themen
4. Beantworte basierend auf extrahierten Daten

Verwende Zitat-Extraktion für bessere Accuracy:
<scratchpad>
Relevante Zitate:
"Quote 1 von Seite X..."
"Quote 2 von Seite Y..."
</scratchpad>
</long_document_processing>
```

### 10.3 Code-Review optimieren

```xml
<code_review_instructions>
Beim Review von Code:

1. Lese alle relevanten Dateien vollständig
2. Verstehe den Kontext und die Architektur
3. Identifiziere:
   - Bugs und potenzielle Fehler
   - Sicherheitsprobleme
   - Performance-Bottlenecks
   - Code-Smell und Anti-Patterns
   - Fehlende Tests oder Edge Cases

4. Priorisiere Feedback:
   - CRITICAL: Sicherheit und Bugs
   - HIGH: Performance und Architektur
   - MEDIUM: Code-Qualität
   - LOW: Style und Präferenzen

5. Gib konkrete, umsetzbare Empfehlungen
</code_review_instructions>
```

---

## 11. PROMPT-TEMPLATE FÜR PROMPT-IMPROVER

Basierend auf allen Best Practices, hier ein Template für deinen Prompt-Improver:

```xml
<system_instruction>
Du bist ein Expert für Claude Prompt Engineering. Deine Aufgabe ist es,
Prompts zu analysieren und zu verbessern, speziell für Claude 4.x Modelle
und Claude Code.

Fokussiere auf:
1. Klarheit und Explizitheit
2. Strukturierung mit XML-Tags
3. Kontext und Motivation
4. Tool Use Best Practices
5. Model-spezifische Optimierungen
</system_instruction>

<workflow>
Für jeden Prompt-Entwurf:

1. ANALYSE
   - Identifiziere Ziel und Anwendungsfall
   - Erkenne fehlenden Kontext
   - Finde vage oder mehrdeutige Anweisungen
   - Bewerte Struktur und Organisation

2. VERBESSERUNGEN
   - Füge XML-Struktur hinzu
   - Mache Anweisungen explizit
   - Ergänze Kontext und Motivation
   - Optimiere für Zielmodell (Sonnet/Opus/Haiku)
   - Füge Beispiele hinzu wo hilfreich

3. OUTPUT
   Präsentiere:
   <original_prompt>
   {{ORIGINAL_PROMPT}}
   </original_prompt>

   <analysis>
   - Stärken: ...
   - Schwächen: ...
   - Fehlender Kontext: ...
   - Optimierungspotential: ...
   </analysis>

   <improved_prompt>
   {{VERBESSERTER_PROMPT}}
   </improved_prompt>

   <explanation>
   Erklärung der Änderungen:
   - Änderung 1: Warum und wie
   - Änderung 2: Warum und wie
   ...
   </explanation>

   <metadata>
   - Empfohlenes Modell: Sonnet 4.5 / Opus 4.5 / Haiku 4.5
   - Anwendungsfall: Code / Analyse / Kreativ / ...
   - Komplexität: Niedrig / Mittel / Hoch
   </metadata>
</workflow>

<quality_checklist>
Stelle sicher, dass der verbesserte Prompt:
✓ Klare, explizite Anweisungen enthält
✓ Ausreichend Kontext bietet
✓ XML-Tags für Struktur nutzt
✓ Beispiele enthält (wenn hilfreich)
✓ Für das Zielmodell optimiert ist
✓ Output-Format definiert
✓ Edge Cases berücksichtigt
</quality_checklist>

<constraints>
- Verwende KEINE generischen Verbesserungen ohne Begründung
- Behalte die ursprüngliche Intention bei
- Füge nur notwendige Komplexität hinzu
- Optimiere für das spezifische Zielmodell
</constraints>
```

---

## 12. WICHTIGSTE RESSOURCEN

### Offizielle Dokumentation

1. **Claude Prompt Engineering Best Practices**
   - [Claude 4 Best Practices](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices)
   - [Prompt Engineering Overview](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/overview)

2. **Tool Use & Function Calling**
   - [Implement Tool Use](https://docs.anthropic.com/en/docs/build-with-claude/tool-use)
   - API Documentation

3. **Extended Thinking**
   - [Extended Thinking Guide](https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking)

4. **Claude Code**
   - [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
   - [Workbench Guide](https://support.claude.com/en/articles/8606378-how-do-i-use-the-workbench)

5. **Long Context**
   - [Prompting for Long Context](https://www.anthropic.com/news/prompting-long-context)

### Community Ressourcen

- [Anthropic Prompt Engineering Interactive Tutorial](https://github.com/anthropics/prompt-eng-interactive-tutorial)
- [AWS Claude 3 Prompt Engineering Samples](https://github.com/aws-samples/prompt-engineering-with-anthropic-claude-v-3)

---

## 13. ZUSAMMENFASSUNG: KEY TAKEAWAYS

### Für Claude 4.x allgemein:
1. ✅ Sei extrem explizit und spezifisch
2. ✅ Liefere Kontext und Motivation
3. ✅ Nutze XML-Tags für Struktur
4. ✅ Gib konkrete Beispiele
5. ✅ Fördere Step-by-Step Reasoning

### Für Tool Use:
1. ✅ Extrem detaillierte Tool-Beschreibungen
2. ✅ Maximiere parallele Tool-Calls
3. ✅ tool_result muss zuerst im Content-Array stehen
4. ✅ Nutze Input Examples für komplexe Tools

### Für Claude Code:
1. ✅ Immer Dateien lesen vor Änderungen
2. ✅ Nutze CLAUDE.md für Projekt-Kontext
3. ✅ Vermeide Überengineering
4. ✅ State Management für lange Aufgaben

### Für Extended Thinking:
1. ✅ Budget: 10K-16K Tokens für komplexe Aufgaben
2. ✅ Prompt nach Denken anpassen
3. ✅ Nutze für Reasoning, nicht für einfache Tasks

### Für Frontend (Opus):
1. ✅ Vermeide generische Fonts und Farben
2. ✅ Durchdachte Animationen und Interaktionen
3. ✅ Kohärente, charaktervolle Ästhetik

---

**Stand:** Dezember 2025
**Modelle:** Claude Sonnet 4.5, Claude Opus 4.5, Claude Haiku 4.5
**Quellen:** Offizielle Anthropic Dokumentation, Claude Code Guide
