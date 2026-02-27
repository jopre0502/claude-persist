# Versionierung + Iterations-Workflow

Versionierung, Archivierung und iterativer Workflow fuer Visualisierungen.

**Hauptdatei:** `skills/assembly-html/SKILL.md`

## Versionierung

Die Version wird in `content.json` gepflegt und im Footer angezeigt.

### content.json

```json
{
  "metadata": {
    "author": "J. Prechtel",
    "date": "08.01.2026",
    "version": "1.0"
  }
}
```

### Footer-Format

```html
<footer>
    <p>{{title}} | {{author}} | {{date}} | v{{version}}</p>
</footer>
```

### Versionsnummerierung

| Aenderung | Version |
|-----------|---------|
| Minor-Aenderungen (Typos, kleine Fixes) | `1.0` -> `1.1` -> `1.2` |
| Major-Aenderungen (neue Sections, Struktur-Umbau) | `1.x` -> `2.0` |

---

## Versions-Archivierung

Vor signifikanten Aenderungen wird die aktuelle Version archiviert.

### Archivierungs-Workflow

```bash
# 1. Aktuellen Stand archivieren (z.B. v1.3 -> Version 1.3/)
mkdir -p "output/projekt-name/Version 1.3"
cp content.json index.html "output/projekt-name/Version 1.3/"
cp -r assets "output/projekt-name/Version 1.3/"

# 2. Version in content.json hochzaehlen
# metadata.version: "1.3" -> "1.4"

# 3. Aenderungen durchfuehren
```

### Ordnerstruktur nach Iterationen

```
output/remote-work-guide/
├── content.json          <- v1.4 (aktuelle Version)
├── index.html            <- v1.4 (aktuelle Version)
├── assets/
│   └── tagesablauf.svg
├── Version 1.3/
│   ├── content.json
│   ├── index.html
│   └── assets/
├── Version 1.2/
│   └── ...
└── Version 1.1/
    └── ...
```

### Wann archivieren?

| Archivieren | Nicht archivieren |
|-------------|-------------------|
| Vor Major-Aenderungen | Bei Typos, kleinen Fixes |
| Vor experimentellen Aenderungen | Bei Minor-Anpassungen |
| Auf explizite User-Anfrage | Bei normalen Iterationen |

---

## Iterations-Workflow

Nach der initialen Generierung dient `content.json` als **Source of Truth**.

### Workflow-Diagramm

```
+---------------------------------------------------------------+
|                    INITIALE GENERIERUNG                        |
|  User-Prompt -> Content-Agent -> content.json                  |
|                     |                                          |
|  Alle Agents (parallel) -> index.html + assets/                |
+---------------------------------------------------------------+
                              |
+---------------------------------------------------------------+
|                    ITERATION (beliebig oft)                    |
|                                                                |
|  1. content.json bearbeiten (Section anpassen)                 |
|                     |                                          |
|  2. Betroffenen Agent aufrufen (siehe Routing-Tabelle)         |
|                     |                                          |
|  3. Assembly-Agent -> index.html aktualisieren                 |
+---------------------------------------------------------------+
```

### Agent-Routing fuer Aenderungen

| Aenderung an Section-Typ | Zustaendiger Agent |
|--------------------------|-------------------|
| `diagram` | Diagram-Agent -> SVG neu rendern via Kroki |
| `mindmap` | Diagram-Agent -> Markmap-Daten aktualisieren |
| `chart` | Chart-Agent -> Vega-Lite Spec neu generieren |
| `text` | Layout-Agent -> HTML-Struktur anpassen |
| `icon-grid` | Layout-Agent -> Grid-Items aktualisieren |
| `comparison` | Layout-Agent -> Tabelle anpassen |
| `smartart` | Layout-Agent -> Inline-SVG neu generieren |
| **Alle Aenderungen** | Assembly-Agent -> index.html zusammenfuehren |

### Checkliste fuer Iterationen

- [ ] content.json ist die einzige Quelle fuer Aenderungen
- [ ] Aenderungen in content.json gespeichert
- [ ] Betroffene Assets (SVGs) neu generiert
- [ ] Browser-Cache geleert / Hard-Refresh (Ctrl+Shift+R)
- [ ] Aenderungen in index.html sichtbar
