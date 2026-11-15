# Play Market materiallari

| Fayl | Play Console'da qayerga |
|---|---|
| `listing/<til>/title.txt` (≤30) | Main store listing → App name |
| `listing/<til>/short_description.txt` (≤80) | Short description |
| `listing/<til>/full_description.txt` (≤4000) | Full description |
| `icon_512.png` | App icon (512×512) |
| `graphics/feature_<til>.png` | Feature graphic (1024×500) |
| `screenshots/<til>/*.png` (1920×1080) | Phone screenshots (kamida 2, ko'pi bilan 8) |
| `data-safety.md` | App content → Data safety, Ads, Content rating, Target audience |
| `../docs/privacy-policy.md` | Ochiq URL'ga joylab, App content → Privacy policy ga havola |

Tillar: `en-US` (asosiy), `ru-RU`, `tr-TR`, `uz`. Play Console o'zbek tilini qo'llab-quvvatlamasa,
o'zbekcha matnni ishlatmang yoki inglizchani asosiy qoldiring.

Qayta yaratish:
```
tools/store_shots.sh store/screenshots tools/demo_progress.json   # skrinshotlar (Xvfb)
python3 tools/make_feature.py                                       # feature graphic
```
Feature asosini qayta olish: `battle.tscn --level=boyazid_02#4 --hero=boyazid --autoplay --speed=2
--stress=40 --cam_fight --no_hud --cam_zoom=1.35 --resolution 2048x1000`, 26-soniya.
