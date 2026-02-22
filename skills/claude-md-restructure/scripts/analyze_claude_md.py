#!/usr/bin/env python3
"""
Analyze CLAUDE.md for size optimization opportunities.

Usage:
    python3 analyze_claude_md.py <path-to-claude-md>
    python3 analyze_claude_md.py CLAUDE.md

Output:
    - Total size in bytes
    - Section breakdown with sizes
    - Decision Log entry count
    - Workflow injection status
    - Optimization recommendations

Exit codes:
    0 = Healthy (<8KB)
    1 = Needs optimization (8-15KB)
    2 = Critical (>15KB)
"""

import sys
import re
from pathlib import Path
from dataclasses import dataclass
from typing import List, Tuple, Optional


@dataclass
class Section:
    """Represents a markdown section."""
    name: str
    level: int  # heading level (1-6)
    start_line: int
    end_line: int
    content: str
    size_bytes: int


@dataclass
class AnalysisResult:
    """Complete analysis of a CLAUDE.md file."""
    file_path: str
    total_bytes: int
    sections: List[Section]
    decision_log_entries: int
    decision_log_bytes: int
    has_workflow_injection: bool
    workflow_injection_bytes: int
    open_questions_resolved: int
    open_questions_active: int
    recommendations: List[str]


def parse_sections(content: str) -> List[Section]:
    """Parse markdown into sections based on headings."""
    lines = content.split('\n')
    sections = []
    current_section = None
    current_start = 0
    current_name = "Preamble"
    current_level = 0

    heading_pattern = re.compile(r'^(#{1,6})\s+(.+)$')

    for i, line in enumerate(lines):
        match = heading_pattern.match(line)
        if match:
            # Save previous section
            if current_start < i:
                section_content = '\n'.join(lines[current_start:i])
                sections.append(Section(
                    name=current_name,
                    level=current_level,
                    start_line=current_start + 1,
                    end_line=i,
                    content=section_content,
                    size_bytes=len(section_content.encode('utf-8'))
                ))

            current_level = len(match.group(1))
            current_name = match.group(2).strip()
            current_start = i

    # Don't forget last section
    if current_start < len(lines):
        section_content = '\n'.join(lines[current_start:])
        sections.append(Section(
            name=current_name,
            level=current_level,
            start_line=current_start + 1,
            end_line=len(lines),
            content=section_content,
            size_bytes=len(section_content.encode('utf-8'))
        ))

    return sections


def count_decision_log_entries(content: str) -> Tuple[int, int]:
    """Count Decision Log entries and estimate bytes."""
    # Look for Decision Log section
    decision_log_match = re.search(
        r'##\s*Decision Log.*?\n(.*?)(?=\n##\s|\n---\s*$|\Z)',
        content,
        re.DOTALL | re.IGNORECASE
    )

    if not decision_log_match:
        return 0, 0

    log_content = decision_log_match.group(1)
    log_bytes = len(log_content.encode('utf-8'))

    # Count table rows (entries)
    # Pattern: | Decision | ... | (table rows, not header/separator)
    table_rows = re.findall(r'^\|[^|]+\|[^|]+\|[^|]+\|[^|]+\|.*\|$', log_content, re.MULTILINE)
    # Exclude header row and separator
    entry_count = max(0, len(table_rows) - 2)

    return entry_count, log_bytes


def detect_workflow_injection(content: str) -> Tuple[bool, int]:
    """Check for workflow-block.txt injection and its size."""
    # Check for injection markers
    begin_marker = '<!-- BEGIN:WORKFLOW-INJECTION'
    end_marker = '<!-- END:WORKFLOW-INJECTION -->'

    if begin_marker in content and end_marker in content:
        start = content.find(begin_marker)
        end = content.find(end_marker) + len(end_marker)
        injection_bytes = end - start
        return True, injection_bytes

    # Check for Session-Continuous Workflow section (legacy/inline)
    workflow_match = re.search(
        r'##\s*Session-Continuous Workflow.*?\n(.*?)(?=\n##\s[^#]|\n---\s*$|\Z)',
        content,
        re.DOTALL | re.IGNORECASE
    )

    if workflow_match:
        workflow_bytes = len(workflow_match.group(0).encode('utf-8'))
        return True, workflow_bytes

    return False, 0


def count_open_questions(content: str) -> Tuple[int, int]:
    """Count resolved vs active open questions."""
    questions_match = re.search(
        r'##\s*Open Questions.*?\n(.*?)(?=\n##\s|\n---\s*$|\Z)',
        content,
        re.DOTALL | re.IGNORECASE
    )

    if not questions_match:
        return 0, 0

    questions_content = questions_match.group(1)

    # Resolved: strikethrough or checkmark
    resolved = len(re.findall(r'~~.+~~|\[x\]|Resolved|resolved|✅', questions_content))

    # Active: bullet points without resolved markers
    all_items = len(re.findall(r'^[\-\*]\s+', questions_content, re.MULTILINE))
    active = max(0, all_items - resolved)

    return resolved, active


def generate_recommendations(result: AnalysisResult) -> List[str]:
    """Generate optimization recommendations based on analysis."""
    recommendations = []

    TARGET_SIZE = 8000

    # Size recommendations
    if result.total_bytes > 15000:
        recommendations.append(
            f"🔴 KRITISCH: Datei ist {result.total_bytes:,} Bytes (Ziel: <8,000). "
            f"Immediate Action: Decision Log auslagern."
        )
    elif result.total_bytes > TARGET_SIZE:
        recommendations.append(
            f"⚠️ Datei ist {result.total_bytes:,} Bytes (Ziel: <8,000). "
            f"Empfehlung: Decision Log auslagern + Progressive Disclosure."
        )
    else:
        recommendations.append(
            f"✅ Datei ist {result.total_bytes:,} Bytes - im Zielbereich."
        )

    # Decision Log recommendations
    if result.decision_log_entries > 10:
        recommendations.append(
            f"📋 Decision Log hat {result.decision_log_entries} Eintraege ({result.decision_log_bytes:,} Bytes). "
            f"Empfehlung: Auslagern nach docs/DECISION-LOG.md"
        )
    elif result.decision_log_entries > 5:
        recommendations.append(
            f"📋 Decision Log hat {result.decision_log_entries} Eintraege. "
            f"Bei >10 Eintraegen: Auslagerung empfohlen."
        )

    # Workflow injection check
    if not result.has_workflow_injection:
        recommendations.append(
            "⚠️ Kein Workflow-Block gefunden. "
            "Falls project-init genutzt: workflow-block.txt sollte injiziert sein."
        )
    else:
        if result.workflow_injection_bytes > 10000:
            recommendations.append(
                f"ℹ️ Workflow-Block ist {result.workflow_injection_bytes:,} Bytes. "
                f"Dies ist normal (Session-Continuous Workflow)."
            )

    # Open Questions
    if result.open_questions_resolved > 3:
        recommendations.append(
            f"📦 {result.open_questions_resolved} resolved Open Questions. "
            f"Empfehlung: In <details> wrappen oder nach Decision Log verschieben."
        )

    # Large sections
    large_sections = [s for s in result.sections if s.size_bytes > 3000 and 'Workflow' not in s.name]
    for section in large_sections:
        recommendations.append(
            f"📏 Section '{section.name}' ist {section.size_bytes:,} Bytes. "
            f"Pruefen auf Auslagerungspotential."
        )

    return recommendations


def analyze_claude_md(file_path: str) -> AnalysisResult:
    """Main analysis function."""
    path = Path(file_path)

    if not path.exists():
        raise FileNotFoundError(f"File not found: {file_path}")

    content = path.read_text(encoding='utf-8')
    total_bytes = len(content.encode('utf-8'))

    sections = parse_sections(content)
    decision_entries, decision_bytes = count_decision_log_entries(content)
    has_workflow, workflow_bytes = detect_workflow_injection(content)
    resolved_q, active_q = count_open_questions(content)

    result = AnalysisResult(
        file_path=str(path),
        total_bytes=total_bytes,
        sections=sections,
        decision_log_entries=decision_entries,
        decision_log_bytes=decision_bytes,
        has_workflow_injection=has_workflow,
        workflow_injection_bytes=workflow_bytes,
        open_questions_resolved=resolved_q,
        open_questions_active=active_q,
        recommendations=[]
    )

    result.recommendations = generate_recommendations(result)

    return result


def print_report(result: AnalysisResult) -> None:
    """Print formatted analysis report."""
    print("=" * 60)
    print("CLAUDE.md ANALYSE REPORT")
    print("=" * 60)
    print(f"\nDatei: {result.file_path}")
    print(f"Groesse: {result.total_bytes:,} Bytes")
    print(f"Ziel: <8,000 Bytes")
    print(f"Delta: {result.total_bytes - 8000:+,} Bytes")

    print("\n" + "-" * 40)
    print("SECTIONS")
    print("-" * 40)

    for section in result.sections:
        size_bar = "█" * min(20, section.size_bytes // 500)
        print(f"  {'#' * section.level} {section.name[:30]:<30} {section.size_bytes:>6,} B  {size_bar}")

    print("\n" + "-" * 40)
    print("KOMPONENTEN")
    print("-" * 40)
    print(f"  Decision Log:        {result.decision_log_entries} Eintraege ({result.decision_log_bytes:,} B)")
    print(f"  Workflow Injection:  {'Ja' if result.has_workflow_injection else 'Nein'} ({result.workflow_injection_bytes:,} B)")
    print(f"  Open Questions:      {result.open_questions_active} aktiv, {result.open_questions_resolved} resolved")

    print("\n" + "-" * 40)
    print("EMPFEHLUNGEN")
    print("-" * 40)
    for rec in result.recommendations:
        print(f"  {rec}")

    print("\n" + "=" * 60)

    # Exit code guidance
    if result.total_bytes > 15000:
        print("Exit Code: 2 (KRITISCH)")
    elif result.total_bytes > 8000:
        print("Exit Code: 1 (Optimierung empfohlen)")
    else:
        print("Exit Code: 0 (Healthy)")


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 analyze_claude_md.py <path-to-claude-md>")
        print("\nExample:")
        print("  python3 analyze_claude_md.py CLAUDE.md")
        print("  python3 analyze_claude_md.py /path/to/project/CLAUDE.md")
        sys.exit(1)

    file_path = sys.argv[1]

    try:
        result = analyze_claude_md(file_path)
        print_report(result)

        # Set exit code
        if result.total_bytes > 15000:
            sys.exit(2)
        elif result.total_bytes > 8000:
            sys.exit(1)
        else:
            sys.exit(0)

    except FileNotFoundError as e:
        print(f"Error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Error analyzing file: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
