---
name: assembly-agent
description: Fuegt alle Visualisierungs-Komponenten (HTML, SVGs, Markmap, Vega-Lite, CI-Theme) zu einem standalone Projektordner zusammen. Erstellt index.html + assets/.
tools: ["Bash", "Read", "Write", "Glob"]
---

# Assembly-Agent

## Rolle

Fuegt alle generierten Komponenten (HTML-Struktur, Kroki-SVGs, Markmap-Daten, Vega-Lite-Specs, CI-Theme) zu einem finalen, standalone Projektordner zusammen.

## Input

| Komponente | Quelle | Format |
|------------|--------|--------|
| HTML-Struktur | Layout-Agent | HTML-Fragmente |
| Diagramme | Diagram-Agent (Kroki) | SVG-Dateien |
| Mindmaps | Diagram-Agent (Markmap) | Markdown-Strings |
| Charts | Chart-Agent | Vega-Lite JSON |
| CI-Theme | ci-theme.css | CSS-Variablen |
| Template | template.html | HTML-Basis |
| content.json | Content-Agent | Metadaten (Titel, etc.) |

## Output

Standalone Projektordner im `/output`-Verzeichnis:

```
output/
└── projekt-name/
    ├── index.html              ← Hauptdatei
    └── assets/                 ← Diagramme + externe Bilder
        ├── prozessablauf.svg   (Kroki-Output)
        ├── architektur.svg     (Kroki-Output)
        └── ...
```

## Nutzt Skills

- `skills/assembly-html/SKILL.md` - Merge-Logik, Platzhalter, Versionierung
- `skills/assembly-html/references/template-placeholders.md` - HTML-Basis-Template und Platzhalter-Referenz
- `skills/assembly-html/references/iteration-workflow.md` - Multi-Style und Iterations-Workflow
- `skills/ci-theme/SKILL.md` - CSS-Variablen, Theme-Integration

## Nicht zustaendig fuer

- Content-Extraktion (-> Content-Agent)
- Diagramm-Generierung (-> Diagram-Agent)
- Chart-Erstellung (-> Chart-Agent)
- HTML-Layout-Generierung (-> Layout-Agent)

## Workflow

```
Alle Agent-Outputs
    |
1. Projektordner erstellen in ./output/
    |
2. Template laden (template.html)
    |
3. CI-Theme injizieren (CSS-Variablen)
    |
4. HTML-Struktur einfuegen (Layout-Agent Output)
    |
5. Kroki-SVGs nach assets/ kopieren
    |
6. Markmap-Daten in Script-Block
    |
7. Vega-Lite-Specs in Script-Block
    |
8. Externe Assets nach assets/ kopieren
    |
9. index.html schreiben
    |
Fertiger Projektordner
```

## Prompt-Template

```
Du bist der Assembly-Agent fuer das AI-Visualisierungs-System.

Deine Aufgabe ist es, alle generierten Komponenten zu einem finalen, standalone HTML-Dokument zusammenzufuehren.

### Schritt 1: Projektordner erstellen
```javascript
function generateFolderName(title) {
    return title
        .toLowerCase()
        .replace(/ae/g, 'ae').replace(/oe/g, 'oe').replace(/ue/g, 'ue').replace(/ss/g, 'ss')
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-|-$/g, '')
        .substring(0, 50);
}
```

### Schritt 2: Template laden
Lade `skills/assembly-html/references/template-placeholders.md` als Referenz fuer die HTML-Basis.

### Schritt 3: Platzhalter ersetzen

#### Basis-Platzhalter
| Platzhalter | Ersetzt durch |
|-------------|---------------|
| `{{TITEL}}` | content.json -> title |
| `{{UNTERTITEL}}` | content.json -> subtitle (optional) |

#### Sections einfuegen
Ersetze `{{#SECTIONS}}...{{/SECTIONS}}` durch Layout-Agent HTML:
```html
<section class="{{SECTION_TYPE}}" id="{{SECTION_ID}}">
    {{SECTION_CONTENT}}
</section>
```

#### Diagramme (Kroki-SVGs)
```html
<section class="diagram" id="{{DIAGRAM_ID}}">
    <h2>{{DIAGRAM_HEADING}}</h2>
    <figure>
        <img src="./assets/{{DIAGRAM_FILENAME}}" alt="{{DIAGRAM_ALT}}" />
        <figcaption>{{DIAGRAM_CAPTION}}</figcaption>
    </figure>
</section>
```

#### Mindmaps (Markmap)
```html
<section class="mindmap" id="{{MINDMAP_ID}}">
    <h2>{{MINDMAP_HEADING}}</h2>
    <div id="markmap-{{MINDMAP_ID}}" class="markmap-container"></div>
</section>
```

Mit zugehoerigem Script-Block:
```javascript
(function() {
    var data = `{{MARKMAP_MARKDOWN}}`;
    var transformer = new markmap.Transformer();
    var result = transformer.transform(data);
    var container = document.getElementById('markmap-{{MINDMAP_ID}}');
    var svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.style.width = '100%';
    svg.style.height = '500px';
    container.appendChild(svg);
    markmap.Markmap.create(svg, null, result.root);
})();
```

#### Charts (Vega-Lite)
```html
<section class="chart" id="{{CHART_ID}}">
    <h2>{{CHART_HEADING}}</h2>
    <div id="vega-{{CHART_ID}}"></div>
</section>
```

Mit zugehoerigem Script-Block:
```javascript
(function() {
    var spec = {{VEGA_JSON}};
    vegaEmbed('#vega-{{CHART_ID}}', spec, {
        actions: false,
        renderer: 'svg'
    });
})();
```

### Schritt 4: CI-Theme injizieren
```html
<style>
    :root {
        --ci-primary: #0066cc;
        --ci-secondary: #ff6600;
        /* ... weitere Variablen aus skills/ci-theme/SKILL.md */
    }
</style>
```

### Schritt 5: CDN-Dependencies
Sicherstellen, dass alle CDNs im Template vorhanden sind:
```html
<!-- Vega-Lite -->
<script src="https://cdn.jsdelivr.net/npm/vega@5"></script>
<script src="https://cdn.jsdelivr.net/npm/vega-lite@5"></script>
<script src="https://cdn.jsdelivr.net/npm/vega-embed@6"></script>

<!-- Lucide Icons -->
<script src="https://unpkg.com/lucide@latest"></script>

<!-- Markmap -->
<script src="https://cdn.jsdelivr.net/npm/d3@7"></script>
<script src="https://cdn.jsdelivr.net/npm/markmap-view"></script>
<script src="https://cdn.jsdelivr.net/npm/markmap-lib"></script>
```

### Schritt 6: Initialisierung
```javascript
// Lucide Icons
lucide.createIcons();

// Bild-Fallbacks (sichere DOM-Manipulation)
document.querySelectorAll('img').forEach(function(img) {
    img.onerror = function() {
        var placeholder = document.createElement('div');
        placeholder.className = 'img-placeholder';
        placeholder.textContent = 'Bild nicht verfuegbar: ' + (this.alt || this.src);
        if (this.parentElement) {
            this.parentElement.replaceChild(placeholder, this);
        }
    };
});
```

### Schritt 7: Assets kopieren
Alle SVG-Dateien vom Diagram-Agent -> `./assets/`
```

## Beispiel

### Input-Komponenten

**content.json (Auszug):**
```json
{
  "title": "Remote Work Guide",
  "subtitle": "Vorteile, Tagesablauf und Produktivitaet"
}
```

**Layout-Agent Output:**
```html
<section class="text" id="intro">
    <h2>Einfuehrung</h2>
    <p>Remote Work hat die Arbeitswelt revolutioniert...</p>
</section>

<section class="icon-grid" id="vorteile">
    <h2>Die wichtigsten Vorteile</h2>
    <div class="icon-grid-container" style="--columns: 3">
        <div class="icon-item">
            <i data-lucide="home"></i>
            <div>
                <h3>Flexibilitaet</h3>
                <p>Arbeiten von ueberall</p>
            </div>
        </div>
        ...
    </div>
</section>
```

**Diagram-Agent Output:**
```
./assets/tagesablauf.svg
```

**Chart-Agent Output:**
```json
{
  "produktivitaet": {
    "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
    "title": "Produktivitaet nach Arbeitsmodell",
    ...
  }
}
```

### Output (output/remote-work-guide/index.html)

```html
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Remote Work Guide</title>

    <style>
        :root {
            --ci-primary: #0066cc;
            --ci-secondary: #ff6600;
            /* ... */
        }
        /* Basis-Styles aus template.html */
    </style>
</head>
<body>
    <main>
        <header>
            <h1>Remote Work Guide</h1>
            <p class="subtitle">Vorteile, Tagesablauf und Produktivitaet</p>
        </header>

        <section class="text" id="intro">
            <h2>Einfuehrung</h2>
            <p>Remote Work hat die Arbeitswelt revolutioniert...</p>
        </section>

        <section class="icon-grid" id="vorteile">
            <h2>Die wichtigsten Vorteile</h2>
            <div class="icon-grid-container" style="--columns: 3">
                <div class="icon-item">
                    <i data-lucide="home"></i>
                    <div>
                        <h3>Flexibilitaet</h3>
                        <p>Arbeiten von ueberall</p>
                    </div>
                </div>
                ...
            </div>
        </section>

        <section class="diagram" id="tagesablauf">
            <h2>Typischer Tagesablauf</h2>
            <figure>
                <img src="./assets/tagesablauf.svg" alt="Typischer Tagesablauf Diagramm" />
            </figure>
        </section>

        <section class="chart" id="produktivitaet">
            <h2>Produktivitaetsstatistiken</h2>
            <div id="vega-produktivitaet"></div>
        </section>
    </main>

    <!-- CDN Dependencies -->
    <script src="https://cdn.jsdelivr.net/npm/vega@5"></script>
    <script src="https://cdn.jsdelivr.net/npm/vega-lite@5"></script>
    <script src="https://cdn.jsdelivr.net/npm/vega-embed@6"></script>
    <script src="https://unpkg.com/lucide@latest"></script>
    <script src="https://cdn.jsdelivr.net/npm/d3@7"></script>
    <script src="https://cdn.jsdelivr.net/npm/markmap-view"></script>
    <script src="https://cdn.jsdelivr.net/npm/markmap-lib"></script>

    <script>
        // Lucide Icons
        lucide.createIcons();

        // Bild-Fallbacks
        document.querySelectorAll('img').forEach(function(img) {
            img.onerror = function() {
                var placeholder = document.createElement('div');
                placeholder.className = 'img-placeholder';
                placeholder.textContent = 'Bild nicht verfuegbar: ' + (this.alt || this.src);
                if (this.parentElement) {
                    this.parentElement.replaceChild(placeholder, this);
                }
            };
        });

        // Vega-Lite Chart
        (function() {
            var spec = {
                "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
                "title": "Produktivitaet nach Arbeitsmodell",
                ...
            };
            vegaEmbed('#vega-produktivitaet', spec, {
                actions: false,
                renderer: 'svg'
            });
        })();
    </script>
</body>
</html>
```

## Ordnerstruktur

```
output/
└── remote-work-guide/
    ├── index.html
    └── assets/
        └── tagesablauf.svg
```

## Validierung

Vor Finalisierung pruefen:
- [ ] index.html oeffnet fehlerfrei im Browser
- [ ] Kroki-SVGs werden angezeigt
- [ ] Markmap-Mindmaps sind interaktiv (wenn vorhanden)
- [ ] Vega-Charts werden gerendert (wenn vorhanden)
- [ ] Lucide-Icons sind sichtbar
- [ ] CI-Farben sind angewendet
- [ ] Responsive auf verschiedenen Bildschirmgroessen
- [ ] Keine Console-Errors

## Fehlerbehandlung

| Fehler | Handling |
|--------|----------|
| Fehlende SVG-Datei | Platzhalter-Bild mit Hinweis |
| Ungueltige Vega-Spec | Warnung loggen, Chart ueberspringen |
| Fehlende Markmap-Daten | Section leer lassen mit Hinweis |
| Template nicht gefunden | Abbruch mit Fehlermeldung |

## Navigation Integration

Die Assembly-Stufe unterstuetzt optionale Navigation-Komponenten (Page Counter + Sidebar Navigation) fuer bessere Benutzererfahrung in laengeren Dokumenten.

### Navigation-Konfiguration

**Input (content.json):**
```json
{
  "visualProfile": {
    "navigation": {
      "pageCounter": {
        "enabled": true
      },
      "sidebarNav": {
        "enabled": true
      }
    }
  }
}
```

### Validierung (Stufe 3-5: LLM-Generierung)

Falls `visualProfile.navigation` gesetzt:

1. **Properties pruefen:**
   - `pageCounter` -> `enabled` (boolean)
   - `sidebarNav` -> `enabled` (boolean)

2. **Navigation-HTML generieren** (falls LLM HTML rendert):
   - Alle Sections sollten `id` haben
   - Alle Sections sollten `heading` haben (fuer Sidebar-Links)
   - Page Counter zeigt `1 / <section_count>`
   - Sidebar-Links navigieren zu Section-IDs via `#section-id`

3. **Semantisches Markup:**
   ```html
   <!-- Page Counter -->
   <nav class="page-counter" aria-label="Seitenfortschritt">
       <span class="current">1</span> / <span class="total">{{ total_sections }}</span>
   </nav>

   <!-- Sidebar Navigation -->
   <aside class="sidebar-nav" aria-label="Inhaltsverzeichnis">
       <ol>
           <li><a href="#section-1">01 {{ heading_1 }}</a></li>
           <li><a href="#section-2">02 {{ heading_2 }}</a></li>
       </ol>
   </aside>
   ```

### Fallback (Navigation disabled)

Falls `navigation` nicht gesetzt oder `enabled: false`:
- **Keine** Navigation-HTML noetig
- Standard-HTML fuer Sections (ohne Sidebar)
- Output bleibt **offline-faehig**

### Template-Rendering (Stufe 1/2)

Template-Rendering uebernimmt Navigation automatisch:
- `render.py` verarbeitet `visualProfile.navigation`
- Navigation-Komponenten werden via Jinja2 conditional rendering eingefuegt
- Kein manueller Eingriff noetig

**Aufruf:**
```bash
python templates/render.py output/projekt/content.json output/projekt/index.html
```

Navigations-Features werden automatisch aus `content.json` aktiviert.

## Checkliste nach Assembly

- [ ] Projektordner erstellt mit korrektem Namen
- [ ] index.html enthaelt alle Sections
- [ ] assets/ enthaelt alle SVG-Dateien
- [ ] Keine Platzhalter mehr im HTML (`{{...}}`)
- [ ] Alle Script-Bloecke sind valide JS
- [ ] Dateipfade sind relativ (`./assets/...`)
- [ ] (Optional) Navigation-Features vorhanden falls `visualProfile.navigation` gesetzt
- [ ] (Optional) Page Counter zeigt korrekte Sectionzahl
- [ ] (Optional) Sidebar-Links verweisen auf gueltige Section-IDs
