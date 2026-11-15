#!/bin/bash
# Barcha ekranlarni 4 tilda suratga oladi va har til uchun bitta jamlanma rasm yasaydi.
# Ishlatish: tools/lang_shots.sh /chiqish/papka
cd "$(dirname "$0")/.."
OUT=${1:-/tmp/lang_shots}
GODOT=${GODOT:-godot}
mkdir -p "$OUT"
SCENES="main_menu mode_select slots_screen campaign_map hero_select battle workshop tactics_shop chests_screen outfits_screen market achievements_screen"
for loc in uz en ru tr; do
  for sc in $SCENES; do
    extra=""; t=2
    [ "$sc" = "battle" ] && extra="--level=temur_02#3 --autoplay --speed=3" && t=12
    [ "$sc" = "campaign_map" ] && extra="--hero=temur"
    d="$OUT/$loc/$sc"; rm -rf "$d"
    timeout 90 xvfb-run -a $GODOT --path . --rendering-driver opengl3 -- --scene=res://scenes/$sc.tscn --locale=$loc $extra --shots="$d" --times=$t >/dev/null 2>&1
    [ -f "$d/shot_01.png" ] || echo "MISSING $loc/$sc"
  done
done
# Sozlamalarni o'zbek tiliga qaytarish
timeout 60 $GODOT --headless --path . -- --locale=uz --quit_after=0.5 >/dev/null 2>&1
python3 - "$OUT" $SCENES <<'PY'
import sys, os
from PIL import Image
out, scenes = sys.argv[1], sys.argv[2:]
for loc in ["uz", "en", "ru", "tr"]:
    W, H, cols = 480, 270, 3
    sheet = Image.new("RGB", (W * cols, H * ((len(scenes) + cols - 1) // cols)), (30, 30, 30))
    for i, sc in enumerate(scenes):
        p = f"{out}/{loc}/{sc}/shot_01.png"
        if os.path.exists(p):
            sheet.paste(Image.open(p).convert("RGB").resize((W, H)), ((i % cols) * W, (i // cols) * H))
    sheet.save(f"{out}/sheet_{loc}.png")
PY
