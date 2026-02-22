#!/usr/bin/env python3
"""
Apply Progressive Disclosure to CLAUDE.md sections.

Wraps resolved/historical content in <details> tags to reduce visible size.

Usage:
    python3 apply_progressive_disclosure.py <claude-md-path> [--dry-run]

Targets:
- Open Questions (resolved entries)
- Known Issues (resolved entries)
- Bekannte Herausforderungen (gelöst entries)
- Historical/completed sections

Exit codes:
    0 = Success (changes made or none needed)
    1 = Error
"""

import sys
import re
from pathlib import Path
from typing import List, Tuple


def find_and_wrap_resolved_questions(content: str) -> Tuple[str, int]:
    """Find Open Questions section and wrap resolved items in <details>."""
    changes = 0

    # Pattern for Open Questions section
    oq_pattern = re.compile(
        r'(##\s*Open Questions.*?\n)(.*?)(?=\n##\s+[^#]|\n---\s*$|\Z)',
        re.DOTALL | re.IGNORECASE
    )

    match = oq_pattern.search(content)
    if not match:
        return content, 0

    header = match.group(1)
    section_content = match.group(2)

    # Check for existing <details>
    if '<details>' in section_content:
        return content, 0

    # Find resolved vs active
    resolved_pattern = re.compile(
        r'^(\s*[-*]\s*)~~(.+?)~~\s*$|^(\s*[-*]\s*)\[x\](.+?)$',
        re.MULTILINE | re.IGNORECASE
    )

    resolved_matches = list(resolved_pattern.finditer(section_content))

    if len(resolved_matches) < 2:
        return content, 0

    # Split into active (top) and resolved (bottom, wrapped)
    lines = section_content.split('\n')
    active_lines = []
    resolved_lines = []

    for line in lines:
        is_resolved = (
            '~~' in line and line.count('~~') >= 2 or
            re.search(r'\[x\]', line, re.IGNORECASE) or
            ('Resolved' in line or 'resolved' in line or '✅' in line)
        )

        if is_resolved:
            resolved_lines.append(line)
        else:
            active_lines.append(line)

    if len(resolved_lines) < 2:
        return content, 0

    # Build new section
    new_section = header
    new_section += '\n'.join(active_lines).strip()
    new_section += f"""

<details>
<summary>Resolved ({len(resolved_lines)} items)</summary>

{chr(10).join(resolved_lines)}

</details>
"""

    changes = len(resolved_lines)

    # Replace in content
    new_content = content[:match.start()] + new_section + content[match.end():]
    return new_content, changes


def find_and_wrap_challenges(content: str) -> Tuple[str, int]:
    """Wrap solved challenges in <details>."""
    changes = 0

    # Pattern for Challenge sections that are solved
    challenge_pattern = re.compile(
        r'(###\s*Challenge\s*\d+:.*?)\n(.*?)(?=\n###\s+|\n##\s+|\Z)',
        re.DOTALL
    )

    matches = list(challenge_pattern.finditer(content))

    for match in reversed(matches):  # Reverse to preserve positions
        header = match.group(1)
        body = match.group(2)

        # Check if solved
        if 'gelöst' in header.lower() or 'solved' in header.lower() or 'Problem gelöst' in body:
            # Already wrapped?
            if '<details>' in body:
                continue

            # Wrap
            new_section = f"""{header}

<details>
<summary>Details (gelöst)</summary>

{body.strip()}

</details>
"""
            content = content[:match.start()] + new_section + content[match.end():]
            changes += 1

    return content, changes


def wrap_large_tables(content: str, max_rows: int = 8) -> Tuple[str, int]:
    """Wrap tables with many rows in <details>."""
    changes = 0

    # Find tables (header + separator + rows)
    table_pattern = re.compile(
        r'(\|[^\n]+\|\n\|[-:\s|]+\|\n)((?:\|[^\n]+\|\n){' + str(max_rows) + r',})',
        re.MULTILINE
    )

    matches = list(table_pattern.finditer(content))

    for match in reversed(matches):
        table_header = match.group(1)
        table_rows = match.group(2)
        row_count = table_rows.count('\n')

        # Check if already in details
        prev_content = content[max(0, match.start()-50):match.start()]
        if '<details>' in prev_content:
            continue

        # Don't wrap if it's the main task table
        if 'UUID' in table_header and 'Dependencies' in table_header:
            continue

        wrapped = f"""<details>
<summary>Tabelle ({row_count} Zeilen)</summary>

{table_header}{table_rows}
</details>
"""
        content = content[:match.start()] + wrapped + content[match.end():]
        changes += 1

    return content, changes


def wrap_reference_sections(content: str) -> Tuple[str, int]:
    """Wrap reference sections that are not frequently needed."""
    changes = 0

    # Sections to potentially wrap
    wrap_candidates = [
        (r'##\s*Referenzen\s*(?:&|und)?\s*Externe\s*Ressourcen', 'Referenzen'),
        (r'##\s*Häufige\s*Development\s*Tasks', 'Development Tasks'),
    ]

    for pattern, name in wrap_candidates:
        section_match = re.search(
            f'({pattern}.*?\\n)(.*?)(?=\\n##\\s+[^#]|\\n---\\s*$|\\Z)',
            content,
            re.DOTALL | re.IGNORECASE
        )

        if not section_match:
            continue

        header = section_match.group(1)
        body = section_match.group(2)

        # Already wrapped?
        if '<details>' in body[:50]:
            continue

        # Wrap the body
        new_section = f"""{header}
<details>
<summary>{name} (klicken zum Aufklappen)</summary>

{body.strip()}

</details>
"""
        content = content[:section_match.start()] + new_section + content[section_match.end():]
        changes += 1

    return content, changes


def apply_progressive_disclosure(file_path: str, dry_run: bool = False) -> bool:
    """Main function to apply all progressive disclosure patterns."""
    path = Path(file_path)

    if not path.exists():
        print(f"Error: File not found: {file_path}")
        return False

    content = path.read_text(encoding='utf-8')
    original_size = len(content.encode('utf-8'))
    total_changes = 0

    print(f"Analyzing: {file_path}")
    print(f"Original size: {original_size:,} bytes")
    print("-" * 40)

    # Apply transformations
    content, changes = find_and_wrap_resolved_questions(content)
    if changes:
        print(f"✓ Wrapped {changes} resolved Open Questions")
        total_changes += changes

    content, changes = find_and_wrap_challenges(content)
    if changes:
        print(f"✓ Wrapped {changes} solved Challenges")
        total_changes += changes

    content, changes = wrap_large_tables(content)
    if changes:
        print(f"✓ Wrapped {changes} large tables")
        total_changes += changes

    content, changes = wrap_reference_sections(content)
    if changes:
        print(f"✓ Wrapped {changes} reference sections")
        total_changes += changes

    # Report
    new_size = len(content.encode('utf-8'))
    print("-" * 40)

    if total_changes == 0:
        print("No changes needed - document already optimized.")
        return True

    print(f"Total changes: {total_changes}")
    print(f"Size change: {original_size:,} -> {new_size:,} bytes ({new_size - original_size:+,})")
    print("(Note: <details> adds some bytes, but reduces visible content)")

    if dry_run:
        print("\nDRY RUN - No changes written")
        return True

    # Create backup
    backup_path = path.with_suffix('.pre-disclosure.backup')
    backup_path.write_text(path.read_text(encoding='utf-8'), encoding='utf-8')
    print(f"Created backup: {backup_path}")

    # Write changes
    path.write_text(content, encoding='utf-8')
    print(f"Updated: {path}")

    return True


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 apply_progressive_disclosure.py <claude-md-path> [--dry-run]")
        print("\nExamples:")
        print("  python3 apply_progressive_disclosure.py CLAUDE.md --dry-run")
        print("  python3 apply_progressive_disclosure.py CLAUDE.md")
        sys.exit(1)

    file_path = sys.argv[1]
    dry_run = '--dry-run' in sys.argv

    success = apply_progressive_disclosure(file_path, dry_run)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
