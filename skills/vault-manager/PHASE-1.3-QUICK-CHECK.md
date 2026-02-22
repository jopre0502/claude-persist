# Phase 1.3 - Quick Validation Checklist

**Use this for fast testing.** Run each command and verify the output.

---

## Pre-Check (1 min)

```bash
# Set environment
export OBSIDIAN_VAULT="/mnt/c/Users/Jonas/Google Drive/01. Prechtel_Documents/250_Obsidian/PKM"

# Verify setup
echo "✓ Vault path: $OBSIDIAN_VAULT"
ls "$OBSIDIAN_VAULT" | head -3
echo "✓ Vault accessible"
```

**Expected:** Vault directory shows folders

---

## Test 1: Files Exist (2 min)

```bash
# All required files
ls -1 ~/.claude/skills/vault-manager/{SKILL.md,scripts/{vault-find.sh,vault-read.sh},references/{SETUP.md,REFERENCE.md}}

echo "✓ All files present"
```

**Expected:** 5 files listed

---

## Test 2: Discovery Works (3 min)

```bash
# Test discovery
~/.claude/skills/vault-manager/scripts/vault-find.sh "Beschreibung" | head -1

echo "✓ Discovery found document"
```

**Expected:** Absolute path printed

---

## Test 3: Read Works (2 min)

```bash
# Test reading
TESTFILE="$OBSIDIAN_VAULT/00  INBOX & QUICK NOTES/Beschreibung_Problematik_LLM-Projekt-Organisatin_Obsidan PARA-Struktur.md"

~/.claude/skills/vault-manager/scripts/vault-read.sh "$TESTFILE" | head -5

echo "✓ Document read successfully"
```

**Expected:** "✅ Document loaded" message

---

## Test 4: Error Handling (2 min)

```bash
# Test error case
~/.claude/skills/vault-manager/scripts/vault-find.sh "this-does-not-exist" 2>&1 | head -3

echo "✓ Error handling works"
```

**Expected:** "Error: Document not found"

---

## Summary

✅ All Quick Checks Pass = **Phase 1.3 Ready for Manual Testing**

Next: Open Claude Code and try: `vault:Beschreibung`

---

**Time to Complete:** ~10 minutes
