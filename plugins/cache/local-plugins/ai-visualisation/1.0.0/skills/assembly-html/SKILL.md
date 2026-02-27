---
name: assembly-html
description: Fuegt alle Visualisierungs-Komponenten zu standalone HTML zusammen. Erstellt Projektordner mit index.html und assets/. Multi-Style und Navigation.
---

# Assembly-HTML Skill

## Zweck

Kombiniert alle generierten Komponenten (HTML-Struktur, Kroki-SVGs, Markmap-Daten, Vega-Lite-Specs, CI-Theme) zu einem finalen, standalone Projektordner.

## Input

| Komponente | Quelle | Format |
|------------|--------|--------|
| HTML-Struktur | Layout-Agent | HTML-Fragment |
| Diagramme | Kroki (via Diagram-Agent) | SVG-Dateien |
| Mindmaps | Markmap-Skill | Markdown-String |
| Charts | Chart-Agent | Vega-Lite JSON |
| Visual Profile | content.json | Theme + Layout-Style |
| Assets | content.json | Datei-Referenzen |

## Multi-Style-Architektur

Das Assembly nutzt ein **zwei-dimensionales Style-System**:

### Dimension 1: Theme (CI-Tokens)
```
themes/
├── default.css       <- Heller Hintergrund, professionell
└── dark-gradient.css <- Dunkler Gradient, Cards auf dunklem Grund
```

### Dimension 2: Layout-Style (Patterns)
```
styles/
├── presentation/     <- Sections, Grids, Tabellen (Standard)
│   ├── components.css
│   └── template.html
└── feed-timeline/    <- Timeline mit Phasen-Cards
    ├── components.css
    └── template.html
```

### Visual Profile Auswertung

```javascript
// content.json -> visualProfile
const visualProfile = content.visualProfile || {};
const theme = visualProfile.theme || 'default';
const layoutStyle = visualProfile.layoutStyle || 'presentation';

// Pfade aufloesen
const themePath = `themes/${theme}.css`;
const stylePath = `styles/${layoutStyle}/components.css`;
const templatePath = `styles/${layoutStyle}/template.html`;
```

### Empfohlene Kombinationen

| Theme | Layout-Style | Use Case |
|-------|--------------|----------|
| `default` | `presentation` | Guides, Reports, Praesentationen |
| `default` | `feed-timeline` | Helle Timeline-Darstellung |
| `dark-gradient` | `feed-timeline` | Narrative Stories, Conversation Flows |
| `dark-gradient` | `presentation` | Dark-Mode Praesentationen |

## Output

```
output/
└── projekt-name/
    ├── index.html        <- Standalone HTML
    └── assets/           <- Diagramme + Bilder
        ├── prozess.svg       (Kroki-Output)
        ├── architektur.svg   (Kroki-Output)
        ├── logo.png          (Externe Bilder)
        └── ...
```

## Assembly-Workflow

```
1. Projektordner erstellen in ./output/
    |
2. Visual Profile auswerten (content.json)
   -> theme: default | dark-gradient
   -> layoutStyle: presentation | feed-timeline
    |
3. Template laden: styles/{layoutStyle}/template.html
    |
4. Theme injizieren: themes/{theme}.css
    |
5. Components injizieren: styles/{layoutStyle}/components.css
    |
6. HTML-Struktur einfuegen (Layout-Agent Output)
    |
7. Kroki-SVGs nach assets/ kopieren
    |
8. Markmap-Daten in Script-Block
    |
9. Vega-Lite-Specs in Script-Block
    |
10. Externe Assets nach assets/ kopieren
    |
11. index.html schreiben
```

### Style-Injection

Der Assembly-Agent muss Theme und Components **inline** injizieren (standalone):

```html
<!-- Option A: Inline (bevorzugt fuer Standalone) -->
<style>
    /* === THEME === */
    :root { --ci-primary: #0066cc; ... }

    /* === COMPONENTS === */
    .card { background: var(--ci-surface); ... }
</style>

<!-- Option B: Externe Links (fuer Development) -->
<link rel="stylesheet" href="../../themes/default.css">
<link rel="stylesheet" href="../../styles/presentation/components.css">
```

## Template-Platzhalter

### Basis-Platzhalter (alle Templates)

| Platzhalter | Ersetzt durch |
|-------------|---------------|
| `{{TITEL}}` | Titel aus content.json |
| `{{UNTERTITEL}}` | Subtitle (optional) |
| `{{AUTHOR}}` | Author aus metadata |
| `{{DATE}}` | Datum aus metadata |
| `{{VERSION}}` | Version aus metadata |
| `{{THEME_PATH}}` | Pfad zum Theme CSS |
| `{{STYLE_PATH}}` | Pfad zum Components CSS |

### Presentation-Style Platzhalter

| Platzhalter | Ersetzt durch |
|-------------|---------------|
| `{{SECTIONS}}` | Generierte HTML-Sections |
| `{{DIAGRAMS}}` | Kroki-SVG-Referenzen |
| `{{MINDMAPS}}` | Markmap-Container |
| `{{CHARTS}}` | Vega-Lite-Container |
| `{{VEGA_SPECS}}` | Vega-Lite JSON im Script |
| `{{MARKMAP_DATA}}` | Markmap Markdown im Script |

**Feed-Timeline-Style Platzhalter:** -> `references/template-placeholders.md`

## Merge-Regeln

### 1. CI-Theme Integration

```html
<style>
    :root {
        /* CI-Theme Variablen */
        --ci-primary: #0066cc;
        ...
    }
</style>
```

### 2. Kroki-Diagramme (SVG)

Alle Diagramme (Mermaid, D2, PlantUML, etc.) werden von Kroki zu SVG gerendert:

```html
<section class="diagram" id="prozess">
    <h2>Prozessablauf</h2>
    <figure>
        <img src="./assets/prozess.svg"
             alt="Prozessablauf Diagramm" />
        <figcaption>Prozessablauf</figcaption>
    </figure>
</section>
```

**Vorteil:** Keine Runtime-Dependencies (Mermaid CDN nicht noetig) -> **100% offline-faehig**

### 3. Markmap Mindmaps (Interaktiv)

Markmap-Daten werden als Markdown-String injiziert:

```html
<section class="mindmap" id="uebersicht">
    <h2>Projektuebersicht</h2>
    <div id="markmap-uebersicht" class="markmap-container"></div>
</section>

<script>
(function() {
    var data = `
# Projekt Alpha
## Phase 1
- Konzeption
- Planung
## Phase 2
- Entwicklung
    `;
    var transformer = new markmap.Transformer();
    var result = transformer.transform(data);
    var container = document.getElementById('markmap-uebersicht');
    var svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.style.width = '100%';
    svg.style.height = '500px';
    container.appendChild(svg);
    markmap.Markmap.create(svg, null, result.root);
})();
</script>
```

### 4. Vega-Lite Charts

```html
<section class="chart" id="umsatz">
    <h2>Umsatzentwicklung</h2>
    <div id="vega-umsatz"></div>
</section>

<script>
(function() {
    var spec = {
        "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
        ...
    };
    vegaEmbed('#vega-umsatz', spec, { actions: false, renderer: 'svg' });
})();
</script>
```

## CDN Dependencies

```html
<!-- Vega-Lite fuer Charts -->
<script src="https://cdn.jsdelivr.net/npm/vega@5"></script>
<script src="https://cdn.jsdelivr.net/npm/vega-lite@5"></script>
<script src="https://cdn.jsdelivr.net/npm/vega-embed@6"></script>

<!-- Lucide Icons -->
<script src="https://unpkg.com/lucide@latest"></script>

<!-- Markmap fuer interaktive Mindmaps -->
<script src="https://cdn.jsdelivr.net/npm/d3@7"></script>
<script src="https://cdn.jsdelivr.net/npm/markmap-view"></script>
<script src="https://cdn.jsdelivr.net/npm/markmap-lib"></script>
```

**Hinweis:** Mermaid CDN ist **nicht** noetig, da Kroki alle Diagramme zu SVG pre-rendert.

## Initialisierungs-Reihenfolge

```javascript
// 1. Lucide Icons
lucide.createIcons();

// 2. Bild-Fallbacks
document.querySelectorAll('img').forEach(function(img) {
    img.onerror = function() { /* Fallback */ };
});

// 3. Vega-Lite Charts
vegaEmbed('#vega-id', spec, { actions: false, renderer: 'svg' });

// 4. Markmap Mindmaps
var transformer = new markmap.Transformer();
// ...
```

## Ordner-Benennung

```javascript
function generateFolderName(title) {
    return title
        .toLowerCase()
        .replace(/ae/g, 'ae')
        .replace(/oe/g, 'oe')
        .replace(/ue/g, 'ue')
        .replace(/ss/g, 'ss')
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-|-$/g, '')
        .substring(0, 50);
}
```

## Validierung vor Merge

| Check | Fehlerbehandlung |
|-------|------------------|
| Template vorhanden? | Abbruch mit Fehler |
| CI-Theme vorhanden? | Default-Werte verwenden |
| HTML-Struktur valide? | Warnung, trotzdem fortfahren |
| Kroki-SVGs vorhanden? | Platzhalter-SVG mit Hinweis |
| Markmap-Daten valide? | Warnung im Output |
| Vega-Specs valide? | Warnung, Chart ueberspringen |
| Assets verfuegbar? | Fallback-Handler greifen |

## Vollstaendiges Beispiel

### Input

**content.json:**
```json
{
  "title": "Produktivitaets-Guide",
  "sections": [
    {"id": "intro", "type": "text", "...": "..."},
    {"id": "prozess", "type": "diagram", "content": {"engine": "mermaid", "...": "..."}},
    {"id": "struktur", "type": "mindmap", "...": "..."},
    {"id": "statistik", "type": "chart", "...": "..."}
  ]
}
```

### Output

**output/produktivitaets-guide/index.html:**
```html
<!DOCTYPE html>
<html lang="de">
<head>
    <title>Produktivitaets-Guide</title>
    <style>:root { --ci-primary: #0066cc; ... }</style>
</head>
<body>
    <main>
        <h1>Produktivitaets-Guide</h1>

        <section id="intro" class="text">...</section>

        <section id="prozess" class="diagram">
            <h2>Prozessablauf</h2>
            <figure>
                <img src="./assets/prozess.svg" alt="Prozessablauf" />
            </figure>
        </section>

        <section id="struktur" class="mindmap">
            <h2>Projektstruktur</h2>
            <div id="markmap-struktur" class="markmap-container"></div>
        </section>

        <section id="statistik" class="chart">
            <h2>Statistik</h2>
            <div id="vega-statistik"></div>
        </section>
    </main>

    <!-- CDNs -->
    <script src="https://cdn.jsdelivr.net/npm/vega@5"></script>
    <script src="https://cdn.jsdelivr.net/npm/vega-lite@5"></script>
    <script src="https://cdn.jsdelivr.net/npm/vega-embed@6"></script>
    <script src="https://unpkg.com/lucide@latest"></script>
    <script src="https://cdn.jsdelivr.net/npm/d3@7"></script>
    <script src="https://cdn.jsdelivr.net/npm/markmap-view"></script>
    <script src="https://cdn.jsdelivr.net/npm/markmap-lib"></script>

    <script>
        lucide.createIcons();

        // Vega Chart
        vegaEmbed('#vega-statistik', {"...": "..."}, {actions: false, renderer: 'svg'});

        // Markmap
        (function() {
            var data = `# Struktur\n## Phase 1\n...`;
            var transformer = new markmap.Transformer();
            var result = transformer.transform(data);
            // ...
        })();
    </script>
</body>
</html>
```

**output/produktivitaets-guide/assets/:**
```
prozess.svg       <- Kroki-generiert (Mermaid -> SVG)
```

## Checkliste nach Assembly

- [ ] index.html oeffnet fehlerfrei im Browser
- [ ] Kroki-SVGs werden angezeigt (Diagramme)
- [ ] Markmap-Mindmaps sind interaktiv (Zoom, Collapse)
- [ ] Vega-Charts werden gerendert
- [ ] Lucide-Icons sind sichtbar
- [ ] Externe Bilder laden korrekt
- [ ] CI-Farben sind angewendet
- [ ] Responsive auf verschiedenen Bildschirmgroessen
- [ ] Offline-faehig (ausser CDN-Libraries)

---

**Weitere Referenzen:**
- Feed-Timeline Platzhalter: -> `references/template-placeholders.md`
- Versionierung + Iterations-Workflow: -> `references/iteration-workflow.md`
