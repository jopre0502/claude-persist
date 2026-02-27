---
name: visualize
description: Erstellt standalone HTML-Visualisierungen aus User-Prompts. Kombiniert Diagramme, Charts, Mindmaps und SmartArt zu einer offline-faehigen Infografik.
arguments:
  - name: prompt
    description: "Der zu visualisierende Inhalt (Text, Thema oder URL)"
    required: true
  - name: style
    description: "Kreativitaetsstufe 1-5 (Default: 3)"
    required: false
  - name: theme
    description: "CI-Theme: default | dark-gradient (Default: default)"
    required: false
  - name: layout
    description: "Layout-Style: presentation | feed-timeline (Default: presentation)"
    required: false
  - name: no-kroki
    description: "Client-Side Mermaid.js statt Kroki-Server verwenden"
    required: false
  - name: output
    description: "Output-Verzeichnis (Default: ./output/)"
    required: false
---

# /visualize Command

Erstellt eine standalone HTML-Visualisierung aus einem Prompt oder Text.

## Aufruf

```
/visualize "Thema oder Text" --style 3 --theme default --layout presentation
```

## Optionen

| Option | Default | Werte | Beschreibung |
|--------|---------|-------|-------------|
| `prompt` | (Pflicht) | Text | Der zu visualisierende Inhalt |
| `--style` | 3 | 1-5 | Kreativitaetsstufe (1=CI-strikt, 5=experimentell) |
| `--theme` | default | default, dark-gradient | Farbschema |
| `--layout` | presentation | presentation, feed-timeline | Strukturelles Layout |
| `--no-kroki` | false | Flag | Erzwingt Client-Side Mermaid.js Fallback |
| `--output` | ./output/ | Pfad | Output-Verzeichnis |

## Was passiert

Dieser Command startet die AI-Visualisierungs-Pipeline:

1. **Content-Extraktion** — Analysiert den Prompt und erstellt strukturierte Inhalte (`content.json`)
2. **Diagramme + Charts + Layout** — Spezialisierte Agents generieren parallel SVGs, Vega-Lite Specs und HTML-Fragmente
3. **Assembly** — Alle Komponenten werden zu einem standalone `index.html` + `assets/` zusammengefuegt

### Pipeline-Ablauf

```
/visualize "Prompt" --style 3
    |
    v
Orchestrator (koordiniert)
    |
    v
Content-Agent -> content.json
    |
    v
Diagram-Agent ---|
Chart-Agent   ---|--> parallel
Layout-Agent  ---|
    |
    v
Assembly-Agent -> output/projekt-name/index.html
```

## Kreativitaetsstufen

| Stufe | Name | Performance | Beschreibung |
|-------|------|------------|-------------|
| 1 | CI-Strikt | ~10-20s | Template-basiert, keine Effekte, strenge CI-Farben |
| 2 | CI-Flexibel | ~10-20s | Template-basiert, Hover/Transitions erlaubt |
| 3 | Profil-Frei | ~100-140s | LLM-HTML, Standard-Effekte (Default) |
| 4 | Strukturell-Frei | ~100-140s | LLM-HTML, Animationen, Glasmorphism |
| 5 | Voll-Kreativ | ~100-140s | LLM-HTML, experimentell |

Details: Lies `skills/creative-levels/SKILL.md` fuer die vollstaendige Matrix.

## Anweisungen fuer Claude

Wenn dieser Command ausgefuehrt wird:

### 1. Argumente parsen

```
PROMPT = $prompt (Pflichtfeld)
STYLE = $style oder 3
THEME = $theme oder "default"
LAYOUT = $layout oder "presentation"
NO_KROKI = $no-kroki oder false
OUTPUT_DIR = $output oder "./output/"
```

### 2. Kreativitaetsstufe laden

Lies `skills/creative-levels/SKILL.md` und wende die Regeln fuer die gewaehlte Stufe an.
Die Stufe beeinflusst:
- Welche Visual Effects erlaubt sind
- Ob Templates (Stufe 1-2) oder LLM-HTML (Stufe 3-5) verwendet wird
- Wie viel strukturelle Freiheit die Agents haben

### 3. Orchestrator starten

Delegiere an den `orchestrator` Agent mit folgendem Kontext:

**User-Prompt:** `$PROMPT`

**Optionen:**
- Kreativitaetsstufe: `$STYLE`
- Theme: `$THEME`
- Layout-Style: `$LAYOUT`
- Kroki-Modus: `$NO_KROKI`
- Output-Verzeichnis: `$OUTPUT_DIR`

Der Orchestrator koordiniert die gesamte Pipeline (Content -> Diagram/Chart/Layout -> Assembly).

### 4. Ergebnis melden

Nach erfolgreichem Assembly:

```
Visualisierung erstellt!

Ordner:  output/projekt-name/
Oeffnen: open output/projekt-name/index.html

Optionen: Style $STYLE | Theme $THEME | Layout $LAYOUT
Sections: X Sections (Y Diagramme, Z Charts)
```

Bei Fehlern: Fehlermeldung des Orchestrators weiterleiten.

## Beispiele

```
# Einfacher Prompt
/visualize "Die Vorteile von Remote Work"

# Mit Optionen
/visualize "Kubernetes Architektur" --style 4 --theme dark-gradient

# Timeline-Layout
/visualize "Geschichte der KI" --layout feed-timeline --style 2

# Ohne Kroki (offline/kein Docker)
/visualize "Agile Methoden" --no-kroki

# Eigenes Output-Verzeichnis
/visualize "Unser Produktportfolio" --output ./presentations/
```
