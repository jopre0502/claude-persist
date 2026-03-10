#!/usr/bin/env python3
"""
Template Renderer für Style 1 & 2
Nutzt Jinja2 um content.json zu HTML zu rendern

Usage:
    python render.py <content.json> <output.html> [--style 1|2]
"""

import json
import sys
from pathlib import Path
from jinja2 import Environment, FileSystemLoader, select_autoescape

def render_text(content):
    """Rendert Text-Section"""
    html = []

    if 'text' in content:
        html.append(f"<p>{content['text']}</p>")

    if 'highlight' in content:
        html.append(f"<p><strong>Wichtig:</strong> {content['highlight']}</p>")

    if 'points' in content:
        html.append("<ul>")
        for point in content['points']:
            html.append(f"<li>{point}</li>")
        html.append("</ul>")

    if 'steps' in content:
        html.append("<ol>")
        for step in content['steps']:
            if isinstance(step, dict):
                html.append(f"<li><strong>{step.get('title', '')}:</strong> {step.get('description', '')}</li>")
            else:
                html.append(f"<li>{step}</li>")
        html.append("</ol>")

    return '\n'.join(html)

def render_comparison_table(content):
    """Rendert Vergleichstabelle"""
    html = []

    if 'caption' in content:
        html.append(f"<p class='caption'>{content['caption']}</p>")

    html.append("<table>")
    html.append("<thead><tr>")

    for header in content.get('headers', []):
        html.append(f"<th>{header}</th>")

    html.append("</tr></thead>")
    html.append("<tbody>")

    for row in content.get('rows', []):
        html.append("<tr>")
        for cell in row:
            html.append(f"<td>{cell}</td>")
        html.append("</tr>")

    html.append("</tbody></table>")

    return '\n'.join(html)

def render_icon_grid(content):
    """Rendert Icon-Grid"""
    html = []

    if 'caption' in content:
        html.append(f"<p class='caption'>{content['caption']}</p>")

    html.append("<div class='icon-grid'>")

    for item in content.get('items', []):
        icon = item.get('icon', 'circle')
        label = item.get('label', '')
        description = item.get('description', '')

        html.append("<div class='icon-card'>")
        html.append(f"<i data-lucide='{icon}'></i>")
        html.append(f"<h3>{label}</h3>")
        html.append(f"<p>{description}</p>")
        html.append("</div>")

    html.append("</div>")

    return '\n'.join(html)

def render_smartart(content):
    """Rendert SmartArt - Placeholder für MVP"""
    smartart_type = content.get('smartartType', '')
    caption = content.get('caption', '')

    # TODO: SmartArt SVG-Generation implementieren
    # Für jetzt: Placeholder
    return f"<p>[SmartArt: {smartart_type} - {caption}]</p>"

def main():
    if len(sys.argv) < 3:
        print("Usage: python render.py <content.json> <output.html> [--style 1|2]")
        sys.exit(1)

    content_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])

    # Style aus Argumenten oder content.json
    style = 1
    if '--style' in sys.argv:
        idx = sys.argv.index('--style')
        if idx + 1 < len(sys.argv):
            style = int(sys.argv[idx + 1])

    # Content.json laden
    with open(content_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Style aus content.json überschreiben wenn vorhanden
    if 'visualProfile' in data and 'creativityLevel' in data['visualProfile']:
        creativity_level = data['visualProfile']['creativityLevel']
        if creativity_level in [1, 2]:
            style = creativity_level

    # Jinja2 Environment erstellen
    # scripts/ -> Plugin-Root -> resources/templates/
    template_dir = Path(__file__).parent.parent / 'resources' / 'templates'
    env = Environment(
        loader=FileSystemLoader(template_dir),
        autoescape=select_autoescape(['html', 'xml'])
    )

    # Helper-Funktionen registrieren
    env.globals['render_text'] = render_text
    env.globals['render_comparison_table'] = render_comparison_table
    env.globals['render_icon_grid'] = render_icon_grid
    env.globals['render_smartart'] = render_smartart

    # Template laden
    template_file = f"style{style}.html.j2"
    template = env.get_template(template_file)

    # Navigation-Konfiguration vorbereiten
    navigation_config = data.get('visualProfile', {}).get('navigation', {})

    # Sections-Liste für Navigation vorbereiten
    sections = data.get('sections', [])
    for idx, section in enumerate(sections):
        if 'id' not in section:
            section['id'] = f"section-{idx}"

    # Render-Kontext erweitern
    render_context = {
        **data,
        'navigation_config': navigation_config if navigation_config else None,
        'sections': sections
    }

    # Rendern
    html = template.render(**render_context)

    # Schreiben
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(html)

    print(f"✅ HTML generiert: {output_path}")
    print(f"   Template: {template_file}")
    print(f"   Sections: {len(data.get('sections', []))}")
    if navigation_config:
        nav_features = []
        if navigation_config.get('pageCounter', {}).get('enabled'):
            nav_features.append('Page Counter')
        if navigation_config.get('sidebarNav', {}).get('enabled'):
            nav_features.append('Sidebar Navigation')
        if nav_features:
            print(f"   Navigation: {', '.join(nav_features)}")

if __name__ == '__main__':
    main()
