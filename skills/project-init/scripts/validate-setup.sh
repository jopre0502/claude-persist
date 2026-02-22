#!/bin/bash

# validate-setup.sh: Verify project infrastructure is correctly configured

PROJECT_DIR="${1:-.}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0
WARNINGS=0

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Project Setup Validation${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}✗ Project directory not found: $PROJECT_DIR${NC}"
    exit 1
fi

echo -e "${BLUE}Checking: $PROJECT_DIR${NC}"
echo ""

# Check 1: CLAUDE.md exists
echo -n "1. CLAUDE.md exists... "
if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
    echo -e "${GREEN}✓${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ MISSING${NC}"
    ((FAILED++))
fi

# Check 2: CLAUDE.md size
echo -n "2. CLAUDE.md size (<8000 chars)... "
CLAUDE_SIZE=$(wc -c < "$PROJECT_DIR/CLAUDE.md" 2>/dev/null || echo "0")
if [ "$CLAUDE_SIZE" -lt 8000 ]; then
    echo -e "${GREEN}✓${NC} ($CLAUDE_SIZE bytes)"
    ((PASSED++))
elif [ "$CLAUDE_SIZE" -eq 0 ]; then
    echo -e "${RED}✗ EMPTY${NC}"
    ((FAILED++))
else
    echo -e "${YELLOW}⚠${NC} OVER ($CLAUDE_SIZE bytes, target <8000)"
    ((WARNINGS++))
fi

# Check 3: PROJEKT.md exists
echo -n "3. docs/PROJEKT.md exists... "
if [ -f "$PROJECT_DIR/docs/PROJEKT.md" ]; then
    echo -e "${GREEN}✓${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ MISSING${NC}"
    ((FAILED++))
fi

# Check 4: PROJEKT.md size
echo -n "4. PROJEKT.md size (<8000 chars)... "
PROJEKT_SIZE=$(wc -c < "$PROJECT_DIR/docs/PROJEKT.md" 2>/dev/null || echo "0")
if [ "$PROJEKT_SIZE" -lt 8000 ]; then
    echo -e "${GREEN}✓${NC} ($PROJEKT_SIZE bytes)"
    ((PASSED++))
elif [ "$PROJEKT_SIZE" -eq 0 ]; then
    echo -e "${RED}✗ EMPTY${NC}"
    ((FAILED++))
else
    echo -e "${YELLOW}⚠${NC} OVER ($PROJEKT_SIZE bytes, target <8000)"
    ((WARNINGS++))
fi

# Check 5: tasks directory exists
echo -n "5. docs/tasks/ directory exists... "
if [ -d "$PROJECT_DIR/docs/tasks" ]; then
    echo -e "${GREEN}✓${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ MISSING${NC}"
    ((FAILED++))
fi

# Check 6: Skill task-template accessible (SSOT, not copied to project)
echo -n "6. Skill task-template accessible... "
if [ -f "$HOME/.claude/skills/project-init/assets/task-md-template.txt" ]; then
    echo -e "${GREEN}✓${NC} (SSOT: ~/.claude/skills/project-init/assets/task-md-template.txt)"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠${NC} MISSING in skill (check skill installation)"
    ((WARNINGS++))
fi

# Check 7: TASK-001 exists
echo -n "7. First task (TASK-001-setup.md) exists... "
if [ -f "$PROJECT_DIR/docs/tasks/TASK-001-setup.md" ]; then
    echo -e "${GREEN}✓${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠${NC} MISSING (create manually)"
    ((WARNINGS++))
fi

# Check 8: CLAUDE.md has content
echo -n "8. CLAUDE.md has project details... "
if grep -q "Project Name\|architecture\|tech" "$PROJECT_DIR/CLAUDE.md"; then
    echo -e "${GREEN}✓${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠${NC} Looks like template (needs customization)"
    ((WARNINGS++))
fi

# Check 9: PROJEKT.md has task structure
echo -n "9. PROJEKT.md has task table... "
if grep -q "TASK-\|UUID\|Status" "$PROJECT_DIR/docs/PROJEKT.md"; then
    echo -e "${GREEN}✓${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠${NC} Task structure may be incomplete"
    ((WARNINGS++))
fi

# Check 10: Global skills installed
echo -n "10. Global session-refresh skill... "
if [ -d "$HOME/.claude/skills/session-refresh" ]; then
    echo -e "${GREEN}✓${NC}"
    ((PASSED++))
else
    echo -e "${RED}✗ NOT FOUND${NC}"
    ((FAILED++))
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Summary
echo -e "Passed: ${GREEN}$PASSED${NC} | Warnings: ${YELLOW}$WARNINGS${NC} | Failed: ${RED}$FAILED${NC}"

if [ "$FAILED" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed! Ready to work.${NC}"
    echo ""
    echo -e "${BLUE}Next:${NC}"
    echo "  cd $PROJECT_DIR"
    echo "  /session-refresh"
    echo "  /run-next-tasks"
    exit 0
elif [ "$FAILED" -eq 0 ]; then
    echo -e "${YELLOW}⚠️ All critical checks passed, but some warnings.${NC}"
    echo ""
    echo -e "${BLUE}Optional:${NC}"
    echo "  - Add PROJEKT-ARCHIVE.md after Phase 1"
    echo "  - Customize CLAUDE.md + PROJEKT.md with details"
    exit 0
else
    echo -e "${RED}❌ Some checks failed. Please fix and run again.${NC}"
    exit 1
fi