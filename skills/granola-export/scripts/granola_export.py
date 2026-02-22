#!/usr/bin/env python3
"""
Granola Export Script - Cross-Platform Version
Exportiert Meeting-Transkripte und Notizen aus Granola.ai.

Unterstützt: macOS, Windows, WSL2
"""

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Optional


def get_default_cache_path() -> Path:
    """
    Ermittelt den Granola Cache-Pfad plattformabhängig.

    Pfade:
    - macOS: ~/Library/Application Support/Granola/cache-v3.json
    - Windows: %APPDATA%/Granola/cache-v3.json
    - WSL2: /mnt/c/Users/<USER>/AppData/Roaming/Granola/cache-v3.json
    """
    # 1. Check for explicit environment variable
    if 'GRANOLA_CACHE_PATH' in os.environ:
        return Path(os.environ['GRANOLA_CACHE_PATH'])

    # 2. macOS
    macos_path = Path.home() / "Library/Application Support/Granola/cache-v3.json"
    if macos_path.exists():
        return macos_path

    # 3. Windows native
    if os.name == 'nt':
        appdata = os.environ.get('APPDATA', '')
        if appdata:
            windows_path = Path(appdata) / "Granola/cache-v3.json"
            if windows_path.exists():
                return windows_path

    # 4. WSL2 - Find Windows user with actual Granola cache
    wsl_base = Path("/mnt/c/Users")
    if wsl_base.exists():
        for user_dir in sorted(wsl_base.iterdir(), key=lambda x: x.name):
            if user_dir.is_dir() and not user_dir.name.startswith(('Default', 'Public', '.')):
                wsl_path = user_dir / "AppData/Roaming/Granola/cache-v3.json"
                try:
                    if wsl_path.exists() and wsl_path.stat().st_size > 100:
                        return wsl_path
                except PermissionError:
                    continue

    # 5. Fallback to macOS path (will error with helpful message)
    return macos_path


def load_cache(cache_path: Optional[Path] = None) -> dict:
    """Lädt den Granola Cache mit Double-JSON Handling."""
    if cache_path is None:
        cache_path = get_default_cache_path()

    if not cache_path.exists():
        raise FileNotFoundError(
            f"Granola Cache nicht gefunden: {cache_path}\n\n"
            "Mögliche Ursachen:\n"
            "1. Granola ist nicht installiert\n"
            "2. Noch kein Meeting aufgezeichnet\n"
            "3. Falscher Pfad (nutze --cache-path)\n\n"
            "Hinweis: Setze GRANOLA_CACHE_PATH Umgebungsvariable für custom Pfad."
        )

    with open(cache_path, 'r', encoding='utf-8') as f:
        raw_data = json.load(f)

    if 'cache' not in raw_data:
        raise ValueError("Ungültiges Cache-Format: 'cache' Key fehlt")

    cache_data = json.loads(raw_data['cache'])

    if 'state' not in cache_data:
        raise ValueError("Ungültiges Cache-Format: 'state' Key fehlt")

    return cache_data['state']


def get_meetings(state: dict, limit: Optional[int] = None) -> list:
    """Extrahiert alle Meetings aus dem State."""
    documents = state.get('documents', {})
    meetings = []

    for doc_id, doc in documents.items():
        # Extract attendees from 'people' dict (it's meeting metadata, not a list)
        people_data = doc.get('people', {})
        attendees = []
        if isinstance(people_data, dict):
            # Creator
            creator = people_data.get('creator', {})
            if creator.get('name'):
                attendees.append({'name': creator.get('name'), 'email': creator.get('email')})
            # Attendees list
            for att in people_data.get('attendees', []):
                if att.get('name') or att.get('email'):
                    attendees.append({'name': att.get('name'), 'email': att.get('email')})

        meeting = {
            'id': doc_id,
            'title': doc.get('title') or 'Untitled',
            'created_at': doc.get('created_at'),
            'updated_at': doc.get('updated_at'),
            'notes_markdown': doc.get('notes_markdown'),
            'notes_plain': doc.get('notes_plain'),
            'summary': doc.get('summary'),
            'overview': doc.get('overview'),
            'workspace_id': doc.get('workspace_id'),
            'attendees': attendees,
        }
        meetings.append(meeting)

    meetings.sort(key=lambda x: x.get('created_at') or '1970-01-01', reverse=True)
    return meetings[:limit] if limit else meetings


def get_transcript(state: dict, meeting_id: str) -> Optional[list]:
    """
    Lädt das Transkript für ein Meeting.

    Granola Struktur: transcripts[document_id] = [utterances...]
    Die transcript_id IST die document_id.
    """
    transcripts = state.get('transcripts', {})

    # Direct lookup - transcript key is the document ID
    if meeting_id in transcripts:
        utterances = transcripts[meeting_id]
        return utterances if utterances else None

    return None


def meeting_to_markdown(meeting: dict, transcript: Optional[list] = None) -> str:
    """Konvertiert ein Meeting nach Markdown."""
    lines = [f"# {meeting['title']}", ""]

    # Metadaten
    if meeting.get('created_at'):
        lines.append(f"**Datum:** {meeting['created_at'][:10]}")
    lines.append(f"**ID:** `{meeting['id']}`")

    # Teilnehmer
    if meeting.get('attendees'):
        attendees = meeting['attendees']
        people_str = ", ".join([p.get('name') or p.get('email', 'Unknown') for p in attendees if p.get('name') or p.get('email')])
        if people_str:
            lines.append(f"**Teilnehmer:** {people_str}")

    lines.append("")

    # Summary (AI-generiert)
    if meeting.get('summary'):
        lines.extend(["## Zusammenfassung", "", meeting['summary'], ""])

    # Overview
    if meeting.get('overview'):
        lines.extend(["## Überblick", "", meeting['overview'], ""])

    # Notizen (Markdown-Format bevorzugt)
    notes = meeting.get('notes_markdown') or meeting.get('notes_plain')
    if notes:
        lines.extend(["## Notizen", "", notes, ""])

    # Transkript
    if transcript:
        lines.extend(["## Transkript", ""])
        for utterance in transcript:
            source = utterance.get('source', 'unknown')
            text = utterance.get('text', '').strip()
            timestamp = utterance.get('start_timestamp', '')

            if text:
                speaker = "🎤 Du" if source == 'microphone' else "🔊 Andere"
                if timestamp and len(timestamp) > 11:
                    lines.append(f"**[{timestamp[11:19]}] {speaker}:** {text}")
                else:
                    lines.append(f"**{speaker}:** {text}")
        lines.append("")

    return '\n'.join(lines)


def meeting_to_json(meeting: dict, transcript: Optional[list] = None) -> dict:
    """Konvertiert ein Meeting nach JSON-Format."""
    result = {
        'id': meeting['id'],
        'title': meeting['title'],
        'created_at': meeting.get('created_at'),
        'updated_at': meeting.get('updated_at'),
        'workspace_id': meeting.get('workspace_id'),
        'summary': meeting.get('summary'),
        'overview': meeting.get('overview'),
        'notes_markdown': meeting.get('notes_markdown'),
        'notes_plain': meeting.get('notes_plain'),
        'attendees': meeting.get('attendees', []),
    }

    if transcript:
        result['transcript'] = transcript

    return result


def safe_filename(title: str, max_length: int = 50) -> str:
    """Erzeugt einen sicheren Dateinamen aus dem Titel."""
    safe = ''.join(c if c.isalnum() or c in ' -_' else '' for c in title)
    safe = ' '.join(safe.split())
    return safe[:max_length].strip() or 'untitled'


def export_meetings(
    output_dir: Path,
    limit: Optional[int] = None,
    include_transcripts: bool = True,
    output_format: str = 'markdown',
    cache_path: Optional[Path] = None
) -> list:
    """Exportiert Meetings in das angegebene Verzeichnis."""
    state = load_cache(cache_path)
    meetings = get_meetings(state, limit)
    output_dir.mkdir(parents=True, exist_ok=True)

    exported = []
    for meeting in meetings:
        transcript = get_transcript(state, meeting['id']) if include_transcripts else None
        date_str = (meeting.get('created_at') or 'unknown')[:10]
        safe_title = safe_filename(meeting['title'])

        if output_format == 'json':
            filename = f"{date_str}_{safe_title}.json"
            filepath = output_dir / filename
            content = meeting_to_json(meeting, transcript)
            filepath.write_text(json.dumps(content, indent=2, ensure_ascii=False), encoding='utf-8')
        else:
            filename = f"{date_str}_{safe_title}.md"
            filepath = output_dir / filename
            content = meeting_to_markdown(meeting, transcript)
            filepath.write_text(content, encoding='utf-8')

        exported.append(str(filepath))
        print(f"✓ Exportiert: {filename}")

    return exported


def list_meetings(cache_path: Optional[Path] = None, limit: int = 20) -> list:
    """Listet die letzten Meetings auf und gibt sie als Liste zurück."""
    state = load_cache(cache_path)
    meetings = get_meetings(state, limit)

    print(f"\n{'='*60}")
    print(f"Letzte {len(meetings)} Meetings:")
    print(f"{'='*60}\n")

    for i, meeting in enumerate(meetings, 1):
        date_str = (meeting.get('created_at') or 'Unbekannt')[:10]
        title = (meeting.get('title') or 'Untitled')[:40]
        has_transcript = get_transcript(state, meeting['id']) is not None
        transcript_icon = "📝" if has_transcript else "  "
        print(f"{i:3}. {transcript_icon} [{date_str}] {title}")

    print(f"\n📝 = Transkript vorhanden")
    return meetings


def get_meeting_content(meeting_id: str, cache_path: Optional[Path] = None) -> str:
    """Holt den Inhalt eines einzelnen Meetings als Markdown (für Claude-Integration)."""
    state = load_cache(cache_path)
    documents = state.get('documents', {})

    if meeting_id not in documents:
        raise ValueError(f"Meeting nicht gefunden: {meeting_id}")

    doc = documents[meeting_id]
    meeting = {
        'id': meeting_id,
        'title': doc.get('title') or 'Untitled',
        'created_at': doc.get('created_at'),
        'updated_at': doc.get('updated_at'),
        'notes_markdown': doc.get('notes_markdown'),
        'notes_plain': doc.get('notes_plain'),
        'summary': doc.get('summary'),
        'overview': doc.get('overview'),
        'workspace_id': doc.get('workspace_id'),
        'attendees': attendees,
    }

    transcript = get_transcript(state, meeting_id)
    return meeting_to_markdown(meeting, transcript)


def main():
    parser = argparse.ArgumentParser(
        description='Exportiert Granola Meeting-Daten (Cross-Platform)',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Beispiele:
  %(prog)s --list                          # Meetings auflisten
  %(prog)s --output ./meetings             # Alle Meetings exportieren
  %(prog)s --output ./meetings --limit 10  # Letzte 10 Meetings
  %(prog)s --output ./meetings --format json
  %(prog)s --get <meeting-id>              # Einzelnes Meeting anzeigen

Umgebungsvariablen:
  GRANOLA_CACHE_PATH    Pfad zur cache-v3.json (optional)
        """
    )

    parser.add_argument('--output', '-o', type=Path, help='Ausgabeverzeichnis')
    parser.add_argument('--limit', '-n', type=int, help='Maximale Anzahl')
    parser.add_argument('--format', '-f', choices=['markdown', 'json'], default='markdown')
    parser.add_argument('--no-transcripts', action='store_true')
    parser.add_argument('--list', '-l', action='store_true', help='Meetings auflisten')
    parser.add_argument('--get', '-g', type=str, help='Einzelnes Meeting abrufen (ID)')
    parser.add_argument('--cache-path', type=Path, help='Custom Cache-Pfad')
    parser.add_argument('--show-path', action='store_true', help='Cache-Pfad anzeigen')

    args = parser.parse_args()

    try:
        if args.show_path:
            path = args.cache_path or get_default_cache_path()
            exists = "✓" if path.exists() else "✗"
            print(f"{exists} {path}")
            sys.exit(0 if path.exists() else 1)

        if args.get:
            print(get_meeting_content(args.get, args.cache_path))
        elif args.list:
            list_meetings(args.cache_path, args.limit or 20)
        elif args.output:
            exported = export_meetings(
                output_dir=args.output,
                limit=args.limit,
                include_transcripts=not args.no_transcripts,
                output_format=args.format,
                cache_path=args.cache_path
            )
            print(f"\n✅ {len(exported)} Meeting(s) exportiert nach: {args.output}")
        else:
            parser.print_help()
            sys.exit(1)

    except FileNotFoundError as e:
        print(f"❌ Fehler: {e}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"❌ Cache-Parsing fehlgeschlagen: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"❌ Unerwarteter Fehler: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
