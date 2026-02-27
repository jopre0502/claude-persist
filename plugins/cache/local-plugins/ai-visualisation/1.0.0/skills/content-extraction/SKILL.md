---
name: content-extraction
description: Extrahiert und strukturiert Inhalte aus User-Prompts via LLM-Analyse fuer Visualisierungen. Erstellt content.json mit Sections, Diagramm-Beschreibungen und Metadaten.
---

# Content-Extraction Skill

## Zweck

Transformiert unstrukturierte Eingaben (User-Prompts, Texte, Daten) in ein strukturiertes `content.json`-Format, das von den nachfolgenden Visualisierungs-Agenten verarbeitet werden kann.

## Workflow

```
User-Input (Text, Prompt, Daten)
    ↓
1. LLM-Analyse des Inputs
    ↓
2. Strukturierung nach Schema
    ↓
3. Output: content.json
```

## LLM-Extraktions-Strategien

Fuer die Inhaltsextraktion nutzt der Content-Agent direkte LLM-Analyse:

| Strategie | Verwendung | Beschreibung |
|-----------|------------|--------------|
| Hauptidee | Kernaussage identifizieren | LLM extrahiert zentrale These und Titel |
| Ideen-Extraktion | Alle Ideen sammeln | Strukturierte Auflistung aller Kernpunkte |
| Einsichten | Tiefere Erkenntnisse | Zusammenhaenge und Implikationen ableiten |
| Zusammenfassung | Kompakte Uebersicht | Verdichtung auf wesentliche Aussagen |
| Empfehlungen | Handlungsempfehlungen | Actionable Items aus dem Input ableiten |

### Strategie-Auswahl nach Use Case

| Visualisierungs-Typ | Empfohlene Strategien |
|---------------------|----------------------|
| Konzept-Erklaerung | Hauptidee → Ideen-Extraktion |
| Prozess/Flow | Einsichten (enthaelt Schritte und Ablaeufe) |
| Vergleich | Einsichten → Empfehlungen |
| Dashboard | Zusammenfassung → Hauptidee |
| Praesentation | Umfassende Analyse (alle Strategien) |

## Output-Format

Das Ergebnis ist eine `content.json`-Datei nach folgendem Schema:

```json
{
  "title": "Haupttitel der Visualisierung",
  "subtitle": "Optionaler Untertitel",
  "sections": [
    {
      "id": "section-1",
      "type": "text|diagram|chart|icon-grid|comparison|quote",
      "heading": "Abschnittsueberschrift",
      "content": { }
    }
  ],
  "assets": [],
  "metadata": {
    "source": "Ursprung der Daten",
    "date": "2026-01-07"
  }
}
```

Siehe [content.schema.json](references/content.schema.json) fuer das vollstaendige JSON-Schema.

## Section-Typen

### text
Einfacher Textabschnitt mit optionalen Aufzaehlungen.

```json
{
  "type": "text",
  "heading": "Einleitung",
  "content": {
    "paragraphs": ["Absatz 1", "Absatz 2"],
    "bullets": ["Punkt 1", "Punkt 2"]
  }
}
```

### diagram
Markierung fuer Mermaid oder D2-Diagramm.

```json
{
  "type": "diagram",
  "heading": "Prozessablauf",
  "content": {
    "diagramType": "mermaid|d2",
    "description": "Beschreibung was dargestellt werden soll",
    "elements": ["Schritt A", "Schritt B", "Schritt C"],
    "relationships": [
      {"from": "Schritt A", "to": "Schritt B", "label": "fuehrt zu"}
    ]
  }
}
```

### chart
Markierung fuer Vega-Lite-Datenvisualisierung.

```json
{
  "type": "chart",
  "heading": "Umsatzentwicklung",
  "content": {
    "chartType": "bar|line|pie|scatter|heatmap",
    "data": [
      {"category": "Q1", "value": 100},
      {"category": "Q2", "value": 150}
    ],
    "xAxis": "category",
    "yAxis": "value"
  }
}
```

### icon-grid
Raster mit Icons und Beschreibungen (Lucide).

```json
{
  "type": "icon-grid",
  "heading": "Unsere Werte",
  "content": {
    "items": [
      {"icon": "heart", "title": "Leidenschaft", "description": "..."},
      {"icon": "target", "title": "Fokus", "description": "..."}
    ],
    "columns": 3
  }
}
```

### comparison
Vergleichstabelle.

```json
{
  "type": "comparison",
  "heading": "Optionen im Vergleich",
  "content": {
    "headers": ["Kriterium", "Option A", "Option B"],
    "rows": [
      ["Preis", "€100", "€150"],
      ["Qualitaet", "Gut", "Sehr gut"]
    ]
  }
}
```

### quote
Hervorgehobenes Zitat.

```json
{
  "type": "quote",
  "heading": null,
  "content": {
    "text": "Das Zitat hier",
    "author": "Name",
    "source": "Quelle"
  }
}
```

## Extraktions-Workflow

### Schritt 1: Input analysieren

Bestimme den Visualisierungs-Typ basierend auf dem User-Prompt:

- "Erklaere..." → Konzept-Erklaerung
- "Zeige den Prozess..." → Flow/Diagramm
- "Vergleiche..." → Comparison
- "Visualisiere die Daten..." → Chart
- "Praesentiere..." → Gemischt

### Schritt 2: LLM-Extraktion

```
# Beispiel-Ablauf fuer Konzept-Erklaerung
1. Hauptidee extrahieren
   → Ergibt: title, core message

2. Ideen strukturiert sammeln
   → Ergibt: sections mit type "text" oder "icon-grid"

3. Zusammenhaenge ableiten
   → Ergibt: zusaetzliche sections, ggf. type "diagram"
```

### Schritt 3: Strukturieren

Transformiere die LLM-Ergebnisse in das content.json-Format:

1. `title` aus Hauptidee-Extraktion
2. `sections` aus kombinierten Analyse-Ergebnissen
3. Identifiziere Beziehungen fuer `diagram`-Sections
4. Extrahiere Datenpunkte fuer `chart`-Sections

### Schritt 4: Validieren

Pruefe gegen [content.schema.json](references/content.schema.json):
- Alle required-Felder vorhanden?
- Section-Types korrekt?
- Diagramm-Elemente konsistent?

## Beispiel

### Input
```
Erstelle eine Infografik ueber die Vorteile von Remote Work.
```

### LLM-Analyse
1. Hauptidee → "Remote Work: Flexibilitaet und Produktivitaet"
2. Ideen-Extraktion → 5 Hauptvorteile
3. Einsichten → Zusammenhaenge zwischen Vorteilen

### Output (content.json)
```json
{
  "title": "Remote Work: Flexibilitaet und Produktivitaet",
  "subtitle": "Die wichtigsten Vorteile im Ueberblick",
  "sections": [
    {
      "id": "intro",
      "type": "text",
      "heading": "Warum Remote Work?",
      "content": {
        "paragraphs": ["Remote Work veraendert die Arbeitswelt..."]
      }
    },
    {
      "id": "benefits",
      "type": "icon-grid",
      "heading": "Die 5 Hauptvorteile",
      "content": {
        "items": [
          {"icon": "clock", "title": "Zeitersparnis", "description": "Kein Pendeln"},
          {"icon": "home", "title": "Work-Life-Balance", "description": "Flexibler Alltag"},
          {"icon": "trending-up", "title": "Produktivitaet", "description": "Weniger Ablenkung"},
          {"icon": "globe", "title": "Talentpool", "description": "Weltweit rekrutieren"},
          {"icon": "leaf", "title": "Nachhaltigkeit", "description": "Weniger CO2"}
        ],
        "columns": 3
      }
    },
    {
      "id": "flow",
      "type": "diagram",
      "heading": "Der Zusammenhang",
      "content": {
        "diagramType": "mermaid",
        "description": "Wie die Vorteile zusammenwirken",
        "elements": ["Flexibilitaet", "Zufriedenheit", "Produktivitaet", "Erfolg"],
        "relationships": [
          {"from": "Flexibilitaet", "to": "Zufriedenheit", "label": "steigert"},
          {"from": "Zufriedenheit", "to": "Produktivitaet", "label": "foerdert"},
          {"from": "Produktivitaet", "to": "Erfolg", "label": "fuehrt zu"}
        ]
      }
    }
  ],
  "metadata": {
    "date": "2026-01-07"
  }
}
```

## Anti-Patterns

❌ **Nicht tun:**
- LLM-Output ohne Nachbearbeitung uebernehmen
- Alle Sections als `text` markieren
- Beziehungen ignorieren (keine Diagramme generieren)
- Daten ohne Struktur in `chart`-Sections packen

✅ **Stattdessen:**
- LLM-Output intelligent auf Section-Types mappen
- Zusammenhaenge als `diagram`-Sections erfassen
- Aufzaehlungen als `icon-grid` strukturieren
- Vergleiche als `comparison`-Tabellen formatieren

---

> **Upgrade-Pfad:** Fabric MCP-Patterns koennen kuenftig als zusaetzliche Extraktions-Engine integriert werden (mcp__fabric-mcp-server__extract_*).
