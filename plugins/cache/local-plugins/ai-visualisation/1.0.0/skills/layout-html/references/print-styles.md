# Print-Styles (16:9 Praesentationsformat)

Die HTML-Visualisierungen unterstuetzen Druck im **16:9 Landscape-Format** fuer Praesentationen.

**Hauptdatei:** `skills/layout-html/SKILL.md`

## Page Setup

```css
@media print {
    @page {
        size: 297mm 167mm landscape;  /* A4-Breite, 16:9-Hoehe */
        margin: 15mm;
    }

    header {
        break-after: page;  /* Titelfolie */
    }

    section {
        break-after: page;  /* Jede Section = eine Seite */
        break-inside: avoid;
    }
}
```

## Seitenaufteilung

| Element | Verhalten |
|---------|-----------|
| `<header>` | Titelfolie (zentriert, volle Seite) |
| `<section>` | Jede Section auf eigener Seite |
| `<footer>` | Auf letzter Seite |

## Print-Header (Section-basiert)

Kopfzeile wird **innerhalb jeder Section** platziert fuer perfekte Alignment:

```html
<section class="text" id="intro">
    <div class="section-header">
        <span class="section-header-left">{{title}}</span>
        <span class="section-header-right">{{subtitle}}</span>
    </div>
    <h2>Section-Titel</h2>
    <!-- Content -->
</section>
```

```css
/* Im Screen-Modus versteckt */
.section-header { display: none; }

/* Im Print-Modus sichtbar */
@media print {
    .section-header {
        display: flex !important;
        justify-content: space-between;
        padding-bottom: 3mm;
        margin-bottom: 5mm;
        border-bottom: 1px solid var(--ci-border);
        font-size: 9pt;
        color: var(--ci-text-muted);
    }
    .section-header-left {
        font-weight: 600;
        color: var(--ci-primary);
    }
}
```

## Print-Anpassungen

| Element | Anpassung |
|---------|-----------|
| Icon-Grid | 2 Spalten statt 3 |
| Diagramme/Charts | Max-Hoehe begrenzt |
| Hintergrundfarben | `print-color-adjust: exact` |
| Schatten | Entfernt |

## Drucken

1. Browser: `Strg+P` / `Cmd+P`
2. Einstellungen:
   - Querformat (wird durch CSS erzwungen)
   - "Hintergrundgrafiken drucken" aktivieren
   - Raender: Minimal
3. PDF speichern: "Als PDF drucken"
