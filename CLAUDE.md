# CLAUDE.md — Jahongirlar

Foydalanuvchi bilan **o'zbek tilida** gaplashing.

To'liq reja: `PLAN.md`. Holat: `PROGRESS.md`. Qarorlar: `DECISIONS.md`.
Foydalanuvchidan kerak narsalar: `NEEDS_USER.md`. Mualliflik: `CREDITS.md`.

## Loyiha
2D tarixiy strategik jang o'yini (Godot 4.5.1, GDScript, Android).
Qahramonlar: Chingizxon, Jaloliddin Manguberdi, Amir Temur, Boyazid Yildirim.

## Arxitektura
| Joy | Vazifa |
|---|---|
| scripts/sim/ | Jang mantig'i (chizishsiz, deterministik): battle_sim, unit_state, team_state, ai_controller |
| scripts/view/ | Chizish: battle.gd (sahna, kamera, effektlar, ovoz), painter.gd (barcha grafika kodda) |
| scripts/ui/ | HUD, bosh menyu, tema |
| scripts/autoload/ | GameData (JSON), GameState (sozlamalar, tarjima), Sfx (ovoz), DevTools (avtotest) |
| data/ | units.json, ai.json, heroes.json, campaigns.json, facts.json, strings.json (4 til: uz, en, ru, tr) |
| tools/ | gen_audio.py (barcha ovoz/musiqa sintezi), balance.gd, smoke_test.sh |
| tests/ | run_tests.gd (unit + bot-vs-bot) |

## Buyruqlar
```
godot --headless --import                                   # resurslarni import
tools/run_tests.sh                                          # unit testlar (SCRIPT ERROR bo'lsa ham yiqiladi)
tools/smoke_test.sh                                         # barcha sahnalar xatosiz ishlashi
godot --headless --path . -s res://tools/balance.gd -- --games=20 --out=docs/balance-report.md
python3 tools/gen_audio.py                                  # ovozlarni qayta yaratish
godot --headless --path . -s res://tools/campaign_balance.gd -- --games=4   # kampaniya qiyinligi
godot --headless --path . -s res://tools/hero_balance.gd -- --games=16     # qahramonlar balansi
# Skrinshot (Xvfb bilan):
xvfb-run -a godot --path . --rendering-driver opengl3 -- --scene=res://scenes/battle.tscn --autoplay --speed=3 --shots=/tmp/s --times=30,90
```

## Qoidalar
- Har bir o'zgarishdan keyin: testlar + smoke test + skrinshot. O'tmasa — tuzat va qayta sina.
- Mavjud o'yinlarni (nomi, personaj, grafika, musiqa) nusxalamang. Faqat original yoki CC0.
- Qon va shafqatsiz tasvir yo'q. Tarixiy faktlar manbali; hech bir xalq kamsitilmaydi.
- Kalitlar (keystore, AdMob ID, .env) hech qachon commit qilinmaydi.
- Balans va bosqichlar kodda emas, JSON'da.
- Testni o'chirib CI'ni yashil qilmang.
