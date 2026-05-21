#!/usr/bin/env python3
"""
quickstart-wt-profile.py
Fuegt ein Windows Terminal Profil fuer ein Claude-Projekt zur settings.json hinzu.

Exit-Codes:
  0  Erfolg
  1  Allgemeiner Fehler (JSON-Parse, IO, Restore)
  2  Profil existiert bereits (ohne --force) -> Orchestrator fragt User
  3  Ungueltige Argumente (Pfad nicht gefunden etc.)
"""

import argparse
import json
import os
import sys
import uuid
from datetime import datetime
from pathlib import Path


def normalize_windows_path(path_str: str) -> str:
    """Normalisiert einen Pfad auf Windows-Backslash-Trenner."""
    return str(Path(path_str)).replace("/", "\\")


def build_profile(project_name: str, pwd: str, tab_color: str,
                  icon_path: str, pwsh_path: str, existing_guid: str = None) -> dict:
    """Baut den WT-Profil-Block. Behaelt existing_guid wenn angegeben."""
    # Windows-Pfade normalisieren
    pwd_win = normalize_windows_path(pwd)
    icon_win = normalize_windows_path(icon_path)
    pwsh_win = normalize_windows_path(pwsh_path)

    # commandline: Single-Quotes um PWD, doppelte Backslashes (durch JSON-Dump automatisch)
    commandline = f"{pwsh_win} -NoExit -Command \"Set-Location '{pwd_win}'; claude\""

    # GUID: existierende behalten (overwrite) oder neue generieren
    guid = existing_guid if existing_guid else "{" + str(uuid.uuid4()) + "}"

    return {
        "commandline": commandline,
        "guid": guid,
        "icon": icon_win,
        "name": project_name,
        "suppressApplicationTitle": True,
        "tabColor": tab_color,
        "tabTitle": project_name,
    }


def parse_args():
    parser = argparse.ArgumentParser(
        description="Fuegt ein Windows Terminal Profil fuer ein Claude-Projekt hinzu."
    )
    parser.add_argument("--settings", required=True,
                        help="Pfad zur WT settings.json")
    parser.add_argument("--project-name", required=True,
                        help="Projektname (wird name + tabTitle)")
    parser.add_argument("--pwd", required=True,
                        help="Projekt-Working-Directory fuer Set-Location")
    parser.add_argument("--tab-color", required=True,
                        help="Tab-Color als #HEX")
    parser.add_argument("--icon-path", required=True,
                        help="Absoluter Pfad zum .claude-icon.ico")
    parser.add_argument("--pwsh-path", default=None,
                        help="Pfad zu pwsh.exe (optional, Default via LOCALAPPDATA)")
    parser.add_argument("--force", action="store_true",
                        help="Ueberschreibe existierendes Profil mit gleichem Namen")
    return parser.parse_args()


def resolve_pwsh_path(pwsh_path_arg) -> str:
    """Loest den pwsh-Pfad auf: Argument > LOCALAPPDATA > Fallback."""
    if pwsh_path_arg:
        return pwsh_path_arg
    localappdata = os.environ.get("LOCALAPPDATA", "")
    if localappdata:
        return os.path.join(localappdata, "Microsoft", "WindowsApps", "pwsh.exe")
    # Fallback
    return "C:\\Users\\Jonas\\AppData\\Local\\Microsoft\\WindowsApps\\pwsh.exe"


def validate_args(args) -> int:
    """Validiert Argumente. Gibt Exit-Code zurueck (0 = OK, 3 = Fehler)."""
    settings_path = Path(args.settings)
    if not settings_path.exists():
        print(f"ERROR: settings.json nicht gefunden: {args.settings}", file=sys.stderr)
        return 3
    if not settings_path.is_file():
        print(f"ERROR: settings-Pfad ist kein File: {args.settings}", file=sys.stderr)
        return 3

    tab_color = args.tab_color
    if not tab_color.startswith("#") or len(tab_color) not in (4, 7):
        print(f"ERROR: tab-color muss #HEX Format haben (z.B. #F8C379): {tab_color}",
              file=sys.stderr)
        return 3

    return 0


def main():
    args = parse_args()

    # --- Argumente validieren ---
    rc = validate_args(args)
    if rc != 0:
        sys.exit(rc)

    settings_path = Path(args.settings)
    pwsh_path = resolve_pwsh_path(args.pwsh_path)

    # --- a) JSON lesen + validieren ---
    try:
        raw_content = settings_path.read_text(encoding="utf-8")
    except OSError as e:
        print(f"ERROR: Konnte settings.json nicht lesen: {e}", file=sys.stderr)
        sys.exit(1)

    try:
        data = json.loads(raw_content)
    except json.JSONDecodeError as e:
        print(f"ERROR: settings.json ist kein valides JSON: {e}", file=sys.stderr)
        sys.exit(1)

    # --- b) Timestamped Backup schreiben ---
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup_path = settings_path.parent / f"{settings_path.name}.bak.{timestamp}"
    try:
        backup_path.write_text(raw_content, encoding="utf-8")
    except OSError as e:
        print(f"ERROR: Konnte Backup nicht schreiben nach {backup_path}: {e}",
              file=sys.stderr)
        sys.exit(1)

    # --- c) Profil-Liste finden und nach existierendem Profil suchen ---
    profiles_section = data.get("profiles", {})
    if isinstance(profiles_section, dict):
        profiles_list = profiles_section.get("list", [])
    else:
        # Manche alten WT-Versionen haben profiles direkt als Liste
        profiles_list = profiles_section if isinstance(profiles_section, list) else []

    existing_index = None
    existing_guid = None
    for i, profile in enumerate(profiles_list):
        if isinstance(profile, dict) and profile.get("name") == args.project_name:
            existing_index = i
            existing_guid = profile.get("guid")
            break

    action = None

    if existing_index is not None:
        # Profil existiert bereits
        if not args.force:
            print(f"PROFILE_EXISTS:{args.project_name}", file=sys.stderr)
            sys.exit(2)
        # --force: In-Place ersetzen, alte GUID behalten
        new_profile = build_profile(
            project_name=args.project_name,
            pwd=args.pwd,
            tab_color=args.tab_color,
            icon_path=args.icon_path,
            pwsh_path=pwsh_path,
            existing_guid=existing_guid,
        )
        profiles_list[existing_index] = new_profile
        action = "overwritten"
    else:
        # Neues Profil anhaengen
        new_profile = build_profile(
            project_name=args.project_name,
            pwd=args.pwd,
            tab_color=args.tab_color,
            icon_path=args.icon_path,
            pwsh_path=pwsh_path,
        )
        profiles_list.append(new_profile)
        action = "inserted"

    # Profil-Liste zurueck in data schreiben
    if isinstance(data.get("profiles"), dict):
        data["profiles"]["list"] = profiles_list
    else:
        data["profiles"] = profiles_list

    # --- f) settings.json zurueckschreiben mit indent=4 ---
    try:
        new_content = json.dumps(data, indent=4, ensure_ascii=False)
        settings_path.write_text(new_content, encoding="utf-8")
    except OSError as e:
        print(f"ERROR: Konnte settings.json nicht schreiben: {e}", file=sys.stderr)
        # Restore aus Backup
        try:
            settings_path.write_text(raw_content, encoding="utf-8")
            print("INFO: Original aus Backup wiederhergestellt.", file=sys.stderr)
        except OSError as restore_err:
            print(f"CRITICAL: Restore fehlgeschlagen: {restore_err}", file=sys.stderr)
        sys.exit(1)

    # --- g) Sanity-Check: erneut json.load() ---
    try:
        verify_content = settings_path.read_text(encoding="utf-8")
        json.loads(verify_content)
    except (json.JSONDecodeError, OSError) as e:
        print(f"ERROR: Sanity-Check fehlgeschlagen nach Schreiben: {e}", file=sys.stderr)
        # Restore aus Backup
        try:
            settings_path.write_text(raw_content, encoding="utf-8")
            print("INFO: Original aus Backup wiederhergestellt.", file=sys.stderr)
        except OSError as restore_err:
            print(f"CRITICAL: Restore fehlgeschlagen: {restore_err}", file=sys.stderr)
        sys.exit(1)

    # --- Erfolg: JSON-Output ---
    result = {
        "status": "ok",
        "action": action,
        "profile_name": args.project_name,
        "guid": new_profile["guid"],
        "backup_path": str(backup_path.name),
    }
    print(json.dumps(result, indent=2))
    sys.exit(0)


if __name__ == "__main__":
    main()
