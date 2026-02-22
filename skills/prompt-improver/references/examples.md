# Prompt-Verbesserungs-Beispiele

Konkrete Vor/Nach-Beispiele für typische Prompt-Optimierungen.

---

## Beispiel 1: Explizitheit erhöhen

### ❌ ORIGINAL (vage)
```
Erstelle ein Dashboard für die Analyse von Benutzerdaten.
```

### ✅ VERBESSERT (explizit)
```xml
<task>
Erstelle ein Analytics-Dashboard für Benutzerdaten. Das Dashboard soll:

1. Mehrere Visualisierungen enthalten (mindestens: Zeitreihen-Diagramm, Balkendiagramm, Heatmap)
2. Filteroptionen für Zeiträume bieten (Tag, Woche, Monat, Jahr)
3. Export-Funktionalität für CSV und PDF haben
4. Real-time Updates unterstützen (WebSocket-Verbindung)
5. Responsive Design für Mobile und Desktop implementieren

Gehe über die Basics hinaus und implementiere eine vollständig ausgestattete, produktionsreife Lösung mit Fehlerbehandlung und optimaler UX.
</task>

<constraints>
- Verwende moderne JavaScript (ES6+)
- Framework: React mit TypeScript
- Styling: Tailwind CSS
- Charts: Recharts Library
</constraints>
```

**Hauptverbesserungen:**
- Spezifische Komponenten genannt (Diagrammtypen)
- Funktionale Requirements explizit (Filter, Export, Real-time)
- Technologie-Stack definiert
- Qualitätserwartungen klar (produktionsreif, Fehlerbehandlung)

---

## Beispiel 2: Kontext und Motivation hinzufügen

### ❌ ORIGINAL (ohne WARUM)
```
Schreibe Code-Kommentare auf Englisch.
Verwende keine Abkürzungen.
Halte Funktionen kurz.
```

### ✅ VERBESSERT (mit WARUM)
```xml
<coding_standards>
<context>
Dieser Code wird von einem internationalen Team gewartet, das verschiedene Erfahrungsstufen hat. Lesbarkeit und Wartbarkeit sind kritisch für langfristigen Projekterfolg.
</context>

<standard name="Sprache">
**Was**: Schreibe alle Code-Kommentare auf Englisch.

**Warum**: Das internationale Team hat Englisch als gemeinsame Sprache. Deutsche Kommentare würden einige Entwickler ausschließen und die Zusammenarbeit erschweren.

**Beispiel**:
```python
# ✅ Calculate user's age based on birthdate
# ❌ Berechne Alter des Benutzers basierend auf Geburtsdatum
```
</standard>

<standard name="Abkürzungen">
**Was**: Verwende keine Abkürzungen in Variablen- oder Funktionsnamen.

**Warum**: Abkürzungen sind mehrdeutig und erfordern Kontext-Wissen. `usr` könnte "user" oder "user service" bedeuten. Explizite Namen sind selbst-dokumentierend und reduzieren Rückfragen.

**Beispiel**:
```python
# ✅ calculate_monthly_revenue()
# ❌ calc_mo_rev()
```
</standard>

<standard name="Funktionslänge">
**Was**: Halte Funktionen unter 50 Zeilen Code.

**Warum**: Lange Funktionen sind schwer zu testen, zu verstehen und zu debuggen. Kleine Funktionen mit einem klaren Zweck verbessern Modularität und Wiederverwendbarkeit. Bei Code-Reviews ist es einfacher, kleinere Einheiten zu überprüfen.

**Beispiel**: Splitte eine 200-Zeilen Funktion in 5 fokussierte Funktionen mit je 40 Zeilen.
</standard>
</coding_standards>
```

**Hauptverbesserungen:**
- Kontext gegeben (internationales Team, Wartbarkeit)
- WARUM für jede Regel erklärt
- Konkrete Beispiele für jede Regel
- Struktur mit XML-Tags

---

## Beispiel 3: Variablen für Workbench einbauen

### ❌ ORIGINAL (hart-codiert)
```
Analysiere die Datei config.json und erstelle einen Bericht.
Adressiere den Bericht an John Doe.
Speichere ihn im Ordner /home/user/reports/.
```

### ✅ VERBESSERT (mit Variablen)
```xml
<task>
Analysiere die Datei {{CONFIG_FILE}} und erstelle einen strukturierten Bericht.

**Zielgruppe**: {{REPORT_RECIPIENT}}
**Ausgabe-Verzeichnis**: {{OUTPUT_DIR}}
**Datum**: {{CURRENT_DATE}}
</task>

<output_format>
Der Bericht soll folgende Struktur haben:

# Konfigurationsanalyse für {{REPORT_RECIPIENT}}
**Datum**: {{CURRENT_DATE}}
**Analysierte Datei**: {{CONFIG_FILE}}

## Zusammenfassung
[...]

## Detaillierte Findings
[...]

## Empfehlungen
[...]

Speichere als: {{OUTPUT_DIR}}/config-analysis-{{CURRENT_DATE}}.md
</output_format>
```

**Hauptverbesserungen:**
- Wiederverwendbar durch `{{VARIABLEN}}`
- Workbench-kompatibel (ROT markiert wenn leer)
- Flexibel für verschiedene Use Cases
- Datum automatisch eingefügt

**Typische Variablen:**
- `{{USER_NAME}}`, `{{USER_EMAIL}}`
- `{{PROJECT_NAME}}`, `{{REPOSITORY_URL}}`
- `{{FILE_PATH}}`, `{{DIRECTORY}}`
- `{{CURRENT_DATE}}`, `{{CURRENT_TIME}}`
- `{{LANGUAGE}}`, `{{FRAMEWORK}}`

---

## Beispiel 4: Extended Thinking für Opus konfigurieren

### ❌ ORIGINAL (kein Extended Thinking)
```
Analysiere diese komplexe mathematische Gleichung und erkläre die Lösung.
```

### ✅ VERBESSERT (mit Extended Thinking)
```xml
<task>
Analysiere die folgende komplexe mathematische Gleichung und entwickle eine Schritt-für-Schritt-Lösung:

{{EQUATION}}
</task>

<approach>
Nutze ausreichend Thinking-Zeit für diese komplexe Aufgabe. Zerlege das Problem in Teilschritte und validiere jeden Schritt, bevor du fortfährst.

<thinking_process>
1. **Gleichung analysieren**: Identifiziere Terme, Operatoren, Variablen
2. **Strategie entwickeln**: Welche Lösungsmethode ist optimal?
3. **Schritt-für-Schritt Lösung**: Jeden Transformationsschritt dokumentieren
4. **Validation**: Lösung durch Rückeinsetzen verifizieren
5. **Alternative Ansätze**: Gibt es elegantere Lösungen?
</thinking_process>

Nach Abschluss jeder Phase überprüfe sorgfältig die Qualität, bevor du weitermachst.
</approach>

<output_format>
Präsentiere deine Lösung in folgendem Format:

## Analyse
[Deine Analyse der Gleichung]

## Lösungsweg
### Schritt 1: [...]
### Schritt 2: [...]
[...]

## Validation
[Beweis dass die Lösung korrekt ist]

## Alternative Ansätze
[Andere mögliche Lösungswege]
</output_format>
```

**API-Konfiguration** (Python):
```python
response = client.messages.create(
    model="claude-opus-4-5",
    max_tokens=16000,
    thinking={
        "type": "enabled",
        "budget_tokens": 16000  # Hoch für komplexe Mathematik
    },
    messages=[...]
)
```

**Hauptverbesserungen:**
- Explizite Aufforderung für Thinking-Zeit
- Strukturierter Thinking-Prozess
- Validation-Schritte eingebaut
- Extended Thinking API-Parameter dokumentiert

---

## Beispiel 5: Tool Use optimieren

### ❌ ORIGINAL (vage Tool-Beschreibung)
```json
{
  "name": "search_database",
  "description": "Searches the database",
  "input_schema": {
    "type": "object",
    "properties": {
      "query": {"type": "string"}
    }
  }
}
```

### ✅ VERBESSERT (EXTREM detailliert)
```json
{
  "name": "search_database",
  "description": "Durchsucht die Produkt-Datenbank nach Artikeln basierend auf Suchkriterien.

  **Was es macht:**
  - Führt eine Volltextsuche in Produktnamen, Beschreibungen und Tags durch
  - Unterstützt UND/ODER-Operatoren und Phrase-Suche mit Anführungszeichen
  - Gibt maximal 100 Ergebnisse zurück, sortiert nach Relevanz

  **Wann verwenden:**
  - Wenn der Benutzer nach Produkten sucht
  - Wenn Produktinformationen basierend auf Beschreibungen gefunden werden müssen
  - Für autocomplete/suggest Features

  **Wann NICHT verwenden:**
  - Für Preis- oder Verfügbarkeitsabfragen (nutze stattdessen check_inventory)
  - Für Bestellhistorie (nutze get_order_history)
  - Für exakte ID-Lookups (nutze get_product_by_id)

  **Rückgabe:**
  - Array von Produkten mit ID, Name, Preis, Kurzbeschreibung
  - Leeres Array wenn keine Treffer
  - Fehler wenn Query ungültig (zu kurz, ungültige Zeichen)",

  "input_schema": {
    "type": "object",
    "properties": {
      "query": {
        "type": "string",
        "description": "Suchbegriff oder Phrase. Mindestens 2 Zeichen. Unterstützt Wildcards (*). Beispiele: 'Laptop', 'rote Schuhe', 'iPhone 15*'"
      },
      "max_results": {
        "type": "integer",
        "description": "Maximale Anzahl Ergebnisse (1-100). Standard: 20. Höhere Werte für umfassende Suchen, niedrigere für schnelle Previews.",
        "default": 20,
        "minimum": 1,
        "maximum": 100
      },
      "category_filter": {
        "type": "string",
        "description": "Optional: Einschränkung auf Kategorie. Gültige Werte: 'electronics', 'clothing', 'books', 'home'. Leer lassen für alle Kategorien.",
        "enum": ["electronics", "clothing", "books", "home", ""]
      }
    },
    "required": ["query"]
  },

  "input_examples": [
    {
      "query": "Laptop",
      "max_results": 10,
      "category_filter": "electronics"
    },
    {
      "query": "rote Schuhe",
      "max_results": 20,
      "category_filter": "clothing"
    },
    {
      "query": "iPhone 15*",
      "max_results": 5
    }
  ]
}
```

**Im Prompt:**
```xml
<tool_use_instructions>
Nutze search_database für Produktsuchen. Rufe IMMER parallel auf wenn mehrere unabhängige Suchen nötig sind.

**Beispiel paralleler Aufruf:**
Wenn Benutzer nach "Laptop und Maus" fragt:
1. search_database(query="Laptop", category_filter="electronics")
2. search_database(query="Maus", category_filter="electronics")

Beide Calls GLEICHZEITIG ausführen, nicht sequenziell.
</tool_use_instructions>
```

**Hauptverbesserungen:**
- EXTREM detaillierte Beschreibung (Was, Wann, Wann nicht, Rückgabe)
- Alle Parameter ausführlich erklärt mit Beispielen
- input_examples für typische Use Cases
- Parallele Tool-Calls explizit gefördert
- Klar was zurückkommt und wie Fehler aussehen

---

## Beispiel 6: Scratchpad-Pattern implementieren

### ❌ ORIGINAL (ohne Scratchpad)
```
Analysiere dieses lange Dokument und beantworte die Frage:
[Dokument]
Frage: Was sind die Hauptthemen?
```

### ✅ VERBESSERT (mit Scratchpad)
```xml
<task>
Analysiere das folgende Dokument und identifiziere die Hauptthemen:

{{DOCUMENT}}

**Frage**: {{QUESTION}}
</task>

<instruction>
Bevor du antwortest, nutze ein <scratchpad> um:
1. Relevante Zitate aus dem Dokument zu extrahieren
2. Themen zu identifizieren und zu gruppieren
3. Deine Analyse zu strukturieren

Strukturiere dein Scratchpad so:

<scratchpad>
## Relevante Zitate
- "Zitat 1 von Seite X..."
- "Zitat 2 von Seite Y..."
[...]

## Identifizierte Themen
1. **Thema A**:
   - Bezug: Zitate 1, 3, 7
   - Bedeutung: ...

2. **Thema B**:
   - Bezug: Zitate 2, 5, 9
   - Bedeutung: ...

## Priorisierung
Hauptthemen (häufigst/wichtigst): ...
Nebenthemen: ...

## Schlussfolgerung
Basierend auf der Analyse: ...
</scratchpad>

<final_answer>
[Deine endgültige, strukturierte Antwort]
</final_answer>
</instruction>
```

**Beispiel Output:**
```xml
<scratchpad>
## Relevante Zitate
- "KI wird die Arbeitswelt fundamental verändern" (Seite 3)
- "42% der Unternehmen investieren in Automatisierung" (Seite 7)
- "Ethische Fragestellungen bleiben ungelöst" (Seite 12)

## Identifizierte Themen
1. **Digitale Transformation**:
   - Bezug: Zitate 1, 2, 5, 8
   - Bedeutung: Zentral, durchzieht gesamtes Dokument

2. **Ethik und KI**:
   - Bezug: Zitate 3, 6, 11
   - Bedeutung: Kritische Bedenken, Nebenthema aber wichtig

3. **Wirtschaftliche Auswirkungen**:
   - Bezug: Zitate 2, 4, 7, 9
   - Bedeutung: Praktische Konsequenzen, Hauptthema

## Priorisierung
- Hauptthemen: Digitale Transformation, Wirtschaftliche Auswirkungen
- Nebenthemen: Ethik, Rechtliche Aspekte

## Schlussfolgerung
Das Dokument fokussiert auf praktische Transformation mit kritischem Blick auf ethische Fragen.
</scratchpad>

<final_answer>
Die drei Hauptthemen des Dokuments sind:

1. **Digitale Transformation** - [...]
2. **Wirtschaftliche Auswirkungen** - [...]
3. **Ethische Fragestellungen** - [...]

[Detaillierte Ausführung]
</final_answer>
```

**Hauptverbesserungen:**
- Scratchpad-Struktur klar vorgegeben
- Reasoning-Prozess transparent
- Bessere Accuracy durch strukturierte Analyse
- Trennung von Analyse und finaler Antwort

---

## Zusammenfassung: Best Practice Patterns

| Pattern | Wann verwenden | Hauptvorteil |
|---------|---------------|--------------|
| **Explizitheit** | Immer | Claude 4.x folgt präzise |
| **WARUM-Kontext** | Bei Verhaltensregeln | Besseres Understanding |
| **Variablen** | Wiederverwendbare Prompts | Workbench-Kompatibilität |
| **Extended Thinking** | Komplexe Reasoning-Tasks | Bessere Lösungsqualität |
| **Detaillierte Tools** | Function Calling | Korrekte Tool-Nutzung |
| **Scratchpad** | Lange Dokumente, Analyse | Höhere Accuracy |

---

**Hinweis**: Diese Beispiele können als Templates für eigene Prompt-Verbesserungen verwendet werden. Passe sie an den spezifischen Use Case an.
