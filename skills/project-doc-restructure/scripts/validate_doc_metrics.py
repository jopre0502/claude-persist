#!/usr/bin/env python3
"""
Validation script for session-continuous documentation metrics.
Calculates TTO, SCI, CLS, and DocDebt scores.
"""

import re
import sys
from datetime import datetime, timedelta
from pathlib import Path


class DocMetricsValidator:
    def __init__(self, file_path):
        self.path = Path(file_path)
        self.content = self.path.read_text(encoding='utf-8')
        self.lines = self.content.split('\n')
        self.metrics = {}

    def validate_all(self):
        """Run all validation checks."""
        self.check_executive_summary()
        self.check_immediate_actions()
        self.check_timestamp()
        self.check_collapsed_sections()
        self.calculate_signal_to_noise()
        self.calculate_health_score()
        return self.metrics

    def check_executive_summary(self):
        """Check if Executive Summary exists in top 100 lines."""
        summary_line = None
        for i, line in enumerate(self.lines[:100]):
            if 'Executive Summary' in line or 'Executive summary' in line:
                summary_line = i
                break

        if summary_line is None:
            self.metrics['executive_summary'] = {
                'found': False,
                'line': None,
                'status': 'ERROR',
                'message': 'Executive Summary missing in top 100 lines'
            }
        elif summary_line > 20:
            self.metrics['executive_summary'] = {
                'found': True,
                'line': summary_line,
                'status': 'WARNING',
                'message': f'Executive Summary too far down (line {summary_line})'
            }
        else:
            self.metrics['executive_summary'] = {
                'found': True,
                'line': summary_line,
                'status': 'OK',
                'message': f'Executive Summary at line {summary_line}'
            }

    def check_immediate_actions(self):
        """Check if Immediate Actions section exists."""
        has_actions = bool(re.search(r'Immediate (Next )?Actions?', self.content, re.IGNORECASE))

        if not has_actions:
            self.metrics['immediate_actions'] = {
                'found': False,
                'status': 'ERROR',
                'message': 'Immediate Next Actions section missing'
            }
        else:
            self.metrics['immediate_actions'] = {
                'found': True,
                'status': 'OK',
                'message': 'Immediate Actions section found'
            }

    def check_timestamp(self):
        """Check if timestamp exists and is recent."""
        match = re.search(r'(?:Letzte Aktualisierung|Last Update|Updated):\s*(\d{4}-\d{2}-\d{2})', self.content)

        if not match:
            self.metrics['timestamp'] = {
                'found': False,
                'age_days': None,
                'status': 'ERROR',
                'message': 'Timestamp missing (format: Letzte Aktualisierung: YYYY-MM-DD)'
            }
        else:
            date_str = match.group(1)
            doc_date = datetime.strptime(date_str, '%Y-%m-%d')
            age = (datetime.now() - doc_date).days

            if age > 30:
                status = 'WARNING'
                message = f'Document outdated (last updated {age} days ago)'
            elif age > 90:
                status = 'ERROR'
                message = f'Document severely outdated ({age} days old)'
            else:
                status = 'OK'
                message = f'Document fresh (updated {age} days ago)'

            self.metrics['timestamp'] = {
                'found': True,
                'age_days': age,
                'status': status,
                'message': message
            }

    def check_collapsed_sections(self):
        """Check if long documents use collapsed sections."""
        line_count = len(self.lines)
        details_count = self.content.count('<details>')

        if line_count > 500 and details_count < 3:
            self.metrics['collapsed_sections'] = {
                'total_lines': line_count,
                'collapsed_count': details_count,
                'status': 'WARNING',
                'message': f'{line_count} lines but only {details_count} collapsed sections. Consider using <details> for completed phases.'
            }
        else:
            self.metrics['collapsed_sections'] = {
                'total_lines': line_count,
                'collapsed_count': details_count,
                'status': 'OK',
                'message': f'{details_count} collapsed sections for {line_count} lines'
            }

    def calculate_signal_to_noise(self):
        """Calculate signal-to-noise ratio for top 50 lines."""
        top_50 = '\n'.join(self.lines[:50])

        # Signal indicators (actionable content)
        signal_patterns = [
            r'^\s*[-*]\s*\[[ x]\]',  # Checkboxes
            r'\*\*(?:Status|Fokus|Next|Aktuell)',  # Bold key terms
            r'^\s*\d+\.',  # Numbered lists
            r'[📊🎯📈🔄⏳✅]',  # Action emojis
        ]

        # Noise indicators
        noise_patterns = [
            r'~~.*~~',  # Strikethrough (outdated)
            r'Coming Soon',  # Empty placeholders
            r'TODO',  # Unfinished sections
        ]

        signal_count = sum(len(re.findall(p, top_50, re.MULTILINE)) for p in signal_patterns)
        noise_count = sum(len(re.findall(p, top_50, re.MULTILINE)) for p in noise_patterns)

        total_chars = len(top_50)
        snr = signal_count / max(total_chars / 100, 1)  # Normalize by 100 chars

        if snr > 0.8:
            status = 'EXCELLENT'
        elif snr > 0.5:
            status = 'OK'
        else:
            status = 'WARNING'

        self.metrics['signal_to_noise'] = {
            'snr': round(snr, 2),
            'signal_count': signal_count,
            'noise_count': noise_count,
            'status': status,
            'message': f'SNR: {snr:.2f} (signal: {signal_count}, noise: {noise_count})'
        }

    def calculate_health_score(self):
        """Calculate overall health score (0-100)."""
        score = 0

        # Executive Summary (25 points)
        if self.metrics['executive_summary']['status'] == 'OK':
            score += 25
        elif self.metrics['executive_summary']['status'] == 'WARNING':
            score += 15

        # Immediate Actions (25 points)
        if self.metrics['immediate_actions']['status'] == 'OK':
            score += 25

        # Timestamp (25 points)
        if self.metrics['timestamp']['found']:
            age = self.metrics['timestamp']['age_days']
            if age <= 7:
                score += 25
            elif age <= 30:
                score += 15
            elif age <= 90:
                score += 5

        # Collapsed Sections (15 points)
        if self.metrics['collapsed_sections']['status'] == 'OK':
            score += 15

        # Signal-to-Noise (10 points)
        if self.metrics['signal_to_noise']['status'] == 'EXCELLENT':
            score += 10
        elif self.metrics['signal_to_noise']['status'] == 'OK':
            score += 5

        if score >= 75:
            status = '🟢 HEALTHY'
        elif score >= 50:
            status = '🟡 NEEDS IMPROVEMENT'
        else:
            status = '🔴 CRITICAL'

        self.metrics['health_score'] = {
            'score': score,
            'status': status,
            'message': f'Overall health: {score}/100'
        }


def main():
    if len(sys.argv) < 2:
        print("Usage: validate_doc_metrics.py <file_path>")
        sys.exit(1)

    file_path = sys.argv[1]

    if not Path(file_path).exists():
        print(f"Error: File not found: {file_path}")
        sys.exit(1)

    validator = DocMetricsValidator(file_path)
    metrics = validator.validate_all()

    # Print results
    print("=" * 60)
    print("DOCUMENTATION HEALTH METRICS")
    print("=" * 60)
    print()

    for key, value in metrics.items():
        if key == 'health_score':
            continue
        print(f"[{value['status']:^7}] {key.replace('_', ' ').title()}")
        print(f"          {value['message']}")
        print()

    print("=" * 60)
    health = metrics['health_score']
    print(f"{health['status']} - {health['message']}")
    print("=" * 60)

    # Exit code based on health score
    if health['score'] >= 75:
        sys.exit(0)
    elif health['score'] >= 50:
        sys.exit(1)
    else:
        sys.exit(2)


if __name__ == '__main__':
    main()
