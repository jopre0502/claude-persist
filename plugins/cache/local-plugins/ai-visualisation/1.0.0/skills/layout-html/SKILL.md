---
name: layout-html
description: Generiert semantische HTML-Strukturen aus content.json. Nutzt Lucide-Icons fuer visuelle Elemente. Enthaelt SmartArt Inline-SVG Templates fuer Consulting-Visuals. Verwende diesen Skill wenn HTML-Layouts fuer Visualisierungen erstellt werden sollen.
---

# Layout-HTML Skill

## Zweck

Transformiert content.json in semantische HTML-Strukturen, die vom Assembly-Agent in das finale Template eingefuegt werden. Fokus auf Struktur, nicht Styling (CSS kommt vom CI-Theme).

## Input

Vollstaendige content.json mit allen Sections.

## Output

HTML-Fragment (ohne `<html>`, `<head>`, `<body>`):

```html
<header>
    <h1>Haupttitel</h1>
    <p class="subtitle">Untertitel</p>
</header>

<section id="intro" class="text">
    <h2>Einleitung</h2>
    <p>Absatz hier...</p>
</section>

<!-- Weitere Sections -->
```

## Section-Typ -> HTML-Mapping

### text

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

->

```html
<section id="einleitung" class="text">
    <h2>Einleitung</h2>
    <p>Absatz 1</p>
    <p>Absatz 2</p>
    <ul>
        <li>Punkt 1</li>
        <li>Punkt 2</li>
    </ul>
</section>
```

### icon-grid

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

->

```html
<section id="unsere-werte" class="icon-grid">
    <h2>Unsere Werte</h2>
    <div class="icon-grid-container" style="--columns: 3">
        <div class="icon-item">
            <i data-lucide="heart"></i>
            <h3>Leidenschaft</h3>
            <p>...</p>
        </div>
        <div class="icon-item">
            <i data-lucide="target"></i>
            <h3>Fokus</h3>
            <p>...</p>
        </div>
    </div>
</section>
```

### comparison

```json
{
  "type": "comparison",
  "heading": "Optionen im Vergleich",
  "content": {
    "headers": ["Kriterium", "Option A", "Option B"],
    "rows": [
      ["Preis", "100 EUR", "150 EUR"],
      ["Qualitaet", "Gut", "Sehr gut"]
    ]
  }
}
```

->

```html
<section id="optionen-im-vergleich" class="comparison">
    <h2>Optionen im Vergleich</h2>
    <table class="comparison-table">
        <thead>
            <tr>
                <th>Kriterium</th>
                <th>Option A</th>
                <th>Option B</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>Preis</td>
                <td>100 EUR</td>
                <td>150 EUR</td>
            </tr>
            <tr>
                <td>Qualitaet</td>
                <td>Gut</td>
                <td>Sehr gut</td>
            </tr>
        </tbody>
    </table>
</section>
```

### quote

```json
{
  "type": "quote",
  "content": {
    "text": "Innovation unterscheidet...",
    "author": "Steve Jobs",
    "source": "Interview 2005"
  }
}
```

->

```html
<section class="quote">
    <blockquote>
        <p>Innovation unterscheidet...</p>
        <footer>
            <cite>Steve Jobs</cite>
            <span class="source">Interview 2005</span>
        </footer>
    </blockquote>
</section>
```

### diagram (Platzhalter)

Diagramme werden als Platzhalter markiert, die der Assembly-Agent befuellt:

```html
<section id="prozessablauf" class="diagram">
    <h2>Prozessablauf</h2>
    <!-- DIAGRAM_PLACEHOLDER: prozessablauf -->
</section>
```

### chart (Platzhalter)

```html
<section id="umsatzentwicklung" class="chart">
    <h2>Umsatzentwicklung</h2>
    <div id="chart-umsatzentwicklung"></div>
</section>
```

### smartart (Inline-SVG)

SmartArt generiert Consulting-Style Visuals als Inline-SVG, CI-konform ueber CSS-Variablen.

**Verfuegbare Templates:**

| smartartType | Use Case | Limits |
|--------------|----------|--------|
| `matrix_2x2` | Portfolio, Risiko-Matrix | max 12 Punkte |
| `chevron_process` | Phasen, Journey | 3-7 Steps |
| `pillars` | Strategie-Saeulen | 3-6 Saeulen |
| `timeline` | Meilensteine, Releases | 4-12 Items |
| `hierarchy` | Org-Chart, Governance | 3-5 Ebenen |

**Beispiel (matrix_2x2):**

```json
{
  "type": "smartart",
  "heading": "Projekt-Priorisierung",
  "content": {
    "smartartType": "matrix_2x2",
    "caption": "Aufwand vs. Nutzen",
    "data": {
      "axisX": { "label": "Aufwand", "lowLabel": "Gering", "highLabel": "Hoch" },
      "axisY": { "label": "Nutzen", "lowLabel": "Gering", "highLabel": "Hoch" },
      "quadrantLabels": {
        "topLeft": "Quick Wins",
        "topRight": "Strategisch",
        "bottomLeft": "Fill-Ins",
        "bottomRight": "Vermeiden"
      },
      "points": [
        { "label": "Feature A", "x": 0.2, "y": 0.8 }
      ]
    }
  }
}
```

->

```html
<section id="projekt-priorisierung" class="smartart">
    <h2>Projekt-Priorisierung</h2>
    <figure class="smartart smartart-matrix_2x2">
        <svg viewBox="0 0 800 450" class="sa-viz">
            <!-- Quadranten, Achsen, Punkte -->
        </svg>
        <figcaption>Aufwand vs. Nutzen</figcaption>
    </figure>
</section>
```

**Styling:** SmartArt nutzt `--sa-*` CSS-Variablen, die auf `--ci-*` mappen.

**SVG-Generierung fuer alle Templates:** -> `references/smartart-svg.md`

## Multi-Element Sections

Eine Section kann mehrere Elemente enthalten, wenn es den Inhalt besser vermittelt.

### Struktur

```json
{
  "id": "tagesablauf",
  "heading": "Typischer Tagesablauf",
  "elements": [
    {
      "type": "diagram",
      "content": { "engine": "mermaid", "source": "..." },
      "layout": "full"
    },
    {
      "type": "text",
      "content": { "bullets": ["Punkt 1", "Punkt 2"] },
      "layout": "full"
    }
  ]
}
```

### HTML-Output

```html
<section id="tagesablauf" class="multi-element">
    <h2>Typischer Tagesablauf</h2>
    <div class="section-elements">
        <div class="element element-full diagram">
            <!-- DIAGRAM_PLACEHOLDER: tagesablauf-0 -->
        </div>
        <div class="element element-full text">
            <ul>
                <li>Punkt 1</li>
                <li>Punkt 2</li>
            </ul>
        </div>
    </div>
</section>
```

### Layout-Optionen

| Layout | CSS-Klasse | Breite | Verwendung |
|--------|------------|--------|------------|
| `full` | `.element-full` | 100% | Untereinander (Default) |
| `half` | `.element-half` | 50% | Side-by-Side |
| `third` | `.element-third` | 33% | Drei nebeneinander |

### Side-by-Side

```json
{
  "id": "vergleich",
  "heading": "Vorher vs. Nachher",
  "elements": [
    { "type": "diagram", "content": {"..."}, "layout": "half" },
    { "type": "diagram", "content": {"..."}, "layout": "half" }
  ]
}
```

-> Container erhaelt zusaetzlich `.section-elements-row` fuer `flex-direction: row`.

### Regeln

| Regel | Beschreibung |
|-------|-------------|
| **Max. 3 Elemente** | KISS: Nicht mehr als 3 Elemente pro Section |
| **Konsistente Layouts** | Alle `half` oder alle `third`, nicht mischen |
| **Print-Kompatibilitaet** | Bei Print: `full` bevorzugen |
| **Semantische Gruppierung** | Nur zusammengehoerige Inhalte gruppieren |

## Lucide Icons

### Integration

Icons werden ueber `data-lucide` Attribute eingebunden:

```html
<i data-lucide="icon-name"></i>
```

Die Lucide-Library ersetzt diese bei Initialisierung durch SVG.

### Haeufig verwendete Icons

| Kategorie | Icons |
|-----------|-------|
| **Navigation** | `arrow-right`, `arrow-left`, `chevron-down`, `menu`, `x` |
| **Aktionen** | `check`, `plus`, `minus`, `edit`, `trash`, `download`, `upload` |
| **Status** | `check-circle`, `alert-circle`, `info`, `help-circle` |
| **Kommunikation** | `mail`, `phone`, `message-circle`, `send` |
| **Business** | `briefcase`, `building`, `users`, `user`, `chart-bar` |
| **Zeit** | `clock`, `calendar`, `timer` |
| **Technologie** | `code`, `database`, `server`, `cloud`, `wifi` |
| **Natur** | `sun`, `moon`, `leaf`, `tree` |
| **Konzepte** | `lightbulb`, `target`, `flag`, `star`, `heart`, `zap` |
| **Richtungen** | `trending-up`, `trending-down`, `move`, `maximize` |

### Icon mit Text

```html
<div class="icon-item">
    <i data-lucide="zap"></i>
    <div>
        <h3>Schnelligkeit</h3>
        <p>Blitzschnelle Reaktionszeiten</p>
    </div>
</div>
```

**Weitere Icon-Patterns (Button, Liste):** -> `references/lucide-icons.md`

## ID-Generierung

Section-IDs werden aus dem Heading generiert:

```javascript
function generateId(heading) {
  return heading
    .toLowerCase()
    .replace(/ae/g, 'ae')
    .replace(/oe/g, 'oe')
    .replace(/ue/g, 'ue')
    .replace(/ss/g, 'ss')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
}

// "Unsere Werte" -> "unsere-werte"
// "Ueber uns" -> "ueber-uns"
```

## Semantische HTML-Regeln

**Verwenden:**
- `<header>` fuer Titel-Bereich
- `<section>` fuer Inhalts-Sektionen
- `<article>` fuer eigenstaendige Inhalte
- `<figure>` und `<figcaption>` fuer Bilder/Diagramme
- `<blockquote>` fuer Zitate
- `<table>` fuer tabellarische Daten

**Vermeiden:**
- `<div>` wenn semantische Alternative existiert
- Inline-Styles (CSS-Klassen nutzen)
- Leere Elemente ohne Inhalt
- Verschachtelte `<section>` ohne Grund

## Klassen-Konventionen

| Element | Klasse | Verwendung |
|---------|--------|------------|
| Section | `.text`, `.icon-grid`, `.comparison`, `.quote`, `.diagram`, `.chart`, `.smartart` | Typ-basiert |
| Container | `.card`, `.box`, `.container` | Layout-Wrapper |
| Grid | `.icon-grid-container`, `.grid-2`, `.grid-3` | Spalten-Layout |
| Tabelle | `.comparison-table` | Vergleichstabellen |
| Icon | `.icon-item`, `.icon-list` | Icon-Kombinationen |

## Barrierefreiheit

```html
<!-- Alt-Text fuer Bilder -->
<img src="./assets/logo.png" alt="Firmenlogo der Beispiel GmbH" />

<!-- ARIA fuer Icons -->
<i data-lucide="check" aria-hidden="true"></i>
<span class="sr-only">Erledigt</span>

<!-- Screenreader-only Text -->
<span class="sr-only">Zum Hauptinhalt springen</span>
```

CSS fuer `.sr-only`:

```css
.sr-only {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    border: 0;
}
```

---

**Weitere Referenzen:**
- SmartArt SVG-Generierung: -> `references/smartart-svg.md`
- Print-Styles (16:9): -> `references/print-styles.md`
- Bild-Fallback + Navigation: -> `references/navigation.md`
- Icon-Patterns: -> `references/lucide-icons.md`
