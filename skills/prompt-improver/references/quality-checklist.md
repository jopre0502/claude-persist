# Quality Checklist für Claude-optimierte Prompts

Verwende diese Checklist zur finalen Validierung verbesserter Prompts.

## ✅ Struktur & Organisation

- [ ] **Rollenund Persona-Definition** am Anfang klar definiert
- [ ] **Hierarchische Struktur** mit XML-Tags oder Markdown vorhanden
- [ ] **Logische Abschnitte** mit klaren Überschriften organisiert
- [ ] **Standard-Tags vorhanden**: `<system_instruction>`, `<context>`, `<task>`, `<constraints>`, `<output_format>`

## ✅ Anweisungen & Klarheit

- [ ] **Spezifische, actionable Anweisungen** (nicht vage oder generisch)
- [ ] **EXTREM explizite Formulierungen** (Claude 4.x Standard)
- [ ] **Kontext und WARUM** für Verhaltensweisen erklärt (Motivation gegeben)
- [ ] **Keine mehrdeutigen Pronomen** oder vage Referenzen
- [ ] **Aktive Sprache** und direkte Anweisungen verwendet
- [ ] **Konkrete Beispiele** wo Verhalten unklar sein könnte

## ✅ Technische Optimierungen

### Variablen
- [ ] **Variablen mit `{{VARIABLE_NAME}}`** wo sinnvoll eingebaut
- [ ] **Häufige Variablen** identifiziert: `{{USER_NAME}}`, `{{PROJECT_NAME}}`, `{{FILE_PATH}}`, `{{CURRENT_DATE}}`
- [ ] **Workbench-Kompatibilität** gegeben

### Extended Thinking (für Opus)
- [ ] **Extended Thinking konfiguriert** wenn komplex (Token Budget angegeben)
- [ ] **Budget-Empfehlung gegeben**: 1K-4K (einfach), 10K-16K (mittel), 16K+ (komplex)
- [ ] **Prompt-Anweisungen** für optimales Thinking enthalten
- [ ] **API-Parameter** dokumentiert (wenn relevant)

### Tool Use (wenn relevant)
- [ ] **Tool-Beschreibungen EXTREM detailliert** (wichtigster Faktor!)
- [ ] **input_examples** für komplexe Tools bereitgestellt
- [ ] **Parallele Tool-Calls** explizit gefördert
- [ ] **tool_result Reihenfolge** korrekt dokumentiert (ZUERST im Array)

### Scratchpad-Pattern
- [ ] **Scratchpad-Pattern** implementiert wenn Reasoning-Transparenz nötig
- [ ] **Struktur-Beispiel** gegeben für `<scratchpad>` Nutzung
- [ ] **Tags vorhanden**: `<scratchpad>`, `<thinking>`, `<analysis>`

## ✅ Beispiele & Format

- [ ] **Output-Format klar spezifiziert** mit Struktur und Tags
- [ ] **Konkrete Beispiele** mit `<example>` Tags vorhanden
- [ ] **Beispiele zeigen EXAKT** gewünschtes Verhalten (nicht generisch)
- [ ] **Edge Cases** in Beispielen abgedeckt
- [ ] **Best Practices** in Beispielen demonstriert

## ✅ Guardrails & Constraints

- [ ] **Explizite Guardrails** und Grenzen definiert
- [ ] **Boundary Conditions** klar kommuniziert
- [ ] **Was NICHT zu tun ist** spezifiziert
- [ ] **Fehlerbehandlung** beschrieben
- [ ] **Edge Cases** adressiert

## ✅ Modell-Spezifisch

- [ ] **Zielmodell identifiziert**: Sonnet 4.5 / Opus 4.5 / Haiku 4.5
- [ ] **Modell-Empfehlung begründet** mit Use Case
- [ ] **Modell-spezifische Optimierungen** angewendet:

### Für Sonnet 4.5:
- [ ] Tool Use Anweisungen explizit
- [ ] Parallele Tool-Calls maximiert
- [ ] Code-Generierung optimiert

### Für Opus 4.5:
- [ ] Extended Thinking konfiguriert
- [ ] Scratchpad-Patterns vorhanden
- [ ] Komplexes Reasoning unterstützt
- [ ] Kontext vertieft

### Für Haiku 4.5:
- [ ] Anweisungen einfach und direkt
- [ ] Explizites Prompting für parallele Calls
- [ ] Fokus auf Geschwindigkeit

## ✅ Sprache & Stil

- [ ] **Sprache**: Deutsch (Standard) oder wie gewünscht
- [ ] **Technische Begriffe** konsistent verwendet
- [ ] **Klar und präzise** formuliert
- [ ] **Keine unnötige Komplexität** eingebaut

## ✅ Claude 4.x Spezifisch

- [ ] **Extreme Explizitheit** erreicht (nicht vage)
- [ ] **Kontext und Motivation** für ALLE wichtigen Verhaltensweisen gegeben
- [ ] **Beispiele entsprechen** EXAKT dem gewünschten Output
- [ ] **Details zählen** - Spezifität maximiert

## ✅ Finale Prüfung

- [ ] **Ursprüngliche Absicht** beibehalten
- [ ] **Alle Verbesserungen** basieren auf Best Practices
- [ ] **Begründungen** für alle Änderungen vorhanden
- [ ] **Keine generischen Verbesserungen** ohne klaren Nutzen
- [ ] **Prompt ist produktionsreif**

---

## Scoring-System (Optional)

Bewerte jeden Abschnitt: 0 (fehlt) bis 3 (exzellent)

- **Struktur & Organisation**: ___ / 3
- **Anweisungen & Klarheit**: ___ / 3
- **Technische Optimierungen**: ___ / 3
- **Beispiele & Format**: ___ / 3
- **Guardrails & Constraints**: ___ / 3
- **Modell-Spezifisch**: ___ / 3
- **Sprache & Stil**: ___ / 3
- **Claude 4.x Spezifisch**: ___ / 3

**Gesamt**: ___ / 24

**Qualitätsstufen:**
- 20-24: Exzellent - Produktionsreif
- 16-19: Gut - Kleinere Verbesserungen möglich
- 12-15: Okay - Signifikante Verbesserungen nötig
- 0-11: Unzureichend - Umfassende Überarbeitung erforderlich

---

**Hinweis**: Nicht alle Punkte sind für jeden Prompt relevant (z.B. Tool Use nur wenn Tools genutzt werden). Markiere nicht-relevante Punkte als "N/A".
