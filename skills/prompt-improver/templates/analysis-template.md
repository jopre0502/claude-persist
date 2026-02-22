# Analyse-Template für Prompt-Verbesserung

Nutze diese Struktur für die systematische Analyse von Prompt-Entwürfen.

---

## 1. ORIGINAL-PROMPT

```
{{ORIGINAL_PROMPT}}
```

---

## 2. ERSTE BEWERTUNG

### Prompt-Typ
- [ ] System Prompt / Agent Definition
- [ ] Task-spezifisch (einmaliger Use Case)
- [ ] Template (wiederverwendbar)
- [ ] Tool/Function Definition
- [ ] Code-Generierung
- [ ] Analyse/Recherche
- [ ] Kreativ/Content-Erstellung
- [ ] Anderes: ___________

### Komplexität
- [ ] Niedrig (einfache Anweisung)
- [ ] Mittel (strukturierte Aufgabe)
- [ ] Hoch (komplexes Reasoning, multiple Schritte)

---

## 3. ZIELMODELL-BESTIMMUNG

Basierend auf Anforderungen:

| Modell | Eignung | Begründung |
|--------|---------|------------|
| **Sonnet 4.5** | ⭐⭐⭐ / ❌ | Tool Use? Code? Production? |
| **Opus 4.5** | ⭐⭐⭐ / ❌ | Reasoning? Kreativ? UI/UX? |
| **Haiku 4.5** | ⭐⭐⭐ / ❌ | Einfach? Speed? Kosten? |

**Empfehlung:** ___________

---

## 4. LÜCKEN-ANALYSE

### Struktur
- [ ] **Fehlend**: Klare Rollenund Persona-Definition
- [ ] **Fehlend**: Hierarchische Organisation (XML/Markdown)
- [ ] **Fehlend**: Logische Abschnitte
- [ ] **Vorhanden aber verbesserungsfähig**: ___________

### Anweisungen
- [ ] **Problem**: Vage Formulierungen (Beispiele: ___________)
- [ ] **Problem**: Implizite Erwartungen (was nicht explizit gesagt wird)
- [ ] **Problem**: Mehrdeutige Referenzen
- [ ] **Problem**: Fehlender Kontext/Motivation (WARUM)
- [ ] **Problem**: Keine konkreten Beispiele

### Technische Aspekte
- [ ] **Fehlt**: Variablen `{{NAME}}` für Wiederverwendbarkeit
- [ ] **Fehlt**: Extended Thinking Konfiguration (bei Komplexität)
- [ ] **Fehlt**: Tool Use Optimierungen
- [ ] **Fehlt**: Scratchpad-Pattern (bei Reasoning-Bedarf)
- [ ] **Fehlt**: Output-Format-Definition

### Beispiele & Format
- [ ] **Problem**: Keine Beispiele vorhanden
- [ ] **Problem**: Beispiele sind zu generisch
- [ ] **Problem**: Output-Format unklar
- [ ] **Problem**: Edge Cases nicht adressiert

### Guardrails
- [ ] **Fehlt**: Explizite Grenzen
- [ ] **Fehlt**: Fehlerbehandlung
- [ ] **Fehlt**: "Was NICHT zu tun ist"

---

## 5. STÄRKEN (Was bereits gut ist)

- ✅ **Stärke 1**: ___________
- ✅ **Stärke 2**: ___________
- ✅ **Stärke 3**: ___________

---

## 6. SCHWÄCHEN (Was verbessert werden muss)

- ❌ **Schwäche 1**: ___________
  - **Auswirkung**: ___________
  - **Verbesserung**: ___________

- ❌ **Schwäche 2**: ___________
  - **Auswirkung**: ___________
  - **Verbesserung**: ___________

- ❌ **Schwäche 3**: ___________
  - **Auswirkung**: ___________
  - **Verbesserung**: ___________

---

## 7. VARIABLEN-IDENTIFIKATION

Welche Teile sollten variabel sein?

| Original (hart-codiert) | Variable | Beispielwert |
|------------------------|----------|--------------|
| "John Doe" | `{{USER_NAME}}` | Max Mustermann |
| "config.json" | `{{CONFIG_FILE}}` | settings.yaml |
| ___________ | ___________ | ___________ |

---

## 8. OPTIMIERUNGSPOTENTIAL

### Priorität 1 (Kritisch)
1. ___________
2. ___________

### Priorität 2 (Wichtig)
1. ___________
2. ___________

### Priorität 3 (Nice-to-have)
1. ___________
2. ___________

---

## 9. ENTSCHEIDUNGSPUNKTE

Fragen an den Benutzer (wenn Mehrdeutigkeit besteht):

1. **Frage**: ___________
   - **Option A**: ___________ (Pro: ___ / Contra: ___)
   - **Option B**: ___________ (Pro: ___ / Contra: ___)

2. **Frage**: ___________
   - **Option A**: ___________
   - **Option B**: ___________

---

## 10. VERBESSERUNGSSTRATEGIE

### Phase 1: Struktur
- [ ] XML-Tags hinzufügen: `<system_instruction>`, `<context>`, `<task>`, etc.
- [ ] Abschnitte logisch organisieren
- [ ] Rolle/Persona klar definieren

### Phase 2: Explizitheit
- [ ] Vage Anweisungen → Präzise Formulierungen
- [ ] Implizite Erwartungen → Explizite Anforderungen
- [ ] Beispiele hinzufügen wo nötig

### Phase 3: Kontext & Motivation
- [ ] WARUM für jedes wichtige Verhalten erklären
- [ ] Kontext für Entscheidungen geben
- [ ] Motivation dokumentieren

### Phase 4: Technische Optimierungen
- [ ] Variablen `{{NAME}}` einbauen
- [ ] Extended Thinking (wenn komplex & Opus)
- [ ] Tool Use Details (wenn relevant)
- [ ] Scratchpad-Pattern (wenn Reasoning)

### Phase 5: Guardrails & Format
- [ ] Output-Format klar spezifizieren
- [ ] Guardrails und Grenzen setzen
- [ ] Fehlerbehandlung beschreiben
- [ ] Edge Cases adressieren

---

## 11. ERWARTETES ERGEBNIS

Nach der Verbesserung sollte der Prompt:

✓ **Struktur**: Klar organisiert mit XML-Tags
✓ **Klarheit**: Extrem explizit, keine Mehrdeutigkeiten
✓ **Kontext**: WARUM für alle wichtigen Verhaltensweisen
✓ **Technisch**: Variablen, Extended Thinking (wenn nötig), Tool Optimierungen
✓ **Beispiele**: Konkret und exakt
✓ **Guardrails**: Klar definiert
✓ **Modell-optimiert**: Für Zielmodell angepasst

---

**Nächster Schritt**: Nutze diese Analyse für die Erstellung des verbesserten Prompts gemäß dem Output-Template.
