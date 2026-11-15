"""Play Market feature graphic (1024x500) — o'yin skrinshoti + sarlavha, 4 tilda.
Asos: store/graphics/feature_base.png (battle.tscn --no_hud --cam_zoom=1.35 --cam_fight, 2048x1000).
Ishlatish: python3 tools/make_feature.py
"""
import json
from PIL import Image, ImageDraw, ImageFont, ImageFilter

FONT = "/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf"
S = json.load(open("data/strings.json"))
base = Image.open("store/graphics/feature_base.png").convert("RGB").resize((1024, 500), Image.LANCZOS)

# Yuqoridan yumshoq qorong'i gradient: sarlavha o'qilishi uchun
shade = Image.new("L", (1024, 500))
for y in range(500):
    shade.paste(int(max(0, 150 - y * 0.75)), (0, y, 1024, y + 1))
dark = Image.new("RGB", (1024, 500), (40, 18, 10))
base = Image.composite(dark, base, shade)

for loc in ["uz", "en", "ru", "tr"]:
    im = base.copy()
    d = ImageDraw.Draw(im)
    title = S["GAME_TITLE"][loc]
    sub = S["MENU_SUBTITLE"][loc]
    size = 96
    f = ImageFont.truetype(FONT, size)
    while d.textlength(title, font=f) > 900:
        size -= 4
        f = ImageFont.truetype(FONT, size)
    fs = ImageFont.truetype(FONT, 34)
    # Soya
    glow = Image.new("RGBA", (1024, 500), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.text((512, 70), title, font=f, anchor="mm", fill=(0, 0, 0, 200), stroke_width=10, stroke_fill=(0, 0, 0, 200))
    glow = glow.filter(ImageFilter.GaussianBlur(8))
    im.paste(glow, (0, 4), glow)
    d.text((512, 70), title, font=f, anchor="mm", fill=(255, 205, 70), stroke_width=4, stroke_fill=(70, 30, 10))
    d.text((512, 142), sub, font=fs, anchor="mm", fill=(255, 245, 225), stroke_width=3, stroke_fill=(50, 20, 10))
    im.save(f"store/graphics/feature_{loc}.png")
    print("store/graphics/feature_%s.png" % loc, im.size)
