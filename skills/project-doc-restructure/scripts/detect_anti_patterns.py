#!/usr/bin/env python3
"""
Anti-pattern detection for session-continuous documentation.
Identifies chronicle, redundancy, wall-of-text, and other anti-patterns.
"""

import re
import sys
from pathlib import Path
from collections import Counter


class AntiPatternDetector:
    def __init__(self, file_path):
        self.path = Path(file_path)
        self.content = self.path.read_text(encoding='utf-8')
        self.lines = self.content.split('\n')
        self.anti_patterns = []

    def detect_all(self):
        """Run all anti-pattern detections."""
        self.detect_chronicle_pattern()
        self.detect_redundancy()
        self.detect_wall_of_text()
        self.detect_premature_optimization()
        self.detect_assumed_context()
        return self.anti_patterns

    def detect_chronicle_pattern(self):
        """Detect chronological organization (oldest first)."""
        # Look for date-based headers in sequence
        date_headers = re.findall(r'^##\s*(\d{4}-\d{2}-\d{2})', self.content, re.MULTILINE)

        if len(date_headers) >= 3:
            # Check if dates are in ascending order (old to new)
            dates = [d for d in date_headers]
            if dates == sorted(dates):
                self.anti_patterns.append({
                    'type': 'CHRONICLE_PATTERN',
                    'severity': 'HIGH',
                    'message': f'Chronological organization detected ({len(date_headers)} date-based sections). Newest content should be first.',
                    'recommendation': 'Restructure with Inverted Pyramid: Current Status → Future → Past (collapsed)'
                })

    def detect_redundancy(self):
        """Detect redundant information across sections."""
        # Check for duplicate section headers
        headers = re.findall(r'^##\s+(.+)$', self.content, re.MULTILINE)
        header_counts = Counter(headers)
        duplicates = {h: c for h, c in header_counts.items() if c > 1}

        if duplicates:
            self.anti_patterns.append({
                'type': 'REDUNDANT_SECTIONS',
                'severity': 'MEDIUM',
                'message': f'Duplicate sections found: {", ".join(duplicates.keys())}',
                'recommendation': 'Consolidate duplicate sections into Single Source of Truth'
            })

        # Check for common status phrases repeated multiple times
        status_patterns = [
            (r'(\d+%)\s+(?:done|erledigt|complete)', 'Progress percentages'),
            (r'(Phase [A-Z]\d*)', 'Phase references'),
            (r'(\d+/\d+)\s+[Tt]asks?', 'Task counts'),
        ]

        for pattern, name in status_patterns:
            matches = re.findall(pattern, self.content, re.IGNORECASE)
            if len(matches) > 4:
                count = Counter(matches)
                most_common = count.most_common(1)[0]
                if most_common[1] > 3:
                    self.anti_patterns.append({
                        'type': 'REDUNDANT_STATUS',
                        'severity': 'LOW',
                        'message': f'{name} repeated {most_common[1]} times: "{most_common[0]}"',
                        'recommendation': 'Define status once in Phase Status Overview table, reference elsewhere'
                    })

    def detect_wall_of_text(self):
        """Detect lack of visual hierarchy."""
        # Find paragraphs > 10 lines without structure
        paragraphs = re.split(r'\n\s*\n', self.content)
        long_paragraphs = []

        for i, para in enumerate(paragraphs):
            lines = para.split('\n')
            # Check if it's prose (not lists, tables, code)
            if (len(lines) > 10 and
                not para.strip().startswith(('#', '-', '*', '|', '```')) and
                para.count('\n-') < 3 and  # Not a list
                para.count('**') < 4):  # Not heavily formatted

                long_paragraphs.append((i, len(lines)))

        if long_paragraphs:
            self.anti_patterns.append({
                'type': 'WALL_OF_TEXT',
                'severity': 'HIGH',
                'message': f'Found {len(long_paragraphs)} long unstructured paragraphs (10+ lines)',
                'recommendation': 'Break into: bullet lists, tables, or structured sections with bold key terms'
            })

        # Check for lack of visual markers (emojis, bold, tables)
        emoji_count = len(re.findall(r'[\U0001F300-\U0001F9FF]', self.content))
        bold_count = len(re.findall(r'\*\*[^*]+\*\*', self.content))
        table_count = self.content.count('|---|')

        total_lines = len(self.lines)
        markers_per_100_lines = (emoji_count + bold_count + table_count) / max(total_lines / 100, 1)

        if markers_per_100_lines < 5:
            self.anti_patterns.append({
                'type': 'LOW_VISUAL_HIERARCHY',
                'severity': 'MEDIUM',
                'message': f'Low visual markers ({markers_per_100_lines:.1f} per 100 lines)',
                'recommendation': 'Add emojis (📊🎯📈), bold key terms, and tables for scannability'
            })

    def detect_premature_optimization(self):
        """Detect future planning before current status."""
        # Find sections by analyzing header positions
        sections = []
        for i, line in enumerate(self.lines):
            if line.startswith('##'):
                sections.append((i, line.strip()))

        if len(sections) < 3:
            return  # Not enough structure to analyze

        # Check if "Geplant"/"Planned"/"Future" appears before "Aktiv"/"Current"/"In Progress"
        for i, (line_num, header) in enumerate(sections[:10]):  # Check first 10 sections
            if re.search(r'(Geplant|Planned|Future|Coming)', header, re.IGNORECASE):
                # Check if there's an active section after this
                for j in range(i + 1, len(sections)):
                    if re.search(r'(Aktiv|Active|Current|In Progress|Läuft)', sections[j][1], re.IGNORECASE):
                        self.anti_patterns.append({
                            'type': 'PREMATURE_OPTIMIZATION',
                            'severity': 'MEDIUM',
                            'message': f'Future planning (line {line_num}) appears before active work (line {sections[j][0]})',
                            'recommendation': 'Reorder: Active work first, then future planning (collapsed)'
                        })
                        break

    def detect_assumed_context(self):
        """Detect sections that assume prior knowledge."""
        # Look for unexplained acronyms and abbreviations in headers or first mentions
        acronym_pattern = r'\b[A-Z]{2,}[A-Z0-9]*\b'

        # Common technical acronyms that don't need explanation
        common_acronyms = {'API', 'REST', 'HTTP', 'JSON', 'XML', 'SQL', 'CSS', 'HTML',
                          'MVP', 'QA', 'PR', 'CI', 'CD', 'UI', 'UX', 'TTO', 'SCI', 'CLS'}

        acronyms_found = set(re.findall(acronym_pattern, self.content))
        unexplained = acronyms_found - common_acronyms

        # Check if acronyms are explained (pattern: "ABC (Full Name)" or "Full Name (ABC)")
        explained = set()
        for acronym in unexplained:
            # Look for explanation pattern within 100 chars of first occurrence
            first_occurrence = self.content.find(acronym)
            if first_occurrence != -1:
                context = self.content[max(0, first_occurrence - 50):first_occurrence + 100]
                if f'({acronym})' in context or f'{acronym} (' in context:
                    explained.add(acronym)

        truly_unexplained = unexplained - explained

        if truly_unexplained and len(truly_unexplained) > 3:
            self.anti_patterns.append({
                'type': 'ASSUMED_CONTEXT',
                'severity': 'MEDIUM',
                'message': f'Unexplained acronyms: {", ".join(sorted(list(truly_unexplained)[:5]))}',
                'recommendation': 'Define acronyms on first use or add glossary section'
            })

        # Check for task IDs without context (e.g., "D1.4" without explaining what D1 is)
        task_refs = re.findall(r'\b([A-Z]\d+\.\d+)\b', self.content)
        if task_refs:
            # Check if phase is explained
            phases = set(ref.split('.')[0] for ref in task_refs)
            for phase in phases:
                if not re.search(rf'(?:Phase|Sprint|Milestone)\s+{phase}', self.content, re.IGNORECASE):
                    self.anti_patterns.append({
                        'type': 'ASSUMED_CONTEXT',
                        'severity': 'LOW',
                        'message': f'Task references like "{phase}.X" used without phase context',
                        'recommendation': f'Include context: "Task {task_refs[0]} (Phase {phase}: Description)"'
                    })
                    break


def main():
    if len(sys.argv) < 2:
        print("Usage: detect_anti_patterns.py <file_path>")
        sys.exit(1)

    file_path = sys.argv[1]

    if not Path(file_path).exists():
        print(f"Error: File not found: {file_path}")
        sys.exit(1)

    detector = AntiPatternDetector(file_path)
    anti_patterns = detector.detect_all()

    # Print results
    print("=" * 70)
    print("ANTI-PATTERN DETECTION RESULTS")
    print("=" * 70)
    print()

    if not anti_patterns:
        print("✅ No anti-patterns detected! Document follows best practices.")
        print()
        sys.exit(0)

    # Group by severity
    high = [ap for ap in anti_patterns if ap['severity'] == 'HIGH']
    medium = [ap for ap in anti_patterns if ap['severity'] == 'MEDIUM']
    low = [ap for ap in anti_patterns if ap['severity'] == 'LOW']

    for severity, patterns in [('HIGH', high), ('MEDIUM', medium), ('LOW', low)]:
        if not patterns:
            continue

        print(f"{'🔴' if severity == 'HIGH' else '🟡' if severity == 'MEDIUM' else '🟢'} {severity} PRIORITY")
        print("-" * 70)

        for ap in patterns:
            print(f"\n❌ {ap['type']}")
            print(f"   Issue: {ap['message']}")
            print(f"   Fix: {ap['recommendation']}")

        print()

    print("=" * 70)
    print(f"Total issues: {len(anti_patterns)} (High: {len(high)}, Medium: {len(medium)}, Low: {len(low)})")
    print("=" * 70)

    # Exit code based on severity
    if high:
        sys.exit(2)
    elif medium:
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == '__main__':
    main()
