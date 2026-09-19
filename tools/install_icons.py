#!/usr/bin/env python3
"""Installs assets/art/key/app_icon.png as the Android and iOS launcher icon.

Uses macOS `sips` so no Python imaging dependency is needed. Re-run whenever
the source icon changes:

    python3 tools/install_icons.py
"""
from __future__ import annotations

import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets/art/key/app_icon.png"
ANDROID_RES = ROOT / "android/app/src/main/res"
IOS_ICONSET = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"

ANDROID_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def resize(src: Path, dst: Path, px: int) -> None:
    """Writes a genuine PNG (Xcode rejects JPEG bytes behind a .png name)."""
    dst.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["sips", "-s", "format", "png", "-z", str(px), str(px), str(src),
         "--out", str(dst)],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def install_android() -> int:
    count = 0
    for folder, px in ANDROID_SIZES.items():
        resize(SOURCE, ANDROID_RES / folder / "ic_launcher.png", px)
        count += 1
    return count


def install_ios() -> int:
    contents = json.loads((IOS_ICONSET / "Contents.json").read_text())
    count = 0
    for image in contents["images"]:
        name = image.get("filename")
        if not name:
            continue
        points = float(image["size"].split("x")[0])
        scale = int(image["scale"].rstrip("x"))
        resize(SOURCE, IOS_ICONSET / name, round(points * scale))
        count += 1
    return count


def main() -> int:
    if not SOURCE.exists():
        print(f"missing source icon: {SOURCE}", file=sys.stderr)
        return 1
    if shutil.which("sips") is None:
        print("sips not found; this script requires macOS", file=sys.stderr)
        return 1
    a = install_android()
    i = install_ios()
    print(f"installed {a} Android and {i} iOS launcher icons from {SOURCE.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
