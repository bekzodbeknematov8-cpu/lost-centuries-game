# Jarayon

### Foydalanuvchi talablari (navbatdagi ishlar uchun MUHIM)
- Bosqichlar yulduz bilan ochiladi, lekin juda qiyin emas; qiziqarlilik saqlansin (PLAN.md §9).
- Jang oxiri: tangani 2× qilish uchun rewarded reklama, kunlik chegara bilan.
- Zaxira qo'shin paketlari (masalan, 100 kamonchi ≤ 4 000 so'm), adolatli narxlar, pulga yutiladigan o'yin bo'lmasin.


### 2026-11-23 (33) — Jonli grafika (1): askarlar va otlar
- Foydalanuvchi: "masofa yaxshi, endi yana jonliroq, realroq". Rassom grafikasi kelguncha kod chizmasi boyitildi:
  piyodalar (tizza bukiladigan oyoqlar, etik, soyali to'n, kamar, sovut plastinkalari, yuz/soqol, dubulg'a yaltirashi, kontur),
  otlar (kontur, qorin soyasi, ikki bo'g'imli oyoqlar, yol, ko'z/quloq, jilov, to'liq dum), chavandozlar (etik, soyali gavda, yuz).
- LOD: ekranda 55+ askar bo'lsa soddaroq chizma (telefonda tezlik). 150 birlik: chizish ~7,5 ms/kadr.
- `tools/art_preview.gd` — eski/yangi uslubni yonma-yon solishtirish.

### 2026-11-23 (32) — Jiddiy xato tuzatildi: otliq va sarkardalar dushman oldida turib qolardi
- Qisqa qurolli askarlar (qilichboz, otliq, sarkarda) dushmandan 1 qadam uzoqda to'xtab, hujum qilmay qolardi. Tuzatildi.
- Askarlar balansi qayta qurildi ("tosh-qaychi-qog'oz" jadvali), kampaniyalar/turnir/kunlik sinov qayta o'lchandi — devor yo'q.
- Oldingi commit (cbe41d7) yiqilgan test bilan push qilingan edi (CI qizil) — shu commit bilan tuzatildi.

### 2026-11-23 (31) — Masofa: askarlar tezroq yuradi
- Foydalanuvchi: "dushmanlar orasidagi masofa juda uzoq". Maydonni qisqartirish jangni cho'zdi (sinab ko'rildi, bekor qilindi),
  o'rniga yurish tezligi ×1.4 (qal'adan qal'agacha ~16 s). Jang o'rtacha 1,7 daqiqa.
- Kampaniyalar 83–95%, turnir har raund 62–100%, kunlik sinov 41–62% — devor yo'q.

### 2026-11-23 (30) — Grafika: "realga yaqinroq"
- Foydalanuvchi: "yana jonliroq, realga yaqinroq bo'lsin". Kodda chizilgan batafsil uslub namunasi ko'rsatildi
  (`docs/prototypes/art_v2_preview.png`, patch saqlab qo'yildi), foydalanuvchi **haqiqiy rassom grafikasini** tanladi.
- `docs/art-brief.md` — rassom uchun texnik topshiriq (o'zbekcha + inglizcha): 7 askar, 7 sarkarda, qal'a, 4 fon,
  animatsiyalar, o'lchamlar, rang niqobi, nomlash, huquqlar. Keyingi qadam: rassom fayllari kelgach o'yinga ulash
  (rasm bo'lmagan joyda hozirgi chizma qoladi).

### 2026-11-23 (29) — Jonlantirish (3): KO'RINISH va TARANGLIK — reja tugadi
- Kamera yaqinroq (askarlar ~20% kattaroq), zarar raqamlari, kuchli zarbada silkinish va chaqnash.
- Oltin tangalari hisobga uchadi; qal'a qulashida sekin harakat va katta portlash; g'alabada konfetti.
- Kampaniyalar biroz qiyinlashtirildi (bot 87–94%), devor yo'q. Boshlanishdagi maslahat matni "Maqsad" bilan ustma-ust tushmaydi.
- Jonlantirish (1)–(3) tugadi: jang 3,1 → 1,8 daqiqa, "O'q yog'dir", "Jangovar ruh", jonli effektlar.

### 2026-11-23 (28) — Jonlantirish (2): TA'SIR — "O'q yog'dir" va "Jangovar ruh"
- Maydonga bosib qal'adan o'q yog'dirish (har 8 s), nishon belgisi, qal'adan uchgan o'qlar, o'ngda tayyorlik tugmasi.
- Ketma-ket 5 yiqitish — "Jangovar ruh!" (+15% zarar/tezlik, 6 s). Ikkalasi ham AI'da bor (adolatli).
- O'rgatuvchi bosqichga yangi qadam. Alp Arslon kuchi muvozanatlandi.
- O'lchov: jang 1,8 daqiqa; kampaniyalar 90–99% (devor yo'q, keyingi qadamda biroz qiyinlashtiriladi), turnir va kunlik sinov joyida.

### 2026-11-23 (27) — Jonlantirish (1): TEZLIK (foydalanuvchi fikri asosida)
- Foydalanuvchi: "zerikarli — sekin va uzoq, qiladigan ish yo'q, ko'rinishi oddiy". Reja: (1) tezlik, (2) ta'sir, (3) ko'rinish.
- `data/tempo.json`: maydon qisqa, yurish/tayyorlash/daromad tezroq, qal'a zaifroq, kuchlar tez tiklanadi.
- Jang o'rtacha 3,1 → 1,6 daqiqa; birinchi to'qnashuv 7 s. `tools/tempo_report.gd` qo'shildi.
- "Sarkarda yiqildi" yozuvi endi haqiqiy vaqtni ko'rsatadi; kuch tugmasidagi doira yangi tiklanish vaqtiga mos.
- Kunlik sinov: "Chidab tur" 150 s, "Oltin oqimi" teng daromad. Kampaniya, turnir, kunlik balansi qayta o'lchandi — devor yo'q.

### 2026-11-18 (26) — 2-navbat (C): Kunlik sinov jangi (rejali ish)
- Rejim tanlashda 6-karta "Kunlik sinov": har kuni sana bo'yicha 8 ta qoidadan biri (otliqlar kuni, zaif qal'alar,
  oltin oqimi, o'q va nayza, sarkardasiz jang, fillar va miltiqlar, chidab tur, qilichlar to'qnashuvi),
  ketma-ket ikki kun bir xil qoida chiqmaydi; raqib sarkarda va relyef ham kunga qarab.
- Mukofot kuniga bir marta (◉250 + ♦5). `data/daily_challenge.json`, `tools/daily_balance.gd`.
- Har qoida bot bilan o'lchandi: 50–75%; "Chidab tur" 37% → dushman daromadi pasaytirildi → 58%.
- Rejim kartalari 6 tasini sig'diradi.

### 2026-11-18 (25) — 2-navbat (B): yangi askarlar — miltiqchi va jangovar fil (rejali ish)
- Miltiqchi (100 ★): uzoqdan, sekin, kuchli; o'q va chaqnash, tutun; yangi ovoz.
- Jangovar fil (250 ★): kajavali fil, yangi "bosib o'tish" mexanikasi (2 qo'shni dushmanga ham zarar); fil na'rasi ovozi.
- Qarshi turish (teng narxli otryadlar): fil > qilichboz/kamonchi; nayzachi, miltiqchi > fil; otliq > miltiqchi.
- HUD faqat ochiq askarlarni ko'rsatadi (7 tagacha sig'adi). AI yangi askarlarni ishlatadi va ularga qarshi javob beradi.
- Dushman fillari faqat tarixan bo'lgan joyda (Dehli, Lahor, Panipat, Xanva). Kampaniyalar qayta o'lchandi: devor yo'q.

### 2026-11-17 (24) — 2-navbat (A): Alp Arslon kampaniyasi, 2-qism (rejali ish)
- 6-kampaniya "Malazgirt sari" (1063–1072): Marv, Ray, Ani, Jand, Kirmon, Isfahon, Gurjiston, Halab,
  Malazgirt, Amudaryo — 250 level (jami **1500 level**). 375 ★ va Boburning 2 viloyatidan keyin ochiladi.
- Xarita va 10 ta manbali fakt (Ibn al-Asir, Attaleiat va b. asosida), 4 tilda.
- Qiyinlik: birinchi o'lchov 100% (juda oson) → dushman iqtisodi oshirildi → 90%, bosslar 50–75%.
- `UITheme.fit_text`: uzun nomlar kichrayadi, sig'masa "…" bilan qisqaradi (kampaniya tablari, kuch tugmasi).
- Kampaniya tablari 6 tasini sig'diradi.

### 2026-11-17 (23) — 2-navbat (A): Alp Arslon, 1-qism (rejali ish)
- Oltinchi sarkarda Alp Arslon: baland uchli qalpoq, oltin hoshiya, lentalar; zangori plash.
- Yangi turdagi kuch "Saljuq chopqini": 15 s ga 4 ta otliq kamonchi chaqiradi; keyin ular chiqib ketadi
  (aholi chegarasi va yo'qotishlar hisobiga kirmaydi). Yangi `UnitState.life` mexanizmi.
- Erkin jang, turnir, ustaxona (5500 tanga). Sarkarda tanlash va turnir tugmalari 6 tasini sig'diradi.
- Qahramonlar balansi: o'rtacha (~66%), keskin ustunlik yo'q. Keyingisi: Alp Arslon kampaniyasi.

### 2026-11-17 (22) — Yangilanish: Bobur kampaniyasi, 2-qism (rejali ish)
- 5-kampaniya "Bobur yo'li" (1494–1527): Andijon, Samarqand, Saripul, Kobul, Qandahor, Hisor, Bajaur,
  Lahor, Panipat, Xanva — 10 viloyat × 25 = 250 level (jami **1250 level**). 300 ★ va Boyazidning 2 viloyatidan keyin ochiladi.
- Yangi xarita (`tools/gen_maps.py`), 10 ta manbali fakt ("Boburnoma" asosida), 4 tilda.
- Qiyinlik: birinchi o'lchovda 60% (juda qiyin) → egri chiziq Temur darajasiga tushirildi → 82%, devor yo'q.
- Kampaniya tablari 5 tasini sig'diradi; g'alaba oynasida bir xil sandiqlar "×N" bo'lib guruhlanadi
  (ko'p yulduz birdan kelganda ro'yxat ekrandan chiqib ketardi).

### 2026-11-16 (21) — Yangilanish: Yangi sarkarda Bobur, 1-qism (rejali ish)
- Zahiriddin Muhammad Bobur: Temuriylar uslubidagi yashil salla va oltin jig'a, yashil plash.
- Maxsus kuch "To'p zarbasi": 3 ta ketma-ket portlash (zarar 55, itarish, 0.8 s karaxtlik), yangi zambarak ovozi.
- Erkin jang, turnir va ustaxonada (4500 tanga) mavjud. Qahramonlar balansi: o'rtacha, keskin ustunlik yo'q.
- Tuzatildi: maxsus kuch tugmasidagi to'liq doira poligoni "triangulation failed" xatosini berardi
  (smoke test endi bu xatoni ham ushlaydi).
- Keyingi qism: Bobur kampaniyasi (10 viloyat), xarita, tarixiy faktlar.

### 2026-11-16 (20) — Yangilanish: Turnir (rejali ish)
- Rejim tanlashdagi "Turnir" kartasi ochildi: sarkarda tanlanadi, ketma-ket 8 jang, raqib — boshqa sarkardalar
  navbat bilan, AI va iqtisod kuchayib boradi (`data/tournament.json`).
- Bitta mag'lubiyat turnirni tugatadi; jangdan chiqish yoki qayta boshlash ham mag'lubiyat (aldashning oldini olish).
- Har raund uchun tanga, chempionga oltin sandiq + ♦15; eng yaxshi natija va chempionlik soni saqlanadi.
- Qiyinlik bot bilan o'lchandi (`tools/tournament_balance.gd`): har raund 58–91%, devor yo'q.
- Shriftda yo'q emoji (🔒, 🎁) olib tashlandi.

### 2026-11-16 (19) — Yangilanish: Haftalik vazifalar (rejali ish)
- Rejim tanlashdagi "Haftalik vazifalar" kartasi ochildi: har hafta (dushanbadan) 5 ta vazifa,
  sana bo'yicha deterministik tanlanadi (`data/weekly.json` hovuzidan 12 ta, ko'rsatkichlar takrorlanmaydi).
- Progress = hafta boshidagi qiymatdan farq; o'tgan haftalardagi natijalar hisoblanmaydi.
- Mukofotlar: tanga / la'l / sandiq; hammasi bajarilsa oltin sandiq bonusi.
- Yangi hisoblagichlar: battles, stars_gained, boss_wins, waves.
- Rus tilidagi ko'plik xatolari ("3 сундуков") ikki nuqtali shaklga o'tkazildi; rejim kartasi izohi sig'may qolsa kichrayadi.

### 2026-11-16 (18) — Yangilanish: Fathlar, 1000 level (rejali ish)
- Har viloyatda 25 level → 4 sarkarda × 10 viloyat × 25 = **1000 level**. Qiyinlik viloyat ichida silliq oshadi.
- Keyingi kampaniya: 2 viloyat zabt + 75/150/225 yulduz. Eski saqlashlar buzilmaydi (testlar bilan tekshirildi).
- Xarita paneli 5×5 panjara (25 level) sig'diradi.
- Kampaniya balansi qayta o'lchandi: 97% / 88% / 77% / 93% (bot), devor yo'q.

### 2026-11-15 (17) — 8-bosqich tayyorgarligi: Play Market materiallari (rejali ish)
- `store/listing/` — nom, qisqa va to'liq tavsif 4 tilda (en-US, ru-RU, tr-TR, uz), limitlar tekshirilgan.
- `store/screenshots/<til>/` — 6 tadan 1920×1080 skrinshot (`tools/store_shots.sh`, demo progress bilan).
- `store/graphics/feature_<til>.png` — 1024×500 feature graphic (`tools/make_feature.py`).
- `docs/privacy-policy.md` (inglizcha) va `store/data-safety.md` (Data Safety, reklama, reyting javoblari).
- Release AAB CI: `.github/workflows/release.yml` (qo'lda yoki v* tegida), "Android AAB" preset
  (Gradle, target SDK 36). Kalit faqat GitHub Secrets orqali; sirlar bo'lmasa vaqtinchalik kalit bilan sinov.
- Tuzatildi: ikki sarkarda yonma-yon kelganda nomlari ustma-ust tushardi.
- Dev bayroqlar: `--no_hud`, `--cam_fight`, `--cam_zoom=` (faqat reklama rasmlari uchun).

### 2026-11-15 (16) — 6-bosqich: performance, 4 til, yakuniy hisobot (rejali ish)
- 150 birlik stress-test (`tools/stress_test.gd`): nishon qidiruvi O(n²) edi → saralangan indeks.
  150 birlik: o'rtacha qadam 6.1 → 1.3 ms, eng yomon 65 → 8 ms. Natija eski kod bilan aynan bir xil.
- `tools/lang_shots.sh`: 12 ekran × 4 til skrinshot; "Win 1 battles" kabi xatolar tuzatildi.
- 20:9 va 4:3 ekranlar tekshirildi. Kampaniya balansi qayta o'lchandi (devor yo'q).
- `docs/final-test-report.md` yozildi.

### 2026-11-15 (15) — 5-bosqich sayqal: fonlar, ovoz, o'tishlar (rejali ish)
- Jang foni viloyat relyefiga mos: cho'l (qum barxanlari), tog' (qorli cho'qqilar, toshlar),
  yashil (daraxtlar, gullar), dasht. Relyef `data/maps.json` dagi `terrain` dan olinadi;
  erkin jangda tasodifiy.
- Ovoz balandligi tenglandi: har bir ovoz RMS o'lchovi asosida `Sfx.GAIN` koeffitsienti oladi
  (masalan, "deny" 0.45, "horse"/"pick" 1.25).
- Menyu o'tish animatsiyasi: `Transition` autoload, barcha ekranlar orasida yumshoq fade.

### 2026-11-15 (14) — Yutuqlar (rejali ish)
**Bajarildi**
- 20 yutuq (`data/achievements.json`): g'alabalar, yulduzlar, viloyat bosslari, cheksiz mudofaa to'lqini,
  yengilgan dushmanlar, ustaxona, sandiqlar, hiylalar, kunlik mukofot, libos, sarkardalar; har biri tanga/la'l beradi.
- Statistika hisoblagichlari (g'alaba, o'ldirish, sandiq, hiyla, kunlik) saqlashga qo'shildi; bosslar barcha
  slotlardan sanaladi.
- Yutuqlar ekrani (progress chizig'i, "Olish"), bosh menyudagi tojda olinadigan mukofotlar soni (qizil nuqta).
- 1 yangi test (52), smoke 32.

### 2026-11-15 (13) — 3 saqlash sloti va qiyinlik (rejali ish)
**Bajarildi**
- Saqlash formati v2: 3 slot, har birida kampaniya yulduzlari va qiyinlik (O'rta / Qiyin / Afsona).
  Tanga, la'l, xaridlar, libos, yaxshilanishlar — umumiy (slotga bog'liq emas, pullik narsa yo'qolmaydi).
  Eski progress avtomatik 1-slotga ko'chiriladi.
- Qiyinlik: Qiyin — dushman iqtisodi ×1,12, qal'a ×1,1, AI bir daraja yuqori; Afsona — ×1,25 / ×1,25.
- Slotlar ekrani (progress %, ★, qiyinlik, "Davom etish", o'chirish tasdig'i bilan); Kampaniya shu orqali.
- 2 yangi test (51), smoke 30.

### 2026-11-14 (12) — §12(h): O'rgatuvchi bosqich (rejali ish)
**Bajarildi**
- 7 qadamli o'rgatish (`TutorialLogic`): ishchi → qilichboz → 3 askar to'plash → Hujum → qahramon kuchi →
  Boshqarish → yakun. Kerakli tugma sariq ramka va o'q bilan yoritiladi; "O'tkazish" tugmasi bor.
- 3-qadamgacha dushman kutib turadi (yangi o'yinchi bosim ostida qolmasin).
- Yangi o'yinchi "O'YNASH" ni bosganda to'g'ridan-to'g'ri o'rgatuvchi levelga tushadi;
  Sozlamalarda "O'rgatishni qayta ko'rish". 1 yangi test (49), smoke 28.

**Sinovda topilgan va tuzatilgan**
- Boshlang'ich maslahat yozuvi va level banneri o'rgatish paneli bilan ustma-ust tushardi → tuzatildi.

### 2026-11-14 (11) — §12(g): Bozor (rejali ish)
**Bajarildi**
- `data/market.json`: Boshlang'ich to'plam ($1.99, bir martalik: 200 la'l + oltin sandiq + Temuriy libosi +
  3 nog'ora), la'l paketlari ($0.99 / $4.99 / $9.99 → 60 / 330 / 700), Reklamasiz ($2.99, 2× mukofot reklamasiz),
  zaxira qo'shin paketlari la'lga (100 kamonchi 60♦, 100 qilichboz 50♦, 50 otliq 80♦), bepul la'l reklama orqali
  (kuniga 3 × 5♦). Narxlar Google Play USD pog'onalari; haqiqiy mahalliy narx Play Billing'dan keladi.
- `Billing` autoload — SINOV rejimi (tasdiq oynasi, pul olinmaydi); haqiqiy Play Billing 7-bosqichda.
- Jangda zaxira tugmalari: bir bosishda 5 askar, bir jangda ko'pi bilan 10, aholi chegarasiga kiradi (adolat).
- 2 yangi test (48), smoke 27 (zaxira chaqirish ham sinovda).

### 2026-11-14 (10) — §12(f): Libos (rejali ish)
**Bajarildi**
- 6 kiyim to'plami (`data/outfits.json`): Klassik (bepul), Temuriy, Dasht (800 tanga), Xorazm, Usmonli
  (1200 tanga), Oltin (80 la'l). Butun qo'shin, qal'a bayrog'i va mini-xaritaga qo'llanadi; faqat ko'rinish.
- Libos ekrani: dasht va o'tovlar fonida 5 askar namunasi, "Ko'rish" (oldindan ko'rish), sotib olish, kiyish.
- `Painter.team_colors()` — o'yinchi libosi faqat team 0 ga. 1 yangi test (46), smoke 24.

### 2026-11-14 (9) — §12(e): Sandiqlar va kunlik mukofot (rejali ish)
**Bajarildi**
- 3 sandiq (`data/chests.json`): Kumush (300 tanga, 2 mukofot), Oltin (40 la'l, 3), La'l (100 la'l, 4);
  ichida tanga / tasodifiy hiyla / la'l. Ehtimollar "Ehtimollar" panelida ochiq ko'rsatiladi (Google Play talabi).
- Sandiqlar ekrani: tanlash, sotib olish, ochish animatsiyasi (qopqoq, nur, mukofot kartalari).
- Kunlik mukofot: 7 kunlik tsikl (tanga, hiyla, kumush sandiq, la'l, oltin sandiq); kun o'tkazib yuborilsa
  seriya qaytadan; bosh menyuda avtomatik ochiladi.
- Bossni birinchi yengishda kumush sandiq, har 25 ★ da oltin sandiq.
- CI tezlashtirildi: smoke test CI'da qisqaroq (`SMOKE_SECONDS=100`). 3 yangi test (45), smoke 22.

**Sinovda topilgan va tuzatilgan**
- Ehtimollar paneli mukofot kartasini yopardi → pastga ko'chirildi.

### 2026-11-14 (8) — §12(d): Hiylalar (rejali ish)
**Bajarildi**
- 6 ta bir martalik jang hiylasi (`data/tactics.json`): Karvon (+300 oltin), Tez qazish (30 s 2×),
  Tabib (hammani 50% davolash), Qalqon devori (12 s −40% zarar), Jangovar nog'ora (12 s +30% tezlik,
  +15% kuch), Minora yomg'iri (20 s 3× tez o'q). Bir jangda ko'pi bilan 3 ta (adolat uchun).
- Hiylalar do'koni (tangaga), yangi o'yinchiga 2 Karvon + 2 Tabib sovg'a; jangda chap pastda tugmalar,
  har biri uchun ovoz/effekt. 3 yangi test (42), smoke 20.

**Sinovda topilgan va tuzatilgan**
- Bosh menyuda Variant tip xatosi (unit testlar ushlamadi, skrinshot/smoke ushladi) → tuzatildi.

### 2026-11-14 (7) — §12(c): Ustaxona va qahramonlarni ochish (rejali ish)
**Bajarildi**
- `data/upgrades.json` + `Upgrades` (sim): 6 ta doimiy yaxshilanish — sovut (HP +5%/daraja), tig'lar (zarar +4%),
  konchilar (oltin +8%), qal'a devorlari (HP va minora +8%), xazina (+50 boshlang'ich oltin), sarkarda qudrati
  (+6% qahramon, kuch 3% tezroq). Narx har darajada ~1,4–1,6× oshadi. Faqat o'yinchi tomoniga ta'sir qiladi.
- Qahramonlar: Chingizxon bepul; qolganlari o'z kampaniyasi ochilganda bepul yoki Ustaxonada tangaga
  (1500 / 2500 / 3500). Qahramon tanlashda yopiqlari qulf bilan.
- Ustaxona ekrani (chodir uslubida), bosh menyuda "Ustaxona" tugmasi. 3 yangi test (39), smoke 18.

**Sinovda topilgan va tuzatilgan**
- `game_state.gd` da tip xatosi: testlar o'tgan bo'lsa ham qat'iy runner SCRIPT ERROR ni ushladi → tuzatildi.

### 2026-11-13 (6) — §12(b): yangi bosh menyu va rejim tanlash (rejali ish)
**Bajarildi**
- Bosh menyu: Registon uslubidagi siluetli kechki fon, katta qahramonlar, "O'YNASH",
  Hiylalar / Libos / Sandiqlar / Bozor (hozircha "Tez orada"), tanga va la'l hisoblagichi,
  pastda: kunlik mukofot, yutuqlar, reyting (tez orada), sozlamalar (til, ovoz, musiqa).
- Rejim tanlash: Kampaniya · Erkin jang (qiyinlik oynasi) · Cheksiz mudofaa (rekord bilan) ·
  Turnir va Haftalik vazifalar (yopiq, yangilanishda).
- La'l (premium valyuta) saqlash formatiga qo'shildi; 36 test, smoke 16 tekshiruv.

### 2026-11-13 (5) — §12(a): viloyatli tarixiy xaritalar (rejali ish)
**Bajarildi**
- 4 qahramon uchun tarixiy xarita (`tools/gen_maps.py` → `assets/maps/*.png`): eski qog'oz uslubi,
  organik viloyat chegaralari, dengizlar (Kaspiy, Orol, Qora dengiz ...), daryolar, relyef belgilari.
- Har viloyat = bo'lim: 9 ta avtomatik level (viloyat shabloni: qiyinlik silliq oshadi, mudofaa/
  oldinroq boshlovchi dushman/qo'shimcha oltin modifikatorlari) + oxirida tarixiy boss (fakt kartasi bilan).
  Jami 4 × 10 × 10 = **400 level** (1.0); keyin 25 gacha kengaytirish mumkin (`Campaign.REGION_LEVELS`).
- Kampaniya ekrani: xarita (shader: yopiq — kulrang, zabt — qahramon rangi, tanlangan — yorqin),
  zabt yo'li, qahramon bayrog'i, viloyatni bosib tanlash; o'ngda 10 level tugmasi (boss — toj).
- Ochilish: keyingi qahramon = oldingisining 4 viloyati + 60/130/200 ★ (eng qisqa yo'lda ~1,6 ★/level).
- Qiyinlik (bot, 3 jang/level, har viloyatdan 3 namuna): 94% / 86% / 90% / 95%, keskin "devor" yo'q.

**Sinovda topilgan va tuzatilgan**
- 4-kampaniya yulduz talabi (260) o'rtacha 2+ ★/level talab qilardi → 200 ga tushirildi (test ushladi).
- Xarita tasodifiy urug'i Python hash'ga bog'liq edi (har safar boshqacha) → deterministik qilindi.
- Uzun qahramon nomi tabda kesilardi → shrift avtomatik kichrayadi.

### 2026-11-13 (4) — cheksiz mudofaa va 2× reklama (rejali ish)
**Bajarildi**
- Cheksiz mudofaa: har 32 s da kuchayib boruvchi dushman to'lqini, har 5-to'lqinda sardor;
  dushman qal'asi buzilmaydi; natija = yetib borilgan to'lqin, rekord saqlanadi, menyuda ko'rinadi.
- Jang oxirida "Reklama ko'rib 2× olish" tugmasi (ixtiyoriy), kuniga 5 marta (`ProgressStore.AD_DAILY_LIMIT`).
  Hozircha `Ads` autoload SINOV rejimida (3 s oyna); haqiqiy AdMob 7-bosqichda ulanadi.
- 3 yangi test (34 jami), smoke test 12 tekshiruv.

### 2026-11-13 (3) — 3-bosqich: kampaniyalar (rejali ish)
**Bajarildi**
- 4 kampaniya × 10 bosqich (`data/campaigns.json`): tarixiy joylar, mudofaa ("bardosh ber") bosqichlari,
  boss bosqichlari (Sind: Jaloliddin vs Chingizxon; Anqara: Temur vs Boyazid va aksincha).
- 1–3 yulduz: g'alaba / qal'a 50%+ / qal'a 80%+ yoki tez g'alaba. Kampaniyalar 15/35/55 ★ bilan ochiladi
  (o'rtacha 1,5–1,8 ★/bosqich — yumshoq talab).
- 40 ta tarixiy fakt kartasi, 4 tilda (`data/facts.json`), g'alaba oynasida chiqadi.
- Kampaniya xaritasi ekrani, natija oynasida yulduz animatsiyasi, tanga, "Keyingi bosqich".
- Saqlash: `ProgressStore` (atomik yozish, buzilgan faylga chidamli).
- Bosh menyu: "Kampaniya" + "Erkin jang (Oson/O'rta/Qiyin)".
- `tools/run_tests.sh`: SCRIPT ERROR bo'lsa ham test yiqiladi (CI ham shuni ishlatadi).

**Sinovda topilgan va tuzatilgan**
- Saqlash testi skript xatosida jim "o'tib" ketardi → qat'iy runner + ProgressStore ajratildi.
- Mudofaa taymeri ekrandan chiqib ketardi; "Yollangan" boshlang'ich ishchilarni sanardi → tuzatildi.
- Kampaniya juda oson edi (bot 1,5 daqiqada 100% 3★): qahramon yolg'iz qal'ani yiqitardi →
  qahramonlar biroz susaytirildi, qal'a minorasi qahramonlarga 2× uradi, qahramonsiz bosqichlarga
  "Dushman sardori" qo'shildi, qiyinlik egri chizig'i sozlandi. Natija (`docs/campaign-balance.md`):
  bot g'alabasi 97% → 77% → 77% → ~80%, o'rtacha 2,3–2,9 ★.

### 2026-11-13 (2) — foydalanuvchi fikri asosida
**Foydalanuvchi aytdi:** boshqaruv tugmalari xunuk va o'ngdagi jangchilarni to'sadi; ikonka xunuk; qiziqarliroq qilish kerak.
**Bajarildi**
- HUD qayta qurildi: barcha tugmalar pastki panelda, ixcham dumaloq ikonka-tugmalar (kod bilan chizilgan),
  jang maydoni to'liq ochiq. Boshqaruv rejimida chap/o'ng va Zarba ham pastki panelda.
- Yangi ikonka (dubulg'a, chalishtirilgan qilichlar, quyosh) + Android adaptive ikonka.
- 2-bosqich: 4 qahramon (Chingizxon — Dasht bo'roni, Jaloliddin — Sind sakrashi,
  Amir Temur — Kuch adolatda, Boyazid — Yashin hujumi): o'z ko'rinishi, oti, plashi,
  maxsus kuch tugmasi (qayta tiklanish soati), o'lsa 40 soniyada qaytadi, AI ham ishlatadi.
- Qahramon tanlash ekrani (tarixiy sana va kuch tavsifi bilan), jang boshida "X VS Y" banneri.
- 5 yangi ovoz (o'q yomg'iri, sakrash, momaqaldiroq, karnay-nog'ora chorlovi, qahramon yiqilishi).
- Dushman endi ertaroq kichik to'lqinlar bilan hujum qiladi (jang tezroq qizishadi).
- Testlar: 23 (7 tasi qahramonlar uchun), smoke test 3 sahna.
- Qahramonlar balansi (16 jang/juftlik): Temur biroz kuchli, Boyazid biroz zaif edi → sozlandi
  (Temur chorlovi +30%, 38 s; Boyazid HP 1080, yashin 85). 6-bosqichda ko'proq jang bilan qayta tekshiriladi.


## Holat: 0–3 ✅ · §12(a) xaritalar ✅ · §12(b) menyu ✅ · §12(c) ustaxona ✅ · §12(d) hiylalar ✅ · §12(e) sandiqlar ✅ · §12(f) libos ✅ · §12(g) bozor ✅ · §12(h) tutorial ✅ · 3 saqlash sloti ✅ · yutuqlar ✅ · 5-bosqich sayqal ✅ · 6-bosqich ✅ · 8-bosqich tayyorgarligi ✅ · yangilanish (a) Fathlar 1000 level ✅ · (b) haftalik vazifalar ✅ · (c) turnir ✅ · (d) Bobur 1-qism ✅ · (d) Bobur kampaniyasi ✅ · yangilanishlar navbati (a)–(d) tugadi; 7-bosqich foydalanuvchi akkauntini kutadi

### 2026-11-13
**Bajarildi**
- Loyiha skeleti (Godot 4.5.1), CI (testlar → APK/Web eksport → Releases "dev-latest").
- Jang mantig'i: oltin iqtisodi, ishchilar, 5 ta birlik (ishchi, qilichboz, nayzachi, kamonchi, otliq),
  yollash navbati, aholi chegarasi, Hujum/Himoya/Chekinish, qal'a minorasi o'qlari, g'alaba/mag'lubiyat.
- Askarni qo'lda boshqarish (chap/o'ng + Zarba, +25% kuch).
- Dushman AI: 3 daraja (oson/o'rta/qiyin), raqib qo'shiniga qarab qarshi birlik tanlaydi.
- Grafika (kodda): jangchilar animatsiyasi, otlar, qal'alar (shikastlanish yoriqlari), kon, parallaks fon,
  uchqun/chang/vayrona effektlari.
- HUD: oltin, aholi, qal'a HP, mini-xarita, birlik tugmalari, pauza, natija oynasi. Bosh menyu. 4 til.
- Ovoz: 25 xil effekt (55 variant), to'qnashuv turiga qarab turli ovoz; 2 musiqa (jang, menyu).
- Testlar: 16 unit/simulyatsiya testi, smoke test, Xvfb skrinshot, Web build brauzerda sinaldi.

**Sinovda topilgan va tuzatilgan**
- Pastki tugmalar askarlarni yopib qo'yardi → jang maydoni yuqoriga ko'chirildi.
- Jang qayerda ketayotgani ko'rinmasdi → mini-xarita qo'shildi.
- GDScript tip xatolari (painter, hud) → tuzatildi; smoke test qo'shildi.

**Balans sinovi (bot-vs-bot) natijasida topilgan va tuzatilgan**
- Nayzachi hamma narsani yengardi, qilichboz juda zaif edi → statlar qayta sozlandi.
- Simulyatsiyada nosimmetriklik: ro'yxatdagi tartib bir tomonga "birinchi zarba" berardi →
  zarbalar qadam oxirida bir vaqtda qo'llanadi, yurish tartibi har qadamda aralashtiriladi (seed bilan).
- Hamma bitta nishonga hujum qilardi (ortiqcha zarar) → nishonlar yaqin dushmanlar orasida taqsimlanadi.
- Natija (teng narxli otryadlar): qilichboz > nayzachi > otliq > qilichboz; otliq > kamonchi.
- Qiyinlik: qiyin bot o'rtani ~75%, osonni ~100% yengadi.

**Ochiq masalalar**
- Kamonchilar aralash qo'shinda hali yetarlicha foydali emas (6-bosqichda sozlanadi).
- Haqiqiy telefonda sinov (foydalanuvchi): boshqaruv qulayligi, ovoz balandligi, tezlik.

**Keyingi**
- 2-bosqich: qahramonlar (Chingizxon, Jaloliddin, Amir Temur, Boyazid) va maxsus kuchlar.
