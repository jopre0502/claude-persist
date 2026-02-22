# Phase 1.3 Testing Guide - Complete Reference

**For Phase 1.3 Validation of UC1 (Read-Only Vault Reference)**

---

## 📋 Available Test Resources

You now have **3 testing documents** in this directory:

### 1. **PHASE-1.3-QUICK-CHECK.md** (⭐ START HERE)
   - **Time:** ~10 minutes
   - **Format:** Quick bash commands
   - **Purpose:** Fast validation of all 5 key functions
   - **Best for:** Quick sanity check before deeper testing

**Use when:** You want to verify things work quickly

---

### 2. **PHASE-1.3-TEST-PLAN.md** (📖 COMPREHENSIVE)
   - **Time:** ~20-30 minutes
   - **Format:** Detailed step-by-step tests with explanations
   - **Purpose:** Full UC1 validation with edge cases
   - **Tests:** 7 comprehensive tests including optional manual skill trigger

**Use when:** You want thorough validation with detailed documentation

---

### 3. **PHASE-1.3-TEST-RESULTS-TEMPLATE.md** (📝 DOCUMENTATION)
   - **Time:** N/A (documentation only)
   - **Format:** Template to record your test results
   - **Purpose:** Document test execution and results
   - **Output:** Professional test report

**Use when:** You want to document test results for records

---

## 🚀 Quick Start

### Option A: Fast Validation (10 min)
```bash
# 1. Read the quick check
cat ~/.claude/skills/vault-manager/PHASE-1.3-QUICK-CHECK.md

# 2. Run each command sequentially
# (copy-paste each command block)

# 3. If all pass → Phase 1.3 Ready!
```

### Option B: Comprehensive Testing (30 min)
```bash
# 1. Read the full test plan
cat ~/.claude/skills/vault-manager/PHASE-1.3-TEST-PLAN.md

# 2. Follow each test section with explanations
# (Execute Test 1-7 in order)

# 3. Document results in template
cat ~/.claude/skills/vault-manager/PHASE-1.3-TEST-RESULTS-TEMPLATE.md
```

---

## 🎯 The 5 Core Tests

All resources focus on validating these 5 critical functions:

### **Test 1: Skill Files Exist** (2 min)
Validates: All required files are present and executable
- SKILL.md (main)
- vault-find.sh (discovery script)
- vault-read.sh (read script)
- SETUP.md (installation guide)
- REFERENCE.md (technical reference)

**Quick Check:** `ls -1 ~/.claude/skills/vault-manager/{SKILL.md,scripts/{vault-find.sh,vault-read.sh},references/{SETUP.md,REFERENCE.md}}`

---

### **Test 2: Document Discovery** (3 min)
Validates: Recursive search finds documents
- Case-insensitive recursive `find` in `$OBSIDIAN_VAULT`
- Handles exact match, partial match, and multiple matches
- Shows error if not found
- Performance: ~100-500ms

**Quick Check:** `~/.claude/skills/vault-manager/scripts/vault-find.sh "Beschreibung"`

---

### **Test 5: Read + Frontmatter Parsing** (2 min)
Validates: Document reading and YAML extraction
- Loads document content
- Parses YAML frontmatter
- Displays metadata (created, modified, tags, status, type)
- Handles error cases

**Quick Check:** `~/.claude/skills/vault-manager/scripts/vault-read.sh "$VAULT_FILE"`

---

## 📊 Test Success Criteria

All tests must pass the following criteria:

| Test | Success Criteria |
|------|------------------|
| **1** | All 5 files present + scripts executable |
| **2** | Index file exists + readable + has entries |
| **3** | Index lookup returns valid path |
| **4** | Fallback finds documents + error handling works |
| **5** | Document loads + metadata parsed |
| **6** | Error handling graceful (missing env) |
| **7** | (Optional) Skill triggers + document loads |

**Phase 1.3 Complete When:** Tests 1-6 PASS + Test 7 Attempted

---

## 🔧 Troubleshooting During Tests

**Problem:** "OBSIDIAN_VAULT not found"
```bash
export OBSIDIAN_VAULT="/mnt/c/Users/Jonas/Google Drive/01. Prechtel_Documents/250_Obsidian/PKM"
```

**Problem:** "vault-find.sh not found"
```bash
chmod +x ~/.claude/skills/vault-manager/scripts/vault-find.sh
```

**Problem:** "Index file not found"
```bash
mkdir -p "$OBSIDIAN_VAULT/01 DASHBOARD"
touch "$OBSIDIAN_VAULT/01 DASHBOARD/llm-development.md"
```

**Problem:** "Scripts fail with permission denied"
```bash
chmod 755 ~/.claude/skills/vault-manager/scripts/*.sh
```

---

## 📈 Testing Workflow

```
START
  ↓
[Choose Test Level]
  ├─ Quick Check (10 min) → Proceed to [Copy Commands]
  ├─ Full Plan (30 min) → Proceed to [Copy Commands]
  └─ Documentation → Proceed to [Copy Template]
  ↓
[Copy Commands]
  ↓
[Execute Each Test]
  ├─ Pass → Continue to next
  ├─ Fail → Debug + Retry
  └─ Error → Check troubleshooting
  ↓
[Document Results] (Optional but Recommended)
  ├─ Copy template
  ├─ Fill in results
  └─ Save for records
  ↓
[Phase 1.3 Status]
  ├─ All Tests Pass → ✅ COMPLETE
  ├─ Some Tests Fail → 🔧 Fix issues + Retry
  └─ Blocker Found → 🚨 Escalate
  ↓
END
```

---

## 📚 Related Documentation

**For implementation details:**
- `SKILL.md` - Main skill implementation
- `references/SETUP.md` - Installation guide
- `references/REFERENCE.md` - Technical reference

**For project status:**
- `CLAUDE.md` - Global architecture
- `docs/PROJEKT.md` - Phase breakdown
- `docs/DECISIONS.md` - Architecture decisions

---

## ⏱️ Time Breakdown

| Activity | Time | Optional? |
|----------|------|-----------|
| Pre-Check (setup) | 1 min | No |
| Quick Check | 10 min | No |
| Full Test Plan | 20 min | Yes |
| Documentation | 5 min | Yes |
| Manual Skill Test | 5 min | Yes |
| **Total (minimum)** | **11 min** | |
| **Total (full)** | **35 min** | |

---

## ✅ Completion Checklist

- [ ] Read this guide (2 min)
- [ ] Choose test level (Quick vs. Full)
- [ ] Execute all commands
- [ ] Verify results against success criteria
- [ ] Document results (optional)
- [ ] Update PROJEKT.md when complete

**When all ✓:** Phase 1.3 Testing Complete!

---

## 🎓 Learning Outcomes

After completing Phase 1.3 testing, you'll understand:

1. ✅ How the recursive discovery works (vault-find.sh)
2. ✅ How vault-find.sh handles edge cases
3. ✅ How vault-read.sh parses YAML frontmatter
4. ✅ How error handling provides helpful guidance
5. ✅ How to troubleshoot common issues
6. ✅ Whether UC1 (Read-Only) is production-ready

---

**Testing Guide Version:** 1.0
**Created:** 2026-01-17
**Status:** Ready for Use

**Next Step After Testing:** Phase 1b (Complex Queries) or Phase 2 (Search)
