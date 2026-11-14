#!/bin/bash
# Har bir sahnani headless rejimda ishga tushirib, skript xatolarini qidiradi.
# Ishlatish: tools/smoke_test.sh   (xato bo'lsa chiqish kodi 1)
cd "$(dirname "$0")/.."
GODOT=${GODOT:-godot}
fail=0
for scene in res://scenes/main_menu.tscn res://scenes/mode_select.tscn res://scenes/workshop.tscn res://scenes/tactics_shop.tscn res://scenes/chests_screen.tscn res://scenes/outfits_screen.tscn res://scenes/market.tscn res://scenes/hero_select.tscn res://scenes/campaign_map.tscn res://scenes/battle.tscn; do
  for diff in easy hard; do
    out=$(timeout 300 $GODOT --headless --path . -- --scene=$scene --diff=$diff --autoplay --speed=8 --quit_after=${SMOKE_SECONDS:-240} 2>&1)
    errs=$(echo "$out" | grep -E "SCRIPT ERROR|Parse Error|Compile Error|Invalid call|Invalid access" | sort | uniq -c)
    if [ -n "$errs" ]; then
      echo "FAIL $scene ($diff)"; echo "$errs"; fail=1
    else
      echo "OK   $scene ($diff)"
    fi
  done
done
# Kampaniya bosqichlari: mudofaa, boss va g'alaba oynasi (yulduz/fakt)
for args in "--level=jaloliddin_04" "--level=temur_10" "--level=chingiz_01 --force_win" "--mode=endless --hero=boyazid" "--level=temur_03#4" "--level=boyazid_07#2 --force_win" "--level=chingiz_02#3 --call_reserve"; do
  out=$(timeout 300 $GODOT --headless --path . -- --scene=res://scenes/battle.tscn $args --autoplay --speed=8 --quit_after=$(( ${SMOKE_SECONDS:-240} / 2 )) 2>&1)
  errs=$(echo "$out" | grep -E "SCRIPT ERROR|Parse Error|Compile Error|Invalid call|Invalid access" | sort | uniq -c)
  if [ -n "$errs" ]; then echo "FAIL battle $args"; echo "$errs"; fail=1; else echo "OK   battle $args"; fi
done
rm -f "$HOME/.local/share/godot/app_userdata/Jahongirlar/progress.json"
exit $fail
