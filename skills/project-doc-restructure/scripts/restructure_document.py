#!/usr/bin/env python3
"""
Restructure project documentation to follow session-continuous patterns.
Transforms traditional docs into Inverted Pyramid structure.

Post-restructure: Optionally detects and reports completed phases that
can be migrated to docs/phases/ for size reduction.
"""

import re
import sys
from pathlib import Path
from datetime import datetime
from typing import List, Tuple, Dict, Optional


class DocumentRestructurer:
    def __init__(self, file_path):
        self.path = Path(file_path)
        self.content = self.path.read_text(encoding='utf-8')
        self.lines = self.content.split('\n')
        self.sections = self._parse_sections()

    def _parse_sections(self) -> List[Dict]:
        """Parse document into sections based on headers."""
        sections = []
        current_section = None

        for i, line in enumerate(self.lines):
            if line.startswith('##'):
                if current_section:
                    sections.append(current_section)

                header_match = re.match(r'^(#+)\s+(.+)$', line)
                level = len(header_match.group(1)) if header_match else 2
                title = header_match.group(2) if header_match else line

                current_section = {
                    'line_start': i,
                    'line_end': i,
                    'level': level,
                    'title': title,
                    'content': []
                }
            elif current_section:
                current_section['content'].append(line)
                current_section['line_end'] = i

        if current_section:
            sections.append(current_section)

        return sections

    def _classify_section(self, section: Dict) -> str:
        """Classify section as ACTIVE, COMPLETED, PLANNED, ARCHIVE."""
        title = section['title'].lower()
        content = '\n'.join(section['content']).lower()

        # Active indicators
        if any(word in title for word in ['aktiv', 'active', 'current', 'in progress', 'läuft']):
            return 'ACTIVE'

        # Completed indicators
        if any(word in title for word in ['abgeschlossen', 'completed', 'done', 'erledigt']):
            return 'COMPLETED'

        # Planned indicators
        if any(word in title for word in ['geplant', 'planned', 'future', 'coming', 'next']):
            return 'PLANNED'

        # Check content for status indicators
        if '100%' in content or 'all tasks' in content.lower():
            return 'COMPLETED'

        # Check for uncompleted tasks
        if '- [ ]' in content:
            return 'ACTIVE'

        # Default to archive for old content
        return 'ARCHIVE'

    def restructure(self) -> str:
        """Restructure document with Inverted Pyramid pattern."""
        output = []

        # Extract metadata
        project_name = self._extract_project_name()
        current_date = datetime.now().strftime('%Y-%m-%d')

        # Header
        output.append(f"# {project_name} - Projektmanagement")
        output.append("")
        output.append(f"> **Letzte Aktualisierung:** {current_date} (Restructured)")
        output.append("")
        output.append("---")
        output.append("")

        # Layer 1: ACTION LAYER
        output.extend(self._generate_executive_summary())
        output.append("")
        output.extend(self._generate_immediate_actions())
        output.append("")
        output.append("---")
        output.append("")

        # Layer 2: CONTEXT LAYER
        output.extend(self._generate_phase_status_overview())
        output.append("")

        # Active phases (expanded)
        active_sections = [s for s in self.sections if self._classify_section(s) == 'ACTIVE']
        for section in active_sections:
            output.extend(self._format_section(section, collapsed=False))
            output.append("")

        output.append("---")
        output.append("")

        # Layer 3: ARCHIVE LAYER
        # Planned phases (collapsed)
        planned_sections = [s for s in self.sections if self._classify_section(s) == 'PLANNED']
        for section in planned_sections:
            output.extend(self._format_section(section, collapsed=True))
            output.append("")

        # Completed phases (collapsed)
        completed_sections = [s for s in self.sections if self._classify_section(s) == 'COMPLETED']
        for section in completed_sections:
            output.extend(self._format_section(section, collapsed=True))
            output.append("")

        # Archive sections (collapsed)
        archive_sections = [s for s in self.sections if self._classify_section(s) == 'ARCHIVE']
        for section in archive_sections:
            output.extend(self._format_section(section, collapsed=True))
            output.append("")

        # Reference Information
        output.extend(self._generate_reference_section())

        return '\n'.join(output)

    def _extract_project_name(self) -> str:
        """Extract project name from document."""
        for line in self.lines[:20]:
            if line.startswith('# '):
                name = line[2:].split('-')[0].strip()
                return name if name else "Project"
        return "Project"

    def _generate_executive_summary(self) -> List[str]:
        """Generate Executive Summary from existing content."""
        summary = [
            "## 📊 Executive Summary",
            "",
            "**Aktueller Status:** [AUTO-GENERATED - NEEDS REVIEW]",
            "",
            "**Was funktioniert:**",
            "- ✅ [Completed item 1]",
            "- ✅ [Completed item 2]",
            "",
            "**Aktueller Fokus:**",
            "- [Current work description]",
            "",
            "**Nächste Session kann starten mit:**",
            "1. [Action 1]",
            "2. Oder: [Action 2]",
            "3. Oder: [Action 3]",
        ]

        # Try to extract actual status
        active_sections = [s for s in self.sections if self._classify_section(s) == 'ACTIVE']
        if active_sections:
            phase_name = active_sections[0]['title']
            summary[2] = f"**Aktueller Status:** {phase_name} (AKTIV)"

        return summary

    def _generate_immediate_actions(self) -> List[str]:
        """Extract immediate actions from document."""
        actions = [
            "## 🎯 Immediate Next Actions",
            "",
            "### Offen:",
        ]

        # Find uncompleted checkboxes
        uncompleted_tasks = []
        for section in self.sections:
            content = '\n'.join(section['content'])
            tasks = re.findall(r'- \[ \] (.+)', content)
            uncompleted_tasks.extend(tasks[:3])  # Max 3 per section

        if uncompleted_tasks:
            for task in uncompleted_tasks[:5]:  # Max 5 total
                actions.append(f"- [ ] {task}")
        else:
            actions.append("- [ ] [No open tasks found - please review and add]")

        actions.append("")
        actions.append("### Entscheidungspunkt:")
        actions.append("- **Option A:** [Decision needed]")
        actions.append("- **Option B:** [Alternative approach]")

        return actions

    def _generate_phase_status_overview(self) -> List[str]:
        """Generate phase status table."""
        overview = [
            "## 📈 Phase Status Overview",
            "",
            "| Phase | Beschreibung | Status | Progress | Priorität |",
            "|-------|--------------|--------|----------|-----------|",
        ]

        # Extract phases from sections
        phase_pattern = r'(?:Phase|Sprint|Milestone)\s+([A-Z]\d*)'

        for section in self.sections:
            if re.search(phase_pattern, section['title'], re.IGNORECASE):
                phase_match = re.search(phase_pattern, section['title'], re.IGNORECASE)
                phase_id = phase_match.group(1) if phase_match else "?"

                # Extract description
                desc_match = re.search(r':\s*(.+)', section['title'])
                desc = desc_match.group(1)[:30] if desc_match else section['title'][:30]

                # Determine status
                classification = self._classify_section(section)
                status_emoji = {
                    'ACTIVE': '🔄 In Arbeit',
                    'COMPLETED': '✅ Abgeschlossen',
                    'PLANNED': '⏳ Geplant',
                    'ARCHIVE': '📦 Archive'
                }
                status = status_emoji.get(classification, '⏳ Geplant')

                # Extract progress
                content = '\n'.join(section['content'])
                progress_match = re.search(r'(\d+%)', content)
                progress = progress_match.group(1) if progress_match else "0%"

                # Priority
                priority = "**AKTIV**" if classification == 'ACTIVE' else "-"

                overview.append(f"| **{phase_id}** | {desc} | {status} | {progress} | {priority} |")

        if len(overview) == 4:  # No phases found
            overview.append("| **A** | [Phase description] | ⏳ Geplant | 0% | **AKTIV** |")

        return overview

    def _format_section(self, section: Dict, collapsed: bool) -> List[str]:
        """Format section with optional collapse."""
        classification = self._classify_section(section)

        # Add emoji based on classification
        emoji_map = {
            'ACTIVE': '🔄',
            'COMPLETED': '📋',
            'PLANNED': '🚀',
            'ARCHIVE': '📚'
        }
        emoji = emoji_map.get(classification, '📄')

        status_text = {
            'ACTIVE': '(AKTIV)',
            'COMPLETED': '(ABGESCHLOSSEN)',
            'PLANNED': '(GEPLANT)',
            'ARCHIVE': ''
        }
        status = status_text.get(classification, '')

        header = f"{'#' * section['level']} {emoji} {section['title']} {status}".strip()

        if not collapsed:
            return [header, ""] + section['content']
        else:
            # Migrated format — link to separate file instead of inline content
            content_preview = '\n'.join(section['content'][:2])
            summary_line = content_preview.split('\n')[0] if content_preview else "Details migrated"

            return [
                header,
                "",
                f"> {summary_line} — Details in separater Datei oder bei Bedarf inline ergaenzen.",
            ]

    def _generate_reference_section(self) -> List[str]:
        """Generate reference information section."""
        current_date = datetime.now().strftime('%Y-%m-%d')

        return [
            "## 📚 Reference Information",
            "",
            "### Entscheidungslog",
            "",
            "| Datum | Entscheidung | Begründung | Phase |",
            "|-------|--------------|------------|-------|",
            f"| {current_date} | Dokument restructured | Improved session continuity | - |",
            "",
            "---",
            "",
            "**Ende des Dokuments** | Für neue Session: Starte bei \"Executive Summary\"",
        ]


def check_for_migratable_phases(file_path: str) -> Optional[int]:
    """
    Check if there are completed phases that could be migrated.

    Returns the number of migratable phases found, or None on error.
    """
    try:
        # Import the migration module
        script_dir = Path(__file__).parent
        sys.path.insert(0, str(script_dir))
        from migrate_completed_phases import PhaseMigrator

        migrator = PhaseMigrator(file_path, dry_run=True, auto=True)
        phases = migrator.detect_completed_phases()
        return len(phases)
    except ImportError:
        return None
    except Exception:
        return None


def main():
    if len(sys.argv) < 2:
        print("Usage: restructure_document.py <file_path> [output_path] [--check-phases]")
        sys.exit(1)

    file_path = sys.argv[1]
    output_path = None
    check_phases = '--check-phases' in sys.argv

    # Parse output path (skip flags)
    for arg in sys.argv[2:]:
        if not arg.startswith('--'):
            output_path = arg
            break

    if not Path(file_path).exists():
        print(f"Error: File not found: {file_path}")
        sys.exit(1)

    print(f"Restructuring: {file_path}")
    print("Applying Inverted Pyramid pattern...")
    print()

    restructurer = DocumentRestructurer(file_path)
    restructured_content = restructurer.restructure()

    if output_path:
        Path(output_path).write_text(restructured_content, encoding='utf-8')
        print(f"Restructured document written to: {output_path}")
    else:
        backup_path = file_path + '.backup'
        Path(backup_path).write_text(restructurer.content, encoding='utf-8')
        Path(file_path).write_text(restructured_content, encoding='utf-8')
        print(f"Original backed up to: {backup_path}")
        print(f"Restructured document written to: {file_path}")

    print()
    print("Next steps:")
    print("1. Review Executive Summary and update with actual status")
    print("2. Review Immediate Actions and add specific tasks")
    print("3. Verify phase classifications (ACTIVE/COMPLETED/PLANNED)")
    print("4. Run validation: validate_doc_metrics.py <file>")

    # Check for migratable phases (if requested or auto-detect)
    if check_phases or True:  # Always check by default
        migratable = check_for_migratable_phases(file_path)
        if migratable and migratable > 0:
            print()
            print("=" * 50)
            print(f"PHASE MIGRATION AVAILABLE")
            print(f"Found {migratable} completed phase(s) that could be migrated to docs/phases/")
            print("This can reduce PROJEKT.md size and improve session continuity.")
            print()
            print("To migrate, run:")
            print(f"  python3 migrate_completed_phases.py {file_path} --dry-run")
            print(f"  python3 migrate_completed_phases.py {file_path} --auto")


if __name__ == '__main__':
    main()
