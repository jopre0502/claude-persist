---
name: vault-manager
description: |
  Use this skill when the user references Vault documents via vault: prefix notation (e.g., "vault:ai-workflows"),
  requests searching the Vault, needs to work with Obsidian documents,
  asks about backlinks or related documents, or requests vault health information.
  Triggered on vault:document references for read-only context loading (UC1).
  Supports read-only access, document discovery, metadata extraction, backlinks, and vault health analysis.
  Keywords: vault, obsidian, vault-lookup, vault-read, vault-search, backlinks, related, orphans, deadends, unresolved, vault-health
model: sonnet
---

# Vault Manager Skill

**Purpose:** Read-only Obsidian Vault integration for Claude Code. Triggered via `vault:` prefix notation for document referencing.

**UC1 Focus:** Read-Only Vault-Referenz via `vault:` Notation
- Discover documents by name (recursive search)
- Load document content and metadata
- Parse YAML frontmatter
- Make content available as context

---

## Triggering Logic

### Detection Patterns

This skill is triggered when user input matches any of these patterns:

1. **vault: Prefix Notation:** `vault:document-name`, `vault:ai-workflows`
   - Triggers: Document lookup + context loading
   - Example: "Nutze vault:ai-workflows als Kontext"

2. **Explicit Skill Reference:** `vault` or `obsidian` keywords
   - Triggers: Skill activation for document operations
   - Example: "Search my Vault for X"

3. **Context Loading:** "load", "read", "fetch" + vault document reference
   - Triggers: Read-only access
   - Example: "Lade vault:project-x und zeige mir..."

4. **Backlinks/Related:** "backlinks", "related", "verlinkt", "linked to"
   - Triggers: Backlink analysis for a document
   - Example: "Zeige mir alle Backlinks zu vault:project-x"

5. **Vault Health:** "orphans", "deadends", "unresolved", "vault health", "vault status"
   - Triggers: Vault-wide graph analysis
   - Example: "Wie gesund ist mein Vault?" or "Zeige verwaiste Notizen"

### Implementation

Claude Code performs **semantic matching** on skill description:
- User input analyzed against this description
- `vault:` prefix or vault/obsidian keywords detected → Skill activates
- User approval requested before loading skill
- Full skill loaded after approval

### Important: No @ Symbol

This skill intentionally does NOT use `@` notation to avoid collision with Claude Code's
native `@file` auto-completion feature. Always use `vault:` prefix for Vault references.

---

## UC1: Read-Only Vault Reference Implementation

### Workflow

```
1. User Input Detection
   └─ Does input contain vault: prefix or vault/obsidian keywords?
      ├─ YES → Continue
      └─ NO → Skill not triggered

2. Document Discovery (CLI)
   └─ obsidian.com search query="<name>" format=json
      ├─ Obsidian internal index (fast, case-insensitive)
      ├─ Returns matches with context
      └─ Prerequisite: Obsidian App muss laufen

3. Content Loading (CLI)
   └─ obsidian.com read file="<path>"
      ├─ Read file content (full)
      └─ obsidian.com properties file="<path>" format=yaml
         ├─ Extract metadata (created, modified, tags, status, type)
         └─ Structured output (YAML/TSV)

4. Context Presentation
   └─ Display metadata + content
      ├─ Show frontmatter (dates, tags, status)
      ├─ Make content available as context
      ├─ Ready for Claude to use in analysis/writing
      └─ NO WRITES (read-only)

5. Error Handling
   └─ If any step fails:
      ├─ "Obsidian not running" → Anleitung: Obsidian App starten
      ├─ "File not found" → Suggest alternative search terms
      └─ Provide setup guidance if needed
```

### Tools (CLI+Bash Hybrid — ADR-005)

**CLI Commands** (Obsidian 1.12+, requires running Obsidian App):
- `obsidian.com search query="<name>" format=json` - Document discovery via Obsidian index
- `obsidian.com read file="<path>"` - File content (full)
- `obsidian.com properties file="<path>" format=yaml` - Metadata/frontmatter extraction
- `obsidian.com tags all counts` - List all unique tags in vault
- `obsidian.com tag name="<tag>" verbose` - Find documents by tag
- `obsidian.com backlinks path="<path>" [counts|total|format=json]` - Incoming links to a file
- `obsidian.com links path="<path>" [total]` - Outgoing links from a file
- `obsidian.com orphans [total|all]` - Files with no incoming links
- `obsidian.com deadends [total|all]` - Files with no outgoing links
- `obsidian.com unresolved [total|counts|verbose|format=json]` - Broken/unresolved links
- `obsidian.com vault [info=name|path|files|folders|size]` - Vault statistics

**Bash Scripts** (scripts/):
- `vault-date.sh --last <dur>` - Find documents by date range (erstellt/modified/file.mtime)
- `vault-export.sh <fileclass> <title> [content]` - Export to Vault (UC2)
- `vault-copy.sh <source> [target-folder]` - Copy/move files into/within Vault (external path, vault: prefix, or document name)
- `vault-base.sh <name>` - Execute Obsidian Base query (parse .base filters)
- `vault-base.sh --list` - List all .base files in vault
- `vault-base.sh --explain <name>` - Show parsed filters human-readable
- `vault-edit.sh <name> [content]` - Edit document with diff + backup (UC3, Cold-Start)
- `vault-edit.sh --path <full-path> [content]` - Edit with known path (UC3, Warm-Path)

**Script Location:** `~/.claude/skills/vault-manager/scripts/`

---

## Edit-Effizienz

- **Cold-Start:** `/vault-work <name>` (CLI search → read → edit via vault-edit.sh)
- **Warm-Path:** Wenn Dokument bereits im Kontext → direkt `vault-edit.sh --path` aufrufen
- **Entscheidungsregel:** Ist der Dateipfad bereits bekannt? → `--path` nutzen, spart CLI-Aufrufe

---

## Configuration & Secrets

### Environment Variables

OBSIDIAN_VAULT must be set to your vault path, e.g.:
/mnt/c/Users/Jonas/Google Drive/01. Prechtel_Documents/250_Obsidian/PKM

### Setup Requirements

**Before using this skill:**

1. ✅ **Obsidian App muss laufen** (CLI kommuniziert via Named Pipe)
   - Check: `obsidian.com vault` (sollte Vault-Info zurueckgeben)

2. ✅ `OBSIDIAN_VAULT` environment variable set (fuer Bash-Scripts)
   - Automatic via SessionStart Hook (`~/.config/secrets/env.d/vault.env`)
   - Manual: `export OBSIDIAN_VAULT="/path/to/vault"`

3. ✅ `obsidian.com` im PATH
   - WSL2: Automatisch via Windows-Interop (`/mnt/c/.../obsidian.com`)
   - Check: `which obsidian.com`

4. ✅ Scripts executable (fuer Bash-Scripts)
   - Location: `~/.claude/skills/vault-manager/scripts/`
   - Check: `ls -la ~/.claude/skills/vault-manager/scripts/*.sh`

---

## Error Handling

### Common Issues & Solutions

**Issue 1: OBSIDIAN_VAULT not set**
Setup: Configure via environment variable or secret-run
File: ~/.config/secrets/env.d/vault.env

**Issue 2: Obsidian App nicht gestartet**
Symptom: CLI-Commands hängen oder geben "connection refused"
Solution: Obsidian App starten, dann erneut versuchen
Fallback: Glob + Read Tools direkt auf `$OBSIDIAN_VAULT` verwenden

**Issue 3: Document not found**
Solution:
1. Test discovery: `obsidian.com search query="name"`
2. Verify document exists in Vault
3. Check spelling/name

**Issue 4: Frontmatter parse error**
Fallback: Show raw frontmatter block
Content still fully available

---

## UC1 Examples

### Example 1: Simple vault: Reference

User: "Nutze vault:ai-workflows als Kontext für deine Antwort"

Skill Flow:
1. Detect: vault:ai-workflows pattern
2. Discover: Find $VAULT/02_Areas/ai-workflows.md
3. Load: Read content + frontmatter
4. Display: Show metadata and content
5. Ready: Claude has context for analysis

### Example 2: Multi-Document Reference

User: "Vergleiche vault:ai-workflows und vault:project-x"

Skill Flow:
1. Detect: Two vault: prefix patterns
2. Discover + Load both documents
3. Present comparison
4. Claude analyzes connections

---

## Discovery: CLI Search

### Primary: Obsidian Search (CLI)

Method: `obsidian.com search query="<name>" format=json`
Performance: Fast (uses Obsidian's internal index, not filesystem scan)
Features: Case-insensitive, content + filename matching, context snippets
Prerequisite: Obsidian App must be running

### Fallback: Glob (wenn Obsidian nicht laeuft)

Method: Glob tool mit Pattern `**/*<name>*.md` auf `$OBSIDIAN_VAULT`
Performance: ~500-1000ms (filesystem scan)
Hinweis: Nur Dateinamen-Match, kein Content-Search

---

## Metadata Extraction

### Frontmatter Schema

Extracted from YAML frontmatter:
- created: YYYY-MM-DD
- modified: YYYY-MM-DD
- tags: [tag1, tag2]
- status: draft|active|done
- type: note|project|meeting

---

## Known Limitations

- **Obsidian muss laufen:** CLI kommuniziert via Named Pipe — ohne Obsidian App kein CLI-Zugriff (Fallback: Glob/Read)
- **No Semantic Search:** CLI bietet Fulltext, aber kein Embedding/Similarity Search (Phase 6+ MCP/RAG)
- **Backlinks + Vault Health:** Vollstaendig via CLI verfuegbar (backlinks, orphans, deadends, unresolved, vault stats)
- UTF-8 Assumption: Non-UTF-8 files may display incorrectly
- No @ Symbol: Uses vault: prefix to avoid collision with Claude Code native @ completion

---

## References

CLI: `obsidian.com` (Obsidian 1.12+, im PATH via WSL2-Interop)
Scripts: `~/.claude/skills/vault-manager/scripts/` (vault-export, vault-edit, vault-date, vault-base, vault-copy)

Documentation:
- ADR-005: `docs/decisions/ADR-005-obsidian-cli-architecture.md` (Hybrid-Strategie)
- SETUP.md: Installation guide
- REFERENCE.md: Scripts reference

---

## Current Status

- UC1 Read: ✅ (CLI: search, read, properties)
- UC2 Export: ✅ (vault-export.sh, 7 Fileclass-Typen)
- UC3 Edit: ✅ (vault-edit.sh, /vault-work Command)
- Phase 4 Search: ✅ (CLI: tags/tag + vault-date.sh, vault-base.sh)
- Phase 5b: CLI Migration ✅ (ADR-005 Hybrid)
- Backlinks: ✅ (CLI: backlinks, links — incoming + outgoing)
- Vault Health: ✅ (CLI: orphans, deadends, unresolved, vault stats)
- Phase 6+: MCP/RAG Evaluation (Semantic Search, Graph-Clustering)

**Strategy:** CLI+Bash Hybrid (ADR-005). CLI fuer Read/Search/Tags, Bash fuer Export/Edit/Base/Date.

Last Updated: 2026-02-19
