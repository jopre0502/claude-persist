#!/usr/bin/env python3
"""
Externalize inline workflow-block to external reference.

Replaces large inline workflow documentation (~10KB) with compact reference
pointing to ~/.claude/skills/project-init/references/WORKFLOW.md.

Usage:
    python3 externalize_workflow.py <path-to-claude-md> [--dry-run]

Example:
    python3 externalize_workflow.py CLAUDE.md --dry-run
    python3 externalize_workflow.py /path/to/project/CLAUDE.md

Output:
    - Backup: CLAUDE.md.pre-workflow-externalization.backup
    - Updated CLAUDE.md with compact reference (~1.5KB instead of ~10KB)
"""

import sys
import re
import shutil
from pathlib import Path
from datetime import datetime

# Compact reference block to replace inline workflow
COMPACT_REFERENCE = '''---

## Session-Continuous Workflow

This project uses an automated session workflow for context optimization and task tracking.

**Detaillierte Workflow-Dokumentation:** `~/.claude/skills/project-init/references/WORKFLOW.md`

### Quick Reference

| Wann | Aktion | Command |
|------|--------|---------|
| Session-Start | Ready-Tasks prüfen | `/run-next-tasks` |
| Während Arbeit | Task-Status updaten | PROJEKT.md + Task-File |
| Token >65% | Docs optimieren | `/session-refresh` |
| Session-Ende | Commit + Optimieren | `/session-refresh` |

### Task-Struktur (⚠️ KRITISCH)

```
docs/tasks/
├── TASK-001-setup.md       ← Task-Dokument DIREKT hier (nicht in Unterordner!)
├── TASK-001/               ← Output-Ordner (NUR für Logs/Artifacts)
│   ├── execution-logs/
│   └── artifacts/
├── TASK-002-feature.md     ← Nächstes Task-Dokument (direkt)
└── TASK-002/               ← Dessen Output-Ordner
```

### Token Budget Schwellwerte

| Budget | Status | Action |
|--------|--------|--------|
| <50% | ✅ Healthy | Continue working |
| 50-65% | ⏳ Monitor | Watch for next trigger |
| **65-70%** | **⚠️ TRIGGER** | **Run `/session-refresh`** |
| 70%+ | 🔴 Alert | Plan session end |

### Core Commands

| Command | Zweck | Wann |
|---------|-------|------|
| `/run-next-tasks` | Ready-Tasks anzeigen | Session-Start |
| `/session-refresh` | Docs + Context optimieren | Token >65%, Session-Ende |
| `/project-doc-restructure` | PROJEKT.md optimieren | Auto via session-refresh |

### Task-Tabellen-Format (7-Column Schema)

| UUID | Task | Status | Dependencies | Effort | Deliverable | Task-File |
|------|------|--------|--------------|--------|-------------|-----------|
| **TASK-001** | Setup | ✅ completed | None | 1h | docs | [Details](tasks/TASK-001-setup.md) |

**Status-Werte:** `✅ completed` | `📋 pending` | `⏳ in_progress` | `🚫 blocked`

### Neue Task erstellen

1. **UUID:** Nächste freie TASK-NNN Nummer
2. **Task-Dokument:** `docs/tasks/TASK-NNN-name.md` (Template: `~/.claude/skills/project-init/assets/task-md-template.txt`)
3. **Output-Ordner:** `mkdir -p docs/tasks/TASK-NNN/{execution-logs,artifacts}`
4. **PROJEKT.md:** Neue Zeile im 7-Column Schema

---

**Vollständige Workflow-Dokumentation:** For complex usage, see `~/.claude/skills/project-init/references/WORKFLOW.md`
'''


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

    # Only consider it "inline" if it's large (>5KB)
    # Small sections might already be externalized
    if section_size < 5000:
        # Check if it contains external reference indicator
        section_content = content[start:end]
        if 'references/WORKFLOW.md' in section_content or '@~/.claude/skills' in section_content:
            return -1, -1, 0  # Already externalized

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

    if section_size < 5000:
        return {
            'success': False,
            'original_size': original_size,
            'new_size': original_size,
            'saved_bytes': 0,
            'message': f"Workflow section is only {section_size:,} bytes - likely already compact"
        }

    # Build new content
    new_content = content[:start] + COMPACT_REFERENCE + content[end:]
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
        print("\nThis script replaces large inline workflow documentation (~10KB)")
        print("with a compact reference to the external WORKFLOW.md file (~1.5KB).")
        print("\nExpected savings: 70-85% of workflow section size")
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
