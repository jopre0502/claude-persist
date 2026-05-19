#!/usr/bin/env python3
"""
Externalize inline workflow-block to Vault-First Compact Block.

Replaces large inline workflow documentation (~10KB) or old reference-only block
with the Vault-First Compact Block (~4KB) that includes Feature Detection,
Vault-First/Local Fallback dual-path, and session-workflow skill reference.

Usage:
    python3 externalize_workflow.py <path-to-claude-md> [--dry-run]

Example:
    python3 externalize_workflow.py CLAUDE.md --dry-run
    python3 externalize_workflow.py /path/to/project/CLAUDE.md

Output:
    - Backup: CLAUDE.md.pre-workflow-externalization.backup
    - Updated CLAUDE.md with Vault-First Compact Block (~4KB instead of ~10KB)
"""

import sys
import re
import shutil
from pathlib import Path
from datetime import datetime

# Vault-First Compact Block to replace inline workflow
# Source of truth: project-init/assets/workflow-block.txt
# This block is loaded at runtime from the file to stay in sync.
COMPACT_REFERENCE_FALLBACK = '''---

## Session-Continuous Workflow

This project uses session-continuous task tracking. Detailed workflow instructions load automatically via the `session-workflow` skill when needed.

### Feature Detection (Once per Session)

```bash
obsidian.com version  # If available → Vault-First, otherwise → Local Fallback
```

### At Session Start

1. **Read CLAUDE.md** (this file) + **docs/PROJEKT.md**
2. **Feature Detection:** `obsidian.com version` → Vault-First or Local mode
3. **Run `/run-next-tasks`** — Shows unblocked tasks (queries Vault Base or PROJEKT.md)

> No `/session-refresh` needed at start if previous session ended with it.

### During Work

- **Start task:** Update status to in_progress (Vault: `property:set` / Local: edit task file + PROJEKT.md)
- **Log progress** in `docs/tasks/TASK-NNN-name.md` (Audit Trail section)
- **Complete task:** Mark completed (same dual-path as above)
- **Next task:** `/run-next-tasks` again
- **Watch token budget** — If >65%: trigger `/session-refresh`

### At Session End (or Token >65%)

1. Update task status (Vault properties and/or PROJEKT.md)
2. **`/session-refresh`** — Consolidates learnings, optimizes docs
3. **Commit + Handoff automatisch** (ohne Rueckfrage)
   - Handoff: `SESSION-HANDOFF-YYYY-MM-DD-SNNN.md` (akkumulierend)
   - **NUR Main-Session** schreibt Handoffs (nicht Subagents)

### Task Structure

```
docs/tasks/
├── TASK-001-setup.md       ← Task-Dokument DIREKT hier
├── TASK-001/               ← Output-Ordner (Logs/Artifacts)
└── ...
```

- **Vault-First:** Vault Base ist SSOT fuer Task-Status. Lokale Files = Audit Trail.
- **Local Fallback:** PROJEKT.md Task-Tabelle ist SSOT. Status: 📋|⏳|📘|✅|🚫|❌
- **PROJEKT.md:** Executive Summary (Vault-First) oder Task-Tabelle (Local Fallback)

### Token Budget

| Budget | Action |
|--------|--------|
| <65% | Continue working |
| **65-70%** | **Run `/session-refresh`** |
| 85%+ | Finish task, commit, end session |

### Commands

| Command | When |
|---------|------|
| `/run-next-tasks` | Before starting work |
| `/session-refresh` | Session END or token >65% |

### New Task erstellen

1. Naechste UUID: Check Vault Base oder PROJEKT.md
2. Task-File: `docs/tasks/TASK-NNN-name.md` (Template: `${CLAUDE_PLUGIN_ROOT}/skills/project-init/assets/task-md-template.txt`)
3. Vault-First: Vault-Dokument mit Fileclass `claude-task` erstellen
4. Output-Ordner: `mkdir -p docs/tasks/TASK-NNN/{execution-logs,artifacts}`
5. PROJEKT.md: Erwaehnen (Vault-First) oder Tabellen-Eintrag (Local Fallback)

---
'''


def load_compact_reference() -> str:
    """Load Compact Block from workflow-block.txt (SSOT) with fallback."""
    import os
    # Try to find workflow-block.txt relative to this script
    script_dir = Path(__file__).parent.parent.parent  # Up to skills/
    workflow_block = script_dir / 'project-init' / 'assets' / 'workflow-block.txt'
    if workflow_block.exists():
        return workflow_block.read_text(encoding='utf-8')
    return COMPACT_REFERENCE_FALLBACK


def find_workflow_section(content: str) -> tuple[int, int, int]:
    """
    Find the inline workflow section in CLAUDE.md.

    Returns:
        (start_pos, end_pos, section_size_bytes)
        Returns (-1, -1, 0) if not found or already externalized.
    """
    # Pattern 1: Check for injection markers (most reliable)
    begin_marker = '<!-- BEGIN:WORKFLOW-INJECTION'
    end_marker = '<!-- END:WORKFLOW-INJECTION -->'

    if begin_marker in content and end_marker in content:
        start = content.find(begin_marker)
        end = content.find(end_marker) + len(end_marker)
        return start, end, end - start

    # Pattern 2: Large Session-Continuous Workflow section (>5KB suggests inline)
    # Find section start
    workflow_header_match = re.search(
        r'^(---\s*\n)?##\s*Session-Continuous Workflow',
        content,
        re.MULTILINE
    )

    if not workflow_header_match:
        return -1, -1, 0

    start = workflow_header_match.start()

    # Find section end (next ## heading or end of file)
    remaining_content = content[workflow_header_match.end():]

    # Look for next major section (## heading not indented or in code block)
    next_section_match = re.search(
        r'\n---\s*\n##\s+[A-Z]|\n##\s+[A-Z][a-zA-Z\s]+\n',
        remaining_content
    )

    if next_section_match:
        end = workflow_header_match.end() + next_section_match.start()
    else:
        # Check for footer pattern
        footer_match = re.search(r'\n---\s*\n\*Last updated:', remaining_content)
        if footer_match:
            end = workflow_header_match.end() + footer_match.start()
        else:
            end = len(content)

    section_size = end - start

    section_content = content[start:end]

    # Already using Vault-First Compact Block? (has Feature Detection marker)
    if 'obsidian.com version' in section_content and 'Vault-First' in section_content:
        return -1, -1, 0  # Already migrated to Vault-First

    # Small sections (<5KB) that reference WORKFLOW.md but lack Vault-First
    # → These are OLD reference-only blocks that need migration to Vault-First
    if section_size < 5000:
        if 'references/WORKFLOW.md' in section_content or '@~/.claude/skills' in section_content:
            # Old reference-only block — migrate to Vault-First Compact Block
            return start, end, section_size

    return start, end, section_size


def externalize_workflow(file_path: str, dry_run: bool = False) -> dict:
    """
    Replace inline workflow section with compact external reference.

    Returns:
        dict with 'success', 'original_size', 'new_size', 'saved_bytes', 'message'
    """
    path = Path(file_path)

    if not path.exists():
        return {
            'success': False,
            'message': f"File not found: {file_path}"
        }

    content = path.read_text(encoding='utf-8')
    original_size = len(content.encode('utf-8'))

    # Find workflow section
    start, end, section_size = find_workflow_section(content)

    if start == -1:
        return {
            'success': False,
            'original_size': original_size,
            'new_size': original_size,
            'saved_bytes': 0,
            'message': "No inline workflow section found (may already be externalized)"
        }

    # Build new content using Vault-First Compact Block
    compact_block = load_compact_reference()
    new_content = content[:start] + compact_block + content[end:]
    new_size = len(new_content.encode('utf-8'))
    saved_bytes = original_size - new_size

    if dry_run:
        return {
            'success': True,
            'dry_run': True,
            'original_size': original_size,
            'new_size': new_size,
            'saved_bytes': saved_bytes,
            'section_removed_bytes': section_size,
            'message': f"DRY RUN: Would save {saved_bytes:,} bytes ({original_size:,} → {new_size:,})"
        }

    # Create backup
    backup_path = path.with_suffix('.md.pre-workflow-externalization.backup')
    shutil.copy2(path, backup_path)

    # Write updated content
    path.write_text(new_content, encoding='utf-8')

    return {
        'success': True,
        'dry_run': False,
        'original_size': original_size,
        'new_size': new_size,
        'saved_bytes': saved_bytes,
        'section_removed_bytes': section_size,
        'backup_path': str(backup_path),
        'message': f"Saved {saved_bytes:,} bytes ({original_size:,} → {new_size:,})"
    }


def print_report(result: dict) -> None:
    """Print formatted report."""
    print("=" * 60)
    print("WORKFLOW EXTERNALIZATION REPORT")
    print("=" * 60)

    if result.get('dry_run'):
        print("\n⚠️  DRY RUN - No changes made\n")

    if result['success']:
        print(f"✅ Status: {'Would succeed' if result.get('dry_run') else 'Success'}")
        print(f"\n📊 Size Impact:")
        print(f"   Original:  {result['original_size']:>10,} bytes")
        print(f"   New:       {result['new_size']:>10,} bytes")
        print(f"   Saved:     {result['saved_bytes']:>10,} bytes ({result['saved_bytes']*100//result['original_size']}%)")

        if result.get('backup_path'):
            print(f"\n💾 Backup: {result['backup_path']}")

        print(f"\n📝 {result['message']}")

        if not result.get('dry_run'):
            print("\n✅ Next steps:")
            print("   1. Verify CLAUDE.md looks correct")
            print("   2. Run: python3 analyze_claude_md.py CLAUDE.md")
            print("   3. Test: /run-next-tasks (verify task-scheduler compatibility)")
    else:
        print(f"❌ Status: No action needed")
        print(f"📝 {result['message']}")

    print("\n" + "=" * 60)


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 externalize_workflow.py <path-to-claude-md> [--dry-run]")
        print("\nExamples:")
        print("  python3 externalize_workflow.py CLAUDE.md --dry-run")
        print("  python3 externalize_workflow.py /path/to/project/CLAUDE.md")
        print("\nThis script replaces old workflow blocks (inline ~10KB or old reference ~1.5KB)")
        print("with the Vault-First Compact Block (~4KB) from workflow-block.txt.")
        print("\nHandles: Full inline injection, old reference-only block, injection markers.")
        sys.exit(1)

    file_path = sys.argv[1]
    dry_run = '--dry-run' in sys.argv

    try:
        result = externalize_workflow(file_path, dry_run)
        print_report(result)

        if result['success']:
            sys.exit(0)
        else:
            sys.exit(1)

    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
