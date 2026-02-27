---
name: creative-levels
description: Definiert 5 Kreativitaetsstufen von CI-strikt bis experimentell. Steuert Agent-Verhalten, Theme-Auswahl und strukturelle Freiheiten.
---

# Creative-Levels Skill

## Zweck

Steuert den Grad kreativer Freiheit bei der Visualisierungserstellung. Von strikter CI-Konformitaet (Stufe 1) bis experimenteller Freiheit (Stufe 5).

## Die 5 Stufen

| Stufe | Name | Kurzform | Beschreibung |
|-------|------|----------|--------------|
| **1** | CI-Strikt | `--strict` | Maximale Konsistenz, keine Abweichungen |
| **2** | CI-Flexibel | `--ci-flex` | Theme-Variationen erlaubt |
| **3** | Profil-Frei | `--profile` | Volle Visual-Profile-Auswahl ★ **Default** |
| **4** | Strukturell-Frei | `--creative` | Komponenten-Experimente moeglich |
| **5** | Voll-Kreativ | `--experimental` | Alles ist erlaubt |

## Detaillierte Matrix

```
                    Stufe 1      Stufe 2      Stufe 3      Stufe 4      Stufe 5
                    CI-Strikt    CI-Flexibel  Profil-Frei  Strukturell  Voll-Kreativ
════════════════════════════════════════════════════════════════════════════════════
CI-TOKENS (Farben)
  Theme-Wahl        default      waehlbar     waehlbar     waehlbar     neu erstellbar
  Farb-Palette      exakt CI     exakt CI     exakt CI     erweiterbar  frei
  Fonts             CI-Fonts     CI-Fonts     CI-Fonts     CI-Fonts     frei
────────────────────────────────────────────────────────────────────────────────────
LAYOUT-STYLE
  Style-Wahl        presentation waehlbar     waehlbar     waehlbar     neu erstellbar
  Komponenten       Standard     Standard     Standard     erweiterbar  frei kombiniert
  Template          unveraendert unveraendert unveraendert anpassbar    frei
────────────────────────────────────────────────────────────────────────────────────
VISUAL EFFECTS
  Section-Spacing   kompakt      grosszuegig  grosszuegig  sehr gross   frei
  Hover-Effekte     keine        erlaubt      erlaubt      erweitert    frei
  Transitions       keine        subtle       subtle       auffaellig   frei
  Schatten/Glow     minimal      CI-shadow    CI-shadow    erweitert    frei
────────────────────────────────────────────────────────────────────────────────────
STRUKTUR (Schema)
  Section-Typen     nur def.     nur def.     nur def.     erweiterbar  frei
  Section-Abfolge   logisch      logisch      frei         frei         frei
────────────────────────────────────────────────────────────────────────────────────
AGENTEN-VERHALTEN
  Rueckfragen       haeufig      bei Bedarf   selten       selten       minimal
  Eigenentscheidung minimal      moderat      hoch         sehr hoch    maximal
════════════════════════════════════════════════════════════════════════════════════
```

## Stufe 1: CI-Strikt (`--strict`)

> **Fuer:** Offizielle Dokumente, Kundenpraesentationen, Brand-kritische Outputs

| Agent | Fixiert | Freiheitsgrad |
|-------|---------|---------------|
| **Content-Agent** | Schema exakt befolgen | Nur definierte Section-Typen |
| **Diagram-Agent** | Engine-Routing nach Tabelle | Mermaid/D2 nach Komplexitaet |
| **Chart-Agent** | CI-Farbpalette strikt | Nur `--ci-primary`, `--ci-success`, `--ci-text-muted` |
| **Layout-Agent** | Standard-Komponenten | `icon-grid`, `comparison-table`, `section` |
| **Assembly-Agent** | Theme: `default`, Style: `presentation` | Keine Auswahl |

## Stufe 2: CI-Flexibel (`--ci-flex`)

> **Fuer:** Interne Dokumente, Varianten, ansprechendere Praesentationen

Erlaubte Visual Effects:
```css
section { margin: 60px 0; }
.card:hover { transform: translateY(-5px); box-shadow: var(--ci-shadow); }
.card { transition: all 0.3s ease; }
```

**Nicht erlaubt:** Animationen, Gradient-Text, Glasmorphism, Glow

## Stufe 3: Profil-Frei (`--profile`) ★ Default

> **Fuer:** Allgemeine Visualisierungen, Guides, Tutorials

Volle Visual-Profile-Auswahl (Theme × Layout-Style). Erbt Visual Effects von Stufe 2.

## Stufe 4: Strukturell-Frei (`--creative`)

> **Fuer:** Experimentelle Outputs, Pitch-Decks, kreative Projekte

Zusaetzlich erlaubt: Animationen, Glasmorphism, Glow-Effekte, Gradient-Text, erweiterte Farbpalette.

## Stufe 5: Voll-Kreativ (`--experimental`)

> **Fuer:** Prototypen, Konzept-Visualisierungen

Keine Einschraenkungen. Schema optional, neue Themes/Styles erstellbar.

## Erkennung im User-Prompt

| User sagt... | → Stufe |
|--------------|---------|
| "offiziell", "Kunde", "Brand" | 1-2 |
| "Guide", "Tutorial", "Report" | 3 |
| "kreativ", "experimentell" | 4-5 |

**Default:** Stufe 3 (Profil-Frei)

## In content.json

```json
{
  "creativeLevel": 3,
  "visualProfile": {
    "theme": "default",
    "layoutStyle": "presentation"
  }
}
```
