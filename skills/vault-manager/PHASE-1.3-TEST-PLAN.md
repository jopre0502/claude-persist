# Phase 1.3 - UC1 Validation Test Plan

**Objective:** Validate UC1 (Read-Only Vault Reference) implementation

**Execution Time:** ~15-20 minutes

---

## Pre-Test Checklist

- [ ] OBSIDIAN_VAULT is set: `echo $OBSIDIAN_VAULT`
- [ ] Vault path accessible: `ls "$OBSIDIAN_VAULT"`
- [ ] Skill directory exists: `ls ~/.claude/skills/vault-manager/`

---

## Test 1: Skill File Integrity

**Objective:** Verify all required files exist and are executablef

**Steps:**
```bash
# Test 1.1: SKILL.md exists and has frontmatter
ls -la ~/.claude/skills/vault-manager/SKILL.md
grep "^---" ~/.claude/skills/vault-manager/SKILL.md

# Test 1.2: Scripts exist and are executable
ls -la ~/.claude/skills/vault-manager/scripts/vault-find.sh
ls -la ~/.claude/skills/vault-manager/scripts/vault-read.sh

# Test 1.3: Documentation files exist
ls -la ~/.claude/skills/vault-manager/references/SETUP.md
ls -la ~/.claude/skills/vault-manager/references/REFERENCE.md
```

**Expected Results:**
- ✅ All files present
- ✅ Scripts show `-rwxr-xr-x` (executable)
- ✅ SKILL.md begins with `---`
- ✅ Documentation files readable

**Pass Criteria:** All 4 checks pass

---

## Test 2: Document Discovery (Recursive Search)

**Objective:** Verify vault-find.sh discovers documents via recursive search

**Steps:**
```bash
# Test 4.1: Search for document not in Index
~/.claude/skills/vault-manager/scripts/vault-find.sh "Beschreibung"

# Test 4.2: Multiple results handling
# Should show warning with 5 options, use first match

# Test 4.3: Error case - non-existent document
~/.claude/skills/vault-manager/scripts/vault-find.sh "does-not-exist-xyz"

# Expected: Clear error message with solutions
```

**Expected Results:**
- ✅ Test 4.1: Returns valid file path
- ✅ Test 4.2: Shows options and returns first match
- ✅ Test 4.3: Shows "Error: Document not found" with helpful guidance

**Pass Criteria:** All 3 cases handled correctly

---

## Test 5: Read Document with Frontmatter Parsing

**Objective:** Verify vault-read.sh loads and parses documents correctly

**Steps:**
```bash
# Test 5.1: Read a real document
REAL_FILE="$OBSIDIAN_VAULT/00  INBOX & QUICK NOTES/Beschreibung_Problematik_LLM-Projekt-Organisatin_Obsidan PARA-Struktur.md"

~/.claude/skills/vault-manager/scripts/vault-read.sh "$REAL_FILE"

# Expected output should have:
# - ✅ Document loaded message
# - ✅ Metadata section with File, Path, Size
# - ✅ Content section with document text

# Test 5.2: Document without frontmatter
SIMPLE_FILE=$(find "$OBSIDIAN_VAULT" -name "*.md" ! -path "*/.obsidian/*" -type f | head -1)

~/.claude/skills/vault-manager/scripts/vault-read.sh "$SIMPLE_FILE"

# Test 5.3: Error case - non-existent file
~/.claude/skills/vault-manager/scripts/vault-read.sh "/path/that/does/not/exist.md"

# Expected: Clear "File not found" error
```

**Expected Results:**
- ✅ Test 5.1: Shows ✅ Document loaded, metadata, content
- ✅ Test 5.2: Handles document without frontmatter gracefully
- ✅ Test 5.3: Shows "Error: File not found" with helpful message

**Pass Criteria:** All 3 cases handled correctly with appropriate output

---

## Test 6: Error Handling - Missing Environment Variable

**Objective:** Verify graceful degradation when OBSIDIAN_VAULT not set

**Steps:**
```bash
# Test 6.1: Unset environment variable
unset OBSIDIAN_VAULT

# Test 6.2: Try to use vault-find.sh
~/.claude/skills/vault-manager/scripts/vault-find.sh "test-doc"

# Expected: Error message with setup guidance

# Test 6.3: Restore environment
export OBSIDIAN_VAULT="/mnt/c/Users/Jonas/Google Drive/01. Prechtel_Documents/250_Obsidian/PKM"
```

**Expected Results:**
- ✅ Shows "Error: Vault path not found"
- ✅ Includes setup instructions
- ✅ Mentions OBSIDIAN_VAULT environment variable

**Pass Criteria:** Error message is clear and actionable

---

## Test 7: Manual Skill Trigger (Optional - Advanced)

**Objective:** Verify skill auto-triggers in Claude Code

**Steps:**
1. Open Claude Code
2. Type: `vault:Beschreibung`
3. Observe: Does the vault-manager skill suggestion appear?
4. If skill triggers, try: "Nutze vault:Beschreibung als Kontext"
5. Observe: Does it load the document?

**Expected Results:**
- ✅ Skill appears in suggestions on `vault:` prefix
- ✅ Document loads when requested
- ✅ Content becomes available as context

**Pass Criteria:** Skill auto-triggers and loads document

---

## Summary & Validation

| Test | Criteria | Status |
|------|----------|--------|
| 1 | Skill files exist + executable | [ ] Pass / [ ] Fail |
| 2 | Index file exists + formatted | [ ] Pass / [ ] Fail |
| 3 | Stage 1 discovery works | [ ] Pass / [ ] Fail |
| 4 | Stage 2 fallback works | [ ] Pass / [ ] Fail |
| 5 | Read + frontmatter parsing | [ ] Pass / [ ] Fail |
| 6 | Error handling | [ ] Pass / [ ] Fail |
| 7 | Manual skill trigger (opt) | [ ] Pass / [ ] Fail |

**Phase 1.3 Completion Criteria:**
- ✅ Tests 1-6 PASS (mandatory)
- ✅ Test 7 PASS (strongly recommended)
- ✅ No blocking errors
- ✅ Documentation accurate

---

## Troubleshooting

### Issue: "OBSIDIAN_VAULT: Unbound variable"
```bash
export OBSIDIAN_VAULT="/mnt/c/Users/Jonas/Google Drive/01. Prechtel_Documents/250_Obsidian/PKM"
```

### Issue: "vault-find.sh: command not found"
```bash
ls -la ~/.claude/skills/vault-manager/scripts/vault-find.sh
chmod +x ~/.claude/skills/vault-manager/scripts/vault-find.sh
```

### Issue: "Index file not found"
Create it:
```bash
mkdir -p "$OBSIDIAN_VAULT/01 DASHBOARD"
touch "$OBSIDIAN_VAULT/01 DASHBOARD/llm-development.md"
```

### Issue: Document not found
Test with a known document name:
```bash
~/.claude/skills/vault-manager/scripts/vault-find.sh "Beschreibung"
# Should find via recursive search
```

---

**Test Plan Version:** 1.0
**Created:** 2026-01-17
**Status:** Ready for Execution
**Next:** Execute tests and document results
