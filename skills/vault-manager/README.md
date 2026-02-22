# Vault Manager Skill

**Claude Code Integration für Obsidian Vault - Read-Only Access (UC1)**

---

## 🎯 Purpose

This skill enables Claude Code to load Obsidian Vault documents as context via `vault:` prefix notation.

**Example:**
```
User: "Nutze vault:ai-workflows als Kontext"
→ Skill loads: $VAULT/04 RESSOURCEN/ai-workflows.md
→ Claude has: Full content + metadata as context
```

---

## 📁 Directory Structure

```
~/.claude/skills/vault-manager/
├── README.md                          # You are here
├── SKILL.md                           # Main skill (auto-triggered)
│
├── scripts/                           # Executable scripts
│   ├── vault-find.sh                  # Discovery (Recursive Search)
│   ├── vault-read.sh                  # Read + YAML parsing
│   ├── vault-export.sh                # Export to Vault (UC2)
│   └── vault-edit.sh                  # Edit with diff + backup (UC3)
│
├── references/                        # Documentation
│   ├── SETUP.md                       # Installation guide
│   └── REFERENCE.md                   # Technical details
│
└── PHASE-1.3-TESTING/                 # Testing resources (below)
    ├── PHASE-1.3-TESTING-GUIDE.md     # Master guide
    ├── PHASE-1.3-QUICK-CHECK.md       # Fast validation (10 min)
    ├── PHASE-1.3-TEST-PLAN.md         # Full testing (30 min)
    └── PHASE-1.3-TEST-RESULTS-TEMPLATE.md  # Results doc
```

---

## 🚀 Quick Start

### Installation (Already Done)
- ✅ Files created in `~/.claude/skills/vault-manager/`
- ✅ Scripts executable
- ✅ Documentation complete

### Testing (Next)
1. Read: `PHASE-1.3-TESTING-GUIDE.md`
2. Choose: Quick Check (10 min) or Full Plan (30 min)
3. Execute: Tests and verify success
4. Document: Results (optional)

### Using the Skill
```bash
# In Claude Code, type:
vault:document-name

# Example:
"Nutze vault:ai-workflows als Kontext für meine Antwort"

# Skill auto-triggers and loads the document
```

---

## 📚 Documentation Files

### Main Documentation
| File | Purpose | Read Time |
|------|---------|-----------|
| **SKILL.md** | Main skill implementation, workflows, examples | 15 min |
| **references/SETUP.md** | Installation, configuration, troubleshooting | 10 min |
| **references/REFERENCE.md** | Scripts reference, error codes, performance specs | 15 min |

### Testing Documentation
| File | Purpose | Time |
|------|---------|------|
| **PHASE-1.3-TESTING-GUIDE.md** | Master testing reference (start here) | 5 min |
| **PHASE-1.3-QUICK-CHECK.md** | 5 quick tests (~10 min to execute) | Execution |
| **PHASE-1.3-TEST-PLAN.md** | 7 comprehensive tests with details (~30 min) | Execution |
| **PHASE-1.3-TEST-RESULTS-TEMPLATE.md** | Template to document your test results | Recording |

---

## 🔧 Scripts

### vault-find.sh
**Purpose:** Discover Vault documents by name

**Recursive Search:**
- Case-insensitive recursive search via `find`
- Performance: ~100-500ms (ausreichend für typische Vault-Größen)
- Handles multiple matches (zeigt Kandidaten, nutzt ersten Match)

**Usage:**
```bash
~/.claude/skills/vault-manager/scripts/vault-find.sh "document-name"

# Returns: /absolute/path/to/document.md
```

### vault-read.sh
**Purpose:** Read document content with YAML frontmatter extraction

**Features:**
- Extracts metadata (created, modified, tags, status, type)
- Displays formatted output with colors
- Handles error cases gracefully
- Works with documents without frontmatter

**Usage:**
```bash
~/.claude/skills/vault-manager/scripts/vault-read.sh "/absolute/path/to/file.md"

# Returns: Document loaded message + metadata + content
```

---

## 🔍 Phase 1.3 Testing

### Test Resources
4 comprehensive test documents created:

1. **PHASE-1.3-TESTING-GUIDE.md** ⭐ START HERE
   - Overview of all testing resources
   - How to choose between quick vs. full testing
   - Success criteria
   - Troubleshooting tips

2. **PHASE-1.3-QUICK-CHECK.md** (10 min)
   - 5 quick bash commands
   - Validates all core functions
   - Best for: Quick sanity check

3. **PHASE-1.3-TEST-PLAN.md** (30 min)
   - 7 detailed test sections
   - Step-by-step instructions
   - Expected results for each
   - Best for: Comprehensive validation

4. **PHASE-1.3-TEST-RESULTS-TEMPLATE.md**
   - Professional test documentation format
   - Fields for each test result
   - Summary section
   - Best for: Recording results

### The Core Tests

All testing focuses on validating these functions:

| # | Function | Test Time | Success Criteria |
|---|----------|-----------|------------------|
| 1 | Skill Files | 2 min | All files exist + scripts executable |
| 2 | Discovery | 3 min | Recursive search finds documents |
| 3 | Read + Parse | 2 min | Document loads + metadata extracted |
| 4 | Error Handling | 2 min | Graceful errors for missing docs/env |

**Total test time:** ~11-35 minutes (depending on depth)

---

## Current Status

- **UC1 Read:** ✅ Complete (vault-find.sh, vault-read.sh)
- **UC2 Export:** ✅ Complete (vault-export.sh, 7 Fileclass-Typen)
- **UC3 Edit:** ✅ Complete (vault-edit.sh, /vault-work Command)
- **Phase 6+:** MCP/RAG Evaluation (Semantic Search, Backlinks)

---

## 📖 Where to Start

### If you want to... | Read this first
| Goal | Document |
|------|----------|
| **Understand what this skill does** | README.md (you're reading it!) |
| **Test the skill** | PHASE-1.3-TESTING-GUIDE.md |
| **Install/configure** | references/SETUP.md |
| **Understand internals** | SKILL.md, references/REFERENCE.md |
| **Run tests (quick)** | PHASE-1.3-QUICK-CHECK.md |
| **Run tests (detailed)** | PHASE-1.3-TEST-PLAN.md |
| **Document test results** | PHASE-1.3-TEST-RESULTS-TEMPLATE.md |

---

## 🎓 Key Concepts

### vault: Prefix Auto-Triggering
- User types: `vault:document-name`
- Skill detects: `vault:` prefix pattern via semantic matching
- Skill executes: vault-find.sh + vault-read.sh
- Result: Document loaded as context

**Note:** `@` notation wird NICHT verwendet (Kollision mit Claude Code's nativer `@file` Auto-Completion).

### Recursive Search Discovery
- Recursive search via vault-find.sh (`find` command)
- Case-insensitive, handles partial matches
- No index file needed

### YAML Frontmatter Extraction
- Documents have optional YAML metadata at top:
  ```yaml
  ---
  created: 2026-01-17
  modified: 2026-01-17
  tags: [ai, workflows]
  status: active
  type: note
  ---
  ```
- Skill extracts and displays this metadata

---

## ⚙️ Configuration

### Environment Variable
```bash
export OBSIDIAN_VAULT="/path/to/your/vault"
```

**Where to set it:**
- Development: Inline before running Claude Code
- Production: Via `~/.config/secrets/env.d/vault.env` + secret-run

See `references/SETUP.md` for detailed setup.

### Document Discovery
Discovery uses recursive search via `vault-find.sh`. No index file needed.

```bash
# Usage:
~/.claude/skills/vault-manager/scripts/vault-find.sh "document-name"
# Returns: /absolute/path/to/document.md
```

---

## 🧪 Testing Next Steps

1. **Read:** `PHASE-1.3-TESTING-GUIDE.md` (5 min)
2. **Choose:** Quick (10 min) or Full (30 min) testing
3. **Execute:** Run all test commands
4. **Document:** Fill in `PHASE-1.3-TEST-RESULTS-TEMPLATE.md`
5. **Update:** Mark Phase 1.3 complete in `docs/PROJEKT.md`

---

## 📞 Support

### Documentation
- `references/SETUP.md` - Installation & troubleshooting
- `references/REFERENCE.md` - Technical reference
- `SKILL.md` - Implementation details

### Testing Issues
- `PHASE-1.3-TESTING-GUIDE.md` - Troubleshooting section
- Test documents have "Troubleshooting" sections

### Project Status
- `docs/PROJEKT.md` - Phase breakdown & task tracking
- `CLAUDE.md` - Global architecture
- `docs/DECISIONS.md` - Architecture decisions (ADRs)

---

## Component Status

| Component | Status | Details |
|-----------|--------|---------|
| **Skill (SKILL.md)** | ✅ Ready | Auto-triggered via `vault:` prefix |
| **Scripts** | ✅ Ready | vault-find.sh, vault-read.sh, vault-export.sh, vault-edit.sh |
| **Commands** | ✅ Ready | /vault-export, /vault-work, /obsidian-sync |
| **Environment** | ✅ Ready | OBSIDIAN_VAULT via SessionStart Hook |
| **Documentation** | ✅ Ready | SETUP.md, REFERENCE.md |

---

**Skill Version:** 2.0 (UC1-3 Complete)
**Created:** 2026-01-17
**Updated:** 2026-02-11
**Strategy:** Bash-First (MCP/RAG Phase 6+ evaluieren)

---

**Quick Links:**
- [Setup Guide](references/SETUP.md)
- [Technical Reference](references/REFERENCE.md)
