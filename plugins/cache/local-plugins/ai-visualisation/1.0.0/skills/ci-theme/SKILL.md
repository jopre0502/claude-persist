---
name: ci-theme
description: CI-Theme-System mit CSS-Variablen. Definiert Farben, Fonts, Spacing fuer Visualisierungen. Runtime und Build-Time Integration.
---

# CI-Theme Skill

## Zweck

Zentrale Styling-Schicht ueber CSS-Variablen. Ermoeglicht konsistentes Erscheinungsbild ueber alle Visualisierungstypen hinweg und einfachen Theme-Wechsel.

## Theme-Architektur

```
Visual Profile = Theme (Farben) × Layout-Style (Struktur)

THEMES (CI-Tokens)          LAYOUT-STYLES (Patterns)
themes/                     styles/
├── default.css ★           ├── presentation/ ★
└── dark-gradient.css       └── feed-timeline/
```

## Verfuegbare Themes

### default.css (Standard)

Heller, professioneller Look fuer Reports und Praesentationen.

```css
:root {
    --ci-primary: #0066cc;
    --ci-secondary: #ff6600;
    --ci-success: #28a745;
    --ci-warning: #ffc107;
    --ci-error: #dc3545;
    --ci-background: #ffffff;
    --ci-surface: #f8f9fa;
    --ci-text: #1a1a1a;
    --ci-text-muted: #6c757d;
    --ci-border: #dee2e6;
    --ci-font-heading: system-ui, -apple-system, sans-serif;
    --ci-font-body: system-ui, -apple-system, sans-serif;
    --ci-spacing-unit: 8px;
    --ci-border-radius: 8px;
    --ci-shadow: 0 2px 8px rgba(0,0,0,0.1);
}
```

### dark-gradient.css (Feed-Timeline)

Dunkler Gradient fuer Timeline-Flows und narrative Darstellungen.

```css
:root {
    --ci-primary: #0066cc;
    --ci-secondary: #6f42c1;
    --ci-background: linear-gradient(180deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
    --ci-surface: #ffffff;
    --ci-text: #1a1a1a;
    --ci-text-on-dark: #ffffff;
    --ci-text-muted-on-dark: rgba(255,255,255,0.6);
    --ci-border-radius: 16px;
    --ci-shadow: 0 10px 40px rgba(0,0,0,0.2);
}
```

## CSS-Variablen-Referenz

| Variable | Verwendung | Default |
|----------|------------|---------|
| `--ci-primary` | Hauptakzent, Links, Buttons | `#0066cc` |
| `--ci-secondary` | Sekundaerer Akzent | `#ff6600` |
| `--ci-success` | Erfolg, Positiv | `#28a745` |
| `--ci-warning` | Warnung | `#ffc107` |
| `--ci-error` | Fehler, Negativ | `#dc3545` |
| `--ci-background` | Hintergrund | `#ffffff` |
| `--ci-surface` | Karten, Boxen | `#f8f9fa` |
| `--ci-text` | Haupttext | `#1a1a1a` |
| `--ci-text-muted` | Gedaempfter Text | `#6c757d` |
| `--ci-border` | Linien, Rahmen | `#dee2e6` |
| `--ci-font-heading` | Ueberschriften | `system-ui` |
| `--ci-font-body` | Fliesstext | `system-ui` |
| `--ci-spacing-unit` | Basis-Spacing | `8px` |
| `--ci-border-radius` | Eckenrundung | `8px` |
| `--ci-shadow` | Schatten | `0 2px 8px rgba(0,0,0,0.1)` |

## Visualisierungs-Integration

### Runtime-Integration (getCITheme)

Fuer Vega-Lite und Markmap werden CSS-Variablen zur Laufzeit gelesen:

```javascript
function getCITheme() {
    var style = getComputedStyle(document.documentElement);
    return {
        primary: style.getPropertyValue('--ci-primary').trim() || '#0066cc',
        secondary: style.getPropertyValue('--ci-secondary').trim() || '#ff6600',
        success: style.getPropertyValue('--ci-success').trim() || '#28a745',
        text: style.getPropertyValue('--ci-text').trim() || '#1a1a1a',
        textMuted: style.getPropertyValue('--ci-text-muted').trim() || '#6c757d',
        border: style.getPropertyValue('--ci-border').trim() || '#dee2e6',
        fontHeading: style.getPropertyValue('--ci-font-heading').trim() || 'system-ui',
        fontBody: style.getPropertyValue('--ci-font-body').trim() || 'system-ui'
    };
}
var CI = getCITheme();
```

### Build-Time (Mermaid via Kroki)

```javascript
const mermaidTheme = `%%{init: {'theme': 'base', 'themeVariables': {
    'primaryColor': '${ciVars['--ci-surface']}',
    'primaryTextColor': '${ciVars['--ci-text']}',
    'primaryBorderColor': '${ciVars['--ci-primary']}',
    'lineColor': '${ciVars['--ci-primary']}',
    'fontFamily': '${ciVars['--ci-font-body']}'
}}}%%`;
```

## CSS-Variable → Visualisierung Mapping

| CSS-Variable | Vega-Lite | Markmap | Mermaid |
|--------------|-----------|---------|---------|
| `--ci-primary` | Bar-Farbe | Depth 0 | primaryBorderColor |
| `--ci-success` | Bar-Farbe | Depth 1 | - |
| `--ci-text` | title.color | - | primaryTextColor |
| `--ci-border` | gridColor | - | - |
| `--ci-surface` | - | - | primaryColor (Box-BG) |
| `--ci-font-body` | config.font | CSS Override | fontFamily |

## Theme in content.json

```json
{
  "visualProfile": {
    "theme": "default",
    "layoutStyle": "presentation"
  }
}
```

## Neues Theme erstellen

1. Neue CSS-Datei in `resources/themes/` erstellen
2. Alle `--ci-*` Variablen definieren
3. In content.json referenzieren
