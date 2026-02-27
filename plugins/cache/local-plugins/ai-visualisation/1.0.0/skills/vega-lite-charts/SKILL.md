---
name: vega-lite-charts
description: Generiert Vega-Lite Specifications fuer Daten-Charts. Bar, Line, Pie, Scatter, Heatmaps mit CI-Theme-Integration.
---

# Vega-Lite Charts Skill

## Zweck

Transformiert `chart`-Sections aus content.json in Vega-Lite JSON-Specifications, die im Browser mit vegaEmbed gerendert werden.

## Vega-Lite via CDN vs. Kroki

| Methode | Output | Interaktiv? | Verwendung |
|---------|--------|-------------|------------|
| **CDN (empfohlen)** | Runtime JS | ✅ Tooltips, Zoom, Pan | Standard fuer alle Charts |
| **Kroki** | Statisches SVG | ❌ | Nur wenn 100% offline noetig |

## Input

Section vom Typ `chart`:

```json
{
  "type": "chart",
  "heading": "Umsatzentwicklung",
  "content": {
    "chartType": "bar",
    "data": [
      {"quartal": "Q1", "umsatz": 100000},
      {"quartal": "Q2", "umsatz": 150000}
    ],
    "xAxis": "quartal",
    "yAxis": "umsatz",
    "title": "Umsatz 2024"
  }
}
```

## Chart-Typen und Marks

| chartType | Vega-Lite Mark | Verwendung |
|-----------|----------------|------------|
| `bar` | `bar` | Kategorien vergleichen |
| `line` | `line` | Trends ueber Zeit |
| `area` | `area` | Kumulative Werte |
| `pie` | `arc` | Anteile zeigen |
| `donut` | `arc` (mit innerRadius) | Anteile zeigen (modern) |
| `scatter` | `point` | Korrelationen |
| `heatmap` | `rect` | Matrix-Daten |

## Basis-Struktur

```json
{
  "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
  "title": "Chart-Titel",
  "width": "container",
  "height": 300,
  "data": { "values": [] },
  "mark": "bar",
  "encoding": {
    "x": {},
    "y": {},
    "color": {}
  }
}
```

## Encoding-Typen

| Feldtyp | type | Beispiel |
|---------|------|----------|
| Kategorien | `nominal` | Produktnamen, Laender |
| Geordnet | `ordinal` | Monate, Groessen (S, M, L) |
| Zahlen | `quantitative` | Umsatz, Anzahl |
| Zeit | `temporal` | Datum, Zeitstempel |

## Chart-Beispiele

### Bar Chart

```json
{
  "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
  "title": "Verkaeufe nach Produkt",
  "width": "container",
  "height": 300,
  "data": {
    "values": [
      {"produkt": "A", "verkaeufe": 120},
      {"produkt": "B", "verkaeufe": 85},
      {"produkt": "C", "verkaeufe": 150}
    ]
  },
  "mark": "bar",
  "encoding": {
    "x": {"field": "produkt", "type": "nominal", "title": "Produkt"},
    "y": {"field": "verkaeufe", "type": "quantitative", "title": "Verkaeufe"},
    "color": {"field": "produkt", "type": "nominal", "legend": null}
  }
}
```

### Line Chart

```json
{
  "mark": {"type": "line", "point": true},
  "encoding": {
    "x": {"field": "monat", "type": "ordinal"},
    "y": {"field": "temp", "type": "quantitative", "title": "Temperatur"}
  }
}
```

### Pie / Donut Chart

```json
{
  "mark": "arc",
  "encoding": {
    "theta": {"field": "anteil", "type": "quantitative"},
    "color": {"field": "kategorie", "type": "nominal"}
  }
}
```

Donut: `"mark": {"type": "arc", "innerRadius": 50}`

### Scatter Plot

```json
{
  "mark": "point",
  "encoding": {
    "x": {"field": "preis", "type": "quantitative"},
    "y": {"field": "qualitaet", "type": "quantitative"},
    "color": {"field": "produkt", "type": "nominal"}
  }
}
```

## CI-Theme-Integration

```javascript
var CI = getCITheme();
var spec = {
    "config": {
        "font": CI.fontBody,
        "title": { "font": CI.fontHeading, "color": CI.text },
        "axis": {
            "labelFont": CI.fontBody,
            "labelColor": CI.text,
            "gridColor": CI.border
        }
    }
};
```

**Hinweis:** CSS-Variablen funktionieren nicht direkt in Vega-Lite JSON. Hex-Werte via `getCITheme()` einsetzen.

## Einbindung im HTML

```html
<section class="chart">
    <div id="chart-1"></div>
</section>

<script>
vegaEmbed('#chart-1', spec, { actions: false, renderer: 'svg' });
</script>
```

## Best Practices

✅ **Empfohlen:**
- `width: "container"` fuer responsive Charts
- Klare Achsen-Titel
- Konsistente Farben
- Legende nur wenn noetig

❌ **Vermeiden:**
- 3D-Effekte
- Zu viele Datenpunkte (>1000)
- Pie Charts mit >6 Segmenten
- Fehlende Achsenbeschriftungen
