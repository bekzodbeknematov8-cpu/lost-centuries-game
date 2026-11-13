#!/bin/bash
# Unit testlarni ishga tushiradi. Hammasi o'tmasa YOKI biror SCRIPT ERROR chiqsa — chiqish kodi 1.
cd "$(dirname "$0")/.."
GODOT=${GODOT:-godot}
out=$(timeout 900 $GODOT --headless --path . -s res://tests/run_tests.gd 2>&1)
echo "$out" | grep -E "^  (OK|FAIL)|test o'tdi|^  - "
errs=$(echo "$out" | grep -E "SCRIPT ERROR|Parse Error|Compile Error")
if [ -n "$errs" ]; then echo "SKRIPT XATOLARI:"; echo "$errs" | sort | uniq -c; exit 1; fi
line=$(echo "$out" | grep -E "^[0-9]+/[0-9]+ test o'tdi")
[ -z "$line" ] && { echo "Natija satri topilmadi"; exit 1; }
a=$(echo "$line" | cut -d/ -f1); b=$(echo "$line" | cut -d/ -f2 | cut -d' ' -f1)
[ "$a" = "$b" ] || exit 1
echo "HAMMASI O'TDI"
