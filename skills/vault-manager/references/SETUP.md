# Vault Manager Skill - Setup Guide

**Status:** UC1-3 Complete (Bash-First)

---

## Prerequisites

Before using the vault-manager skill, ensure these are complete:

### 1. ✅ Claude Code Installation

Already installed (you're using it)

### 2. ✅ OBSIDIAN_VAULT Environment Variable

Set via SessionStart Hook (automatic) or manually:
```bash
# In ~/.config/secrets/env.d/vault.env:
OBSIDIAN_VAULT="/mnt/c/Users/Jonas/Google Drive/01. Prechtel_Documents/250_Obsidian/PKM"
```

### 3. ✅ Document Discovery (Automatic)

Discovery erfolgt via **Recursive Search** (`vault-find.sh`). Keine Index-Datei notwendig.

```bash
# vault-find.sh sucht rekursiv im $OBSIDIAN_VAULT
~/.claude/skills/vault-manager/scripts/vault-find.sh "document-name"
# Returns: /absolute/path/to/document.md
```

**Performance:** ~100-500ms (ausreichend für typische Vault-Größen).

---

## Installation Steps

### Step 1: Verify Skill Directory

The skill is already installed at:
```
~/.claude/skills/vault-manager/
├── SKILL.md                    # Main skill (auto-loaded)
├── scripts/
│   ├── vault-find.sh          # Document discovery
│   └── vault-read.sh          # Content reading
└── references/
    ├── SETUP.md               # You are here
    └── REFERENCE.md           # Technical reference
```

**Verify scripts are executable:**
```bash
ls -la ~/.claude/skills/vault-manager/scripts/
# Should show: -rwxr-xr-x ... vault-find.sh
#              -rwxr-xr-x ... vault-read.sh
```

### Step 2: Set OBSIDIAN_VAULT Environment Variable

**Option A: Via secret-run (Recommended for Production)**

Edit or create: `~/.config/secrets/env.d/vault.env`
```bash
OBSIDIAN_VAULT=/mnt/c/Users/Jonas/Google\ Drive/01.\ Prechtel_Documents/250_Obsidian/PKM
```

Usage:
```bash
# Start Claude Code with Vault environment
secret-run vault -- claude code

# Or run specific commands
secret-run vault -- /vault-backup
```

**Option B: Inline (Development)**

Set before running Claude Code:
```bash
export OBSIDIAN_VAULT=/path/to/vault
claude code
```

**Option C: Fallback in Skill**

The skill checks for `OBSIDIAN_VAULT` and falls back to default paths:
```bash
VAULT_PATH="${OBSIDIAN_VAULT:-.}"
```

If not set, shows setup guide.

### Step 3: Verify Setup

```bash
# Check OBSIDIAN_VAULT is set
echo $OBSIDIAN_VAULT

# Check scripts are executable
ls -la ~/.claude/skills/vault-manager/scripts/*.sh

# Test discovery
~/.claude/skills/vault-manager/scripts/vault-find.sh "test"
```

---

## Usage: Quick Start

### Using the Skill

The skill is **auto-triggered** when you use `vault:` prefix notation:

```
User: "Nutze vault:ai-workflows als Kontext"

→ Skill detects: vault:ai-workflows
→ Triggers: vault-manager skill
→ Discovers: $VAULT/04 RESSOURCEN/ai-workflows.md
→ Loads: Content + metadata
→ Ready: Claude has context
```

**Note:** `@` notation wird NICHT verwendet (Kollision mit Claude Code's nativer `@file` Auto-Completion).

### Manual Testing

Test scripts directly:

```bash
# Test discovery (recursive search)
~/.claude/skills/vault-manager/scripts/vault-find.sh "ai-workflows"
# Expected: /path/to/vault/04 RESSOURCEN/ai-workflows.md

# Test reading document
~/.claude/skills/vault-manager/scripts/vault-read.sh "/path/to/document.md"
# Expected: ✅ Document loaded + Metadata + Content
```

---

## Troubleshooting

### Issue 1: "OBSIDIAN_VAULT not configured"

**Cause:** Environment variable not set

**Solution:**
```bash
# Check if set:
echo $OBSIDIAN_VAULT

# If empty:
export OBSIDIAN_VAULT=/path/to/vault
echo $OBSIDIAN_VAULT  # Should show path now

# Or use secret-run:
secret-run vault -- echo $OBSIDIAN_VAULT
```

### Issue 2: "Document not found"

**Cause:** Document doesn't exist or spelling is off

**Solution:**
1. Test discovery directly:
   ```bash
   ~/.claude/skills/vault-manager/scripts/vault-find.sh "my-doc"
   ```

2. Verify document exists:
   ```bash
   ls -la "$OBSIDIAN_VAULT/path/to/my-doc.md"
   ```

### Issue 3: Frontmatter not parsing

**Cause:** Invalid YAML syntax

**Solution:** Check frontmatter format:
```markdown
---
created: 2026-01-17           # Correct: YYYY-MM-DD
modified: 2026-01-17
tags: [ai, workflows]         # Correct: [item1, item2]
status: active                # Correct: single value
type: note
---
```

**Invalid examples:**
```markdown
---
created: Jan 17, 2026         # Wrong: human-readable date
tags: ai, workflows           # Wrong: missing brackets
status: "Active"              # Wrong: uppercase in quoted string
---
```

---

## Testing Checklist

After setup, verify functionality:

- [ ] OBSIDIAN_VAULT set: `echo $OBSIDIAN_VAULT` (shows path)
- [ ] vault-find.sh works: `vault-find.sh test-doc` (finds or errors gracefully)
- [ ] vault-read.sh works: `vault-read.sh /path/to/doc.md` (shows metadata + content)
- [ ] Skill auto-triggers: In Claude Code, use `vault:` prefix and see if skill auto-triggers
- [ ] Document loads: "Nutze vault:ai-workflows als Kontext" loads the document

---

## Next Steps

### Current Status
- [x] UC1 Read: vault-find.sh + vault-read.sh
- [x] UC2 Export: vault-export.sh + /vault-export
- [x] UC3 Edit: vault-edit.sh + /vault-work
- [x] Backup: /obsidian-sync
- [ ] Phase 6+: MCP/RAG Evaluation (optional)

---

## Support & References

**Technical Reference:** See `REFERENCE.md`
- Scripts documentation
- Error codes and meanings
- Frontmatter schema details

**Project Documentation:**
- `CLAUDE.md` - Global architecture
- `docs/PROJEKT.md` - Phase breakdown
- `docs/PKM-WORKFLOW.md` - Vault integration workflow

---

**Installation Status:** ✅ Complete
**Last Updated:** 2026-02-11
