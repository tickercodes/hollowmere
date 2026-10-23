#!/usr/bin/env python3
"""Synthesises every sound effect and placeholder voicemail for the game.

Pure standard library (wave/math/random) so it runs anywhere. Output is written
to assets/audio/*.wav, then transcoded to .m4a with afconvert or ffmpeg when
available (the Flutter app loads .m4a; falls back to .wav).

Voicemail speech uses macOS `say` as a placeholder for real voice acting. The
mixing code keeps the story-critical background cues (water, two-tone siren,
buoy bell) at fixed timestamps that the Audio Forensics mini-game references.

Licensed music and radio static come from the internet:
python3 tools/fetch_audio.py

Story whispers (exact lines from voicemails and Wren's last message) are
built here with the same macOS `say` voices as the placeholder voicemails:
python3 tools/build_audio.py --whispers

Run from the repo root: python3 tools/build_audio.py
"""
from __future__ import annotations

import math
import random
import shutil
import struct
import subprocess
import sys
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "audio"
SR = 22050
random.seed(7)

Samples = list[float]

# macOS `say` placeholders until real VO ships. Flo/Shelley read more naturally
VOICE_WREN = "Flo (English (US))"
VOICE_MARA = "Shelley (English (US))"
VOICE_ARDIS = "Moira"


# ---------------------------------------------------------------- primitives
def silence(seconds: float) -> Samples:
    return [0.0] * int(SR * seconds)


def sine(freq: float, seconds: float, amp: float = 0.5, phase: float = 0.0) -> Samples:
    n = int(SR * seconds)
    w = 2 * math.pi * freq / SR
    return [amp * math.sin(w * i + phase) for i in range(n)]


def noise(seconds: float, amp: float = 0.5) -> Samples:
    return [amp * (random.random() * 2 - 1) for _ in range(int(SR * seconds))]


def lowpass(x: Samples, cutoff: float) -> Samples:
    rc = 1.0 / (2 * math.pi * cutoff)
    dt = 1.0 / SR
    a = dt / (rc + dt)
    y, prev = [], 0.0
    for s in x:
        prev = prev + a * (s - prev)
        y.append(prev)
    return y


def highpass(x: Samples, cutoff: float) -> Samples:
    low = lowpass(x, cutoff)
    return [s - l for s, l in zip(x, low)]


def envelope(x: Samples, attack: float, release: float) -> Samples:
    n = len(x)
    a = max(1, int(SR * attack))
    r = max(1, int(SR * release))
    out = list(x)
    for i in range(min(a, n)):
        out[i] *= i / a
    for i in range(min(r, n)):
        out[n - 1 - i] *= i / r
    return out


def decay(x: Samples, tau: float) -> Samples:
    return [s * math.exp(-i / (SR * tau)) for i, s in enumerate(x)]


def mix(*layers: Samples) -> Samples:
    n = max(len(l) for l in layers)
    out = [0.0] * n
    for l in layers:
        for i, s in enumerate(l):
            out[i] += s
    return out


def place(base: Samples, clip: Samples, at: float) -> Samples:
    start = int(SR * at)
    end = start + len(clip)
    out = list(base) + [0.0] * max(0, end - len(base))
    for i, s in enumerate(clip):
        out[start + i] += s
    return out


def gain(x: Samples, g: float) -> Samples:
    return [s * g for s in x]


def normalise(x: Samples, peak: float = 0.9) -> Samples:
    m = max(1e-9, max(abs(s) for s in x))
    return [s * peak / m for s in x]


def write_wav(name: str, x: Samples) -> Path:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / f"{name}.wav"
    clipped = [max(-1.0, min(1.0, s)) for s in x]
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(s * 32767)) for s in clipped))
    return path


# ------------------------------------------------------------------- sounds
def water(seconds: float, amp: float = 0.35) -> Samples:
    """Reservoir lapping: band-limited noise with slow amplitude swell."""
    base = lowpass(highpass(noise(seconds, 1.0), 120), 900)
    return [
        amp * s * (0.6 + 0.4 * math.sin(2 * math.pi * 0.23 * i / SR))
        for i, s in enumerate(base)
    ]


def siren_two_tone(cycles: int = 3) -> Samples:
    """The spillway release warning: alternating 660/880 Hz, 0.45 s each."""
    out: Samples = []
    for _ in range(cycles):
        out += envelope(sine(660, 0.45, 0.5), 0.01, 0.03)
        out += envelope(sine(880, 0.45, 0.5), 0.01, 0.03)
    return out


def bell_clang() -> Samples:
    """Decommissioned buoy bell: inharmonic partials, long decay."""
    partials = [(392, 1.0), (587, 0.6), (784, 0.35), (1046, 0.25), (1568, 0.12)]
    layers = [decay(sine(f, 3.0, 0.5 * a), 0.9 + 0.3 * a) for f, a in partials]
    strike = decay(lowpass(noise(0.05, 0.8), 3000), 0.01)
    return envelope(mix(place(mix(*layers), strike, 0.0)), 0.002, 0.2)


def car_door() -> Samples:
    thud = decay(lowpass(noise(0.25, 1.0), 180), 0.06)
    latch = decay(highpass(noise(0.04, 0.6), 2000), 0.01)
    return place(thud, latch, 0.03)


def message_in() -> Samples:
    return mix(envelope(sine(1046, 0.12, 0.4), 0.005, 0.05),
               place(silence(0.12), envelope(sine(1318, 0.16, 0.35), 0.005, 0.08), 0.11))


def message_out() -> Samples:
    return envelope(sine(880, 0.09, 0.3), 0.005, 0.05)


def notification() -> Samples:
    return mix(envelope(sine(1568, 0.08, 0.35), 0.003, 0.04),
               place(silence(0.08), envelope(sine(2093, 0.18, 0.3), 0.003, 0.12), 0.08))


def glitch() -> Samples:
    """Mirror instability: gated digital noise bursts with a pitch drop."""
    out = silence(0.6)
    for k in range(7):
        burst = highpass(noise(0.03 + 0.01 * (k % 3), 0.7), 800 + 300 * k)
        out = place(out, burst, 0.05 * k + random.random() * 0.02)
    sweep = [0.3 * math.sin(2 * math.pi * (1200 - 1000 * i / (SR * 0.5)) * i / SR)
             for i in range(int(SR * 0.5))]
    return envelope(mix(out, decay(sweep, 0.3)), 0.001, 0.05)


def tap() -> Samples:
    return decay(lowpass(noise(0.03, 0.6), 2500), 0.008)


def unlock() -> Samples:
    out = silence(0.5)
    for i, f in enumerate((523, 659, 784, 1046)):
        out = place(out, envelope(sine(f, 0.14, 0.3), 0.005, 0.08), 0.09 * i)
    return out


def error() -> Samples:
    return mix(envelope(sine(220, 0.22, 0.35), 0.005, 0.1),
               envelope(sine(233, 0.22, 0.25), 0.005, 0.1))


def ringtone() -> Samples:
    out = silence(3.0)
    for k in range(2):
        for i in range(4):
            out = place(out, envelope(sine(1200 + (i % 2) * 200, 0.12, 0.35), 0.005, 0.05),
                        k * 1.6 + i * 0.16)
    return out


def hum(seconds: float) -> Samples:
    return gain(mix(sine(50, seconds, 0.12), sine(100, seconds, 0.05),
                    lowpass(noise(seconds, 0.15), 300)), 0.6)


def pin_success() -> Samples:
    return mix(unlock(), place(silence(0.4), envelope(sine(1568, 0.3, 0.2), 0.01, 0.2), 0.36))


# --------------------------------------------------------------- voicemails
def say_to_samples(text: str, voice: str, rate: int = 175) -> Samples:
    """macOS TTS placeholder. Returns silence of a plausible length elsewhere."""
    if shutil.which("say") is None:
        return silence(0.4 * max(1, len(text.split())))
    tmp_aiff = OUT / "_tts.aiff"
    tmp_wav = OUT / "_tts.wav"
    subprocess.run(["say", "-v", voice, "-r", str(rate), "-o", str(tmp_aiff), text],
                   check=True)
    subprocess.run(["afconvert", "-f", "WAVE", "-d", f"LEI16@{SR}", "-c", "1",
                    str(tmp_aiff), str(tmp_wav)], check=True)
    with wave.open(str(tmp_wav), "rb") as w:
        frames = w.readframes(w.getnframes())
    tmp_aiff.unlink(missing_ok=True)
    tmp_wav.unlink(missing_ok=True)
    return [s / 32768 for s in struct.unpack(f"<{len(frames) // 2}h", frames)]


def phone_line(x: Samples) -> Samples:
    """Make TTS sound like a voicemail: band-limit and add faint hiss."""
    voice = lowpass(highpass(x, 300), 3400)
    return mix(gain(voice, 0.9), lowpass(noise(len(x) / SR, 0.02), 4000))


def voicemail_wren_47s() -> Samples:
    """Ep1 key evidence. Timeline (seconds) referenced by the mini-game:
    0-47 water; 6.0 Wren speaks; 23.0 two-tone siren; 31.5 buoy bell;
    44.0 car door; 46.2 line cut.
    """
    bed = water(47.0, 0.28)
    speech = phone_line(say_to_samples(
        "Jonah. Jonah, I found it. I found the box. It's exactly where he said. "
        "The grids were right, all of them. I'm at the... wait.", VOICE_WREN, 168))
    bed = place(bed, gain(speech, 0.8), 6.0)
    bed = place(bed, gain(siren_two_tone(3), 0.45), 23.0)
    bed = place(bed, gain(bell_clang(), 0.5), 31.5)
    whisper = phone_line(say_to_samples("Someone's here.", VOICE_WREN, 150))
    bed = place(bed, gain(whisper, 0.55), 39.0)
    bed = place(bed, gain(car_door(), 0.8), 44.0)
    cut = decay(highpass(noise(0.15, 0.5), 1500), 0.03)
    bed = place(bed, cut, 46.2)
    return normalise(bed[: int(SR * 47.0)], 0.85)


# Exact phrases from the scripts. Played between scenes as leaked backup audio.
# (id, spoken text, macOS voice, rate)
STORY_WHISPERS = [
    ("voice_still_up", "still up?", VOICE_WREN, 148),
    ("voice_found_it", "I found it.", VOICE_WREN, 160),
    ("voice_here", "Someone's here.", VOICE_WREN, 145),
    ("voice_hearing", "If you're hearing this", VOICE_WREN, 155),
    ("voice_stop", "Stop looking.", "Ralph", 138),
    ("voice_alive", "She's alive if you stop.", "Ralph", 140),
    ("voice_marina", "Stay away from the marina.", "Daniel", 162),
    ("voice_quiet", "Don't tell anyone.", "Fred", 152),
]


def leak(text: str, voice: str, rate: int) -> Samples:
    """A short canon line leaking through the shared backup: phone-line, close."""
    speech = phone_line(say_to_samples(text, voice, rate))
    hiss = lowpass(noise(len(speech) / SR + 0.2, 0.035), 3200)
    body = mix(gain(speech, 0.88), hiss[: len(speech)])
    return normalise(envelope(silence(0.12) + body + silence(0.28), 0.03, 0.16), 0.78)


def write_whispers() -> list[Path]:
    return [write_wav(name, leak(text, voice, rate)) for name, text, voice, rate in STORY_WHISPERS]


def voicemail(name: str, text: str, voice: str, background: str, rate: int = 175) -> Samples:
    speech = phone_line(say_to_samples(text, voice, rate))
    length = len(speech) / SR + 1.5
    beds = {
        "diner": mix(hum(length), place(silence(length), gain(bell_clang(), 0.25), length - 2.2)),
        "dock": water(length, 0.25),
        "car": lowpass(noise(length, 0.12), 250),
        "office": hum(length),
        "quiet": lowpass(noise(length, 0.03), 500),
    }
    return normalise(place(beds[background], speech, 0.8), 0.85)


def transcode(paths: list[Path]) -> None:
    if shutil.which("afconvert"):
        for p in paths:
            subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", "-b", "64000",
                            str(p), str(p.with_suffix(".m4a"))], check=True)
    elif shutil.which("ffmpeg"):
        for p in paths:
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(p),
                            "-c:a", "aac", "-b:a", "64k", str(p.with_suffix(".m4a"))],
                           check=True)
    else:
        return
    for p in paths:
        p.unlink()


if __name__ == "__main__":
    whispers_only = "--whispers" in sys.argv
    if whispers_only:
        transcode(write_whispers())
        print(f"wrote {len(STORY_WHISPERS)} story whispers -> assets/audio")
        sys.exit(0)
    written = [
        write_wav("sfx_message_in", message_in()),
        write_wav("sfx_message_out", message_out()),
        write_wav("sfx_notification", notification()),
        write_wav("sfx_glitch", glitch()),
        write_wav("sfx_tap", tap()),
        write_wav("sfx_unlock", pin_success()),
        write_wav("sfx_error", error()),
        write_wav("sfx_ringtone", ringtone()),
        write_wav("sfx_siren", siren_two_tone(2)),
        write_wav("sfx_bell", bell_clang()),
        write_wav("sfx_car_door", car_door()),
        write_wav("amb_water", normalise(water(20.0, 0.4), 0.6)),
        write_wav("amb_hum", normalise(hum(20.0), 0.5)),
        write_wav("vm_wren_47s", voicemail_wren_47s()),
        write_wav("vm_jonah", voicemail(
            "vm_jonah", "It's Jonah. Whatever she told you, forget it. Stay away from the marina. "
            "I mean it. Please.", "Daniel", "dock")),
        write_wav("vm_mara", voicemail(
            "vm_mara", "John, it's Mara Calloway, Wren's mother. The police won't tell me anything. "
            "If you've heard from her, anything at all, please call me back.", VOICE_MARA, "quiet", 162)),
        write_wav("vm_deacon", voicemail(
            "vm_deacon", "It's Deacon, from the Waterline. Wren left her camera bag here. "
            "You should come get it. Come after close. Don't tell anyone.", "Fred", "diner")),
        write_wav("vm_ardis", voicemail(
            "vm_ardis", "John, this is Ardis Locke. I wanted to check in personally. This town looks after "
            "its own. If the police have Wren's phone I'd like to know, so I can push them. Call me.",
            VOICE_ARDIS, "office")),
        write_wav("vm_unknown", voicemail(
            "vm_unknown", "Stop looking. She's alive if you stop.", "Ralph", "car")),
    ]
    whispers = write_whispers()
    transcode(written + whispers)
    print(f"wrote {len(written) + len(whispers)} audio files -> assets/audio")
