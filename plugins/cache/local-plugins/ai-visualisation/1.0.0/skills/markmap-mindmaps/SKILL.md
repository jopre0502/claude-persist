---
name: markmap-mindmaps
description: Generiert interaktive Mindmaps mit Markmap.js. Markdown-Syntax fuer hierarchische Visualisierungen mit Zoom, Pan und Collapse.
---

# Markmap-Mindmaps Skill

## Zweck

Erstellt interaktive Mindmaps aus Markdown-Struktur. Im Gegensatz zu statischen SVGs (Kroki) bleiben Markmap-Mindmaps **interaktiv** im Browser.

## Warum Markmap statt Kroki/Mermaid?

| Aspekt | Mermaid Mindmap (Kroki) | Markmap |
|--------|-------------------------|---------|
| Output | Statisches SVG | Interaktives JS |
| Zoom/Pan | ❌ | ✅ |
| Expand/Collapse | ❌ | ✅ |
| Animation | ❌ | ✅ |
| Syntax | Mermaid-spezifisch | Standard Markdown |
| Offline | ✅ (SVG) | ✅ (CDN cached) |

## CDN-Einbindung

```html
<script src="https://cdn.jsdelivr.net/npm/d3@7"></script>
<script src="https://cdn.jsdelivr.net/npm/markmap-view"></script>
<script src="https://cdn.jsdelivr.net/npm/markmap-lib"></script>
```

## Syntax (Markdown)

Markmap verwendet **Standard-Markdown-Headings**:

```markdown
# Hauptthema

## Zweig 1
### Unterpunkt 1.1
### Unterpunkt 1.2
- Detail A
- Detail B

## Zweig 2
### Unterpunkt 2.1
- [ ] Checkbox (unchecked)
- [x] Checkbox (checked)

## Zweig 3
### Mit **Formatierung**
- *Kursiv*
- `Code`
- [Link](https://example.com)
```

## Input (content.json)

```json
{
  "type": "mindmap",
  "heading": "Projektuebersicht",
  "content": {
    "root": "Projekt Alpha",
    "branches": [
      {
        "title": "Phase 1",
        "items": ["Konzeption", "Planung", "Ressourcen"]
      },
      {
        "title": "Phase 2",
        "items": ["Entwicklung", "Testing"]
      }
    ]
  }
}
```

## Transformation zu Markdown

```javascript
function contentToMarkdown(content) {
  let md = `# ${content.root}\n\n`;

  content.branches.forEach(branch => {
    md += `## ${branch.title}\n`;
    branch.items.forEach(item => {
      if (typeof item === 'string') {
        md += `- ${item}\n`;
      } else if (item.children) {
        md += `### ${item.title}\n`;
        item.children.forEach(child => {
          md += `- ${child}\n`;
        });
      }
    });
    md += '\n';
  });

  return md;
}
```

## HTML-Einbindung

```html
<section class="mindmap">
    <h2>Projektuebersicht</h2>
    <div id="markmap-projektuebersicht" class="markmap-container"></div>
</section>

<script>
(function() {
    const { Transformer, Markmap } = window.markmap;
    const transformer = new Transformer();
    const { root } = transformer.transform(markmapData);

    const container = document.getElementById('markmap-projektuebersicht');
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.style.width = '100%';
    svg.style.height = '500px';
    container.appendChild(svg);

    Markmap.create(svg, null, root);
})();
</script>
```

## Styling

```css
.markmap-container {
    width: 100%;
    min-height: 400px;
    background: var(--ci-surface);
    border-radius: var(--ci-border-radius);
    overflow: hidden;
}

.markmap-node-circle { fill: var(--ci-primary); }
.markmap-node-text { fill: var(--ci-text); font-family: var(--ci-font-body); }
.markmap-link { stroke: var(--ci-border); }
```

## Interaktive Features

| Feature | Bedienung |
|---------|-----------|
| **Zoom** | Mausrad / Pinch |
| **Pan** | Klicken + Ziehen |
| **Expand/Collapse** | Klick auf Knoten-Kreis |
| **Fit to View** | Doppelklick auf Hintergrund |

## Wann Markmap vs. Kroki?

| Anwendungsfall | Empfehlung |
|----------------|------------|
| Brainstorming, Ideensammlung | **Markmap** |
| Organisationsstrukturen | **Markmap** |
| Hierarchische Konzepte | **Markmap** |
| Prozesse, Flows | Kroki (Mermaid/D2) |
| Sequenzdiagramme | Kroki |
| Architektur-Diagramme | Kroki (D2) |

## Best Practices

✅ **Empfohlen:**
- Maximal 4 Hierarchie-Ebenen fuer Lesbarkeit
- Kurze, praegnante Labels
- Konsistente Formatierung
- Sinnvolle Gruppierung in Zweige

❌ **Vermeiden:**
- Zu viele Ebenen (>5)
- Sehr lange Texte in Knoten
- Mehr als 50 Knoten gesamt
- Mischung von Listen und Headings ohne Struktur
