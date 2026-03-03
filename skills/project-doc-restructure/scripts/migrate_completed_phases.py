#!/usr/bin/env python3
"""
Migrate completed phases from PROJEKT.md to docs/phases/.

This script detects completed phases that are still inline in PROJEKT.md
and migrates them to separate files in docs/phases/, replacing the inline
content with a link reference.

Usage:
    python3 migrate_completed_phases.py <projekt_md_path> [--dry-run] [--auto]

Options:
    --dry-run   Show what would be migrated without making changes
    --auto      Automatically migrate without prompting
"""

import re
import sys
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass


@dataclass
class Phase:
    """Represents a detected phase in PROJEKT.md."""
    number: Optional[int]
    name: str
    status: str  # 'completed', 'active', 'planned'
    start_line: int
    end_line: int
    header_line: str
    content: List[str]
    is_collapsed: bool


class PhaseMigrator:
    """Handles detection and migration of completed phases."""

    # Patterns for detecting completed phases
    PHASE_HEADER_PATTERNS = [
        # ## Phase 1: Foundation (ABGESCHLOSSEN)
        r'^##\s+(?:📋\s+)?Phase\s+(\d+):\s*(.+?)\s*\((?:ABGESCHLOSSEN|COMPLETED|✅|completed)\)',
        # ## Phase 01: Name (✅ completed)
        r'^##\s+(?:📋\s+)?Phase\s+(\d+):\s*(.+?)\s*\(✅\s*(?:completed|COMPLETE)?\)',
        # ## 📋 Phase 1: Name (ABGESCHLOSSEN)
        r'^##\s+📋\s+Phase\s+(\d+):\s*(.+?)\s*\((?:ABGESCHLOSSEN|COMPLETED)\)',
    ]

    PHASE_GENERIC_PATTERN = r'^##\s+(?:📋\s+)?Phase\s+(\d+):\s*(.+?)(?:\s*\(([^)]+)\))?$'

    COMPLETED_INDICATORS = [
        '✅', 'ABGESCHLOSSEN', 'COMPLETED', 'completed', 'COMPLETE',
        '100%', 'all tasks completed', 'alle Tasks erledigt'
    ]

    def __init__(self, projekt_md_path: str, dry_run: bool = False, auto: bool = False):
        self.projekt_path = Path(projekt_md_path)
        self.dry_run = dry_run
        self.auto = auto

        if not self.projekt_path.exists():
            raise FileNotFoundError(f"PROJEKT.md not found: {projekt_md_path}")

        self.content = self.projekt_path.read_text(encoding='utf-8')
        self.lines = self.content.split('\n')

        # Determine docs directory (parent of PROJEKT.md)
        self.docs_dir = self.projekt_path.parent
        self.phases_dir = self.docs_dir / 'phases'

    def detect_completed_phases(self) -> List[Phase]:
        """Find all completed phases that are still inline in PROJEKT.md."""
        phases = []
        i = 0

        while i < len(self.lines):
            line = self.lines[i]

            # Check if line matches a phase header
            phase = self._parse_phase_header(line, i)
            if phase:
                # Find the end of this phase section
                end_line = self._find_section_end(i)
                phase.end_line = end_line
                phase.content = self.lines[i:end_line + 1]

                # Check if this phase is completed and not already a link
                if phase.status == 'completed' and not self._is_already_migrated(phase):
                    phases.append(phase)

                i = end_line + 1
            else:
                i += 1

        return phases

    def _parse_phase_header(self, line: str, line_num: int) -> Optional[Phase]:
        """Parse a potential phase header line."""
        # Try specific completed patterns first
        for pattern in self.PHASE_HEADER_PATTERNS:
            match = re.match(pattern, line, re.IGNORECASE)
            if match:
                return Phase(
                    number=int(match.group(1)),
                    name=match.group(2).strip(),
                    status='completed',
                    start_line=line_num,
                    end_line=line_num,
                    header_line=line,
                    content=[],
                    is_collapsed=False
                )

        # Try generic phase pattern
        match = re.match(self.PHASE_GENERIC_PATTERN, line, re.IGNORECASE)
        if match:
            phase_num = int(match.group(1))
            phase_name = match.group(2).strip()
            status_hint = match.group(3) if match.group(3) else ''

            # Determine status from hint
            status = self._determine_status(status_hint, line)

            return Phase(
                number=phase_num,
                name=phase_name,
                status=status,
                start_line=line_num,
                end_line=line_num,
                header_line=line,
                content=[],
                is_collapsed=False
            )

        return None

    def _determine_status(self, status_hint: str, full_line: str) -> str:
        """Determine phase status from indicators."""
        check_text = f"{status_hint} {full_line}".lower()

        for indicator in self.COMPLETED_INDICATORS:
            if indicator.lower() in check_text:
                return 'completed'

        if any(word in check_text for word in ['aktiv', 'active', 'in progress', 'läuft']):
            return 'active'

        if any(word in check_text for word in ['geplant', 'planned', 'future']):
            return 'planned'

        return 'unknown'

    def _find_section_end(self, start_line: int) -> int:
        """Find the end line of a section (before next same-level header or EOF)."""
        current_level = self._get_header_level(self.lines[start_line])
        in_details = False

        for i in range(start_line + 1, len(self.lines)):
            line = self.lines[i]

            # Legacy: Track <details> blocks for backward-compatible parsing of older documents
            if '<details>' in line:
                in_details = True
            if '</details>' in line:
                in_details = False
                continue

            # Legacy: Don't break inside <details>
            if in_details:
                continue

            # Check for same-level or higher-level header
            if line.startswith('#'):
                level = self._get_header_level(line)
                if level <= current_level:
                    return i - 1

            # Check for horizontal rule (often section separator)
            if line.strip() == '---' and i > start_line + 5:
                # Look ahead to see if next content is a new major section
                for j in range(i + 1, min(i + 5, len(self.lines))):
                    if self.lines[j].startswith('## '):
                        return i - 1

        return len(self.lines) - 1

    def _get_header_level(self, line: str) -> int:
        """Get the heading level (number of # characters)."""
        match = re.match(r'^(#+)', line)
        return len(match.group(1)) if match else 0

    def _is_already_migrated(self, phase: Phase) -> bool:
        """Check if a phase is just a link reference (already migrated)."""
        content_text = '\n'.join(phase.content)

        # Check if content is minimal (just a table row or link)
        if len(phase.content) < 5:
            if '[Details]' in content_text or 'phases/' in content_text:
                return True

        # Check for explicit "see phases/" reference
        if re.search(r'\[.*\]\(phases/Phase-\d+', content_text):
            return True

        return False

    def migrate_phase(self, phase: Phase) -> Tuple[str, str]:
        """
        Migrate a phase to docs/phases/.

        Returns:
            Tuple of (phase_file_path, link_markdown)
        """
        # Generate filename
        phase_num_str = f"{phase.number:02d}" if phase.number else "XX"
        safe_name = re.sub(r'[^\w\-]', '-', phase.name.strip())
        safe_name = re.sub(r'-+', '-', safe_name).strip('-')[:30]
        filename = f"Phase-{phase_num_str}-{safe_name}.md"

        phase_file_path = self.phases_dir / filename

        # Generate phase file content
        phase_content = self._generate_phase_file_content(phase)

        # Generate link for PROJEKT.md
        link_markdown = f"[Details](phases/{filename})"

        if not self.dry_run:
            # Create phases directory if needed
            self.phases_dir.mkdir(parents=True, exist_ok=True)

            # Write phase file
            phase_file_path.write_text(phase_content, encoding='utf-8')

        return str(phase_file_path), link_markdown

    def _generate_phase_file_content(self, phase: Phase) -> str:
        """Generate the content for the migrated phase file."""
        current_date = datetime.now().strftime('%Y-%m-%d')

        # Clean up content - remove collapsed details wrapper if present
        content_lines = phase.content.copy()

        # Legacy: Remove outer <details>/<summary> if the whole phase was collapsed (backward compat)
        if content_lines and '<details>' in content_lines[0]:
            content_lines = self._unwrap_details(content_lines)

        # Add metadata header
        header = f"""# Phase {phase.number}: {phase.name}

> **Status:** Abgeschlossen
> **Migrated from PROJEKT.md:** {current_date}

---

"""

        # Build content body
        body_lines = []
        skip_header = True  # Skip the original ## Phase header

        for line in content_lines:
            if skip_header and line.startswith('## '):
                skip_header = False
                continue
            if not skip_header:
                body_lines.append(line)

        # If we have no body, use original content
        if not body_lines:
            body_lines = content_lines[1:]  # Skip first line (header)

        body = '\n'.join(body_lines).strip()

        return header + body + '\n'

    def _unwrap_details(self, lines: List[str]) -> List[str]:
        """Legacy: Remove outer <details>/<summary> wrapper if present (backward compat for older docs)."""
        result = []
        in_wrapper = False
        depth = 0

        for i, line in enumerate(lines):
            if i == 0 and '<details>' in line:
                in_wrapper = True
                depth = 1
                continue

            if in_wrapper:
                if '<summary>' in line and '</summary>' in line:
                    continue
                if '<summary>' in line:
                    continue
                if '</summary>' in line:
                    continue
                if '<details>' in line:
                    depth += 1
                if '</details>' in line:
                    depth -= 1
                    if depth == 0:
                        in_wrapper = False
                        continue

            result.append(line)

        return result

    def update_projekt_md(self, phase: Phase, link_markdown: str) -> str:
        """
        Replace inline phase content with a link reference.

        Returns the updated PROJEKT.md content.
        """
        new_lines = self.lines.copy()

        # Create replacement content
        phase_num_str = f"{phase.number:02d}" if phase.number else "XX"
        replacement = [
            f"## 📋 Phase {phase.number}: {phase.name} (ABGESCHLOSSEN)",
            "",
            f"> Ausgelagert: {link_markdown}",
            ""
        ]

        # Replace the phase section
        new_lines[phase.start_line:phase.end_line + 1] = replacement

        return '\n'.join(new_lines)

    def run(self) -> Dict:
        """
        Run the migration process.

        Returns a summary dict with results.
        """
        results = {
            'detected': [],
            'migrated': [],
            'skipped': [],
            'errors': [],
            'dry_run': self.dry_run
        }

        print(f"{'[DRY RUN] ' if self.dry_run else ''}Scanning: {self.projekt_path}")
        print()

        # Detect completed phases
        phases = self.detect_completed_phases()
        results['detected'] = [{'number': p.number, 'name': p.name} for p in phases]

        if not phases:
            print("No completed inline phases found for migration.")
            return results

        print(f"Found {len(phases)} completed phase(s) for potential migration:")
        for phase in phases:
            print(f"  - Phase {phase.number}: {phase.name} (lines {phase.start_line + 1}-{phase.end_line + 1})")
        print()

        # Process each phase
        updated_content = self.content
        offset = 0  # Track line number shifts

        for phase in phases:
            # Adjust line numbers for previous migrations
            adjusted_phase = Phase(
                number=phase.number,
                name=phase.name,
                status=phase.status,
                start_line=phase.start_line - offset,
                end_line=phase.end_line - offset,
                header_line=phase.header_line,
                content=phase.content,
                is_collapsed=phase.is_collapsed
            )

            if not self.auto and not self.dry_run:
                response = input(f"Migrate Phase {phase.number}: {phase.name}? [y/N] ")
                if response.lower() != 'y':
                    results['skipped'].append({'number': phase.number, 'name': phase.name})
                    print(f"  Skipped.")
                    continue

            try:
                # Migrate phase file
                phase_file, link = self.migrate_phase(phase)

                if self.dry_run:
                    print(f"  Would create: {phase_file}")
                    print(f"  Would replace inline content with: {link}")
                else:
                    print(f"  Created: {phase_file}")

                    # Update PROJEKT.md content
                    self.lines = updated_content.split('\n')
                    updated_content = self.update_projekt_md(adjusted_phase, link)

                    # Calculate offset for next iteration
                    original_lines = adjusted_phase.end_line - adjusted_phase.start_line + 1
                    new_lines = 4  # Our replacement is 4 lines
                    offset += original_lines - new_lines

                    print(f"  Updated PROJEKT.md with link reference")

                results['migrated'].append({
                    'number': phase.number,
                    'name': phase.name,
                    'file': phase_file,
                    'link': link
                })

            except Exception as e:
                results['errors'].append({
                    'number': phase.number,
                    'name': phase.name,
                    'error': str(e)
                })
                print(f"  ERROR: {e}")

        # Write updated PROJEKT.md
        if results['migrated'] and not self.dry_run:
            # Create backup
            backup_path = str(self.projekt_path) + '.pre-migration.backup'
            Path(backup_path).write_text(self.content, encoding='utf-8')
            print(f"\nBackup created: {backup_path}")

            # Write updated content
            self.projekt_path.write_text(updated_content, encoding='utf-8')
            print(f"Updated: {self.projekt_path}")

        # Summary
        print()
        print("=" * 50)
        print("Migration Summary:")
        print(f"  Detected:  {len(results['detected'])}")
        print(f"  Migrated:  {len(results['migrated'])}")
        print(f"  Skipped:   {len(results['skipped'])}")
        print(f"  Errors:    {len(results['errors'])}")

        if self.dry_run:
            print("\n[DRY RUN] No changes were made.")

        return results


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        print("\nError: Missing PROJEKT.md path")
        sys.exit(1)

    projekt_path = sys.argv[1]
    dry_run = '--dry-run' in sys.argv
    auto = '--auto' in sys.argv

    try:
        migrator = PhaseMigrator(projekt_path, dry_run=dry_run, auto=auto)
        results = migrator.run()

        # Exit code based on results
        if results['errors']:
            sys.exit(2)
        elif results['migrated']:
            sys.exit(0)
        else:
            sys.exit(0)  # No phases to migrate is also success

    except FileNotFoundError as e:
        print(f"Error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.exit(2)


if __name__ == '__main__':
    main()
