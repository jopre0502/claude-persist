#!/usr/bin/env python3
"""
Migrate Decision Log from CLAUDE.md to docs/DECISION-LOG.md.

Usage:
    python3 migrate_decision_log.py <claude-md-path> [--dry-run]
    python3 migrate_decision_log.py CLAUDE.md
    python3 migrate_decision_log.py CLAUDE.md --dry-run

What it does:
1. Extracts Decision Log table from CLAUDE.md
2. Creates/updates docs/DECISION-LOG.md with full content
3. Replaces inline Decision Log with link + summary (last 3 entries)
4. Creates backup before modifying

Exit codes:
    0 = Success
    1 = Error or no Decision Log found
"""

import sys
import re
from pathlib import Path
from datetime import datetime
from typing import Tuple, List, Optional


def find_decision_log_section(content: str) -> Tuple[Optional[int], Optional[int], Optional[str]]:
    """Find Decision Log section boundaries and content."""
    # Pattern for Decision Log heading
    heading_pattern = re.compile(
        r'^##\s*Decision Log.*$',
        re.MULTILINE | re.IGNORECASE
    )

    match = heading_pattern.search(content)
    if not match:
        return None, None, None

    start = match.start()

    # Find next ## heading (section end)
    next_section = re.search(r'\n##\s+[^#]', content[match.end():])
    if next_section:
        end = match.end() + next_section.start()
    else:
        # Check for --- separator
        separator = re.search(r'\n---\s*\n', content[match.end():])
        if separator:
            end = match.end() + separator.start()
        else:
            end = len(content)

    section_content = content[start:end]
    return start, end, section_content


def parse_decision_table(section_content: str) -> List[dict]:
    """Parse Decision Log table into list of entries."""
    entries = []

    # Find table rows
    table_pattern = re.compile(
        r'^\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|(?:\s*([^|]*)\s*\|)?',
        re.MULTILINE
    )

    rows = table_pattern.findall(section_content)

    for row in rows:
        decision = row[0].strip()
        rationale = row[1].strip()
        impact = row[2].strip()
        status = row[3].strip()
        date = row[4].strip() if len(row) > 4 else ""

        # Skip header and separator rows
        if decision.lower() == 'decision' or decision.startswith('-'):
            continue
        if '---' in decision or '---' in rationale:
            continue

        entries.append({
            'decision': decision,
            'rationale': rationale,
            'impact': impact,
            'status': status,
            'date': date
        })

    return entries


def extract_open_questions(section_content: str) -> str:
    """Extract Open Questions subsection if present."""
    # Look for Open Questions within the Decision Log section or nearby
    oq_pattern = re.compile(
        r'(?:##|###)\s*Open Questions.*?\n(.*?)(?=\n(?:##|###)\s+|\n---|\Z)',
        re.DOTALL | re.IGNORECASE
    )

    match = oq_pattern.search(section_content)
    if match:
        return match.group(0)
    return ""


def generate_decision_log_file(
    entries: List[dict],
    project_name: str,
    open_questions: str = ""
) -> str:
    """Generate content for docs/DECISION-LOG.md."""
    today = datetime.now().strftime("%Y-%m-%d")

    # Separate active vs resolved
    active = [e for e in entries if 'Stable' in e['status'] or 'Active' in e['status'].lower() or 'Monitored' in e['status']]
    resolved = [e for e in entries if e not in active]

    content = f"""# Decision Log - {project_name}

Architectural Decisions fuer {project_name}. Ausgelagert aus CLAUDE.md zur Groessenoptimierung.

> **Zurueck zu:** [CLAUDE.md](../CLAUDE.md)

Letzte Aktualisierung: {today}

---

## Active Decisions

| Decision | Rationale | Impact | Status | Datum |
|----------|-----------|--------|--------|-------|
"""

    for e in active:
        content += f"| {e['decision']} | {e['rationale']} | {e['impact']} | {e['status']} | {e['date']} |\n"

    if not active:
        content += "| (keine aktiven Entscheidungen) | - | - | - | - |\n"

    content += f"""
---

## Historical / Resolved

<details>
<summary>Historische Entscheidungen ({len(resolved)} Eintraege)</summary>

| Decision | Rationale | Impact | Status | Datum |
|----------|-----------|--------|--------|-------|
"""

    for e in resolved:
        content += f"| {e['decision']} | {e['rationale']} | {e['impact']} | {e['status']} | {e['date']} |\n"

    content += """
</details>

---

"""

    if open_questions:
        content += open_questions + "\n\n---\n\n"

    content += f"*Migrated from CLAUDE.md: {today}*\n"

    return content


def generate_replacement_section(entries: List[dict]) -> str:
    """Generate compact replacement for CLAUDE.md."""
    # Get last 3 entries
    recent = entries[-3:] if len(entries) >= 3 else entries

    today = datetime.now().strftime("%Y-%m-%d")

    content = """## Decision Log

> Vollstaendiger Decision Log: [docs/DECISION-LOG.md](docs/DECISION-LOG.md)

**Letzte Entscheidungen:**
"""

    for e in recent:
        status_emoji = "✅" if "Stable" in e['status'] else "🟡"
        content += f"- {status_emoji} **{e['decision'][:50]}** - {e['rationale'][:60]}...\n"

    content += f"\n*{len(entries)} Eintraege insgesamt. Letzte Aktualisierung: {today}*\n"

    return content


def migrate_decision_log(claude_md_path: str, dry_run: bool = False) -> bool:
    """Main migration function."""
    path = Path(claude_md_path)

    if not path.exists():
        print(f"Error: File not found: {claude_md_path}")
        return False

    content = path.read_text(encoding='utf-8')

    # Find Decision Log section
    start, end, section_content = find_decision_log_section(content)

    if start is None:
        print("Error: No Decision Log section found in CLAUDE.md")
        return False

    print(f"Found Decision Log section at lines ~{content[:start].count(chr(10))}-{content[:end].count(chr(10))}")
    print(f"Section size: {len(section_content):,} bytes")

    # Parse entries
    entries = parse_decision_table(section_content)
    print(f"Parsed {len(entries)} Decision Log entries")

    if len(entries) == 0:
        print("Warning: No table entries found. Check table format.")
        # Still proceed - might be a different format

    # Extract open questions if present
    open_questions = extract_open_questions(content)

    # Determine project name
    project_match = re.search(r'^#\s+(.+?)(?:\s*-|$)', content, re.MULTILINE)
    project_name = project_match.group(1).strip() if project_match else "Project"

    # Generate new files
    decision_log_content = generate_decision_log_file(entries, project_name, open_questions)
    replacement_section = generate_replacement_section(entries)

    # Determine paths
    docs_path = path.parent / "docs"
    decision_log_path = docs_path / "DECISION-LOG.md"

    if dry_run:
        print("\n" + "=" * 50)
        print("DRY RUN - No changes made")
        print("=" * 50)
        print(f"\nWould create: {decision_log_path}")
        print(f"Content preview ({len(decision_log_content)} bytes):")
        print("-" * 40)
        print(decision_log_content[:500] + "...")
        print("-" * 40)
        print(f"\nWould replace Decision Log section in CLAUDE.md:")
        print(replacement_section)
        print("-" * 40)
        print(f"\nEstimated size reduction: {len(section_content) - len(replacement_section):,} bytes")
        return True

    # Create backup
    backup_path = path.with_suffix('.pre-decision-migration.backup')
    backup_path.write_text(content, encoding='utf-8')
    print(f"Created backup: {backup_path}")

    # Ensure docs directory exists
    docs_path.mkdir(parents=True, exist_ok=True)

    # Write DECISION-LOG.md
    decision_log_path.write_text(decision_log_content, encoding='utf-8')
    print(f"Created: {decision_log_path}")

    # Update CLAUDE.md
    new_content = content[:start] + replacement_section + content[end:]
    path.write_text(new_content, encoding='utf-8')
    print(f"Updated: {path}")

    # Report
    old_size = len(content.encode('utf-8'))
    new_size = len(new_content.encode('utf-8'))
    print(f"\nSize reduction: {old_size:,} -> {new_size:,} bytes ({old_size - new_size:,} saved)")

    return True


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 migrate_decision_log.py <claude-md-path> [--dry-run]")
        print("\nExamples:")
        print("  python3 migrate_decision_log.py CLAUDE.md --dry-run")
        print("  python3 migrate_decision_log.py CLAUDE.md")
        sys.exit(1)

    file_path = sys.argv[1]
    dry_run = '--dry-run' in sys.argv

    success = migrate_decision_log(file_path, dry_run)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
