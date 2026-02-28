# Marktanalyse: my-claude-knowledge-hub im Wettbewerbsumfeld

> **Datum:** 2026-02-28
> **Methodik:** Parallele Web-Recherche (15+ Suchen, 3 Research-Agents) zu GitHub-Repos, Reddit-Diskussionen, Viral-Faktoren und Zielgruppen-Dynamik
> **Sicherheitsstufe:** Mittel-Hoch (multiple Quellen, aktuelle Daten, aber Prognosen sind inherent unsicher)

---

## Executive Summary

Das Claude Code Ecosystem explodiert: **70.000 GitHub Stars** für Claude Code selbst, **~2 Mrd. USD ARR**, **4% aller öffentlichen GitHub-Commits** von Claude Code geschrieben. Der Markt für Claude Code Konfigurationen, Skills und Workflows ist heiß, aber zunehmend umkämpft. **my-claude-knowledge-hub** hat mehrere einzigartige Differenzierungsmerkmale (Anti-Halluzination, Obsidian-Integration, Session-kontinuierliches Task-Management), steht aber vor der Herausforderung, sich gegen deutlich größere Repos (obra/superpowers mit 42k Stars, SuperClaude mit 20k Stars) zu behaupten.

**Die zentrale Erkenntnis:** Die Marktlücke liegt nicht bei "noch einer awesome-list", sondern bei einem **opinionated, sofort einsetzbaren Workflow-System** -- vergleichbar mit dem Sprung von "awesome-react" zu "create-react-app". Genau das kann dieses Repo sein.

---

## 1. Wettbewerbslandschaft

### Tier 1 -- Große Player (>10k Stars)

| Repo | Stars | Fokus | vs. my-claude-knowledge-hub |
|------|-------|-------|----------------------------|
| [obra/superpowers](https://github.com/obra/superpowers) | ~42.000 | Agentic Skills Framework, 7-Phasen-Workflow (Brainstorming → TDD → Execution), Plugin-Marketplace | **Stärkster Konkurrent.** Ähnlicher Ansatz, aber massiv größere Community. Hat eigenen Marketplace. Fokussiert auf SW-Engineering-Methodik. Kein Anti-Halluzination, kein Obsidian, kein Session-Management. |
| [SuperClaude-Org/SuperClaude_Framework](https://github.com/SuperClaude-Org/SuperClaude_Framework) | ~20.400 | Meta-Programming Framework, 19 Commands, 9 kognitive Personas, Shell-Installer | Anderer Ansatz: Persona-Flag-System statt dedizierte Agents. Hat `install.sh` -- deutlich niedrigere Einstiegshürde. |
| [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) | ~21.600 | Kuratierte Liste (Skills, Hooks, Commands, Plugins) | **Aggregator, kein Konkurrent.** Hier gelistet zu werden = Sichtbarkeitsziel #1. |

### Tier 2 -- Mittlere Player (1k-10k Stars)

| Repo | Stars | Fokus | Relevanz |
|------|-------|-------|----------|
| [diet103/claude-code-infrastructure-showcase](https://github.com/diet103/claude-code-infrastructure-showcase) | ~8.400 | 5 Skills, 6 Hooks, 10 Agents, **Skill-Auto-Activation via Hooks** | **Ähnlichster Ansatz.** Kleiner im Umfang, aber innovatives Auto-Activation-Feature. |
| [ruvnet/ruflo](https://github.com/ruvnet/ruflo) | ~5.800 Commits | Multi-Agent-Orchestration-Plattform, Swarm Intelligence, WASM/Rust | Enterprise-Grade-Runtime. Völlig andere Liga (Plattform vs. Config-Repo). |
| [smtg-ai/claude-squad](https://github.com/smtg-ai/claude-squad) | ~5.600 | Terminal-App für Multiple Agent-Instanzen (tmux + git worktrees) | Komplementär: claude-squad managed WO Agents laufen, my-claude-knowledge-hub definiert WAS sie tun. |
| [trailofbits/skills](https://github.com/trailofbits/skills) | ~3.000 | Security-fokussierte Skills (CodeQL, Semgrep, Variant Analysis) | Spezialisierter Security-Konkurrent. Professionell, aber eng fokussiert. |
| [levnikolaevich/claude-code-skills](https://github.com/levnikolaevich/claude-code-skills) | wachsend | 102 production-ready Skills, Agile-Lifecycle, Multi-Model Review | **Direkter Konkurrent im Task-Management.** Mehr Skills (102 vs. 18), aber kein Obsidian, kein Anti-Halluzination, kein Session-Management. |
| [rohitg00/awesome-claude-code-toolkit](https://github.com/rohitg00/awesome-claude-code-toolkit) | wachsend | 135 Agents, 35 Skills (+15.000 via SkillKit), 42 Commands | Quantitativ überlegen. Aber: Katalog statt kohärentes System. Breite > Tiefe. |

### Tier 3 -- Nischen-Player mit relevanten Features

| Repo | Relevanz |
|------|----------|
| [kryptobaseddev/cleo](https://github.com/kryptobaseddev/cleo) | **Einziger Konkurrent mit Anti-Halluzinations-Fokus** (Token-Validation, Schema Enforcement). Aber nur Task-Management. |
| [ArtemXTech/claude-code-obsidian-starter](https://github.com/ArtemXTech/claude-code-obsidian-starter) | **Nächster Konkurrent in der Obsidian-Nische.** Pre-configured Vault, Mobile Setup. Weniger tiefe Integration. |
| [automazeio/ccpm](https://github.com/automazeio/ccpm) | Task-Management via GitHub Issues. Stark in GitHub-Integration, schwächer offline. |
| [serpro69/claude-starter-kit](https://github.com/serpro69/claude-starter-kit) | Template-Repo mit Template-Sync-Workflow (upstream-Updates automatisch pullen). |
| [FlorianBruniaux/claude-code-ultimate-guide](https://github.com/FlorianBruniaux/claude-code-ultimate-guide) | Umfassender Guide, nicht kopierbares System. Referenz statt Template. |

### Angrenzende Ecosysteme

| Ecosystem | Key Repos | Vergleich |
|-----------|-----------|-----------|
| **Cursor Rules** | [awesome-cursorrules](https://github.com/PatrickJS/awesome-cursorrules) | Ähnliche Idee (.cursorrules ≈ CLAUDE.md), IDE-spezifisch |
| **Aider** | [Aider-AI/aider](https://github.com/Aider-AI/aider) | Tool, kein Config-Framework |
| **Copilot** | `.github/copilot-instructions.md` | Weniger mächtig, aber tief in GitHub integriert |
| **Skills Marketplace** | [SkillHub](https://www.skillhub.club/), Anthropic Marketplace | 7.000+ Skills, wachsendes Ecosystem |

---

## 2. Was die Community will (Reddit & Forum-Analyse)

### Top Pain Points (nach Häufigkeit)

| # | Pain Point | Community-Signal | Relevanz für unser Repo |
|---|-----------|------------------|------------------------|
| 1 | **Rate Limits & Kosten** | Selbst $200/Monat reicht bei Multi-Agent nicht | Indirekt: Budget-Aware Planning adressiert das |
| 2 | **Kontextverlust zwischen Sessions** | "Stunden an Arbeit gehen verloren" | **DIREKT adressiert:** PROJEKT.md + session-refresh |
| 3 | **Ungewollte Code-Änderungen** | Claude hält sich nicht an Scope | Anti-Halluzination + strenge Instructions |
| 4 | **Permission-Fatigue** | "Es fragt für alles um Erlaubnis" | auto-approve-readonly Hook |
| 5 | **Code-Qualität ~30% First-Pass** | Duplikate, bizarre Dateinamen | Anti-Halluzinations-Protokoll |
| 6 | **Skill-Discovery fehlt** | Kein zentraler Marketplace | Skill-Creator + organisierte Skill-Bibliothek |
| 7 | **Token-Overhead bei Multi-Agent** | 50K Tokens pro Subagent-Turn | Environment-Isolation-Dokumentation |
| 8 | **CLAUDE.md Maintenance** | Wie groß, wie strukturiert? | Dokumentierte Best Practices |

### Was am meisten nachgefragt wird

1. **Persistenter, intelligenter Kontext** über Sessions hinweg → *Wir haben das: PROJEKT.md + session-refresh*
2. **Integration von persönlichem Wissen** (Obsidian, Docs, ADRs) als AI-Kontext → *Wir haben das: vault-manager + obsidian-pilot*
3. **Standardisierte Agent-Harnesses** (CLAUDE.md + Skills + Hooks + Memory vereint) → *Wir haben das: integriertes System*
4. **Ein Skill-Ecosystem** mit Discovery, Installation und Sharing → *Teilweise: skill-creator, aber kein Marketplace*
5. **Ready-to-use Starter-Kits** für verschiedene Projekt-Setups → *Gap: nur ein Setup, nicht multi-template*

### Community-Stimmung

- Claude Code hält **70% Usage-Anteil** auf Vibe Kanban -- kein anderes Tool erreicht 20%
- r/ClaudeCode: **4.200+ wöchentliche Contributors**, 3x mehr als r/Codex
- **66% der Entwickler** berichten das "80%-Problem" (Addy Osmani) -- AI-Lösungen fast richtig, aber nicht ganz
- Community baut aktiv Lösungen: 4-Terminal-Setups, shared Planning-Docs, Fan-out/Fan-in Patterns

---

## 3. Alleinstellungsmerkmale (USPs) von my-claude-knowledge-hub

### Was KEIN anderer Konkurrent hat

| USP | Nächster Konkurrent | Unser Vorteil |
|-----|---------------------|---------------|
| **Anti-Halluzinations-Protokoll** | cleo (nur Task-Validation) | Systemisches Protokoll: Faktenmodus, Quelle-oder-Stille, Sicherheitsstufen, Selbstprüfung. In CLAUDE.md verankert. |
| **Obsidian als First-Class Integration** | ArtemXTech (Pre-configured Vault) | Tiefere Integration: vault-manager Skill, obsidian-pilot Agent, vault:-Referenzen, MCP, Commands |
| **Session-Continuous Task-Management** | ccpm (GitHub Issues) | PROJEKT.md mit 7-Column-Schema, Task-Files, offline-fähig, kein externer Tool-Overhead |
| **Budget-Aware Planning** | Keiner | Token-Budget-Tracking, Action-Budget-Heuristiken, automatische Zyklus-Grenzen |
| **Environment-Isolation-Dokumentation** | Keiner | Explizite Rules für Subagent-Vererbung, Vault-Referenz-Auflösung, Secrets-Management |

### Was Konkurrenten besser machen

| Bereich | Wer | Was fehlt uns |
|---------|-----|---------------|
| **Community & Adoption** | superpowers (42k Stars) | Massiv größere Community, offizieller Marketplace |
| **Installierbarkeit** | SuperClaude (`install.sh`) | Kein One-Liner-Install, nur Repo-Klonen |
| **Quantität** | rohitg00 (135 Agents) | Weniger Skills/Agents (aber battle-tested) |
| **Security-Tiefe** | trailofbits | Keine CodeQL/Semgrep-Integration |
| **Skill-Auto-Activation** | diet103 | Keine Hook-basierte Auto-Erkennung |
| **Dokumentation** | claude-code-ultimate-guide | Kein Getting-Started-Guide, keine Videos |
| **Englisch als Primärsprache** | Alle anderen | Deutschsprachig = Reichweiten-Limiter |

---

## 4. Gap-Analyse: Wo sich das Repo entwickeln kann

### Gap 1: Installierbarkeit & Onboarding (Kritisch)
**Problem:** Aktuell muss man das Repo klonen und selbst anpassen. SuperClaude hat `install.sh`, superpowers hat `/plugin install`.
**Empfehlung:** Ein `install.sh` Script, das selektiv Skills, Hooks und CLAUDE.md-Templates installiert. Idealerweise auch als Plugin für den Anthropic Skills Marketplace.
**Impact:** Senkt die Einstiegshürde massiv. Statt "studiere mein Repo" → "führe einen Befehl aus".

### Gap 2: Englischsprachiges README & Internationalisierung (Kritisch für Viralität)
**Problem:** Deutschsprachige Dokumentation begrenzt die Reichweite auf ~8% der GitHub-Nutzer.
**Empfehlung:** README.md auf Englisch, CLAUDE.md kann weiterhin Deutsch sein (das ist der Punkt -- anpassbar). Deutsche Erklärungen als `docs/de/`.
**Impact:** 10-12x mehr potenzielle Nutzer.

### Gap 3: Visuelle Dokumentation (Hoch)
**Problem:** Kein Architektur-Diagramm, keine GIFs, kein Quickstart-Video. "Popular repositories tend to have a README with pictures/gifs of the product in action."
**Empfehlung:** Mermaid-Diagramm der System-Architektur, GIF einer typischen Session, Vorher/Nachher-Vergleich.
**Impact:** Entscheidend für GitHub Trending und Social-Media-Shares.

### Gap 4: Multi-Template-Support (Mittel)
**Problem:** Nur ein Setup. Community will Starter-Kits für verschiedene Projekt-Typen.
**Empfehlung:** Templates für: Solo-Developer, Team-Projekt, Obsidian-PKM, Security-fokussiert.
**Impact:** Breitere Zielgruppe, mehr Contribution-Möglichkeiten.

### Gap 5: Skill-Auto-Activation (Mittel)
**Problem:** Skills müssen manuell invoked oder in CLAUDE.md referenziert werden.
**Empfehlung:** Hook-basierte Auto-Activation (diet103-Pattern übernehmen).
**Impact:** Smoother UX, weniger manuelle Konfiguration.

### Gap 6: Community-Infrastruktur (Mittel-Hoch)
**Problem:** Kein CONTRIBUTING.md, keine GitHub Discussions, keine "Good First Issue"-Labels.
**Empfehlung:** CONTRIBUTING.md, Issue-Templates, Discussions aktivieren, klare Contribution-Guidelines.
**Impact:** Ermöglicht Community-Wachstum und zeigt Professionalität.

### Gap 7: Content-Marketing-Pipeline (Hoch)
**Problem:** Kein begleitender Blog/Content, keine Hacker-News-Präsenz.
**Empfehlung:** Dev.to/Medium-Artikel ("How I structured my Claude Code workflow"), Show HN Post, Tweet-Thread.
**Impact:** Primärer Wachstumstreiber. Ohne Content kein organisches Discovery.

---

## 5. Was fehlt, um viral zu gehen

### Die Viral-Formel (basierend auf awesome-chatgpt-prompts, Supabase, ScrapeGraphAI)

| Faktor | Status bei uns | Aktion nötig |
|--------|---------------|--------------|
| **Echtes Problem lösen** | ✅ Ja (Session-Kontinuität, Anti-Halluzination) | Besser kommunizieren |
| **README-Qualität** | ❌ Fehlt (keine Grafiken, GIFs, Quickstart) | **Priorität 1** |
| **Setup in < 5 Min** | ❌ Fehlt (kein install.sh) | **Priorität 1** |
| **Timing** | ⚠️ Gut, aber Fenster schließt sich (Markt wird voller) | Jetzt handeln |
| **Community-Contributions** | ❌ Fehlt (keine CONTRIBUTING.md) | **Priorität 2** |
| **Englisch** | ❌ Primär Deutsch | **Priorität 1** |
| **Content-Marketing** | ❌ Kein begleitender Content | **Priorität 2** |
| **Social Proof** | ❌ Keine Stars, keine Referenzen | Kommt mit Marketing |
| **Naming/SEO** | ⚠️ "my-claude-knowledge-hub" ist beschreibend, aber nicht catchy | Erwägen |

### Realistische Wachstumsprognose

| Phase | Zeitraum | Stars | Voraussetzung |
|-------|----------|-------|---------------|
| Seeding | Monat 1-2 | ~50-100 | Englisches README + install.sh |
| First Traction | Monat 3-4 | ~200-500 | Blog-Post + Reddit/HN |
| Breakout | Monat 5-6 | ~1.000-2.000 | HN Front Page oder Listing bei awesome-claude-code |
| Organic Growth | Monat 7-12 | ~5.000+ | Community-Contributions + regelmäßige Updates |

**Referenz:** ScrapeGraphAI brauchte 6 Monate für die ersten 1.000 Stars, dann nur 4 Monate für die nächsten 9.000. Wachstum ist nicht-linear.

### Launch-Strategie (Konkret)

**Phase 1 (Sofort): Repo-Readiness**
- [ ] Englisches README.md mit Architektur-Diagramm
- [ ] `install.sh` für One-Liner-Setup
- [ ] CONTRIBUTING.md + Issue-Templates
- [ ] GIF einer typischen Session

**Phase 2 (Woche 1-2): Seeding**
- [ ] Eintrag bei [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) beantragen
- [ ] Eintrag bei [awesome-claude-skills](https://github.com/travisvn/awesome-claude-skills) beantragen
- [ ] Post auf r/ClaudeAI, r/ChatGPTPro, r/ObsidianMD
- [ ] Dev.to Artikel: "How I built an anti-hallucination workflow for Claude Code"

**Phase 3 (Woche 3-4): Amplification**
- [ ] "Show HN" Post auf Hacker News
- [ ] Twitter/X Thread mit konkreten Beispielen
- [ ] YouTube Screencast

**Phase 4 (Monat 2+): Community-Building**
- [ ] GitHub Discussions aktivieren
- [ ] "Good First Issue"-Labels
- [ ] Launch-Week-Stil: Alle 4-6 Wochen gebündelte Updates

---

## 6. Separate Dimension: Zielgruppe jenseits von GitHub-Developern

### Die Kernfrage: Spricht unser Repo eine Zielgruppe an, die sonst nicht auf GitHub vertreten ist?

**Kurze Antwort: Ja, teilweise -- und das ist eine massive Chance.**

### Die "Obsidian-Claude-Brücke" als Unique Audience Play

**Obsidian-Community (1.5 Mio+ Nutzer, 22% YoY-Wachstum):**
- Viele Obsidian-Nutzer sind **KEINE klassischen Developer**: Akademiker, Researcher, Writer, Knowledge Worker
- 3.625+ Obsidian-Repos auf GitHub zeigen: die Community IST bereits auf GitHub aktiv
- Die Obsidian-Community sucht aktiv nach AI-Integration (Smart Connections: 600.000+ Downloads)
- **Aber:** Diese Nutzer scheitern oft an der Komplexität von Claude Code Setup

**Die Zielgruppen-Matrix:**

| Segment | Auf GitHub? | Erreichbar? | Potenzial | Wie ansprechen? |
|---------|-------------|-------------|-----------|-----------------|
| **Developer (Claude Code Power User)** | ✅ Definitiv | Hoch | Hoch (aber umkämpft) | GitHub + Reddit |
| **Obsidian Power User (semi-technisch)** | ✅ Meist ja | Hoch | **Sehr hoch** (unterversorgt) | Obsidian Forum + r/ObsidianMD |
| **Prompt Engineers** | ✅ Ja | Hoch | Hoch | Dev.to + Twitter |
| **"Vibe Coder" (Neue Developer durch AI)** | ⚠️ Teilweise | Mittel | Mittel | YouTube + Tutorials |
| **Knowledge Worker (nicht-technisch)** | ❌ Selten | Niedrig auf GitHub | Niedrig auf GitHub, hoch extern | Blog + Video |
| **Freelancer/Solo-Unternehmer** | ⚠️ Teilweise | Mittel | Mittel | Product Hunt + Blog |

### Bewertung: Nicht-traditionelle GitHub-Audience

**Stärke (Score: 7/10):**
Das Repo adressiert mit der Obsidian-Integration, dem Anti-Halluzinations-Protokoll und dem session-kontinuierlichen Task-Management tatsächlich Pain Points, die über pure Developer hinausgehen. Besonders die Obsidian-PKM-Community (Akademiker, Researcher, Writer) ist eine wachsende GitHub-Audience, die von klassischen Developer-Tools nicht gut bedient wird.

**Einschränkung:**
Die rein nicht-technische Zielgruppe wird GitHub nicht als primäre Anlaufstelle nutzen. Für diese braucht es Content-Distribution über andere Kanäle.

### Wie die Nicht-Developer-Audience erschlossen werden kann

1. **Obsidian-Integration prominent zeigen** → Zieht PKM-Community an
2. **"No terminal required"-Sektion** → Für Claude Code Desktop/Web-App-Nutzer
3. **Begleit-Blog auf Deutsch UND Englisch** → SEO für breitere Zielgruppe
4. **Template "Obsidian-PKM-Workflow"** → Dediziertes Setup für Knowledge Worker
5. **Tutorials mit konkreten Obsidian-Use-Cases** → YouTube/Medium-Content

### Das "awesome-chatgpt-prompts"-Prinzip

Der erfolgreichste vergleichbare Case (143k+ Stars) zeigt: **Das größte Potenzial liegt in extremer Zugänglichkeit.**
- Ersteller hatte "no proficiency on any kind of AI"
- Jeder konnte die Prompts sofort nutzen
- Kein Setup, kein Terminal, keine Dependencies
- Funktionierte über alle AI-Tools hinweg

**Lektion für uns:** Je niedriger die Einstiegshürde, desto breiter die Zielgruppe. Eine "Kopier diese CLAUDE.md und leg los"-Experience ist viral-fähiger als ein komplexes Multi-Component-System.

---

## 7. Strategische Empfehlungen (Priorisiert)

### Muss-haben (Blocker für Wachstum)

| # | Empfehlung | Aufwand | Impact |
|---|-----------|---------|--------|
| 1 | **Englisches README.md** mit Architektur-Diagramm und GIF | Mittel | Kritisch |
| 2 | **`install.sh`** für selektive Installation | Mittel | Kritisch |
| 3 | **Listing bei awesome-claude-code** beantragen | Gering | Hoch |
| 4 | **Erster Content-Piece** (Dev.to oder Medium) | Mittel | Hoch |

### Sollte-haben (Beschleunigt Wachstum)

| # | Empfehlung | Aufwand | Impact |
|---|-----------|---------|--------|
| 5 | CONTRIBUTING.md + Issue-Templates | Gering | Mittel |
| 6 | Multi-Template-Support (Solo, Team, PKM) | Hoch | Hoch |
| 7 | Skill-Auto-Activation via Hooks | Mittel | Mittel |
| 8 | Anthropic Skills Marketplace Kompatibilität | Mittel | Hoch |

### Kann-haben (Differenzierung stärken)

| # | Empfehlung | Aufwand | Impact |
|---|-----------|---------|--------|
| 9 | Video-Content / Screencast | Mittel | Mittel |
| 10 | Discord-Community (ab ~500 Stars) | Gering | Mittel |
| 11 | "Anti-Halluzination" als eigenständiges, referenzierbares Projekt | Mittel | Hoch |
| 12 | Naming-Überarbeitung (catchy + SEO-optimiert) | Gering | Mittel |

---

## 8. Risikobewertung

| Risiko | Wahrscheinlichkeit | Mitigation |
|--------|-------------------|------------|
| **Markt-Sättigung** (zu viele Claude-Code-Repos) | Mittel | Differenzierung als "System" statt "Liste" |
| **Schnelle API-Änderungen** (Claude Code evolves rapidly) | Hoch | Regelmäßige Pflege, automatisierte Checks |
| **Anthropic shipped Built-in-Lösung** (offizieller Marketplace wächst) | Mittel | Jetzt positionieren, bevor Window schließt |
| **Sprachbarriere** (Deutsch als Primärsprache) | Hoch | Englisches README als sofortige Maßnahme |
| **Nischen-Zielgruppe zu klein** | Niedrig | 4% aller GitHub-Commits = massive Basis |

---

## 9. Fazit

### Wo stehen wir?

**my-claude-knowledge-hub** hat ein **starkes, differenziertes Fundament**, das mehrere Community-Pain-Points adressiert, die kein anderer Konkurrent so systematisch abdeckt:

- Anti-Halluzination (einzigartig in dieser Tiefe)
- Obsidian-Integration (einzigartig als First-Class-Feature)
- Session-Kontinuität (besser als die meisten Konkurrenten)
- Budget-Aware Planning (einzigartig)

### Was fehlt?

Die **Verpackung und Distribution**:
- Kein englisches README
- Kein Quick-Install
- Keine visuelle Dokumentation
- Kein Content-Marketing
- Keine Community-Infrastruktur

### Die Chance

Der Claude Code Markt wächst mit ~100% YoY. Das Timing-Fenster ist **jetzt offen, aber schließt sich**. Superpowers (42k Stars) und SuperClaude (20k Stars) wachsen schnell. Wer jetzt nicht positioniert ist, wird in 6 Monaten in einem gesättigten Markt kämpfen.

**Die Kill-Feature-Kombination**, die kein anderes Repo hat:
```
Anti-Halluzination + Obsidian + Session-Kontinuität = "The Structured AI Workflow"
```

**Das ist die Positionierung, die viral gehen kann.**

---

## Quellen

### GitHub-Repos (direkte Konkurrenten)
- [obra/superpowers](https://github.com/obra/superpowers)
- [SuperClaude-Org/SuperClaude_Framework](https://github.com/SuperClaude-Org/SuperClaude_Framework)
- [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)
- [diet103/claude-code-infrastructure-showcase](https://github.com/diet103/claude-code-infrastructure-showcase)
- [ruvnet/ruflo](https://github.com/ruvnet/ruflo)
- [smtg-ai/claude-squad](https://github.com/smtg-ai/claude-squad)
- [trailofbits/skills](https://github.com/trailofbits/skills)
- [levnikolaevich/claude-code-skills](https://github.com/levnikolaevich/claude-code-skills)
- [rohitg00/awesome-claude-code-toolkit](https://github.com/rohitg00/awesome-claude-code-toolkit)
- [kryptobaseddev/cleo](https://github.com/kryptobaseddev/cleo)
- [ArtemXTech/claude-code-obsidian-starter](https://github.com/ArtemXTech/claude-code-obsidian-starter)
- [travisvn/awesome-claude-skills](https://github.com/travisvn/awesome-claude-skills)
- [f/awesome-chatgpt-prompts](https://github.com/f/awesome-chatgpt-prompts)

### Markt- und Trend-Analysen
- [SemiAnalysis: Claude Code is the Inflection Point](https://newsletter.semianalysis.com/p/claude-code-is-the-inflection-point)
- [CB Insights: Who's winning the AI coding race?](https://www.cbinsights.com/research/report/coding-ai-market-share-december-2025/)
- [Mordor Intelligence: AI Code Tools Market](https://www.mordorintelligence.com/industry-reports/artificial-intelligence-code-tools-market)
- [Incremys: Claude 2026 Statistics](https://www.incremys.com/en/resources/blog/claude-statistics)

### Community-Analysen
- [Claude Code Reddit 2026 (aitooldiscovery)](https://www.aitooldiscovery.com/guides/claude-code-reddit)
- [Claude Code Pain Points (GitHub Gist)](https://gist.github.com/eonist/0a5f4ae592eadafd89ed122a24e50584)
- [Claude Code Best Practices (Morph)](https://www.morphllm.com/claude-code-best-practices)
- [Addy Osmani: AI Coding Workflow 2026](https://addyosmani.com/blog/ai-coding-workflow/)

### Viral-Faktoren & Growth
- [HackerNoon: GitHub Stars Playbook](https://hackernoon.com/the-ultimate-playbook-for-getting-more-github-stars)
- [ScrapeGraphAI: Boost GitHub Stars](https://scrapegraphai.com/blog/gh-stars)
- [ToolJet: 12 Ways to Get More GitHub Stars](https://blog.tooljet.com/12-ways-to-get-more-github-stars-for-your-open-source-projects/)
- [Supabase Launch Week Strategy](https://launchweek.dev/n/rorstro)

### Obsidian & Knowledge Management
- [Obsidian AI Second Brain Guide 2026 (NxCode)](https://www.nxcode.io/resources/news/obsidian-ai-second-brain-complete-guide-2026)
- [Obsidian + Claude Code (Medium)](https://sonnyhuynhb.medium.com/i-built-an-ai-powered-second-brain-with-obsidian-claude-code-heres-how-b70e28100099)
- [Awesome Obsidian AI Tools (GitHub)](https://github.com/danielrosehill/Awesome-Obsidian-AI-Tools)
