#!/usr/bin/env python3
"""Download licensed music and radio-static bridges from the public internet.

Spoken interstitial lines are story quotes, built by tools/build_audio.py
--whispers, not downloaded. Sources here are CC0 (OpenGameArt) or the Mixkit
License (free for commercial use, attribution optional).

Run from the repo root: python3 tools/fetch_audio.py
Requires ffmpeg.
"""
from __future__ import annotations

import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "audio"
UA = "HollowmereFiles/0.1 (game asset fetch; +https://opengameart.org)"

# dest stem without extension -> (url, ffmpeg extra args)
ASSETS: dict[str, tuple[str, list[str]]] = {
    # Music — actual scored pieces, not pads/drones.
    "music_menu": (
        "https://opengameart.org/sites/default/files/solopiano4.ogg",
        ["-b:a", "96k"],
    ),
    "music_play": (
        "https://assets.mixkit.co/music/671/671.mp3",
        ["-b:a", "96k"],
    ),
    "music_scene": (
        "https://opengameart.org/sites/default/files/GoshtPiano2.ogg",
        ["-b:a", "96k"],
    ),
    "music_echoes": (
        "https://assets.mixkit.co/music/188/188.mp3",
        ["-b:a", "96k"],
    ),
    # Phone-static bridges between beats (Mixkit License). No spoken words.
    "voice_radio": (
        "https://assets.mixkit.co/active_storage/sfx/2566/2566-preview.mp3",
        ["-t", "5.5", "-b:a", "64k", "-ac", "1"],
    ),
    "voice_static": (
        "https://assets.mixkit.co/active_storage/sfx/2563/2563-preview.mp3",
        ["-b:a", "64k", "-ac", "1"],
    ),
}


def download(url: str, dest: Path) -> None:
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=60) as resp, dest.open("wb") as out:
        out.write(resp.read())
    if dest.stat().st_size < 2000:
        raise RuntimeError(f"tiny download ({dest.stat().st_size} B) from {url}")


def transcode(src: Path, dest: Path, extra: list[str]) -> None:
    cmd = [
        "ffmpeg", "-y", "-loglevel", "error", "-i", str(src),
        "-c:a", "aac", "-ar", "44100", *extra, str(dest),
    ]
    subprocess.run(cmd, check=True)
    if not dest.exists() or dest.stat().st_size < 1000:
        raise RuntimeError(f"transcode produced empty file {dest}")


def main() -> int:
    if subprocess.run(["ffmpeg", "-version"], capture_output=True).returncode != 0:
        print("ffmpeg is required", file=sys.stderr)
        return 1
    OUT.mkdir(parents=True, exist_ok=True)
    old_bed = OUT / "music_bed.m4a"
    with tempfile.TemporaryDirectory(prefix="hm-audio-") as tmp:
        tmp_dir = Path(tmp)
        for name, (url, extra) in ASSETS.items():
            raw = tmp_dir / name
            print(f"fetch {name}", flush=True)
            download(url, raw)
            transcode(raw, OUT / f"{name}.m4a", extra)
    if old_bed.exists():
        old_bed.unlink()
        print("removed music_bed.m4a (drone)")
    print(f"wrote {len(ASSETS)} files -> {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
