#!/bin/bash
# Play Market skrinshotlari (1920x1080), 4 tilda. Demo progress bilan ishlaydi (asl fayl zaxiralanadi).
# Ishlatish: tools/store_shots.sh store/screenshots tools/demo_progress.json
cd "$(dirname "$0")/.."
OUT=${1:-store/screenshots}; DEMO=${2:-tools/demo_progress.json}
GODOT=${GODOT:-godot}
U="$HOME/.local/share/godot/app_userdata/Jahongirlar"
mkdir -p "$U" "$OUT"
[ -f "$U/progress.json" ] && cp "$U/progress.json" "$U/progress.json.bak"
run() { # til nom sahna vaqt qo'shimcha...
  local loc=$1 name=$2 sc=$3 t=$4; shift 4
  cp "$DEMO" "$U/progress.json"
  rm -rf "/tmp/ss_$$"
  timeout 120 xvfb-run -a -s "-screen 0 1920x1080x24" $GODOT --path . --rendering-driver opengl3 --resolution 1920x1080 -- \
    --scene=res://scenes/$sc.tscn --locale=$loc "$@" --shots=/tmp/ss_$$ --times=$t >/dev/null 2>&1
  mkdir -p "$OUT/$loc"
  if [ -f /tmp/ss_$$/shot_01.png ]; then mv /tmp/ss_$$/shot_01.png "$OUT/$loc/$name.png"; else echo "MISSING $loc/$name"; fi
}
for loc in en uz ru tr; do
  run $loc 1_battle battle 24 --level=temur_06#2 --autoplay --speed=2 --stress=30 --cam_fight
  run $loc 2_map campaign_map 2 --hero=jaloliddin
  run $loc 3_menu main_menu 2
  run $loc 4_heroes hero_select 2
  run $loc 5_workshop workshop 2
  run $loc 6_battle_desert battle 24 --level=boyazid_02#4 --hero=boyazid --autoplay --speed=2 --stress=30 --cam_fight
done
rm -rf /tmp/ss_$$
timeout 60 $GODOT --headless --path . -- --locale=uz --quit_after=0.5 >/dev/null 2>&1
if [ -f "$U/progress.json.bak" ]; then mv "$U/progress.json.bak" "$U/progress.json"; else rm -f "$U/progress.json"; fi
