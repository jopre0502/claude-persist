# Delegation Patterns

Entscheidungshilfe: Wann Subagent vs. Main Session?

## Entscheidungsmatrix

| Kriterium | → Subagent | → Main Session |
|-----------|-------------------|----------------|
| **Abhängigkeit** | Unabhängig von anderen Steps | Braucht Ergebnis vorheriger Steps |
| **Shared State** | Kein gemeinsamer State | Modifiziert gemeinsamen State |
| **User-Interaktion** | Keine Rückfragen nötig | Könnte Rückfragen erfordern |
| **Komplexität** | Klar definiert, deterministisch | Erfordert Judgment Calls |
| **Risiko** | Niedriges Risiko, reversibel | Irreversibel oder kritisch |

---

## Parallelisierbarkeits-Heuristik

### ✅ Kandidaten für Subagents

```
1. Research/Analyse
   - "Lies Datei X und fasse zusammen"
   - "Suche nach Pattern Y im Codebase"
   - "Analysiere bestehende Implementation"

2. Generierung (unabhängig)
   - "Erstelle Test-Datei für Module X"
   - "Generiere Dokumentation für API Y"
   - "Schreibe Migration Script"

3. Validierung (read-only)
   - "Prüfe ob alle Dependencies installiert"
   - "Validiere Schema gegen Spec"
   - "Linte Code in Directory X"
```

### ❌ NICHT für Subagents

```
1. Sequentielle Abhängigkeiten
   - "Erstelle Datei A, dann importiere in B"
   - "Refaktor X, dann update Tests"

2. Shared State
   - Mehrere Steps modifizieren gleiche Datei
   - Database-Transaktionen mit Abhängigkeiten

3. User-Interaktion wahrscheinlich
   - "Implementiere Feature nach User-Präferenz"
   - "Wähle zwischen Optionen A/B/C"

4. Kritische/Irreversible Aktionen
   - Deployments
   - Daten-Migrationen (Production)
   - Externe API-Calls mit Side Effects
```

---

## Konsolidierungs-Muster

Nach Subagent Completion:

```
1. Ergebnis lesen (TaskOutput oder Read output_file)
2. Erfolg prüfen:
   ├─ Erfolgreich → In Gesamtkontext integrieren
   └─ Fehlgeschlagen → User informieren, Recovery planen
3. Nächste abhängige Steps freigeben
```

---

## Beispiel-Szenario

**Task:** "Implementiere Logging für alle API Endpoints"

**Analyse:**
- Step 1: "Finde alle Endpoints" → ✅ Background (Research, read-only)
- Step 2: "Design Logging-Struktur" → ❌ Main Session (Architektur-Entscheidung)
- Step 3: "Implementiere Logger-Modul" → ❌ Main Session (braucht Design aus Step 2)
- Step 4: "Schreibe Tests für Logger" → ✅ Background (unabhängig nach Step 3)
- Step 5: "Update alle Endpoints" → ❌ Main Session (shared state, viele Dateien)

**Resultat:**
- Main Session: Steps 2, 3, 5 (sequentiell)
- Background: Step 1 (parallel zu nichts), Step 4 (parallel zu Step 5)

---

---

## Explizite Mode-Hints (Action-Level)

### Wann Hints setzen vs. Heuristik vertrauen?

**Hints setzen wenn:**
- Task hat klare Parallelisierbarkeits-Struktur (z.B. 3 unabhängige Research-Steps)
- Modell-Wahl ist kostenrelevant (viele Subagents → haiku spart erheblich)
- Task-Ersteller hat Domänenwissen über Komplexität der Steps
- Wiederkehrender Task-Typ mit bekanntem Muster

**Heuristik vertrauen wenn:**
- Unsicher über Parallelisierbarkeit
- Steps haben unklare Abhängigkeiten
- Erstmalige Task-Art ohne Erfahrungswerte

### Syntax

```markdown
# Am Ende der Step-Zeile:
1. [ ] Step-Beschreibung `[subagent:haiku]`    ← Subagent mit Haiku
2. [ ] Step-Beschreibung `[subagent:sonnet]`   ← Subagent mit Sonnet
3. [ ] Step-Beschreibung `[subagent:opus]`     ← Subagent mit Opus
4. [ ] Step-Beschreibung `[subagent]`          ← Subagent, erbt Parent-Modell
5. [ ] Step-Beschreibung `[main]`              ← Main Session
6. [ ] Step-Beschreibung                       ← Kein Hint, Heuristik entscheidet
```

### Modell-Auswahl nach Aufgabentyp

| Aufgabentyp | Empfohlenes Modell | Begründung |
|-------------|-------------------|------------|
| Datei-Suche, Grep, Schema-Check | `haiku` | Read-only, klar definiert, schnell |
| Docs generieren, Tests schreiben | `sonnet` | Moderate Komplexität, gute Balance |
| Code Review, Architektur-Analyse | `opus` | Tiefes Verständnis nötig |
| Unbekannt / Mixed | *(kein Hint)* | Parent-Modell erbt, User kann in Phase 3 anpassen |

### Beispiel mit Modell-Hints

**Task:** "Implementiere Logging für alle API Endpoints"

```markdown
1. [ ] Finde alle Endpoints `[subagent:haiku]`
2. [ ] Design Logging-Struktur `[main]`
3. [ ] Implementiere Logger-Modul `[main]`
4. [ ] Schreibe Tests für Logger `[subagent:sonnet]`
5. [ ] Update alle Endpoints `[main]`
```

**Ergebnis:** Step 1 läuft günstig mit Haiku (reine Suche), Step 4 mit Sonnet (Code-Generierung), Rest in Main Session.

---

## Environment-Bootstrap für Sub-Agents

### Problem

Sub-Agents (Agent tool) erben **keine** env vars aus dem SessionStart Hook (`CLAUDE_ENV_FILE`).
Betrifft: `$OBSIDIAN_VAULT`, `$N8N_BASE_URL`, und alle via `~/.config/secrets/env.d/*.env` geladenen Variablen.

### Bootstrap-Pattern: `sops -d` Inline

Jeder Bash-Call im Sub-Agent, der env vars braucht, muss diese selbst entschlüsseln:

```bash
# Vault-Operationen im Sub-Agent:
source <(sops -d ~/.config/secrets/env.d/vault.env) && obsidian.com search query="test"

# n8n-Operationen im Sub-Agent:
source <(sops -d ~/.config/secrets/env.d/n8n.env) && curl "$N8N_BASE_URL/api/v1/workflows"
```

**Wichtig:** `source <(sops -d ...)` setzt env vars nur für den aktuellen Bash-Call. Jeder neue Bash-Call braucht das Prefix erneut — es gibt kein `export` über Tool-Calls hinweg.

### Delegation-Entscheidung: Pfade vs. Secrets

| Kategorie | Beispiele | Sub-Agent Bootstrap? | Methode |
|-----------|-----------|---------------------|---------|
| **Pfade** | `OBSIDIAN_VAULT`, `N8N_BASE_URL` | ✅ Ja | `sops -d <profil>.env` |
| **API Keys** | `N8N_API_KEY`, `GITHUB_TOKEN` | ❌ Nein | Main-Session auflösen, Ergebnis übergeben |

**Regel:** Wenn ein Sub-Agent nur Pfade/URLs braucht → Bootstrap via `sops -d`. Wenn API Keys nötig → Main-Session führt den Call aus und übergibt das Ergebnis als Klartext im Prompt.

### Prompt-Template für Vault-fähige Sub-Agents

Wenn ein Sub-Agent Vault-Zugriff braucht, dieses Pattern im `prompt:`-Parameter verwenden:

```
Du hast Zugriff auf den Obsidian Vault via CLI.
Für jeden Bash-Call der $OBSIDIAN_VAULT braucht, prefixe mit:
  source <(sops -d ~/.config/secrets/env.d/vault.env) &&

Beispiel: source <(sops -d ~/.config/secrets/env.d/vault.env) && obsidian.com read file="notiz.md"
```

### Wann NICHT delegieren (trotz Bootstrap)

- Vault-Operation braucht **Kontext aus der Konversation** (z.B. User hat gerade ein Dokument bearbeitet)
- Operation braucht **echte Secrets** (API Keys) — Main-Session only
- Operation ist **interaktiv** (braucht AskUserQuestion)

---

*Referenz für task-orchestrator Phase 2*
