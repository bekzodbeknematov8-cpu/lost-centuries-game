#!/usr/bin/env python3
"""Jahongirlar: qahramon xaritalarini eski qog'oz-xarita uslubida chizadi.

Kirish:  data/maps.json  (viloyat markazlari, relyef, dengizlar, daryolar)
Chiqish: assets/maps/<qahramon>.png      — ko'rinadigan xarita (1000x600)
         assets/maps/<qahramon>_idx.png  — viloyat indeksi (R = viloyat raqami + 1, 0 = dengiz)
Hammasi noldan chiziladi (tashqi rasm yo'q).   python3 tools/gen_maps.py
"""
import json
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "maps")

TERRAIN = {
    "steppe": (205, 184, 132),
    "desert": (232, 206, 140),
    "green": (170, 182, 112),
    "mountain": (184, 166, 146),
}
SEA = (150, 190, 205)
SEA_DEEP = (128, 172, 192)
INK = (74, 48, 26)


def value_noise(w, h, cell, rng):
    gw, gh = w // cell + 2, h // cell + 2
    g = rng.random((gh, gw))
    ys = np.linspace(0, gh - 1.001, h)
    xs = np.linspace(0, gw - 1.001, w)
    y0 = ys.astype(int)
    x0 = xs.astype(int)
    fy = (ys - y0)[:, None]
    fx = (xs - x0)[None, :]
    fy = fy * fy * (3 - 2 * fy)
    fx = fx * fx * (3 - 2 * fx)
    a = g[y0][:, x0]
    b = g[y0][:, x0 + 1]
    c = g[y0 + 1][:, x0]
    d = g[y0 + 1][:, x0 + 1]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def fbm(w, h, rng, base=80, octaves=4):
    out = np.zeros((h, w))
    amp = 1.0
    total = 0.0
    cell = base
    for _ in range(octaves):
        out += value_noise(w, h, max(2, cell), rng) * amp
        total += amp
        amp *= 0.5
        cell //= 2
    return out / total


def poly_mask(w, h, poly):
    img = Image.new("L", (w, h), 0)
    ImageDraw.Draw(img).polygon([tuple(p) for p in poly], fill=255)
    return np.asarray(img) > 0


def render(hero, m):
    w, h = m["size"]
    rng = np.random.default_rng(sum(ord(c) * (i + 1) for i, c in enumerate(hero)))
    yy, xx = np.mgrid[0:h, 0:w].astype(float)
    n1 = fbm(w, h, rng, 90)
    n2 = fbm(w, h, rng, 90)
    # Organik chegaralar uchun koordinatalarni "egamiz" (domain warping)
    wx = xx + (n1 - 0.5) * 70
    wy = yy + (n2 - 0.5) * 70

    # Quruqlik: chetlari to'lqinsimon orol + dengiz ko'pburchaklari
    edge = np.minimum.reduce([xx, w - 1 - xx, yy, h - 1 - yy]) + (fbm(w, h, rng, 150, 3) - 0.5) * 150 + (fbm(w, h, rng, 40, 2) - 0.5) * 30
    land = edge > 34
    sea_noise = fbm(w, h, rng, 40)
    for poly in m["seas"]:
        mask = poly_mask(w, h, poly)
        grown = np.asarray(Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(10))) / 255.0
        land &= ~((grown + (sea_noise - 0.5) * 0.6) > 0.5)

    centers = np.array([r["center"] for r in m["regions"]], dtype=float)
    d = (wx[None] - centers[:, 0, None, None]) ** 2 + (wy[None] - centers[:, 1, None, None]) ** 2
    idx = np.argmin(d, axis=0)
    idx = np.where(land, idx + 1, 0).astype(np.uint8)

    # Ranglar
    rgb = np.zeros((h, w, 3), dtype=float)
    for i, r in enumerate(m["regions"]):
        col = np.array(TERRAIN[r["terrain"]], dtype=float)
        rgb[idx == i + 1] = col
    depth = np.asarray(Image.fromarray((land * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(18))) / 255.0
    sea_col = np.array(SEA_DEEP)[None, None] * (1 - depth[..., None]) + np.array(SEA)[None, None] * depth[..., None]
    rgb[idx == 0] = sea_col[idx == 0]
    # Qog'oz donadorligi
    grain = (fbm(w, h, rng, 6, 2) - 0.5) * 22 + (fbm(w, h, rng, 120, 2) - 0.5) * 26
    rgb += grain[..., None]

    # Chegaralar va qirg'oq chizig'i
    border = np.zeros((h, w), bool)
    border[:, :-1] |= idx[:, :-1] != idx[:, 1:]
    border[:-1, :] |= idx[:-1, :] != idx[1:, :]
    coast = border & ((idx == 0) | np.roll(idx == 0, 1, 0) | np.roll(idx == 0, 1, 1))
    b_img = Image.fromarray((border * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(3))
    c_img = Image.fromarray((coast * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(5))
    bm = np.asarray(b_img) > 0
    cm = np.asarray(c_img) > 0
    rgb[bm] = rgb[bm] * 0.35 + np.array(INK) * 0.65
    rgb[cm] = np.array(INK) * 0.9
    # Vinyetka
    vig = 1.0 - 0.18 * (((xx / w - 0.5) ** 2 + (yy / h - 0.5) ** 2) * 2.2)
    rgb *= vig[..., None]

    img = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8))
    dr = ImageDraw.Draw(img)
    prng = np.random.default_rng(7)

    # Daryolar
    for river in m["rivers"]:
        pts = [tuple(p) for p in river]
        dr.line(pts, fill=INK, width=8, joint="curve")
        dr.line(pts, fill=(120, 170, 200), width=5, joint="curve")

    # Dengiz to'lqinlari
    for _ in range(140):
        x, y = prng.integers(0, w), prng.integers(0, h)
        if idx[y, x] == 0 and depth[y, x] < 0.6:
            dr.arc([x - 9, y - 4, x + 9, y + 4], 200, 340, fill=(100, 140, 165), width=2)

    # Relyef belgilari
    for i, r in enumerate(m["regions"]):
        ys_, xs_ = np.nonzero(idx == i + 1)
        if len(xs_) == 0:
            continue
        count = {"mountain": 9, "desert": 7, "green": 10, "steppe": 6}[r["terrain"]]
        for _ in range(count):
            k = prng.integers(0, len(xs_))
            x, y = int(xs_[k]), int(ys_[k])
            if abs(x - r["center"][0]) < 40 and abs(y - r["center"][1]) < 30:
                continue  # nom yoziladigan joy bo'sh qolsin
            if bm[max(0, y - 12):y + 12, max(0, x - 14):x + 14].any():
                continue
            t = r["terrain"]
            if t == "mountain":
                dr.polygon([(x - 13, y + 8), (x, y - 12), (x + 13, y + 8)], fill=(160, 140, 122), outline=INK)
                dr.line([(x - 3, y - 7), (x, y - 12), (x + 4, y - 6)], fill=(245, 240, 230), width=2)
            elif t == "desert":
                dr.arc([x - 14, y - 4, x + 14, y + 10], 200, 340, fill=(180, 140, 80), width=2)
                dr.arc([x - 6, y - 10, x + 18, y + 4], 200, 340, fill=(180, 140, 80), width=2)
            elif t == "green":
                dr.ellipse([x - 6, y - 10, x + 6, y + 2], fill=(110, 140, 70), outline=INK)
                dr.line([(x, y + 2), (x, y + 8)], fill=INK, width=2)
            else:
                dr.line([(x - 6, y + 4), (x - 3, y - 4)], fill=(130, 120, 70), width=2)
                dr.line([(x, y + 4), (x + 1, y - 6)], fill=(130, 120, 70), width=2)
                dr.line([(x + 6, y + 4), (x + 4, y - 4)], fill=(130, 120, 70), width=2)

    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, f"{hero}.png"))
    idx_rgb = np.zeros((h, w, 3), np.uint8)
    idx_rgb[..., 0] = idx
    Image.fromarray(idx_rgb).save(os.path.join(OUT, f"{hero}_idx.png"))
    sizes = [int((idx == i + 1).sum()) for i in range(len(m["regions"]))]
    print(hero, "viloyat maydonlari:", sizes)
    return sizes


def main():
    maps = json.load(open(os.path.join(ROOT, "data", "maps.json")))
    for hero, m in maps.items():
        sizes = render(hero, m)
        bad = [m["regions"][i]["id"] for i, s in enumerate(sizes) if s < 3000]
        if bad:
            raise SystemExit(f"{hero}: juda kichik yoki dengizda qolgan viloyatlar: {bad}")


if __name__ == "__main__":
    main()
