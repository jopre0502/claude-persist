#!/bin/bash

# project-init: Complete Session-Continuous Project Initialization
# Usage: ./init-project.sh /path/to/project [--docs-path PATH] [--from-claude-md PATH]
#
# Options:
#   --docs-path PATH      Documentation directory name (default: "docs", alternative: "90_DOCS")
#   --from-claude-md PATH Copy existing CLAUDE.md from this path

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Defaults
PROJECT_DIR="."
DOCS_DIR="90_DOCS"
FROM_CLAUDE_MD=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --docs-path)
            DOCS_DIR="$2"
            shift 2
            ;;
        --from-claude-md)
            FROM_CLAUDE_MD="$2"
            shift 2
            ;;
        -*)
            echo "Unknown option: $1"
            exit 1
            ;;
        *)
            PROJECT_DIR="$1"
            shift
            ;;
    esac
done

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Project Initialization - Session-Continuous Workflow${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Validate project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${YELLOW}✗ Project directory not found: $PROJECT_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Project directory: $PROJECT_DIR${NC}"
echo ""

# Step 1: Create directory structure
echo -e "${BLUE}Step 1: Creating directory structure...${NC}"
echo -e "${BLUE}   Using docs path: $DOCS_DIR${NC}"
mkdir -p "$PROJECT_DIR/$DOCS_DIR/tasks/TASK-001/execution-logs"
mkdir -p "$PROJECT_DIR/$DOCS_DIR/tasks/TASK-001/artifacts"
mkdir -p "$PROJECT_DIR/$DOCS_DIR/phases"
echo -e "${GREEN}✓ Created: $DOCS_DIR/tasks/TASK-001/ (with execution-logs/, artifacts/)${NC}"
echo -e "${GREEN}✓ Created: $DOCS_DIR/phases/ (for completed phase archives)${NC}"

# Step 1b: Create default directory structure from template
TEMPLATE_FILE="$SCRIPT_DIR/../assets/directory-template.txt"
if [ -f "$TEMPLATE_FILE" ]; then
    echo ""
    echo -e "${BLUE}Step 1b: Creating default directory structure...${NC}"
    while IFS='|' read -r dir_path description; do
        # Skip comments and empty lines
        [[ "$dir_path" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$dir_path" ]] && continue
        # Trim whitespace
        dir_path=$(echo "$dir_path" | xargs)
        description=$(echo "$description" | xargs)
        mkdir -p "$PROJECT_DIR/$dir_path"
        echo -e "${GREEN}✓ Created: $dir_path${NC} ($description)"
    done < "$TEMPLATE_FILE"
    # Create handoffs directory inside DOCS_DIR (not in template to avoid duplication)
    mkdir -p "$PROJECT_DIR/$DOCS_DIR/handoffs"
    echo -e "${GREEN}✓ Created: $DOCS_DIR/handoffs/ (Session-Handoff files)${NC}"
else
    echo -e "${YELLOW}⚠ Directory template not found: $TEMPLATE_FILE${NC}"
fi

# Step 2: Create/verify CLAUDE.md
echo ""
echo -e "${BLUE}Step 2: Setting up CLAUDE.md...${NC}"

if [ -f "$PROJECT_DIR/CLAUDE.md" ] && [ -z "$FROM_CLAUDE_MD" ]; then
    echo -e "${YELLOW}ℹ CLAUDE.md already exists - skipping${NC}"
elif [ -n "$FROM_CLAUDE_MD" ] && [ -f "$FROM_CLAUDE_MD" ]; then
    echo -e "${GREEN}✓ Copying CLAUDE.md from: $FROM_CLAUDE_MD${NC}"
    cp "$FROM_CLAUDE_MD" "$PROJECT_DIR/CLAUDE.md"

    # Check if workflow block is already present
    if ! grep -q "Session-Continuous Workflow" "$PROJECT_DIR/CLAUDE.md"; then
        echo -e "${GREEN}✓ Injecting Session-Continuous Workflow reference${NC}"

        # Use compact reference block instead of full inline injection
        WORKFLOW_BLOCK=""
        if [ -f "$(dirname "$0")/../assets/workflow-reference-block.txt" ]; then
            WORKFLOW_BLOCK=$(cat "$(dirname "$0")/../assets/workflow-reference-block.txt")
            # Replace {{DOCS_PATH}} placeholder
            WORKFLOW_BLOCK="${WORKFLOW_BLOCK//\{\{DOCS_PATH\}\}/$DOCS_DIR}"
        elif [ -f "$(dirname "$0")/../assets/workflow-block.txt" ]; then
            # Fallback to full block if reference not available
            echo -e "${YELLOW}⚠ Using full workflow-block (reference-block not found)${NC}"
            WORKFLOW_BLOCK=$(cat "$(dirname "$0")/../assets/workflow-block.txt")
            WORKFLOW_BLOCK="${WORKFLOW_BLOCK//\{\{DOCS_PATH\}\}/$DOCS_DIR}"
        fi

        # Insert before "Last updated" line (or at end if not found)
        if grep -q "Last updated" "$PROJECT_DIR/CLAUDE.md"; then
            # Insert before last updated
            sed -i '/Last updated/i\'"$WORKFLOW_BLOCK"'\n' "$PROJECT_DIR/CLAUDE.md"
        else
            # Just append
            echo "$WORKFLOW_BLOCK" >> "$PROJECT_DIR/CLAUDE.md"
        fi
    else
        echo -e "${YELLOW}ℹ Workflow section already present${NC}"
    fi
else
    echo -e "${GREEN}✓ Creating CLAUDE.md from template${NC}"

    # Get the compact workflow reference block from skill assets
    WORKFLOW_BLOCK=""
    if [ -f "$(dirname "$0")/../assets/workflow-reference-block.txt" ]; then
        WORKFLOW_BLOCK=$(cat "$(dirname "$0")/../assets/workflow-reference-block.txt")
        # Replace {{DOCS_PATH}} placeholder
        WORKFLOW_BLOCK="${WORKFLOW_BLOCK//\{\{DOCS_PATH\}\}/$DOCS_DIR}"
    elif [ -f "$(dirname "$0")/../assets/workflow-block.txt" ]; then
        # Fallback to full block if reference not available
        WORKFLOW_BLOCK=$(cat "$(dirname "$0")/../assets/workflow-block.txt")
        WORKFLOW_BLOCK="${WORKFLOW_BLOCK//\{\{DOCS_PATH\}\}/$DOCS_DIR}"
    fi

    # Create CLAUDE.md with workflow block injected
    cat > "$PROJECT_DIR/CLAUDE.md" << 'EOF'
# CLAUDE.md - [Your Project Name]

Guidance for Claude Code when working on [Your Project].

## Project Overview

**[Project Name]** - [One-sentence description]

**Core Goals:**
- [Goal 1]
- [Goal 2]
- [Goal 3]

**Current Phase:** Phase 1 (Setup)
**Status:** 🚀 Kickoff

---

## Architecture & Tech Stack

**Technology:** [Language/Framework]
**Key Dependencies:** [Main libraries]
**Architecture Pattern:** [Pattern]

---

## Development Guidelines

### Code Style
- Indentation: 2 spaces
- Naming: camelCase for functions, snake_case for files
- Comments: Only for non-obvious logic

### Anti-Over-Engineering
- Only make explicitly requested changes
- No speculative improvements
- Trust existing patterns

### Commit Messages (German)
Format: `[Typ]: Kurzbeschreibung`
Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

---

## Project Management

See **__DOCS_DIR__/PROJEKT.md** for tasks and session model.

EOF

    # Replace placeholder in CLAUDE.md
    sed -i "s|__DOCS_DIR__|$DOCS_DIR|g" "$PROJECT_DIR/CLAUDE.md"

    # Inject workflow block
    if [ -n "$WORKFLOW_BLOCK" ]; then
        echo "$WORKFLOW_BLOCK" >> "$PROJECT_DIR/CLAUDE.md"
    fi

    # Add footer
    cat >> "$PROJECT_DIR/CLAUDE.md" << 'EOF'

---

*Last updated: [Date]*
EOF
    echo -e "${YELLOW}⚠ CLAUDE.md created - please customize project details!${NC}"
    echo -e "${GREEN}✓ Workflow reference included (details: ~/.claude/skills/project-init/references/WORKFLOW.md)${NC}"
fi

# Step 3: Create PROJEKT.md
echo ""
echo -e "${BLUE}Step 3: Setting up PROJEKT.md...${NC}"

if [ -f "$PROJECT_DIR/$DOCS_DIR/PROJEKT.md" ]; then
    echo -e "${YELLOW}ℹ PROJEKT.md already exists - skipping${NC}"
else
    # Load PROJEKT.md template
    PROJEKT_TEMPLATE_FILE="$SCRIPT_DIR/../assets/projekt-md-template.txt"
    if [ ! -f "$PROJEKT_TEMPLATE_FILE" ]; then
        echo -e "${YELLOW}✗ Template not found: $PROJEKT_TEMPLATE_FILE${NC}"
        exit 1
    fi

    # Copy template and perform substitutions using sed
    cp "$PROJEKT_TEMPLATE_FILE" "$PROJECT_DIR/$DOCS_DIR/PROJEKT.md"

    # Perform substitutions with sed (more reliable than bash for {{}} patterns)
    sed -i "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" "$PROJECT_DIR/$DOCS_DIR/PROJEKT.md"
    sed -i "s|{{DATE}}|$(date +%Y-%m-%d)|g" "$PROJECT_DIR/$DOCS_DIR/PROJEKT.md"
    sed -i "s|{{PROJECT_DESCRIPTION}}|[Project description]|g" "$PROJECT_DIR/$DOCS_DIR/PROJEKT.md"
    sed -i "s|{{ARCHITECTURE_BRIEF}}|[Architecture brief]|g" "$PROJECT_DIR/$DOCS_DIR/PROJEKT.md"
    sed -i "s|{{CONFIG_PATH}}|[Config path]|g" "$PROJECT_DIR/$DOCS_DIR/PROJEKT.md"
    sed -i "s|{{DATA_PATH}}|[Data path]|g" "$PROJECT_DIR/$DOCS_DIR/PROJEKT.md"
    sed -i "s|{{FIRST_FEATURE}}|[First Feature]|g" "$PROJECT_DIR/$DOCS_DIR/PROJEKT.md"
    sed -i "s|{{EST1}}|[Estimate]|g" "$PROJECT_DIR/$DOCS_DIR/PROJEKT.md"
    sed -i "s|{{DEL1}}|feature|g" "$PROJECT_DIR/$DOCS_DIR/PROJEKT.md"
    sed -i "s|{{SECOND_FEATURE}}|[Second Feature]|g" "$PROJECT_DIR/$DOCS_DIR/PROJEKT.md"
    sed -i "s|{{EST2}}|[Estimate]|g" "$PROJECT_DIR/$DOCS_DIR/PROJEKT.md"
    sed -i "s|{{DEL2}}|feature|g" "$PROJECT_DIR/$DOCS_DIR/PROJEKT.md"
    sed -i "s|{{DOCS_PATH}}|$DOCS_DIR|g" "$PROJECT_DIR/$DOCS_DIR/PROJEKT.md"
    echo -e "${GREEN}✓ Created: $DOCS_DIR/PROJEKT.md (using standardized 7-column schema)${NC}"
fi

# Step 4: Create first task file
# NOTE: Task template is NOT copied to project (SSOT in skill: assets/task-md-template.txt)
echo ""
echo -e "${BLUE}Step 4: Creating first task (TASK-001)...${NC}"

if [ ! -f "$PROJECT_DIR/$DOCS_DIR/tasks/TASK-001-setup.md" ]; then
    cat > "$PROJECT_DIR/$DOCS_DIR/tasks/TASK-001-setup.md" << 'EOF'
# TASK-001: Project Setup

**UUID:** TASK-001
**Status:** pending
**Created:** __DATE__
**Effort:** 1h
**Dependencies:** None

---

## Objective

Complete initial project setup and documentation infrastructure.

---

## Implementation Steps

1. Review CLAUDE.md and customize project details
2. Review PROJEKT.md and define first 2-3 tasks (TASK-002, TASK-003)
3. Run: `wc -c CLAUDE.md __DOCS_DIR__/PROJEKT.md` (verify <8000 chars each)
4. Test: `/session-refresh` (verify workflow)
5. Test: `/run-next-tasks` (verify scheduler)

---

## Acceptance Criteria

- [ ] CLAUDE.md customized + under 8K chars
- [ ] PROJEKT.md defined + under 8K chars
- [ ] First workflow tested successfully
- [ ] Ready for TASK-002

---

## Output Location

All execution outputs for this task go to this task's directory:
- **Logs:** `__DOCS_DIR__/tasks/TASK-001/execution-logs/`
- **Artifacts:** `__DOCS_DIR__/tasks/TASK-001/artifacts/`

> Background agents should write their output to these subdirectories, not to random locations.

---

## Audit Trail

- __DATE__ - Created
EOF
    # Replace placeholders
    sed -i "s|__DOCS_DIR__|$DOCS_DIR|g" "$PROJECT_DIR/$DOCS_DIR/tasks/TASK-001-setup.md"
    sed -i "s|__DATE__|$(date +%Y-%m-%d)|g" "$PROJECT_DIR/$DOCS_DIR/tasks/TASK-001-setup.md"
    echo -e "${GREEN}✓ Created: $DOCS_DIR/tasks/TASK-001-setup.md${NC}"
fi

# Step 5: Verify sizes
echo ""
echo -e "${BLUE}Step 5: Verifying file sizes...${NC}"

CLAUDE_SIZE=$(wc -c < "$PROJECT_DIR/CLAUDE.md" 2>/dev/null || echo "0")
PROJEKT_SIZE=$(wc -c < "$PROJECT_DIR/$DOCS_DIR/PROJEKT.md" 2>/dev/null || echo "0")

echo "CLAUDE.md: $CLAUDE_SIZE bytes (target: <8000)"
if [ "$CLAUDE_SIZE" -lt 8000 ]; then
    echo -e "${GREEN}✓ Under limit${NC}"
else
    echo -e "${YELLOW}⚠ Over limit - compress content${NC}"
fi

echo "PROJEKT.md: $PROJEKT_SIZE bytes (target: <8000)"
if [ "$PROJEKT_SIZE" -lt 8000 ]; then
    echo -e "${GREEN}✓ Under limit${NC}"
else
    echo -e "${YELLOW}⚠ Over limit - compress content${NC}"
fi

# Step 6: Summary
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ Project Initialization Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Customize CLAUDE.md with your project details"
echo "2. Customize PROJEKT.md with your first tasks"
echo "3. Run: cd $PROJECT_DIR && /session-refresh"
echo "4. Run: /run-next-tasks (start first task)"
echo ""
echo -e "${BLUE}Structure:${NC}"
ls -la "$PROJECT_DIR" | grep -E "CLAUDE|00_|10_|20_|90_|99_"
echo ""
echo -e "${GREEN}Ready to work! 🚀${NC}"