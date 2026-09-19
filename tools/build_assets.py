#!/usr/bin/env python3
"""Asset pipeline for The Hollowmere Files.

1. Converts generated PNG art into size-capped JPEGs under assets/img/ (what the
   Flutter app actually bundles; the PNG originals in assets/art/ are the source
   of truth and are not shipped).
2. Composes docs/draft_contact_sheet.png so the visual direction can be reviewed
   in one image.

Run from the repo root: python3 tools/build_assets.py
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
ART = ROOT / "assets" / "art"
OUT = ROOT / "assets" / "img"
DOCS = ROOT / "docs"

# Longest edge per category. Portraits are shown small (avatars/call screens),
# evidence photos are zoomable so they keep more resolution. UI drafts under
# assets/art/ui are review material only and are never bundled.
MAX_EDGE = {
    "portraits": 768,
    "locations": 1280,
    "evidence": 1280,
    "key": 1280,
}

# Not shipped as an in-app asset; tools/install_icons.py turns it into the
# platform launcher icons.
SKIP = {"app_icon"}


def convert_all() -> list[Path]:
    written: list[Path] = []
    for category, max_edge in MAX_EDGE.items():
        src_dir = ART / category
        dst_dir = OUT / category
        dst_dir.mkdir(parents=True, exist_ok=True)
        for src in sorted(src_dir.glob("*.png")):
            if src.stem in SKIP:
                continue
            img = Image.open(src).convert("RGB")
            img.thumbnail((max_edge, max_edge), Image.LANCZOS)
            dst = dst_dir / (src.stem + ".jpg")
            img.save(dst, "JPEG", quality=86, optimize=True, progressive=True)
            written.append(dst)
    return written


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for candidate in (
        "/System/Library/Fonts/Supplemental/Menlo.ttc",
        "/System/Library/Fonts/Menlo.ttc",
        "/System/Library/Fonts/Helvetica.ttc",
    ):
        if Path(candidate).exists():
            return ImageFont.truetype(candidate, size)
    return ImageFont.load_default()


def contact_sheet() -> Path:
    """Three rows: cast, UI drafts, world/evidence. Fixed cell heights, labels."""
    rows = [
        ("CAST", sorted((ART / "portraits").glob("*.png")), 260),
        ("UI DRAFTS", sorted((ART / "ui").glob("*.png")), 520),
        (
            "WORLD & EVIDENCE",
            sorted((ART / "locations").glob("*.png"))
            + sorted((ART / "evidence").glob("*.png"))
            + [ART / "key" / "key_art.png"],
            300,
        ),
    ]
    pad, label_h, title_h = 14, 26, 44
    bg = (10, 12, 14)
    font, title_font = _font(14), _font(22)

    rendered_rows: list[tuple[str, list[tuple[Image.Image, str]]]] = []
    for title, paths, cell_h in rows:
        cells = []
        for p in paths:
            im = Image.open(p).convert("RGB")
            scale = cell_h / im.height
            im = im.resize((max(1, int(im.width * scale)), cell_h), Image.LANCZOS)
            cells.append((im, p.stem))
        rendered_rows.append((title, cells))

    width = max(
        sum(c.width for c, _ in cells) + pad * (len(cells) + 1)
        for _, cells in rendered_rows
    )
    height = sum(
        title_h + cells[0][0].height + label_h + pad for _, cells in rendered_rows
    ) + pad

    sheet = Image.new("RGB", (width, height), bg)
    draw = ImageDraw.Draw(sheet)
    y = pad
    for title, cells in rendered_rows:
        draw.text((pad, y), title, fill=(79, 209, 197), font=title_font)
        y += title_h
        x = pad
        for im, name in cells:
            sheet.paste(im, (x, y))
            draw.text((x, y + im.height + 4), name, fill=(200, 200, 200), font=font)
            x += im.width + pad
        y += cells[0][0].height + label_h + pad

    DOCS.mkdir(exist_ok=True)
    out = DOCS / "draft_contact_sheet.png"
    sheet.save(out, "PNG", optimize=True)
    return out


if __name__ == "__main__":
    files = convert_all()
    total = sum(f.stat().st_size for f in files) / 1e6
    print(f"converted {len(files)} images -> assets/img ({total:.1f} MB)")
    print(f"contact sheet -> {contact_sheet().relative_to(ROOT)}")
    sys.exit(0)
