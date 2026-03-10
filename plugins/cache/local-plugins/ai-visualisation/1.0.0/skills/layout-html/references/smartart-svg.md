# SmartArt SVG-Generierung

Detaillierte SVG-Generierungslogik fuer jeden SmartArt-Typ.

**Hauptdatei:** `skills/layout-html/SKILL.md` (Uebersicht + Beispiel)

## Gemeinsame Regeln

| Regel | Wert | Begruendung |
|-------|------|------------|
| ViewBox | `0 0 800 450` | 16:9 Format |
| Text-Wrapping | `<tspan>` bei >20 Zeichen | Overflow vermeiden |
| Fonts | `var(--sa-font-body)` | CI-Konsistenz |
| Koordinaten | Prozentual (0-1) -> Pixel | Flexible Positionierung |

## matrix_2x2 SVG-Struktur

```svg
<svg viewBox="0 0 800 450" class="sa-viz">
    <!-- Quadranten -->
    <rect class="sa-box sa-quadrant-tl" x="100" y="50" width="300" height="175" />
    <rect class="sa-box sa-quadrant-tr" x="400" y="50" width="300" height="175" />
    <rect class="sa-box sa-quadrant-bl" x="100" y="225" width="300" height="175" />
    <rect class="sa-box sa-quadrant-br" x="400" y="225" width="300" height="175" />

    <!-- Achsen -->
    <line class="sa-axis" x1="100" y1="225" x2="700" y2="225" />
    <line class="sa-axis" x1="400" y1="50" x2="400" y2="400" />

    <!-- Achsen-Labels -->
    <text class="sa-text sa-axis-label" x="400" y="430">{{axisX.label}}</text>
    <text class="sa-text sa-axis-label" x="80" y="225" transform="rotate(-90, 80, 225)">{{axisY.label}}</text>

    <!-- Quadranten-Labels -->
    <text class="sa-text sa-quadrant-label" x="250" y="140">{{quadrantLabels.topLeft}}</text>

    <!-- Punkte (fuer jeden Punkt in data.points) -->
    <g class="sa-point-group">
        <circle class="sa-accent sa-point" cx="{{x * 600 + 100}}" cy="{{(1-y) * 350 + 50}}" r="8" />
        <text class="sa-text sa-point-label" x="{{...}}" y="{{...}}">{{label}}</text>
    </g>
</svg>
```

**Koordinaten-Transformation:**
- `x`: `0.0` (links) -> `1.0` (rechts) -> Pixel: `x * 600 + 100`
- `y`: `0.0` (unten) -> `1.0` (oben) -> Pixel: `(1-y) * 350 + 50`

## chevron_process SVG-Struktur

```svg
<svg viewBox="0 0 800 450" class="sa-viz">
    <!-- Fuer jeden Step (3-7) -->
    <g class="sa-chevron-group">
        <polygon class="sa-chevron" points="{{chevronPath}}" />
        <text class="sa-text sa-chevron-text" x="{{center}}" y="{{center}}">
            <tspan>{{step.title}}</tspan>
        </text>
        <text class="sa-text sa-chevron-sublabel" x="{{...}}" y="{{...}}">{{step.subtitle}}</text>
    </g>
</svg>
```

**Chevron-Breite Berechnung:**
- Bei 3 Steps: `200px` pro Chevron
- Bei 7 Steps: `100px` pro Chevron
- Formel: `chevronWidth = (800 - 2*margin) / numSteps`

## pillars SVG-Struktur

```svg
<svg viewBox="0 0 800 450" class="sa-viz">
    <!-- Basis -->
    <rect class="sa-pillar-base" x="50" y="400" width="700" height="40" rx="4" />

    <!-- Fuer jede Saeule (3-6) -->
    <g class="sa-pillar-group">
        <rect class="sa-pillar" x="{{...}}" y="100" width="{{pillarWidth}}" height="300" rx="4" />
        <rect class="sa-pillar-header" x="{{...}}" y="100" width="{{pillarWidth}}" height="50" rx="4" />
        <text class="sa-text sa-pillar-title" x="{{center}}" y="130">{{pillar.title}}</text>
        <text class="sa-text sa-pillar-content" x="{{...}}" y="{{...}}">
            <tspan>{{pillar.items[0]}}</tspan>
            <tspan x="{{...}}" dy="20">{{pillar.items[1]}}</tspan>
        </text>
    </g>
</svg>
```

## timeline SVG-Struktur

```svg
<svg viewBox="0 0 800 450" class="sa-viz">
    <!-- Hauptlinie -->
    <line class="sa-timeline-line" x1="50" y1="225" x2="750" y2="225" />

    <!-- Fuer jeden Punkt (4-12) -->
    <g class="sa-timeline-item">
        <circle class="sa-timeline-point" cx="{{x}}" cy="225" r="10" />
        <text class="sa-text sa-timeline-label" x="{{x}}" y="{{labelY}}">{{item.label}}</text>
        <text class="sa-text sa-timeline-date" x="{{x}}" y="{{dateY}}">{{item.date}}</text>
    </g>
</svg>
```

**Alternating Labels:**
- Gerade Indizes: Label oben (`y="200"`)
- Ungerade Indizes: Label unten (`y="260"`)

## hierarchy SVG-Struktur

```svg
<svg viewBox="0 0 800 450" class="sa-viz">
    <!-- Root Node -->
    <rect class="sa-node sa-node-root" x="350" y="30" width="100" height="40" rx="4" />
    <text class="sa-text sa-node-text sa-node-text-root" x="400" y="55">{{root.label}}</text>

    <!-- Connector Lines -->
    <path class="sa-connector" d="M 400 70 L 400 100 L 200 100 L 200 130" />

    <!-- Level 1 Nodes -->
    <rect class="sa-node sa-node-level-1" x="150" y="130" width="100" height="40" rx="4" />

    <!-- Level 2 Nodes -->
    <rect class="sa-node sa-node-level-2" x="100" y="230" width="80" height="35" rx="4" />
</svg>
```

**Hierarchie-Layout Algorithmus:**
1. Root mittig positionieren
2. Kinder gleichmaessig verteilen
3. Verbindungslinien mit Bezier-Kurven oder L-Pfaden

## CSS-Klassen Referenz

| Klasse | Verwendung |
|--------|------------|
| `.sa-viz` | SVG-Container |
| `.sa-box` | Basis-Rechteck |
| `.sa-quadrant-*` | Matrix-Quadranten (tl, tr, bl, br) |
| `.sa-axis` | Achsenlinien |
| `.sa-point` | Datenpunkte |
| `.sa-chevron` | Chevron-Polygone |
| `.sa-pillar` | Saeulen-Rechtecke |
| `.sa-timeline-*` | Timeline-Elemente |
| `.sa-node` | Hierarchie-Knoten |
| `.sa-connector` | Verbindungslinien |
| `.sa-text` | Basis-Text |
| `.sa-text-heading` | Ueberschriften |
| `.sa-text-label` | Labels |
| `.sa-text-muted` | Gedaempfter Text |
