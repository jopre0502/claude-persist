# Lucide Icons - Erweiterte Patterns

Zusaetzliche Icon-Patterns ueber die Basis-Integration hinaus.

**Hauptdatei:** `skills/layout-html/SKILL.md` (Integration + Icon-Tabelle)

## Icon als Button

```html
<button class="icon-button">
    <i data-lucide="download"></i>
    <span>Herunterladen</span>
</button>
```

## Icon-Liste

```html
<ul class="icon-list">
    <li>
        <i data-lucide="check"></i>
        <span>Erster Vorteil</span>
    </li>
    <li>
        <i data-lucide="check"></i>
        <span>Zweiter Vorteil</span>
    </li>
</ul>
```

## Icon-Groessen

Lucide-Icons skalieren ueber CSS `width`/`height`:

```css
.icon-item i { width: 24px; height: 24px; }
.icon-item.large i { width: 48px; height: 48px; }
.icon-button i { width: 16px; height: 16px; }
```

## Best Practices

- Immer `aria-hidden="true"` auf dekorative Icons
- `<span class="sr-only">` fuer Screenreader-Text bei Icon-only Buttons
- Konsistente Groessen innerhalb einer Section
- Max 10 verschiedene Icons pro Visualisierung (visuelle Konsistenz)
