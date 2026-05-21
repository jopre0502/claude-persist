#!/usr/bin/env python3
"""
Generate a single V2-squircle .ico icon for Claude Code project quickstart.

Writes two files into <PWD>:
  .claude-icon.ico       — multi-resolution ICO (16/32/48/256px)
  .claude-icon.meta.json — parameters used, absolute icon path

Also prints the meta JSON to stdout so orchestrators can parse it with jq.

Usage:
    python quickstart-icon.py --pwd <DIR> --project-id <ID> --symbol <SYM> [--accent <#HEX>]

Available symbols: sparkle, code, search, shield, gear, diamond, layers,
                   lightning, compass, pen, book, puzzle, brain, cloud, terminal
"""

import argparse
import json
import math
import os
import sys
from datetime import datetime, timezone, timedelta

try:
    from PIL import Image, ImageDraw
except ImportError:
    print("ERROR: Pillow not installed. Run: pip install Pillow", file=sys.stderr)
    sys.exit(1)

GENERATOR_VERSION = "1.0.0"

# Claude Code CI Colors
CLAUDE_ORANGE = (212, 114, 74)
CLAUDE_LIGHT = (232, 149, 110)
CLAUDE_DARK = (184, 90, 56)
CLAUDE_CREAM = (245, 230, 211)
WHITE = (255, 255, 255)
DARK_BG = (45, 45, 45)
DARK_SURFACE = (60, 60, 60)


def hex_to_rgb(hex_color: str) -> tuple:
    h = hex_color.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))


def blend_color(c1: tuple, c2: tuple, factor: float) -> tuple:
    return tuple(int(a + (b - a) * factor) for a, b in zip(c1, c2))


def color_alpha(color: tuple, alpha: int) -> tuple:
    return color[:3] + (alpha,)


# ─── Shape Drawing Library ───────────────────────────────────────────

def draw_sparkle(draw, cx, cy, size, color, alpha=255):
    """Claude-signature multi-point sparkle with tapered rays."""
    fill = color_alpha(color, alpha)
    r = size * 0.45
    for angle_deg in [0, 90, 180, 270]:
        a = math.radians(angle_deg)
        tip_x = cx + r * math.cos(a)
        tip_y = cy + r * math.sin(a)
        spread = math.radians(12)
        arm = r * 0.25
        lx = cx + arm * math.cos(a + spread)
        ly = cy + arm * math.sin(a + spread)
        rx = cx + arm * math.cos(a - spread)
        ry = cy + arm * math.sin(a - spread)
        draw.polygon([(tip_x, tip_y), (lx, ly), (cx, cy), (rx, ry)], fill=fill)
    r2 = r * 0.55
    for angle_deg in [45, 135, 225, 315]:
        a = math.radians(angle_deg)
        tip_x = cx + r2 * math.cos(a)
        tip_y = cy + r2 * math.sin(a)
        spread = math.radians(10)
        arm = r2 * 0.2
        lx = cx + arm * math.cos(a + spread)
        ly = cy + arm * math.sin(a + spread)
        rx = cx + arm * math.cos(a - spread)
        ry = cy + arm * math.sin(a - spread)
        draw.polygon([(tip_x, tip_y), (lx, ly), (cx, cy), (rx, ry)], fill=fill)
    dot_r = max(1, int(size * 0.06))
    draw.ellipse([cx - dot_r, cy - dot_r, cx + dot_r, cy + dot_r], fill=fill)


def draw_code_brackets(draw, cx, cy, size, color, alpha=255):
    """Stylized code brackets < / > with dynamic angles."""
    fill = color_alpha(color, alpha)
    w = max(2, int(size * 0.06))
    h = size * 0.35
    gap = size * 0.12
    lx = cx - gap - size * 0.08
    draw.line([(lx - size * 0.15, cy - h * 0.5), (lx, cy)], fill=fill, width=w)
    draw.line([(lx, cy), (lx - size * 0.15, cy + h * 0.5)], fill=fill, width=w)
    rx = cx + gap + size * 0.08
    draw.line([(rx + size * 0.15, cy - h * 0.5), (rx, cy)], fill=fill, width=w)
    draw.line([(rx, cy), (rx + size * 0.15, cy + h * 0.5)], fill=fill, width=w)
    draw.line([(cx + size * 0.06, cy - h * 0.35), (cx - size * 0.06, cy + h * 0.35)],
              fill=fill, width=w)


def draw_search(draw, cx, cy, size, color, alpha=255):
    """Magnifying glass with bold ring."""
    fill = color_alpha(color, alpha)
    w = max(2, int(size * 0.06))
    r = size * 0.18
    gcx, gcy = cx - size * 0.05, cy - size * 0.06
    draw.ellipse([gcx - r, gcy - r, gcx + r, gcy + r], outline=fill, width=w)
    hx = gcx + r * 0.7
    hy = gcy + r * 0.7
    draw.line([(hx, hy), (hx + size * 0.15, hy + size * 0.15)], fill=fill, width=w + 1)
    gr = r * 0.3
    draw.arc([gcx - gr - r * 0.3, gcy - gr - r * 0.3,
              gcx + gr - r * 0.3, gcy + gr - r * 0.3],
             200, 280, fill=color_alpha(WHITE, alpha // 2), width=max(1, w // 2))


def draw_shield(draw, cx, cy, size, color, alpha=255):
    """Security shield with pointed bottom."""
    fill = color_alpha(color, alpha)
    w = size * 0.3
    h = size * 0.38
    points = [
        (cx, cy - h),
        (cx + w, cy - h * 0.6),
        (cx + w, cy + h * 0.1),
        (cx, cy + h),
        (cx - w, cy + h * 0.1),
        (cx - w, cy - h * 0.6),
    ]
    draw.polygon(points, fill=fill)
    inner = [(x * 0.7 + cx * 0.3, y * 0.7 + cy * 0.3) for x, y in points]
    draw.polygon(inner, outline=color_alpha(WHITE, alpha // 3), width=max(1, int(size * 0.02)))


def draw_diamond(draw, cx, cy, size, color, alpha=255):
    """Gem/diamond with facets."""
    fill = color_alpha(color, alpha)
    w = size * 0.25
    h = size * 0.35
    draw.polygon([(cx, cy - h), (cx + w, cy - h * 0.15), (cx - w, cy - h * 0.15)],
                 fill=color_alpha(blend_color(color, WHITE, 0.3), alpha))
    draw.polygon([(cx - w, cy - h * 0.15), (cx + w, cy - h * 0.15), (cx, cy + h)],
                 fill=fill)
    lw = max(1, int(size * 0.015))
    draw.line([(cx, cy - h), (cx, cy + h)], fill=color_alpha(WHITE, alpha // 4), width=lw)
    draw.line([(cx - w, cy - h * 0.15), (cx + w, cy - h * 0.15)],
              fill=color_alpha(WHITE, alpha // 3), width=lw)


def draw_layers(draw, cx, cy, size, color, alpha=255):
    """Stacked layers/pages."""
    w = size * 0.28
    h = size * 0.12
    gap = size * 0.1
    for i, offset_y in enumerate([-gap, 0, gap]):
        a = alpha - i * 30
        c = blend_color(color, WHITE, i * 0.15)
        y = cy + offset_y
        draw.polygon([
            (cx, y - h), (cx + w, y), (cx, y + h), (cx - w, y)
        ], fill=color_alpha(c, a))
        draw.polygon([
            (cx, y - h), (cx + w, y), (cx, y + h), (cx - w, y)
        ], outline=color_alpha(WHITE, a // 3), width=max(1, int(size * 0.01)))


def draw_lightning(draw, cx, cy, size, color, alpha=255):
    """Lightning bolt."""
    fill = color_alpha(color, alpha)
    s = size * 0.4
    points = [
        (cx + s * 0.1, cy - s),
        (cx - s * 0.2, cy - s * 0.05),
        (cx + s * 0.05, cy - s * 0.05),
        (cx - s * 0.1, cy + s),
        (cx + s * 0.2, cy + s * 0.05),
        (cx - s * 0.05, cy + s * 0.05),
    ]
    draw.polygon(points, fill=fill)


def draw_compass(draw, cx, cy, size, color, alpha=255):
    """Compass rose."""
    r = size * 0.3
    w = r * 0.25
    for angle_deg, c in [(0, color), (90, blend_color(color, WHITE, 0.4)),
                          (180, color), (270, blend_color(color, WHITE, 0.4))]:
        a = math.radians(angle_deg)
        tip_x = cx + r * math.cos(a)
        tip_y = cy - r * math.sin(a)
        perp = a + math.pi / 2
        lx = cx + w * math.cos(perp)
        ly = cy - w * math.sin(perp)
        rx = cx - w * math.cos(perp)
        ry = cy + w * math.sin(perp)
        draw.polygon([(tip_x, tip_y), (lx, ly), (rx, ry)], fill=color_alpha(c, alpha))
    dr = max(2, int(size * 0.04))
    draw.ellipse([cx - dr, cy - dr, cx + dr, cy + dr], fill=color_alpha(WHITE, alpha))


def draw_terminal(draw, cx, cy, size, color, alpha=255):
    """Terminal prompt >_ symbol."""
    fill = color_alpha(color, alpha)
    w = max(2, int(size * 0.06))
    s = size * 0.2
    draw.line([(cx - s, cy - s * 0.7), (cx, cy)], fill=fill, width=w)
    draw.line([(cx, cy), (cx - s, cy + s * 0.7)], fill=fill, width=w)
    draw.line([(cx + s * 0.15, cy + s * 0.7), (cx + s, cy + s * 0.7)], fill=fill, width=w)


def draw_gear(draw, cx, cy, size, color, alpha=255):
    """Gear/cog shape."""
    fill = color_alpha(color, alpha)
    outer_r = size * 0.3
    inner_r = size * 0.19
    teeth = 8
    points = []
    for i in range(teeth * 2):
        angle = (math.pi * 2 * i) / (teeth * 2) - math.pi / 2
        r = outer_r if i % 2 == 0 else inner_r
        points.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
    draw.polygon(points, fill=fill)
    hole_r = size * 0.09
    draw.ellipse([cx - hole_r, cy - hole_r, cx + hole_r, cy + hole_r],
                 fill=color_alpha((0, 0, 0), 0))


def draw_pen(draw, cx, cy, size, color, alpha=255):
    """Pen/pencil."""
    fill = color_alpha(color, alpha)
    w = max(2, int(size * 0.05))
    length = size * 0.35
    angle = math.radians(-45)
    tx = cx - length * 0.5 * math.cos(angle)
    ty = cy - length * 0.5 * math.sin(angle)
    bx = cx + length * 0.5 * math.cos(angle)
    by = cy + length * 0.5 * math.sin(angle)
    draw.line([(tx, ty), (bx, by)], fill=fill, width=w + 2)
    tip_len = size * 0.08
    tipx = bx + tip_len * math.cos(angle)
    tipy = by + tip_len * math.sin(angle)
    draw.polygon([(bx - w * 0.4 * math.sin(angle), by + w * 0.4 * math.cos(angle)),
                  (bx + w * 0.4 * math.sin(angle), by - w * 0.4 * math.cos(angle)),
                  (tipx, tipy)], fill=color_alpha(blend_color(color, WHITE, 0.3), alpha))
    draw.line([(bx + size * 0.05, by + size * 0.12), (bx + size * 0.2, by + size * 0.12)],
              fill=color_alpha(color, alpha // 2), width=max(1, w // 2))


def draw_book(draw, cx, cy, size, color, alpha=255):
    """Open book shape."""
    fill = color_alpha(color, alpha)
    w = size * 0.3
    h = size * 0.25
    lw = max(1, int(size * 0.025))
    draw.polygon([(cx, cy - h * 0.3), (cx - w, cy - h), (cx - w, cy + h), (cx, cy + h * 0.5)],
                 fill=fill, outline=color_alpha(WHITE, alpha // 3), width=lw)
    draw.polygon([(cx, cy - h * 0.3), (cx + w, cy - h), (cx + w, cy + h), (cx, cy + h * 0.5)],
                 fill=color_alpha(blend_color(color, WHITE, 0.15), alpha),
                 outline=color_alpha(WHITE, alpha // 3), width=lw)
    draw.line([(cx, cy - h * 0.3), (cx, cy + h * 0.5)],
              fill=color_alpha(WHITE, alpha // 2), width=lw)


def draw_puzzle(draw, cx, cy, size, color, alpha=255):
    """Puzzle piece."""
    fill = color_alpha(color, alpha)
    s = size * 0.2
    tab = s * 0.35
    draw.rounded_rectangle([cx - s, cy - s, cx + s, cy + s],
                           radius=int(s * 0.15), fill=fill)
    draw.ellipse([cx - tab, cy - s - tab, cx + tab, cy - s + tab], fill=fill)
    draw.ellipse([cx + s - tab, cy - tab, cx + s + tab, cy + tab],
                 fill=color_alpha(blend_color(color, (0, 0, 0), 0.3), alpha))


def draw_brain(draw, cx, cy, size, color, alpha=255):
    """Abstract brain/network — AI/ML."""
    fill = color_alpha(color, alpha)
    node_r = max(2, int(size * 0.035))
    lw = max(1, int(size * 0.02))
    nodes = [
        (cx - size * 0.15, cy - size * 0.18),
        (cx + size * 0.12, cy - size * 0.2),
        (cx - size * 0.22, cy + size * 0.02),
        (cx + size * 0.2, cy - size * 0.02),
        (cx - size * 0.08, cy + size * 0.18),
        (cx + size * 0.1, cy + size * 0.15),
        (cx, cy - size * 0.05),
    ]
    connections = [(0, 1), (0, 2), (1, 3), (2, 4), (3, 5), (4, 5), (0, 6), (1, 6), (3, 6), (4, 6)]
    for i, j in connections:
        draw.line([nodes[i], nodes[j]], fill=color_alpha(color, alpha // 2), width=lw)
    for nx, ny in nodes:
        draw.ellipse([nx - node_r, ny - node_r, nx + node_r, ny + node_r], fill=fill)


def draw_cloud(draw, cx, cy, size, color, alpha=255):
    """Cloud shape — DevOps/infra."""
    fill = color_alpha(color, alpha)
    r1 = size * 0.14
    r2 = size * 0.11
    r3 = size * 0.12
    positions = [
        (cx - size * 0.1, cy, r1),
        (cx + size * 0.08, cy - size * 0.02, r1),
        (cx, cy - size * 0.08, r3),
        (cx - size * 0.18, cy + size * 0.02, r2),
        (cx + size * 0.17, cy + size * 0.02, r2),
    ]
    for px, py, r in positions:
        draw.ellipse([px - r, py - r, px + r, py + r], fill=fill)


# Symbol registry
SYMBOLS = {
    'sparkle': draw_sparkle,
    'code': draw_code_brackets,
    'search': draw_search,
    'shield': draw_shield,
    'diamond': draw_diamond,
    'layers': draw_layers,
    'lightning': draw_lightning,
    'compass': draw_compass,
    'terminal': draw_terminal,
    'gear': draw_gear,
    'pen': draw_pen,
    'book': draw_book,
    'puzzle': draw_puzzle,
    'brain': draw_brain,
    'cloud': draw_cloud,
}


# ─── Icon Variant ────────────────────────────────────────────────────

def create_squircle_icon(size, symbol_name, accent, draw_symbol_fn):
    """V2: Bold squircle with accent band, symbol, and starburst decoration."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    margin = size // 12
    corner_r = size // 4

    draw.rounded_rectangle([margin, margin, size - margin, size - margin],
                           radius=corner_r, fill=CLAUDE_ORANGE + (255,))

    band_h = size // 5
    for i in range(band_h):
        alpha = int(40 * (1 - i / band_h))
        y = margin + i
        draw.line([(margin + corner_r // 2, y), (size - margin - corner_r // 2, y)],
                  fill=color_alpha(WHITE, alpha))

    band_y = size - margin - size // 6
    draw.rounded_rectangle([margin, band_y, size - margin, size - margin],
                           radius=corner_r // 2, fill=color_alpha(accent, 230))

    sym_cy = size // 2 - size // 14
    draw_symbol_fn(draw, size // 2, sym_cy, size, WHITE, 245)

    sb_r = size // 8
    sb_x = int(size - margin - sb_r * 1.2)
    sb_y = int(margin + sb_r * 1.2)
    draw_sparkle(draw, sb_x, sb_y, sb_r, CLAUDE_CREAM, 100)

    return img


# ─── IO ──────────────────────────────────────────────────────────────

def save_ico(images_by_size, filepath):
    sizes = sorted(images_by_size.keys())
    base_img = images_by_size[sizes[-1]]
    ico_images = [images_by_size[s] for s in sizes]
    base_img.save(filepath, format='ICO',
                  sizes=[(s, s) for s in sizes],
                  append_images=ico_images[:-1] if len(ico_images) > 1 else [])


# ─── Main ─────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description='Generate a V2-squircle .ico icon for a Claude Code project quickstart.'
    )
    parser.add_argument('--pwd', required=True,
                        help='Project working directory (output target for icon + meta)')
    parser.add_argument('--project-id', required=True,
                        help='Lower-case project identifier, max 30 chars (e.g. "aurena-co-ceo-case")')
    parser.add_argument('--symbol', required=True,
                        help=f'Symbol name. Available: {", ".join(sorted(SYMBOLS.keys()))}')
    parser.add_argument('--accent', default='#D4724A',
                        help='Accent hex color, default #D4724A (Claude Orange)')
    args = parser.parse_args()

    # Validate PWD
    if not os.path.isdir(args.pwd):
        print(f"ERROR: --pwd directory does not exist: {args.pwd}", file=sys.stderr)
        sys.exit(1)

    # Validate symbol
    symbol_name = args.symbol.lower()
    if symbol_name not in SYMBOLS:
        print(f"ERROR: Unknown symbol '{symbol_name}'. Available: {', '.join(sorted(SYMBOLS.keys()))}",
              file=sys.stderr)
        sys.exit(1)

    draw_fn = SYMBOLS[symbol_name]
    accent = hex_to_rgb(args.accent)

    # Output paths (idempotent — overwrite if exists)
    icon_path = os.path.abspath(os.path.join(args.pwd, '.claude-icon.ico'))
    meta_path = os.path.abspath(os.path.join(args.pwd, '.claude-icon.meta.json'))

    # Generate icon at all ICO sizes
    ico_sizes = [16, 32, 48, 256]
    images = {}
    for s in ico_sizes:
        images[s] = create_squircle_icon(s, symbol_name, accent, draw_fn)

    save_ico(images, icon_path)

    # Build meta
    # Use local offset for generated_at (UTC+2 for CET/CEST; adjust if needed)
    tz_offset = timedelta(hours=2)
    now = datetime.now(timezone(tz_offset))
    meta = {
        "accent_color": args.accent,
        "symbol": symbol_name,
        "project_id": args.project_id,
        "icon_path": icon_path,
        "generated_at": now.isoformat(timespec='seconds'),
        "generator_version": GENERATOR_VERSION,
    }

    with open(meta_path, 'w', encoding='utf-8') as f:
        json.dump(meta, f, indent=2, ensure_ascii=False)
        f.write('\n')

    # Single JSON line to stdout for orchestrator
    print(json.dumps(meta))


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
