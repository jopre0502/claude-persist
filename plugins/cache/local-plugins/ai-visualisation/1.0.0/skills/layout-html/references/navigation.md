# Navigation + Bild-Fallback

Ergaenzende Patterns fuer Navigation und robustes Bild-Handling.

**Hauptdatei:** `skills/layout-html/SKILL.md`

## Bild-Fallback-Handling

Bilder werden mit CSS-basiertem Fallback bei Ladefehler eingebunden.

### CSS-Fallback

```css
/* Fallback-Styling fuer fehlende Bilder */
img.img-fallback:not([src]),
img.img-fallback[src=""] {
    display: none;
}

.img-placeholder {
    display: flex;
    align-items: center;
    justify-content: center;
    background: var(--ci-background, #f8f9fa);
    border: 2px dashed var(--ci-error, #dc3545);
    border-radius: var(--ci-border-radius, 8px);
    color: var(--ci-error, #dc3545);
    padding: 20px;
    min-height: 100px;
}
```

### JavaScript-Fallback (sicher)

**Wichtig:** `textContent` statt `innerHTML` fuer sichere DOM-Manipulation:

```javascript
img.onerror = function() {
    var placeholder = document.createElement('div');
    placeholder.className = 'img-placeholder';
    placeholder.textContent = 'Bild nicht verfuegbar';
    this.parentElement.replaceChild(placeholder, this);
};
```

## Navigation-Komponenten

Navigation-Features (Page Counter, Sidebar Index) sind in CLAUDE.md des Hauptprojekts dokumentiert.

**Implementierung (TASK-M03):**
- `navigation.css` - Styles fuer Counter + Sidebar
- `navigation.js` - IntersectionObserver fuer Auto-Tracking

**Schema-Integration:** `visualProfile.navigation` in content.json

**CSS-Variablen:** `--nav-*` Namespace (Counter, Sidebar)
