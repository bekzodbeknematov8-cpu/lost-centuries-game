#!/bin/bash
# Har bir sahnani headless rejimda ishga tushirib, skript xatolarini qidiradi.
# Ishlatish: tools/smoke_test.sh   (xato bo'lsa chiqish kodi 1)
cd "$(dirname "$0")/.."
GODOT=${GODOT:-godot}
fail=0
for scene in res://scenes/main_menu.tscn res://scenes/hero_select.tscn res://scenes/battle.tscn; do
  for diff in easy hard; do
    out=$(timeout 300 $GODOT --headless --path . -- --scene=$scene --diff=$diff --autoplay --speed=8 --quit_after=240 2>&1)
    errs=$(echo "$out" | grep -E "SCRIPT ERROR|Parse Error|Compile Error|Invalid call|Invalid access" | sort | uniq -c)
    if [ -n "$errs" ]; then
      echo "FAIL $scene ($diff)"; echo "$errs"; fail=1
    else
      echo "OK   $scene ($diff)"
    fi
  done
done
exit $fail
