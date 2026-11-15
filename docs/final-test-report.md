# Yakuniy sinov hisoboti (6-bosqich)

Sana: 2026-11-15 · Versiya: 1.0 oldi (dev-latest)

## 1. Avtomatik testlar
| Sinov | Natija |
|---|---|
| `tools/run_tests.sh` (unit + bot-vs-bot, 54 ta) | ✅ hammasi o'tdi |
| `tools/smoke_test.sh` (12 ekran × 2 qiyinlik + 8 maxsus jang) | ✅ 32/32 OK, SCRIPT ERROR yo'q |
| CI (GitHub Actions: testlar, smoke, APK + Web eksport) | ✅ har commitda |

## 2. Performance (150 birlik stress-test)
`godot --headless --path . -s res://tools/stress_test.gd -- --units=150` — ikkala tomon hujumda, 80 s jang.

| Birliklar | Oldin: o'rt./eng yomon qadam | Keyin: o'rt./eng yomon qadam |
|---|---|---|
| 150 | 6.1 ms / 65 ms | **1.3 ms / 8 ms** |
| 300 | 26 ms / 227 ms | **3.9 ms / 28 ms** |

- Sabab: har askar nishonni butun ro'yxatdan qidirardi (O(n²)), to'dada esa har safar saralash.
- Tuzatish: har qadam boshida x bo'yicha saralangan indeks + ikki tomonga qidiruv; saralash native
  `PackedInt64Array.sort()` bilan. Natija eski kod bilan **aynan bir xil** (`hero_balance.gd` taqqoslandi,
  `test_fast_nearest_matches_bruteforce` testi).
- Chizish: 150 birlikda `_draw` CPU vaqti ~3.9 ms/kadr (ekrandan tashqaridagilar chizilmaydi).
  Xvfb dagi umumiy kadr vaqti dasturiy (GPU'siz) renderer sababli yuqori; haqiqiy telefonda sinash kerak.
- Oddiy o'yinda har tomonda maks. 30 aholi, ya'ni yuk stress-testdan ancha kam.

## 3. Ekranlar 4 tilda (uz/en/ru/tr)
`tools/lang_shots.sh <papka>` — 12 ekran × 4 til, har til uchun jamlanma rasm.
- Barcha ekranlar ochiladi, matnlar sig'adi (uzun nomlar avtomatik kichrayadi).
- Topilgan va tuzatilgan: "Win 1 battles" / "Выиграйте 1 битв" — 1 ta maqsadli yutuqlar uchun
  alohida matn (`MET_WINS_1`, `MET_BOSSES_1`).
- Bozordagi "Test rejimi" yozuvi faqat sinov rejimida chiqadi (haqiqiy Billing ulanganda yo'qoladi).

## 4. Ekran nisbatlari
1280×720 (16:9), 1600×720 (20:9, zamonaviy telefon), 1024×768 (4:3, planshet) da
bosh menyu, jang, xarita, ustaxona tekshirildi — elementlar ekrandan chiqmaydi, ustma-ust tushmaydi.

## 5. Kampaniya qiyinligi
Batafsil: `docs/campaign-balance.md`. Bot (o'rta AI, qo'lda boshqaruvsiz) natijalari:

| Kampaniya | G'alaba | O'rt. yulduz |
|---|---|---|
| Chingizxon | 95% | 2.9 |
| Jaloliddin | 87% | 2.6 |
| Amir Temur | 75% | 2.3 |
| Boyazid | 90% | 2.7 |

Hech bir bosqich 50% dan past emas → keskin "devor" yo'q. Kampaniyalar ketma-ket ochilgani uchun
o'yinchi Boyazidga kelganda ustaxona yaxshilanishlari bilan kuchliroq bo'ladi.

## 6. Ochiq masalalar (foydalanuvchi / 7-8 bosqich)
- Haqiqiy telefonda sinov: boshqaruv qulayligi, FPS, ovoz balandligi.
- Haqiqiy AdMob va Google Play Billing (akkauntlar kerak — `NEEDS_USER.md`).
- Store materiallari va release AAB (8-bosqich tayyorgarligi — keyingi ish).
