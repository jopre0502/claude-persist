# HTML-Templates für Kreativitätsstufe 1 & 2

> **Performance-Optimierung:** Template-basierte HTML-Generierung ist ~6-12x schneller als LLM-Generierung

## Übersicht

Diese Templates ermöglichen **schnelle HTML-Generierung** für die Kreativitätsstufen 1 (CI-Strikt) und 2 (CI-Flexibel) durch Template-Rendering statt LLM-Output.

**Performance-Gewinn:**
- LLM-Generierung: ~100-140s
- Template-Rendering: ~10-20s
- **Speedup: 6-12x schneller**

**Trade-off:** Weniger Flexibilität, aber standardisierte und konsistente Outputs.

## Templates

| Template | Kreativitätsstufe | Features | Use Case |
|----------|-------------------|----------|----------|
| `style1.html.j2` | 1 (CI-Strikt) | Nur CI-Farben, keine Effekte | Formale Dokumentation, Compliance |
| `style2.html.j2` | 2 (CI-Flexibel) | Hover, Transitions, Landing-Page-Spacing | Präsentationen, Guides |

**Wichtig:** Stufe 3-5 bleiben **LLM-generiert** (kreative Freiheit erforderlich)

## Nutzung

### Voraussetzungen

```bash
pip install jinja2
```

### Basis-Usage

```bash
python templates/render.py input/content.json output/index.html --style 1
```

**Parameter:**
- `<content.json>`: Input-Datei (strukturierte Content-Daten)
- `<output.html>`: Output-Pfad
- `--style 1|2`: Kreativitätsstufe (optional, wird aus content.json übernommen wenn vorhanden)

### Beispiele

**Style 1 (CI-Strikt):**
```bash
python templates/render.py \
  output/secrets-mcp-setup/content.json \
  output/secrets-mcp-setup/index-style1.html \
  --style 1
```

**Style 2 (CI-Flexibel):**
```bash
python templates/render.py \
  output/claude-statusline-tutorial/content.json \
  output/claude-statusline-tutorial/index-style2.html \
  --style 2
```

**Auto-Detect Style aus content.json:**
```bash
# Liest creativityLevel aus content.json
python templates/render.py \
  output/projekt-name/content.json \
  output/projekt-name/index.html
```

## Template-Struktur

### Jinja2 Template-Format

**Basis-Struktur:**
```html
<!DOCTYPE html>
<html lang="de">
<head>
    <title>{{ title }}{% if subtitle %} - {{ subtitle }}{% endif %}</title>
    <style>
        /* CI-Variablen */
        :root {
            --ci-primary: #1976d2;
            /* ... */
        }
    </style>
</head>
<body>
    <header>
        <h1>{{ title }}</h1>
        {% if subtitle %}<p class="subtitle">{{ subtitle }}</p>{% endif %}
    </header>

    <main>
        {% for section in sections %}
        <section class="{{ section.type }}-section">
            <h2>{{ section.heading }}</h2>

            {% if section.type == 'text' %}
                {{ render_text(section.content) }}
            {% elif section.type == 'diagram' %}
                <img src="./assets/{{ section.content.filename }}" alt="{{ section.content.caption }}">
            <!-- ... -->
            {% endif %}
        </section>
        {% endfor %}
    </main>

    <footer>
        <!-- Metadata -->
    </footer>
</body>
</html>
```

### Helper-Funktionen

Die `render.py` bietet folgende Helper-Funktionen:

| Funktion | Zweck | Input |
|----------|-------|-------|
| `render_text(content)` | Text-Sections mit Highlights, Listen | `content.text`, `content.points`, `content.steps` |
| `render_comparison_table(content)` | Vergleichstabellen | `content.headers`, `content.rows` |
| `render_icon_grid(content)` | Icon-Grids mit Lucide | `content.items[]` |
| `render_smartart(content)` | SmartArt-Visuals | `content.smartartType`, `content.data` |

**Beispiel (Text-Section):**
```python
content = {
    "text": "Haupttext hier",
    "highlight": "Wichtiger Hinweis",
    "points": ["Punkt 1", "Punkt 2"]
}
# Rendert: <p>Haupttext</p> <p><strong>Wichtig:</strong> Hinweis</p> <ul><li>Punkt 1</li>...</ul>
```

## Section-Typen

### Unterstützte Section-Typen

| Typ | Rendering | Assets erforderlich |
|-----|-----------|---------------------|
| `text` | HTML-Formatierung | Nein |
| `diagram` | `<img src="assets/...">` | **Ja** (SVG) |
| `comparison` | `<table>` | Nein |
| `icon-grid` | Lucide Icons + Grid | Nein (CDN) |
| `smartart` | Inline-SVG | Nein |
| `mindmap` | Markmap.js | Nein (CDN) |

### Text-Section Schema

```json
{
  "type": "text",
  "heading": "Überschrift",
  "content": {
    "text": "Haupttext mit **Markdown**-Formatierung",
    "highlight": "Optional: Hervorgehobener Text",
    "points": ["Aufzählungspunkt 1", "Punkt 2"],
    "steps": [
      {"title": "Schritt 1", "description": "Beschreibung"},
      {"title": "Schritt 2", "description": "Beschreibung"}
    ]
  }
}
```

### Diagram-Section Schema

```json
{
  "type": "diagram",
  "heading": "Diagramm-Titel",
  "content": {
    "caption": "Beschreibung des Diagramms",
    "filename": "architecture.svg",
    "diagramType": "mermaid",
    "code": "graph LR\n  A --> B"
  }
}
```

**Wichtig:** `filename` muss auf existierende SVG in `./assets/` verweisen

### Comparison-Table Schema

```json
{
  "type": "comparison",
  "heading": "Vergleich",
  "content": {
    "caption": "Optional: Tabellenbeschreibung",
    "headers": ["Spalte 1", "Spalte 2"],
    "rows": [
      ["Wert A1", "Wert A2"],
      ["Wert B1", "Wert B2"]
    ]
  }
}
```

### Icon-Grid Schema

```json
{
  "type": "icon-grid",
  "heading": "Features",
  "content": {
    "caption": "Optional: Grid-Beschreibung",
    "items": [
      {
        "icon": "zap",
        "label": "Feature 1",
        "description": "Kurze Beschreibung"
      }
    ]
  }
}
```

**Lucide Icons:** https://lucide.dev/icons/

### Mindmap-Section Schema

```json
{
  "type": "mindmap",
  "heading": "Übersicht",
  "content": {
    "caption": "Interaktive Mindmap",
    "markdown": "# Root\n\n## Branch 1\n- Leaf 1\n- Leaf 2\n\n## Branch 2"
  }
}
```

**Rendering:** Automatisch via Markmap.js (CDN)

## Style-Unterschiede

### Style 1 (CI-Strikt)

**Merkmale:**
- Keine visuellen Effekte
- Nur CI-Farben
- Standard-Spacing
- Formales Layout

**CSS-Features:**
```css
section {
    border: 1px solid var(--ci-border);
    border-radius: 4px;
    /* KEIN hover, KEINE transition */
}
```

**Use Cases:**
- Compliance-Dokumentation
- Formale Reports
- Print-optimierte Outputs

### Style 2 (CI-Flexibel)

**Merkmale:**
- Hover-Effekte (`transform`, `box-shadow`)
- Subtle Transitions (0.3s)
- Landing-Page-Spacing (großzügiger)
- Interaktive Elemente

**CSS-Features:**
```css
section {
    border: 1px solid var(--ci-border);
    border-radius: 8px;
    transition: transform 0.3s ease, box-shadow 0.3s ease;
}

section:hover {
    transform: translateY(-4px);
    box-shadow: 0 8px 24px rgba(25, 118, 210, 0.15);
}
```

**Use Cases:**
- Präsentationen
- Online-Guides
- Landing-Pages

## Performance-Metriken

| Komponente | LLM-Generierung | Template-Rendering | Speedup |
|------------|-----------------|---------------------|---------|
| **HTML-Output** | ~100-140s | ~10-20s | **6-12x** |
| Content-Parsing | Inkludiert | ~2-3s | - |
| Asset-Linking | Inkludiert | ~1s | - |

**Basis:** Messung aus `docs/debug-log-2026-01-10_115040.md`

**Empfehlung:** Nutze Templates für Stufe 1 & 2, LLM für Stufe 3-5

## Erweiterung

### Neue Helper-Funktion hinzufügen

**In `render.py`:**
```python
def render_custom_section(content):
    """Rendert Custom-Section"""
    html = []
    # Custom-Logik hier
    return '\n'.join(html)

# In main():
env.globals['render_custom_section'] = render_custom_section
```

**Im Template:**
```html
{% if section.type == 'custom' %}
    {{ render_custom_section(section.content) }}
{% endif %}
```

### Template anpassen

**CSS-Anpassungen:**
```html
<style>
    :root {
        /* Überschreibe CI-Variablen für Custom-Theme */
        --ci-primary: #custom-color;
    }
</style>
```

**Section-Layout ändern:**
```html
{% for section in sections %}
<section class="{{ section.type }}-section" data-section-id="{{ loop.index }}">
    <!-- Custom-Layout -->
</section>
{% endfor %}
```

## Debugging

### Template-Rendering fehlschlägt

**Symptom:**
```bash
jinja2.exceptions.TemplateNotFound: style1.html.j2
```

**Lösung:**
```bash
# Prüfe Template-Verzeichnis
ls templates/*.j2

# Stelle sicher, dass render.py aus Projekt-Root aufgerufen wird
cd /path/to/AI-Visualisation
python templates/render.py ...
```

### Section rendert nicht

**Symptom:** Section-Typ wird nicht erkannt

**Debug:**
```python
# In render.py: Debug-Output hinzufügen
print(f"Rendering section: {section.get('type')}")
```

**Typische Fehler:**
- Falsche Section-Typ-Schreibweise (`Diagram` statt `diagram`)
- Fehlende Helper-Funktion-Registrierung
- Content-Schema passt nicht zu Helper-Funktion

### Assets fehlen

**Symptom:** Diagramme werden nicht angezeigt

**Lösung:**
```bash
# Prüfe Assets-Verzeichnis
ls output/projekt-name/assets/*.svg

# Stelle sicher, dass SVGs vor HTML-Rendering generiert wurden
# 1. Kroki-Rendering → assets/
# 2. Template-Rendering → index.html
```

## Integration in Pipeline

### Workflow mit Templates

```
User-Prompt
    ↓
Content-Agent → content.json
    ↓
Diagram-Agent → assets/*.svg (via Kroki)
    ↓
[Stufe 1/2] → python render.py (SCHNELL)
[Stufe 3-5] → LLM-Generierung (FLEXIBEL)
    ↓
output/projekt-name/
    ├── index.html
    ├── content.json
    └── assets/*.svg
```

### Conditional Template-Usage

**Pseudocode:**
```python
creativity_level = content_json['visualProfile']['creativityLevel']

if creativity_level in [1, 2]:
    # Template-Rendering (schnell)
    run_template_renderer(content_json, output_path, style=creativity_level)
else:
    # LLM-Generierung (flexibel)
    run_llm_html_generation(content_json, output_path)
```

## Navigation Template Variables

Die Templates unterstützen optionale Navigation-Komponenten über folgende Variablen aus `content.json`:

### Navigation-Konfiguration (visualProfile.navigation)

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

### Template-Variablen

| Variable | Typ | Quelle | Zweck |
|----------|-----|--------|-------|
| `navigation_config` | object | `visualProfile.navigation` | Navigation-Einstellungen |
| `navigation_config.pageCounter.enabled` | bool | `visualProfile.navigation.pageCounter.enabled` | Seitenzähler anzeigen |
| `navigation_config.sidebarNav.enabled` | bool | `visualProfile.navigation.sidebarNav.enabled` | Seitenleiste anzeigen |
| `sections` | array | `content.json` → `sections` | Alle Sections mit `id` + `heading` |
| `sections|length` | int | Berechnet | Gesamtanzahl Sections |

### render.py Verarbeitung

Die `render.py` führt folgende Verarbeitungsschritte durch:

1. **Navigation-Config extrahieren:**
   ```python
   navigation_config = data.get('visualProfile', {}).get('navigation', {})
   ```

2. **Section-IDs generieren (wenn fehlend):**
   ```python
   for idx, section in enumerate(sections):
       if 'id' not in section:
           section['id'] = f"section-{idx}"
   ```

3. **Render-Kontext übergeben:**
   ```python
   render_context = {
       **data,
       'navigation_config': navigation_config if navigation_config else None,
       'sections': sections
   }
   ```

### Komponenten

#### Page Counter (Seitenzähler)

**CSS-Klasse:** `.page-counter`

**Rendering (falls enabled):**
```html
<nav class="page-counter" aria-label="Seitenfortschritt">
    <span class="current">1</span> / <span class="total">{{ sections|length }}</span>
</nav>
```

**Styling (Style 1):**
- Position: Sticky (oben, nach Header)
- Hintergrund: `var(--ci-primary-light)`
- Schriftstil: Grau mit fetter Seitennummer
- Kein Hover-Effekt

**Styling (Style 2):**
- Position: Sticky (oben, nach Header)
- Hintergrund: `var(--ci-primary-light)`
- Hover-Effekt: Box-Shadow
- Transition: 0.3s ease

#### Sidebar Navigation (Inhaltsverzeichnis)

**CSS-Klasse:** `.sidebar-nav`

**Rendering (falls enabled):**
```html
<aside class="sidebar-nav" aria-label="Inhaltsverzeichnis">
    <ol>
        {% for section in sections %}
        <li><a href="#{{ section.id }}">{{ "%02d"|format(loop.index) }} {{ section.heading }}</a></li>
        {% endfor %}
    </ol>
</aside>
```

**Styling (Style 1):**
- Position: Fixed, linke Seite
- Breite: 250px
- Hintergrund: `var(--ci-primary-light)`
- Links: Farbe `var(--ci-primary)`, Hover: Unterline
- Body erhält `margin-left: 250px`

**Styling (Style 2):**
- Position: Fixed, linke Seite
- Breite: 280px
- Hintergrund: Gradient (`var(--ci-primary-light)` zu transparent)
- Links: Farbe `var(--ci-primary)`, Hover: `var(--ci-secondary)` + Underline
- Hover-Effekt: Box-Shadow (2px 0 12px)
- Body erhält `margin-left: 280px`
- Transition: 0.3s ease

### Print-Optimierung

Beide Navigation-Komponenten sind in Print-Styles versteckt:
```css
@media print {
    .page-counter { display: none; }
    .sidebar-nav { display: none; }
}
```

### Fallback (Navigation disabled)

Falls `navigation_config` nicht gesetzt oder Navigation disabled:
- Templates rendern **ohne** Navigation-Elemente
- Layout bleibt **unverändert** (kein margin-left)
- Standard-Rendering der Sections

### content.json Beispiel

**Mit Navigation:**
```json
{
  "title": "Projekt-Anleitung",
  "sections": [
    { "id": "einfuehrung", "heading": "Einführung", "type": "text", "content": {...} },
    { "id": "installation", "heading": "Installation", "type": "text", "content": {...} },
    { "id": "verwendung", "heading": "Verwendung", "type": "text", "content": {...} }
  ],
  "visualProfile": {
    "theme": "default",
    "creativityLevel": 2,
    "navigation": {
      "pageCounter": { "enabled": true },
      "sidebarNav": { "enabled": true }
    }
  }
}
```

**Ohne Navigation (Fallback):**
```json
{
  "title": "Projekt-Anleitung",
  "sections": [...],
  "visualProfile": {
    "theme": "default",
    "creativityLevel": 2
    // navigation nicht gesetzt
  }
}
```

## Changelog

| Datum | Version | Änderung |
|-------|---------|----------|
| 17.01.2026 | 1.1 | Navigation-Integration: Page Counter + Sidebar Navigation |
| 10.01.2026 | 1.0 | Initial: Style 1 & 2 Templates, render.py, README |
