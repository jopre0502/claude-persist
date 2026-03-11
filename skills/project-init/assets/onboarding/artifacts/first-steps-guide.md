# Workshop: Claude Code + Knowledge Hub Setup

> **Format:** Hybrid (Vorbereitungs-Guide + Live-Session)
> **Zielgruppe:** Tech-affine Nicht-Entwickler (Windows)
> **Dauer:** ~30 Min Vorbereitung (selbststaendig) + ~90 Min Live-Session
> **Voraussetzung:** Teilnahme an der Praesentation "Next Level KI"

---

## Wie dieser Workshop funktioniert

Dieser Workshop ist selbst ein **Task** — genau so, wie Sie spaeter Ihre eigenen Projekte strukturieren. Jeder Schritt ist eine **Action** mit einer **Definition of Done**. Sie arbeiten den Task ab, Claude hilft Ihnen dabei, und am Ende ist der Task "completed".

**Sie lernen das System, indem Sie es benutzen.**

### Ihre Unterlagen

| Dokument | Was | Wann benutzen |
|----------|-----|---------------|
| **[TASK-000-onboarding.md](tasks/TASK-000-onboarding.md)** | Der Task — 10 Actions mit Schritten + DoD | Waehrend des gesamten Workshops |
| **[Cheatsheet](tasks/TASK-000/artifacts/cheatsheet.md)** | 1-Seiter zum Ausdrucken — die wichtigsten Befehle | Nach dem Workshop, neben den Monitor haengen |
| **Dieses Dokument** | Hintergrund — Kosten, Accounts, Troubleshooting, Links | Bei Fragen und Problemen |

---

## Ablauf

```
VOR DER SESSION (selbststaendig, ~30 Min)
  → TASK-000 Actions A1–A4: System, Software, VS Code, Claude Code
  → Dieses Dokument: Abschnitt "Accounts + Kosten" lesen

LIVE-SESSION (mit Trainer, ~90 Min)
  0:00  Troubleshooting (wer hat Probleme mit A1–A4?)
  0:15  Action A5: Knowledge Hub klonen
  0:30  Action A6: CLAUDE.md personalisieren
  0:40  Action A7: Smoke Test
  0:50  Action A8: /project-init — Erstes Projekt
  1:05  Action A9: Session-Continuity erleben
  1:15  Action A10: Eigenstaendig navigieren
  1:25  Abnahme + Q&A
```

---

## Accounts + Kosten

### Anthropic Account (Pflicht)

1. Registrieren: https://console.anthropic.com/
2. Plan waehlen:

| Plan | Preis | Claude Code | Web-Interface | Empfehlung |
|------|-------|-------------|---------------|------------|
| Free | $0 | Nein | Ja (limitiert) | Nicht fuer Claude Code |
| Pro | $20/Monat | Ja (limitiert) | Ja | Einstieg, fuer den Workshop ausreichend |
| Max | $100/Monat | Ja (hoeheres Limit) | Ja | Produktive Nutzung |
| Team | $30/User/Monat | Ja | Nur Claude Code | Teams ohne Web-Bedarf |

**Sie brauchen mindestens Pro ($20/Monat).** Fuer den Workshop reicht das. Fuer produktive Nutzung empfehle ich Max.

**Kostenvergleich:** Pro = $240/Jahr, Max = $1.200/Jahr. Ein einziger Mitarbeiter-Tag kostet mehr als ein Jahresabo Pro.

### GitHub Account (Pflicht)

- Falls noch keiner: https://github.com/signup
- Wird gebraucht fuer: Knowledge Hub klonen

---

## Troubleshooting

| Problem | Ursache | Loesung |
|---------|---------|---------|
| `claude` nicht gefunden | PATH nicht aktualisiert | **Neues Terminal oeffnen** (loest 90% der Faelle) |
| `winget` nicht verfuegbar | Alte Windows-Version | .msi-Installer manuell herunterladen |
| Auth fehlgeschlagen | Browser-Session expired | `claude logout` → `claude` neu starten |
| Skills nicht sichtbar | Hub nicht in `~/.claude/` | `ls ~/.claude/skills/` pruefen — Ordner muss existieren |
| Token-Limit schnell erreicht | Pro-Plan hat niedrigeres Limit | Auf Max upgraden oder Sessions kuerzer halten |
| PowerShell 5 statt 7 | VS Code Default falsch | Terminal → Dropdown → "Select Default Profile" → **"PowerShell"** |
| `git clone` scheitert | Permission denied | HTTPS statt SSH: `https://github.com/...` (nicht `git@github.com:...`) |
| Alles installiert, aber Skills fehlen | Falscher Pfad geklont | `~/.claude/` muss DIREKT skills/, agents/, etc. enthalten — kein Unterordner |

---

## Nuetzliche Links

| Was | URL |
|-----|-----|
| Anthropic Console | https://console.anthropic.com/ |
| Claude Code Docs | https://docs.anthropic.com/en/docs/claude-code |
| Knowledge Hub Repo | https://github.com/jopre0502/claude-persist |
| VS Code Download | https://code.visualstudio.com/ |
| PowerShell Releases | https://github.com/PowerShell/PowerShell/releases |
| Node.js Download | https://nodejs.org/ |

---

## Trainer-Notizen

### Vorbereitung (Trainer)

- [ ] Knowledge Hub Repo ist public (oder Invites verschickt)
- [ ] TASK-000 + Cheatsheet an Teilnehmer gesendet (mind. 3 Tage vorher)
- [ ] Eigene Demo-Umgebung bereit (sauberes Projekt fuer Live-Demo)
- [ ] Fallback-Screenshots fuer alle Live-Demos vorbereitet

### Timing-Tipps

| Action | Risiko | Tipp |
|--------|--------|------|
| A1–A4 (Pre) | Hoch — jemand hat was vergessen | 15 Min Puffer am Anfang einplanen |
| A5 (Clone) | Mittel — Pfad-Probleme | Windows-Pfad `C:\Users\NAME\.claude\` explizit zeigen |
| A6 (CLAUDE.md) | Niedrig — aber Teilnehmer werden kreativ | Nicht abwuergen! Kreativitaet ist gut. |
| A9 (Session-Continuity) | Niedrig — aber DER Moment | LANGSAM machen. Pause. Wirken lassen. |
| A10 (Eigenstaendig) | Mittel — Teilnehmer unsicher | Zurueckhalten! Nur bei >2 Min Stillstand eingreifen. |

### Typische Fragen + Antworten

| Frage | Antwort |
|-------|---------|
| "Ist das sicher?" | Ja, lokal. Code geht an Anthropic API (wie ChatGPT). Permission-System regelt Zugriffe. |
| "Geht das mit ChatGPT?" | Nein. Claude Code ist CLI + Skill-System. Cursor/Copilot sind aehnlich, aber ohne vergleichbares Oekosystem. |
| "Brauche ich Programmier-Kenntnisse?" | Fuer Nutzung: Nein. Fuer Anpassung (Skills, Hooks): Ja, aber Claude hilft dabei. |
| "Was wenn ich was kaputt mache?" | Git ist das Sicherheitsnetz. `git status`, `git diff`, `git checkout -- .` → alles rueckgaengig. |

### /project-init TASK-000 Integration

Wenn Teilnehmer `/project-init` ausfuehren, pruefen ob TASK-000 in PROJEKT.md erscheint:

```
| TASK-000 | Onboarding Tutorial | pending | - | 2h | Funktionierendes Setup | docs/tasks/TASK-000-onboarding.md |
```

Falls der User das Tutorial ueberspringt → Status auf `completed` setzen.

---

**Version:** 2.0 | **Erstellt:** 2026-03-02 | **Aenderung:** Refactored — TASK-000 ist SSOT, Guide ist Companion
