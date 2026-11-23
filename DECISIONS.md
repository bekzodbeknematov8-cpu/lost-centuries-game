# Qarorlar jurnali

| Sana | Qaror | Sabab |
|---|---|---|
| 2026-11-13 | Godot **4.5.1** stable, GL Compatibility renderer | Barqaror; arzon Android telefonlarda ham ishlaydi; 4.6 yangi, kamroq sinalgan |
| 2026-11-13 | Jang mantig'i (`scripts/sim`) chizishdan to'liq ajratilgan, qat'iy 1/30 s qadam | Headless rejimda minglab bot-vs-bot simulyatsiya, deterministik testlar |
| 2026-11-13 | Barcha grafika kod orqali chiziladi (`painter.gd`) | Mualliflik muammosi yo'q, kichik hajm; keyinroq rassom grafikasi bilan almashtirish mumkin |
| 2026-11-13 | Barcha ovoz va musiqa `tools/gen_audio.py` da sintez qilinadi | 100% original; do'mbira (Karplus-Strong), doira, nog'ora, karnay; hijoz ladi |
| 2026-11-13 | GUT o'rniga o'zimizning yengil test runner | Tashqi bog'liqlik yo'q, CI'da tez |
| 2026-11-13 | Tarjimalar `data/strings.json` da, ish vaqtida TranslationServer'ga yuklanadi | CSV import bosqichiga bog'liq emas |
| 2026-11-13 | Sinov APK: GitHub Actions → Releases "dev-latest" | Bulut konteynerida Android SDK yuklab bo'lmaydi; GitHub runner'larda SDK bor; telefondan yuklash qulay |
| 2026-11-13 | Birliklar: ishchi, qilichboz, nayzachi, kamonchi, otliq | Tosh-qaychi-qog'oz: nayza>otliq>kamonchi>piyoda |
| 2026-11-13 | HUD: barcha tugmalar pastki panelda, dumaloq ikonka-tugmalar | Foydalanuvchi: tugmalar jang maydonini to'sardi |
| 2026-11-13 | Qahramon har jangda bepul, aholi joyi olmaydi, o'lsa 40 s da qaytadi | Har jangda qahramon markaziy rol o'ynashi uchun |
| 2026-11-13 | Qahramonlar `data/heroes.json` da; dushman qahramoni tasodifiy (kampaniyada bosqichdan olinadi) | Balans JSON'da |
| 2026-11-13 | Jaloliddin ingliz/turk tillarida tarixiy nomi bilan (Jalal al-Din Mingburnu / Celaleddin) | Tarixiy aniqlik |
| 2026-11-13 | Kampaniya ochilishi: oldingi kampaniya tugashi + jami 15/35/55 ★ | Foydalanuvchi: "yulduz kerak, lekin juda qiyin bo'lmasin" |
| 2026-11-13 | Qahramonsiz bosqichlarda "Dushman sardori" (tanlab bo'lmaydi) | Aks holda o'yinchi qahramoni yolg'iz yutardi |
| 2026-11-13 | Qal'a minorasi qahramonlarga 2× zarar | Qahramon qo'shinsiz qal'ani ololmasligi kerak |
| 2026-11-13 | Saqlash `user://progress.json`, atomik yozish | Telefon o'chib qolsa ham progress buzilmaydi |
| 2026-11-13 | 2× reklama kuniga 5 marta, faqat tugma bosilganda | Foydalanuvchi talabi; reklama bezor qilmasin, tangalar qadrsizlanmasin |
| 2026-11-13 | Reklama `Ads` autoload orqali (hozir sinov rejimi) | AdMob plaginini keyin kod o'zgartirmasdan ulash uchun |
| 2026-11-15 | Saqlash slotlarida faqat kampaniya progressi; iqtisod va xaridlar umumiy | Pullik narsalar bir slotda qolib ketmasligi uchun |

## 2026-11-16 — Fathlar: 25 level/viloyat (1000 level)
- Har viloyatda 25 level (24 avtomatik + boss). Level ID'lar o'zgarmadi (`region#n`), shuning uchun
  eski saqlashlardagi yulduzlar saqlanadi; yangi #10–#24 levellar #9 dan keyin ochiladi.
- Keyingi kampaniya oldingisining **2** viloyati zabt etilgach ochiladi (avval 4): 2×25 = 50 level,
  avvalgi 4×10 = 40 ga yaqin — o'yinchi kutadigan o'yin vaqti deyarli o'zgarmaydi.
- Yulduz talablari ~1.5 yulduz/level: 75 / 150 / 225 (avval 60 / 130 / 200).
- Migratsiya: kampaniyada allaqachon yulduz bo'lsa, u ochiq qoladi (yangi qoidalar eski progressni yopmaydi).
- `region_levels` va `unlock_after_region` endi `data/campaigns.json` da (balans JSON'da).

## 2026-11-16 — Yangi sarkarda: Zahiriddin Muhammad Bobur
- **Nega Bobur (To'maris emas):** hayoti yaxshi hujjatlashtirilgan — o'zining "Boburnoma" xotiralari
  (asosiy manba), shuningdek Abul Fazlning "Akbarnoma"si. 10 ta viloyatlik kampaniya uchun yetarli aniq voqealar bor:
  Andijon (1494) → Samarqand (1497, 1500, 1511) → Kobul (1504) → Qandahor → Panipat (1526) → Xanva (1527).
  To'maris haqida asosan Gerodotning bitta hikoyasi bor — butun kampaniya uchun manba yetarli emas.
- **Maxsus kuch "To'p zarbasi":** Panipat jangida (1526) Bobur qo'shini zambarak va miltiqlardan foydalangani
  "Boburnoma"da yozilgan. O'yinda: dushman to'dasiga 3 ta ketma-ket portlash — zarar, itarish, qisqa karaxtlik.
  Qon yo'q: faqat chaqnash, tutun va chang.
- **Hurmat:** raqiblar (Shayboniyxon, Lodiylar, Rajput hukmdorlari) neytral, tarixiy hukmdor sifatida
  ko'rsatiladi; hech bir xalq salbiy tasvirlanmaydi.
- Ikki bosqichda: (1) sarkarda, kuch, ko'rinish, erkin jang/turnir/ustaxona; (2) kampaniya, xarita, faktlar.
- Narxi ustaxonada 4500 tanga (oldingilari 1500/2500/3500); kampaniyasi qo'shilgach u orqali ham ochiladi.

## 2026-11-17 — Oltinchi sarkarda: Alp Arslon
- **Nega Alp Arslon (To'maris emas):** manbalar ko'p va mustaqil — Ibn al-Asir ("al-Komil fi-t-tarix"),
  Nizomulmulk davri yozuvlari, Malazgirt (1071) jangini ko'rgan vizantiyalik tarixchi Mixail Attaleiat.
  10 viloyatlik kampaniya uchun aniq voqealar bor (Xuroson, Ani 1064, Gurjiston, Halab 1070, Malazgirt 1071 ...).
  To'maris haqida asosan Gerodotning bitta hikoyasi — kampaniya uchun yetarli emas (yana qoldirildi).
- **Maxsus kuch "Saljuq chopqini" (yangi tur — chaqiruv):** 15 soniyaga 4 ta otliq kamonchi chaqiradi,
  keyin ular jangdan chiqib ketadi (o'lim/yo'qotish hisoblanmaydi, aholi chegarasini egallamaydi).
  Saljuqiy qo'shinida otliq kamonchilar asosiy kuch bo'lgani manbalarda qayd etilgan.
- **Hurmat:** raqiblar (Vizantiya, Fotimiylar, Qoraxoniylar va b.) neytral, tarixiy davlatlar sifatida.
- Narx: ustaxonada 5500 tanga. 2-qism: kampaniya, xarita, faktlar.

## 2026-11-18 — Yangi askarlar: miltiqchi va jangovar fil
- **Miltiqchi:** uzoqdan kuchli zarba, sekin qayta o'qlash. Kamonchi va filni yengadi; otliq va qilichbozga yutqazadi.
  O'yinchiga 100 ★ da ochiladi. Bobur qo'shini o'qotar qurollardan foydalangan ("Boburnoma", Bajaur 1519, Panipat 1526).
- **Jangovar fil:** juda chidamli, bir zarbada 2 ta qo'shni dushmanni ham "bosib o'tadi" (40% zarar).
  Qilichboz, kamonchi, otliqni yengadi; nayzachi va miltiqchiga yutqazadi. O'yinchiga 250 ★ da ochiladi.
- **Dushmanda faqat tarixan bo'lgan joyda:** fillar — Dehli (Temur, 1398), Lahor/Panipat/Xanva (Bobur);
  JSON'da har boss uchun `enemy_extra`. Erkin jang/turnirda oson raqib faqat asosiy askarlar bilan.
- Cheksiz mudofaada: 8-to'lqindan miltiqchi, 12-dan fil.
- Kampaniya balansi vositasi bot-o'yinchiga o'sha kampaniya ochilgan paytdagi askarlarni beradi.

## 2026-11-23 — Jonlantirish (1): tezlik
- Foydalanuvchi telefonda: "zerikarli — sekin va uzoq". O'lchov (tools/tempo_report.gd): jang o'rtacha 3,1 daqiqa.
- Barcha tempo sozlamalari bitta joyda — `data/tempo.json` (BattleSim.setup hamma rejimga qo'llaydi):
  maydon 3200→2400, yurish ×1.25, tayyorlash ×1.4 tez, daromad ×1.35, boshlang'ich oltin ×1.3, qal'a ×0.8,
  sarkarda kuchi qayta tiklanishi ×0.6 (15–23 s), sarkarda qaytishi 40→24 s.
- Natija: jang 3,1 → 1,6 daqiqa, birinchi bosqichlar ~70–85 s. Kampaniyalar: devor yo'q (Chingiz 84%, Temur 82%, qolganlar 91–100%).
- Kuch tiklanishi ham qisqartirildi, aks holda qisqa jangda sarkarda kuchi kam ishlatilib, kampaniyalar qiyinlashardi (Chingiz 73% bo'lib qolgandi).

## 2026-11-23 — Jonlantirish (2): o'yinchi ta'siri
- **"O'q yog'dir":** maydonga qisqa bosish — qal'adan o'sha joyga o'q yomg'iri (8 s, radius 75, 2×12 zarar).
  Ikki tomonga bir xil: dushman AI ham ishlatadi (eng zich to'daga, oson AI faqat 5+ askarga).
  Birinchi variant (17 zarar, 7 s) himoyani juda kuchaytirib jangni 2,3 daqiqaga cho'zdi → pasaytirildi (1,8 daqiqa).
- **"Jangovar ruh":** 4 s ichida 5 ta dushman yiqitilsa — 6 s davomida +15% zarar va tezlik (ikki tomon uchun).
- Sarkarda kuchlari tez tiklanishi (×0.6) bilan Alp Arslon chopqini deyarli doimiy bo'lib qoldi → kuch 44 s, otliqlar 11 s.
- O'rgatuvchi bosqichga "O'q yog'dir" qadami qo'shildi.

## 2026-11-23 — Jonlantirish (3): ko'rinish va taranglik
- Kamera ×1.2 yaqinroq (tempo.json: camera_zoom), zarar raqamlari (kuchli zarba ≥40 — oltin rang, silkinish, chaqnash),
  qazilgan oltin tanga bo'lib hisobga uchadi, qal'a qulashida 1,3 s sekin harakat + portlashlar, g'alabada konfetti.
- Taranglik: har kampaniyaga `enemy_scale` (campaigns.json) — bot g'alabasi 90–99% dan 87–94% ga.
  boyazid_10 (yakuniy boss) 16 jangda 11/16.

## 2026-11-23 — "Dushmanlar orasidagi masofa uzoq" (foydalanuvchi)
- Sinab ko'rildi: maydon 2400→1900 — jang **uzoqlashdi** (74→131 s): himoya chizig'i (qal'adan 520) va himoya zonasi (430)
  qisqa maydonni deyarli butunlay qoplab, ikki qo'shin o'rtada to'xtab qoladi. Bekor qilindi.
- Tanlangan yechim: maydon 2400 qoladi, yurish tezligi ×1.25→×1.4 (qal'adan qal'agacha ~20 s → ~16 s).
  ×1.6 ham sinaldi — birinchi kampaniyalar juda qiyinlashdi (Chingiz 64%).
- Qayta muvozanat: Chingiz/Jaloliddin enemy_scale 0.96, Bobur 1.03, temur_10 daromadi 0.92 (16 jangda 8/16),
  turnir raundlari daromadi ×1.12 (juda oson bo'lib qolgandi), "Chidab tur" dushman daromadi 1.2.
