#!/usr/bin/env python3
"""Jahongirlar: barcha ovoz effektlari va musiqani noldan sintez qiladi.

Tashqi namunalar ishlatilmaydi, shuning uchun hamma narsa loyihaning o'ziga tegishli
(mualliflik huquqi muammosi yo'q). Ishga tushirish:

    python3 tools/gen_audio.py            # assets/audio/ ga yozadi

Talablar: numpy, ffmpeg (musiqani .ogg ga o'girish uchun).
"""
import os
import subprocess
import sys
import wave

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX_DIR = os.path.join(ROOT, "assets", "audio", "sfx")
MUSIC_DIR = os.path.join(ROOT, "assets", "audio", "music")
SR = 22050
MSR = 32000

rng = np.random.default_rng(2026)


# ---------------------------------------------------------------- yordamchilar

def t_axis(dur, sr=SR):
    return np.arange(int(dur * sr)) / sr


def env_exp(dur, decay, attack=0.002, sr=SR):
    t = t_axis(dur, sr)
    e = np.exp(-t / max(decay, 1e-4))
    if attack > 0:
        e *= np.clip(t / attack, 0, 1)
    return e


def noise(dur, sr=SR):
    return rng.standard_normal(int(dur * sr))


def band(x, lo, hi, sr=SR, soft=0.15):
    """FFT orqali polosali filtr (yumshoq qirralar bilan)."""
    n = len(x)
    if n == 0:
        return x
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(n, 1 / sr)
    w = np.ones_like(f)
    if lo > 0:
        w *= 1 / (1 + np.exp(-(f - lo) / (lo * soft + 1)))
    if hi < sr / 2:
        w *= 1 / (1 + np.exp((f - hi) / (hi * soft + 1)))
    return np.fft.irfft(X * w, n)


def formants(x, peaks, sr=SR):
    """Ovoz (vokal) formantlarini qo'llash: [(markaz, kenglik, kuch)]."""
    n = len(x)
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(n, 1 / sr)
    w = np.zeros_like(f)
    for c, bw, g in peaks:
        w += g * np.exp(-0.5 * ((f - c) / bw) ** 2)
    return np.fft.irfft(X * w, n)


def sine(freq, dur, sr=SR, phase=0.0):
    t = t_axis(dur, sr)
    if callable(freq):
        ph = 2 * np.pi * np.cumsum(freq(t)) / sr
        return np.sin(ph + phase)
    return np.sin(2 * np.pi * freq * t + phase)


def glide(f0, f1, dur, sr=SR, curve=3.0):
    def fn(t):
        k = np.clip(t / dur, 0, 1)
        return f1 + (f0 - f1) * np.exp(-curve * k)
    return sine(fn, dur, sr)


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[: len(p)] += p
    return out


def place(buf, x, at, sr=SR, gain=1.0):
    i = int(at * sr)
    if i >= len(buf):
        return
    j = min(len(buf), i + len(x))
    buf[i:j] += x[: j - i] * gain


def pad(x, dur, sr=SR):
    n = int(dur * sr)
    if len(x) >= n:
        return x[:n]
    return np.concatenate([x, np.zeros(n - len(x))])


def normalize(x, peak=0.89):
    m = np.max(np.abs(x)) if len(x) else 0
    if m < 1e-9:
        return x
    return x * (peak / m)


def fade(x, fin=0.002, fout=0.02, sr=SR):
    x = x.copy()
    a = int(fin * sr)
    b = int(fout * sr)
    if a > 0:
        x[:a] *= np.linspace(0, 1, a)
    if b > 0:
        x[-b:] *= np.linspace(1, 0, b)
    return x


def reverb(x, sr=SR, length=0.8, decay=0.25, wet=0.18, circular=False):
    n = int(length * sr)
    ir = rng.standard_normal(n) * np.exp(-np.arange(n) / (decay * sr))
    ir = band(ir, 200, 6000, sr)
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
    if circular:
        L = len(x)
        y = np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(ir, L), L)
    else:
        L = len(x) + n
        y = np.fft.irfft(np.fft.rfft(x, L) * np.fft.rfft(ir, L), L)
        x = pad(x, L / sr, sr)
    return x * (1 - wet) + y * wet * 3


def write_wav(path, x, sr=SR):
    x = np.clip(x, -1, 1)
    data = (x * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(data.tobytes())


def pluck(freq, dur, sr=SR, bright=0.6, decay=0.996):
    """Karplus-Strong: do'mbira/dutor torining tovushi."""
    n = int(dur * sr)
    p = max(2, int(round(sr / freq)))
    buf = band(rng.standard_normal(p * 4), 60, 1500 + 6000 * bright, sr)[:p]
    out = np.zeros(n)
    out[:p] = buf
    i = p
    while i < n:
        j = min(n, i + p)
        prev = out[i - p: j - p]
        prev2 = out[i - p - 1: j - p - 1] if i - p - 1 >= 0 else np.concatenate([[0], out[i - p: j - p - 1]])
        if len(prev2) < len(prev):
            prev2 = np.concatenate([prev2, np.zeros(len(prev) - len(prev2))])
        out[i:j] = decay * 0.5 * (prev + prev2)
        i = j
    # Tana rezonansi
    body = band(out, 90, 3500, sr)
    return fade(body, 0.001, 0.05, sr)


def brass(freq, dur, sr=SR, vib=5.0, bright=1.0):
    """Karnay ga o'xshash mis puflama cholg'u."""
    t = t_axis(dur, sr)
    swell = np.clip(t / 0.08, 0, 1) * (0.85 + 0.15 * np.clip(t / 0.4, 0, 1))
    rel = np.clip((dur - t) / 0.15, 0, 1)
    f = freq * (1 + 0.006 * np.sin(2 * np.pi * vib * t) * np.clip(t / 0.3, 0, 1))
    ph = 2 * np.pi * np.cumsum(f) / sr
    out = np.zeros_like(t)
    for h in range(1, 14):
        amp = (1.0 / h) * (bright ** (h / 4))
        out += amp * np.sin(h * ph)
    out = band(out, freq * 0.8, 4500 * bright, sr)
    return out * swell * rel


def doira_dum(sr=SR, f=95):
    return mix(glide(f * 1.6, f, 0.35, sr, 6) * env_exp(0.35, 0.12, 0.002, sr),
               band(noise(0.08, sr), 80, 600, sr) * env_exp(0.08, 0.02, 0.001, sr) * 0.4)


def doira_tak(sr=SR):
    n = band(noise(0.12, sr), 1200, 4000, sr) * env_exp(0.12, 0.025, 0.001, sr)
    rings = band(noise(0.18, sr), 5500, 9500, sr) * env_exp(0.18, 0.06, 0.003, sr) * 0.35
    return mix(n, rings)


def nogora(sr=SR):
    return mix(glide(120, 55, 0.6, sr, 5) * env_exp(0.6, 0.22, 0.003, sr),
               band(noise(0.15, sr), 60, 400, sr) * env_exp(0.15, 0.04, 0.001, sr) * 0.6)


# ---------------------------------------------------------------- effektlar

def sfx_sword_clash():
    f0 = rng.uniform(1700, 2600)
    dur = 0.7
    parts = []
    for r, a, d in [(1, 1, 0.35), (1.47, 0.7, 0.28), (2.09, 0.5, 0.22), (2.56, 0.4, 0.18), (3.21, 0.3, 0.12), (0.53, 0.35, 0.2)]:
        parts.append(sine(f0 * r * rng.uniform(0.99, 1.01), dur) * env_exp(dur, d * rng.uniform(0.8, 1.2)) * a)
    hit = band(noise(0.03), 2500, 10000) * env_exp(0.03, 0.006, 0.0005) * 2.0
    thump = sine(180, 0.08) * env_exp(0.08, 0.02) * 0.5
    return mix(*parts, hit, thump)


def sfx_sword_shield():
    wood = band(noise(0.25), 250, 1100) * env_exp(0.25, 0.05, 0.001) * 1.5
    low = glide(200, 120, 0.25) * env_exp(0.25, 0.07) * 0.9
    ring = sine(rng.uniform(1000, 1400), 0.3) * env_exp(0.3, 0.09) * 0.25
    return mix(wood, low, ring)


def sfx_hit_flesh():
    thud = band(noise(0.15), 60, 650) * env_exp(0.15, 0.03, 0.001) * 1.4
    body = glide(110, 60, 0.15) * env_exp(0.15, 0.05) * 0.9
    cloth = band(noise(0.1), 2000, 5000) * env_exp(0.1, 0.02) * 0.2
    return mix(thud, body, cloth)


def sfx_spear_hit():
    w = band(noise(0.09), 1200, 3500) * np.sin(np.linspace(0, np.pi, int(0.09 * SR))) * 0.5
    out = np.zeros(int(0.35 * SR))
    place(out, w, 0.0)
    place(out, sfx_hit_flesh(), 0.06)
    place(out, band(noise(0.06), 400, 1600) * env_exp(0.06, 0.015) * 0.6, 0.06)
    return out


def sfx_arrow_flesh():
    return mix(glide(260, 160, 0.12) * env_exp(0.12, 0.035) * 0.9,
               band(noise(0.06), 500, 1600) * env_exp(0.06, 0.012) * 0.8)


def sfx_arrow_shield():
    f = rng.uniform(800, 1000)
    return mix(band(noise(0.12), f * 0.8, f * 2.2) * env_exp(0.12, 0.02, 0.0005) * 1.6,
               sine(f * 0.7, 0.12) * env_exp(0.12, 0.03) * 0.6,
               sine(f * 1.9, 0.08) * env_exp(0.08, 0.015) * 0.3)


def sfx_arrow_metal():
    f = rng.uniform(2800, 3600)
    return mix(sine(f, 0.35) * env_exp(0.35, 0.1) * 0.5, sine(f * 1.53, 0.3) * env_exp(0.3, 0.07) * 0.3,
               band(noise(0.02), 3000, 9000) * env_exp(0.02, 0.004) * 1.5)


def sfx_arrow_ground():
    return band(noise(0.12), 100, 900) * env_exp(0.12, 0.025, 0.001)


def sfx_bow():
    f = rng.uniform(170, 230)
    tw = pluck(f, 0.35, bright=0.4, decay=0.985) * 1.2
    wh = band(noise(0.18), 1800, 5000) * np.sin(np.linspace(0, np.pi, int(0.18 * SR))) ** 2 * 0.35
    out = np.zeros(int(0.4 * SR))
    place(out, tw, 0)
    place(out, wh, 0.02)
    return out


def sfx_swing():
    dur = rng.uniform(0.2, 0.28)
    n = int(dur * SR)
    x = noise(dur)
    # Markaz chastotasi siljiydigan "vush" ovozi
    out = np.zeros(n)
    seg = 8
    for i in range(seg):
        a = i * n // seg
        b = (i + 1) * n // seg
        c = 700 + 2200 * (i / seg)
        out[a:b] = band(x, c * 0.6, c * 1.4)[a:b]
    return out * np.sin(np.linspace(0, np.pi, n)) ** 1.5


def sfx_death():
    dur = 0.45
    f0 = rng.uniform(105, 170)
    t = t_axis(0.3)
    f = f0 * (1.0 - 0.35 * t / 0.3)
    ph = 2 * np.pi * np.cumsum(f) / SR
    src = sum(np.sin(h * ph) / h for h in range(1, 25))
    vowel = formants(src, [(350, 80, 1.0), (800, 120, 0.6), (2300, 200, 0.2)])
    vowel *= np.clip(t / 0.02, 0, 1) * np.exp(-t / 0.12)
    out = np.zeros(int(dur * SR))
    place(out, normalize(vowel, 0.55), 0)
    place(out, sfx_hit_flesh() * 0.7, 0.2)
    place(out, band(noise(0.2), 1500, 5000) * env_exp(0.2, 0.06) * 0.12, 0.18)
    return out


def sfx_horse():
    out = np.zeros(int(0.6 * SR))
    for i, at in enumerate([0.0, 0.09, 0.2, 0.29]):
        hoof = mix(band(noise(0.05), 900, 2500) * env_exp(0.05, 0.01, 0.0005),
                   glide(160, 90, 0.08) * env_exp(0.08, 0.02) * 0.8)
        place(out, hoof, at, gain=1.0 - i * 0.12)
    return out


def sfx_castle_hit():
    boom = glide(90, 45, 0.6) * env_exp(0.6, 0.18, 0.002) * 1.0
    crunch = band(noise(0.4), 80, 900) * env_exp(0.4, 0.09, 0.001) * 0.9
    out = mix(boom, crunch)
    for i in range(6):
        place(out, band(noise(0.03), 1500, 5000) * env_exp(0.03, 0.008) * 0.25, rng.uniform(0.05, 0.4))
    return out


def sfx_castle_fall():
    dur = 3.0
    rum = band(noise(dur), 30, 400) * env_exp(dur, 1.0, 0.05) * 1.2
    out = rum.copy()
    for i in range(7):
        place(out, glide(80, 35, 0.8) * env_exp(0.8, 0.25) * 0.9, i * 0.32 + rng.uniform(0, 0.1))
    for i in range(40):
        place(out, band(noise(0.04), 1200, 6000) * env_exp(0.04, 0.01) * 0.3, rng.uniform(0.1, 2.4))
    return reverb(out, length=1.2, decay=0.4, wet=0.25)


def sfx_coin():
    out = np.zeros(int(0.45 * SR))
    for k, (f, at) in enumerate([(2093, 0.0), (2637 * rng.uniform(0.99, 1.01), 0.06)]):
        tone = mix(sine(f, 0.4) * env_exp(0.4, 0.12), sine(f * 2.76, 0.25) * env_exp(0.25, 0.05) * 0.3)
        place(out, tone * (0.8 if k else 1.0), at)
    return out


def sfx_pick():
    return mix(band(noise(0.05), 3000, 8000) * env_exp(0.05, 0.006, 0.0005) * 1.2,
               sine(rng.uniform(380, 480), 0.1) * env_exp(0.1, 0.025) * 0.7,
               band(noise(0.15), 200, 1200) * env_exp(0.15, 0.03) * 0.3)


def sfx_ready():
    out = np.zeros(int(0.6 * SR))
    place(out, doira_dum() * 0.7, 0)
    place(out, pluck(587, 0.5, bright=0.7) * 0.6, 0.02)
    place(out, pluck(880, 0.45, bright=0.7) * 0.5, 0.1)
    return out


def sfx_click():
    return mix(sine(1500, 0.04) * env_exp(0.04, 0.008), band(noise(0.02), 2000, 6000) * env_exp(0.02, 0.003) * 0.4)


def sfx_deny():
    t = t_axis(0.16)
    sq = np.sign(np.sin(2 * np.pi * 150 * t))
    return band(sq, 80, 1200) * env_exp(0.16, 0.08) * 0.6


def karnay_phrase(notes, sr=SR, bright=0.9):
    total = sum(d for _, d in notes) + 0.3
    out = np.zeros(int(total * sr))
    at = 0.0
    for f, d in notes:
        place(out, brass(f, d + 0.05, sr, bright=bright), at, sr)
        at += d
    return out


def sfx_horn_attack():
    out = karnay_phrase([(174.6, 0.25), (233.1, 0.9)])
    return reverb(out, length=1.0, decay=0.3, wet=0.25)


def sfx_horn_retreat():
    out = karnay_phrase([(233.1, 0.3), (174.6, 0.3), (146.8, 0.7)], bright=0.7)
    return reverb(out, length=1.0, decay=0.3, wet=0.25)


def sfx_horn_enemy():
    out = karnay_phrase([(146.8, 0.3), (196.0, 0.9)], bright=0.6)
    out = band(out, 100, 2200)
    return reverb(out, length=1.4, decay=0.5, wet=0.45)


def sfx_drum():
    out = np.zeros(int(1.2 * SR))
    for at in [0.0, 0.22, 0.44]:
        place(out, nogora(), at, gain=0.9 if at else 1.0)
    return reverb(out, length=0.8, decay=0.25, wet=0.2)


def sfx_victory():
    sr = SR
    out = np.zeros(int(4.0 * sr))
    place(out, karnay_phrase([(174.6, 0.2), (220.0, 0.2), (261.6, 0.2), (349.2, 1.3)], bright=1.0) * 0.8, 0.0)
    for i in range(16):
        place(out, doira_tak() * (0.5 + 0.03 * i), 0.0 + i * 0.07)
    place(out, nogora(), 0.6)
    place(out, nogora(), 1.2)
    for i, f in enumerate([349.2, 440.0, 523.3, 698.5]):
        place(out, pluck(f, 1.5, bright=0.8) * 0.5, 1.25 + i * 0.05)
    return reverb(out, length=1.2, decay=0.35, wet=0.22)


def sfx_defeat():
    out = np.zeros(int(4.0 * SR))
    for i, f in enumerate([293.7, 277.2, 233.1, 220.0, 146.8]):
        place(out, pluck(f, 1.4, bright=0.5) * 0.7, i * 0.38)
    place(out, nogora() * 0.9, 0.0)
    place(out, nogora() * 0.9, 1.52)
    place(out, brass(73.4, 1.8, bright=0.5) * 0.35, 1.5)
    return reverb(out, length=1.4, decay=0.5, wet=0.3)


def sfx_arrow_rain():
    out = np.zeros(int(1.6 * SR))
    place(out, sfx_horn_attack()[: int(0.6 * SR)] * 0.5, 0.0)
    for i in range(14):
        place(out, sfx_bow() * 0.5, rng.uniform(0.0, 0.5))
    for i in range(12):
        w = band(noise(0.3), 1500, 4500) * np.sin(np.linspace(0, np.pi, int(0.3 * SR))) ** 2 * 0.3
        place(out, w, rng.uniform(0.3, 1.0))
    return reverb(out, length=0.8, decay=0.25, wet=0.2)


def sfx_leap():
    out = np.zeros(int(1.2 * SR))
    place(out, sfx_swing() * 0.8, 0.0)
    for at in [0.0, 0.08, 0.16]:
        place(out, sfx_horse() * 0.5, at)
    place(out, glide(70, 35, 0.7) * env_exp(0.7, 0.2) * 1.0, 0.45)
    place(out, band(noise(0.5), 60, 700) * env_exp(0.5, 0.12) * 0.8, 0.45)
    return out


def sfx_thunder():
    dur = 2.4
    crack = band(noise(0.25), 1500, 9000) * env_exp(0.25, 0.04, 0.0005) * 1.4
    rumble = band(noise(dur), 30, 350) * env_exp(dur, 0.7, 0.05) * 1.2
    out = mix(crack, rumble)
    for i in range(8):
        place(out, band(noise(0.06), 800, 6000) * env_exp(0.06, 0.012) * 0.5, rng.uniform(0.0, 0.3))
    place(out, sfx_horse() * 0.6, 0.05)
    return reverb(out, length=1.4, decay=0.5, wet=0.3)


def sfx_rally():
    out = np.zeros(int(3.0 * SR))
    place(out, karnay_phrase([(174.6, 0.18), (233.1, 0.18), (261.6, 0.18), (349.2, 0.9)], bright=1.0) * 0.8, 0.0)
    for at in [0.0, 0.36, 0.72, 0.9, 1.08]:
        place(out, nogora() * 0.8, at)
    for i in range(10):
        place(out, doira_tak() * 0.35, 1.1 + i * 0.07)
    return reverb(out, length=1.0, decay=0.3, wet=0.22)


def sfx_hero_down():
    out = np.zeros(int(2.4 * SR))
    place(out, brass(146.8, 0.5, bright=0.6) * 0.6, 0.0)
    place(out, brass(110.0, 1.2, bright=0.5) * 0.6, 0.45)
    place(out, nogora() * 0.9, 0.0)
    place(out, nogora() * 0.7, 0.45)
    return reverb(out, length=1.2, decay=0.4, wet=0.3)


SFX = {
    "sword_clash": (sfx_sword_clash, 4), "sword_shield": (sfx_sword_shield, 3),
    "hit_flesh": (sfx_hit_flesh, 4), "spear_hit": (sfx_spear_hit, 3),
    "arrow_flesh": (sfx_arrow_flesh, 3), "arrow_shield": (sfx_arrow_shield, 3),
    "arrow_metal": (sfx_arrow_metal, 2), "arrow_ground": (sfx_arrow_ground, 2),
    "bow": (sfx_bow, 3), "swing": (sfx_swing, 3), "death": (sfx_death, 4),
    "horse": (sfx_horse, 2), "castle_hit": (sfx_castle_hit, 3), "castle_fall": (sfx_castle_fall, 1),
    "coin": (sfx_coin, 3), "pick": (sfx_pick, 3), "ready": (sfx_ready, 1), "click": (sfx_click, 1),
    "deny": (sfx_deny, 1), "horn_attack": (sfx_horn_attack, 1), "horn_retreat": (sfx_horn_retreat, 1),
    "horn_enemy": (sfx_horn_enemy, 1), "drum": (sfx_drum, 1), "victory": (sfx_victory, 1),
    "defeat": (sfx_defeat, 1), "arrow_rain": (sfx_arrow_rain, 1), "leap": (sfx_leap, 1),
    "thunder": (sfx_thunder, 1), "rally": (sfx_rally, 1), "hero_down": (sfx_hero_down, 1),
}


# ---------------------------------------------------------------- musiqa

# D frigiy-dominant (hijoz) lad: Markaziy Osiyo va Sharq ohanglariga yaqin.
SCALE = [0, 1, 4, 5, 7, 8, 10]
D3 = 146.83


def note_freq(degree, octave=0, root=D3):
    o, d = divmod(degree, len(SCALE))
    return root * 2 ** ((SCALE[d] + 12 * (o + octave)) / 12)


def make_melody(bars, seed, density=0.75):
    r = np.random.default_rng(seed)
    motif = []
    deg = 7
    for i in range(8):
        if r.random() < density or i == 0:
            deg = int(np.clip(deg + r.choice([-2, -1, -1, 1, 1, 2, 0, 3]), 3, 12))
            motif.append(deg)
        else:
            motif.append(None)
    phrases = []
    for b in range(bars):
        m = list(motif)
        if b % 4 == 1:
            m = [None if x is None else x + 1 for x in m]
        elif b % 4 == 2:
            m = [None if (x is None or r.random() < 0.2) else int(np.clip(x + r.choice([-1, 0, 1, 2]), 2, 13)) for x in m]
        elif b % 4 == 3:
            m = m[:5] + [9, 8, 7]
        phrases.append(m)
    return phrases


def render_music(bpm, bars, seed, battle=True):
    beat = 60.0 / bpm
    bar = beat * 4
    dur = bar * bars
    n = int(dur * MSR)
    mel = np.zeros(n)
    drone = np.zeros(n)
    perc = np.zeros(n)
    horn = np.zeros(n)
    phrases = make_melody(bars, seed, 0.8 if battle else 0.6)
    eighth = beat / 2
    for b in range(bars):
        t0 = b * bar
        for i, deg in enumerate(phrases[b]):
            if deg is None:
                continue
            f = note_freq(deg, 0)
            place(mel, pluck(f, eighth * 3, MSR, bright=0.75 if battle else 0.55, decay=0.994), t0 + i * eighth, MSR, 0.55)
            if battle and i % 2 == 1:
                place(mel, pluck(f, eighth, MSR, bright=0.8, decay=0.99), t0 + i * eighth + eighth / 2, MSR, 0.25)
        # Burdon (asosiy va kvinta tor), do'mbira uslubida urib chalinadi
        strum = [0, 2, 3] if battle else [0, 2]
        for k in strum:
            place(drone, pluck(D3 / 2 if k == 0 else D3 * 0.75, beat * 1.5, MSR, bright=0.35), t0 + k * beat, MSR, 0.45)
            place(drone, pluck(D3 * 0.75, beat, MSR, bright=0.3), t0 + k * beat + 0.012, MSR, 0.3)
        # Doira naqshi
        if battle:
            pattern = [("dum", 0), ("tak", 1.5), ("tak", 2), ("dum", 2.5), ("tak", 3), ("tak", 3.5)]
            if b % 2 == 1:
                pattern += [("tak", 0.75), ("tak", 1.0)]
            if b % 4 == 0:
                place(perc, nogora(MSR) * 0.9, t0, MSR)
        else:
            pattern = [("dum", 0), ("tak", 2), ("tak", 3)] if b % 2 == 0 else [("dum", 0), ("tak", 2.5)]
        for kind, pos in pattern:
            snd = doira_dum(MSR) if kind == "dum" else doira_tak(MSR)
            place(perc, snd, t0 + pos * beat, MSR, 0.8 if kind == "dum" else 0.45)
        if battle and b % 8 == 0:
            place(horn, brass(D3, bar * 0.9, MSR, bright=0.7), t0, MSR, 0.22)
        if battle and b % 8 == 4:
            place(horn, brass(D3 * 2 ** (7 / 12), bar * 0.9, MSR, bright=0.7), t0, MSR, 0.18)
    out = mel * 1.0 + drone * 0.8 + perc * (0.9 if battle else 0.6) + horn
    out = reverb(out, MSR, length=1.2, decay=0.35, wet=0.16, circular=True)
    return normalize(out, 0.8)


def write_ogg(path, x):
    tmp = path[:-4] + ".tmp.wav"
    write_wav(tmp, x, MSR)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "4", path], check=True)
    os.remove(tmp)


def main():
    os.makedirs(SFX_DIR, exist_ok=True)
    os.makedirs(MUSIC_DIR, exist_ok=True)
    only = set(sys.argv[1:])
    for name, (fn, count) in SFX.items():
        if only and name not in only:
            continue
        for i in range(count):
            x = fade(normalize(fn()), 0.001, 0.03)
            fname = f"{name}_{i + 1}.wav" if count > 1 else f"{name}.wav"
            write_wav(os.path.join(SFX_DIR, fname), x)
        print("sfx", name, count)
    if not only or "music" in only:
        write_ogg(os.path.join(MUSIC_DIR, "battle.ogg"), render_music(126, 24, seed=11, battle=True))
        print("music battle")
        write_ogg(os.path.join(MUSIC_DIR, "menu.ogg"), render_music(84, 16, seed=5, battle=False))
        print("music menu")


if __name__ == "__main__":
    main()
