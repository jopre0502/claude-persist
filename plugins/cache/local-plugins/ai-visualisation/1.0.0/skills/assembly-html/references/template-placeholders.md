# Feed-Timeline-Style Platzhalter

Spezifische Platzhalter fuer das Feed-Timeline Layout.

**Hauptdatei:** `skills/assembly-html/SKILL.md` (Basis- und Presentation-Platzhalter)

## Platzhalter-Referenz

| Platzhalter | Ersetzt durch |
|-------------|---------------|
| `{{PHASES}}` | Timeline-Phasen Array |
| `{{PHASE_TYPE}}` | question, insight, analysis, correction, research, decision, conclusion, takeaway |
| `{{PHASE_ICON}}` | Emoji fuer Phase |
| `{{PHASE_HEADING}}` | Ueberschrift der Phase |
| `{{PHASE_BULLETS}}` | Bullet-Liste |
| `{{PHASE_DECISIONS}}` | Entscheidungs-Boxen |
| `{{PHASE_PATHS}}` | Vergleichende Optionen |
| `{{PHASE_TAKEAWAYS}}` | Nummerierte Erkenntnisse |

## Phase-Type Mapping

| Phase-Type | Icon | Farbe | Verwendung |
|------------|------|-------|------------|
| `question` | ❓ | Blau | Fragestellungen |
| `insight` | 💡 | Gelb | Erkenntnisse |
| `analysis` | 🔍 | Gruen | Analysen |
| `correction` | ⚠️ | Orange | Korrekturen |
| `research` | 📚 | Lila | Recherche |
| `decision` | ✅ | Gruen | Entscheidungen |
| `conclusion` | 🎯 | Rot | Zusammenfassungen |
| `takeaway` | 📌 | Blau | Key Takeaways |

## HTML-Struktur

```html
<div class="timeline-phase phase-{{PHASE_TYPE}}">
    <div class="phase-icon">{{PHASE_ICON}}</div>
    <div class="phase-content">
        <h3>{{PHASE_HEADING}}</h3>
        <ul>
            {{PHASE_BULLETS}}
        </ul>
        <!-- Optional: Entscheidungs-Boxen -->
        <div class="phase-decisions">
            {{PHASE_DECISIONS}}
        </div>
    </div>
</div>
```
