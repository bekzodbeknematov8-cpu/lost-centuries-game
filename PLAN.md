# JAHONGIRLAR — to'liq ish rejasi (Claude uchun prompt)

> Ushbu matnni yangi sessiyada yoki ish boshida Claude'ga to'liq yuboring.
> Repo ichida u `PLAN.md` bo'lib saqlanadi va `CLAUDE.md` unga havola qiladi.

---

## 1. Rol va maqsad

Sen "Jahongirlar" mobil o'yinining yagona dasturchisi, o'yin dizayneri va testerisan.
Maqsad: Google Play'ga yuklashga tayyor, sifatli, o'ynash qiziqarli va daromad keltiradigan
2D strategik-jang o'yinini noldan oxirigacha yaratish.

- Foydalanuvchi bilan **o'zbek tilida** gaplash.
- Ish bir necha hafta davom etadi va foydalanuvchi ko'pincha yo'q bo'ladi, shuning uchun **mustaqil ishla**:
  oqilona qaror qabul qil, uni `DECISIONS.md` ga yoz va davom et. Faqat haqiqatan
  foydalanuvchiga bog'liq narsalarni (pul, akkaunt, kalitlar) `NEEDS_USER.md` ga yoz.
- Har ish kuni oxirida `PROGRESS.md` ni yangila: nima qilindi, nima qoldi, qanday muammolar bor.
- Kichik bosqichlar bilan ishla va har bir bosqichdan keyin commit va push qil.

## 2. O'yin konsepsiyasi

**Janr:** 2D yondan ko'rinishdagi "qo'shin to'plab, dushman qal'asini yiqit" strategiyasi
(Stick War janriga o'xshash, lekin **butunlay original**: Stick War'ning nomi, chiziqcha-odam uslubi,
dunyosi, birlik nomlari va grafikasi nusxalanmaydi).

**Asosiy sikl (core loop):**
1. Chapda o'yinchi qal'asi, o'ngda dushman qal'asi turadi.
2. Ishchilar konda oltin qazib qal'aga tashiydi.
3. Oltinga askarlar yollanadi (har birining narxi va tayyorlanish vaqti bor).
4. Qo'shinga buyruq beriladi: **Hujum / Himoya / Chekinish**.
5. O'yinchi istalgan askar yoki qahramonni **qo'lda boshqara oladi**
   (joystik bilan harakat, tugma bilan zarba yoki maxsus kuch).
6. Dushman qal'asini (yoki bayrog'ini) birinchi bo'lib yiqitgan tomon g'olib bo'ladi.

**Qahramonlar:**

| Qahramon | Maxsus kuch | O'ziga xos birliklar |
|---|---|---|
| Chingizxon | "Dasht bo'roni": o'q yomg'iri | Otliq kamonchi |
| Jaloliddin Manguberdi | "Sind sakrashi": qurshovdan yorib chiqish, zarba to'lqini | Xorazm suvoriysi |
| Amir Temur | "Kuch adolatda": butun qo'shinga himoya va hujum bonusi | Jangovar fil, og'ir suvoriy |
| Boyazid Yildirim | "Yashin hujumi": tezkor chaqmoq zarbasi | Yangichar, to'p |

**Umumiy birliklar:** ishchi, qilichboz, nayzachi (otliqlarga qarshi kuchli), kamonchi,
qalqonchi, otliq. Balans "tosh-qaychi-qog'oz" tamoyiliga tayanadi.

**Kampaniyalar (osondan qiyinga, har biri 10 bosqichdan):**
1. Chingizxon: dasht qabilalarini birlashtirish (o'rgatuvchi, eng oson).
2. Jaloliddin: Xorazm mudofaasi (o'rtacha).
3. Amir Temur: Movarounnahrdan Anqara jangigacha (1402); final jangi Boyazidga qarshi.
4. Boyazid: Nikopol jangi (1396); eng qiyin.

Kampaniyalar ketma-ket ochiladi. Har bosqich uchun 3 yulduz beriladi
(g'alaba, qal'a holati, vaqt).

**Qo'shimcha rejimlar:** Cheksiz mudofaa (to'lqinlar), "Qiyin" va "Afsona" darajalari.

**Ta'limiy qism:** har bosqichdan keyin 1–2 jumlalik **tekshirilgan** tarixiy fakt kartasi chiqadi.
Tarixiy shaxslar hurmat bilan tasvirlanadi, hech bir xalq kamsitilmaydi.

**Meta-progress:** yulduz va oltin evaziga yaxshilanishlar daraxti (birliklar, qal'a, qahramon kuchlari),
qahramon kiyimlari va saqlash tizimi (lokal fayl).

## 3. Texnologiya

- **Dvijok:** Godot 4 (barqaror versiya, aniq versiyasi `DECISIONS.md` ga yoziladi), GDScript.
- **Testlar:** GUT (Godot Unit Test) va headless "bot vs bot" simulyatsiyalari.
- **Grafika:** kod va SVG orqali chizilgan original, toza "flat" uslub, skelet animatsiyasi
  (Godot Skeleton2D yoki AnimationPlayer). Tashqi assetlar faqat CC0 litsenziyali bo'ladi va
  `CREDITS.md` ga yoziladi.
- **Ovoz:** CC0 effektlar va musiqa yoki procedural generatsiya; `CREDITS.md` ga yoziladi.
- **Tillar:** o'zbek (lotin), ingliz, rus, turk. Barcha matnlar `translations/*.csv` da saqlanadi,
  kodda qattiq yozilgan matn bo'lmaydi.
- **Platforma:** Android (minimal API 24, nishon API Google Play talab qilgan eng so'nggi versiya),
  AAB formatida. Sinov uchun Web (HTML5) build ham chiqariladi.
- **CI:** GitHub Actions: testlar va Android/Web eksport har push'da ishlaydi.

## 4. Repo tuzilmasi

```
project.godot
scenes/        (battle, menu, map, ui)
scripts/       (units, ai, economy, campaign, save, ads, iap, i18n)
data/          (units.json, heroes.json, levels/*.json, facts.json)
assets/        (art, audio, fonts)
translations/
tests/         (unit + simulyatsiya)
tools/         (balans simulyatori, skrinshot generator)
store/         (Play Market matnlari, skrinshotlar, ikonka, feature graphic)
docs/          (privacy-policy.md va boshqalar)
PLAN.md  PROGRESS.md  DECISIONS.md  NEEDS_USER.md  CREDITS.md  CLAUDE.md
```

Balans va bosqich ma'lumotlari kodda emas, **JSON fayllarda** saqlanadi, shunda ularni tez o'zgartirish mumkin.

## 5. Bosqichlar (taxminan 4 hafta)

### 0-bosqich: Sozlash (1-kun)
- Godot'ni headless o'rnatish, loyiha skeleti, GUT, CI.
- `CLAUDE.md`, `PROGRESS.md`, `DECISIONS.md` fayllari.
- **Tayyorlik mezoni:** CI yashil, bo'sh sahna Web'ga eksport bo'ladi.

### 1-bosqich: O'ynasa bo'ladigan prototip (2–4-kunlar)
- Jang maydoni, kamera surish, ikki qal'a.
- Oltin iqtisodi va ishchilar; qilichboz, kamonchi, nayzachi.
- Hujum, himoya va chekinish buyruqlari; birlikni qo'lda boshqarish.
- Oddiy dushman AI; g'alaba va mag'lubiyat.
- **Tayyorlik mezoni:** bitta bosqich boshidan oxirigacha o'ynaladi; Web build havolasi
  foydalanuvchiga yuboriladi.

### 2-bosqich: Birliklar va qahramonlar (5–8-kunlar)
- Barcha birliklar, 4 qahramon va ularning maxsus kuchlari.
- Dushman AI'ning 3 darajasi (oson, o'rta, qiyin): iqtisod, qo'shin tarkibi, taktika.
- Asosiy animatsiyalar va effektlar (zarba, o'lim, o'q, chang).
- **Tayyorlik mezoni:** har bir qahramon bilan to'liq jang o'ynaladi va testlar o'tadi.

### 3-bosqich: Kampaniyalar va bosqichlar (9–13-kunlar)
- Kampaniya xaritasi va 40 bosqich (JSON). Qiyinlik bir tekis oshib boradi,
  bosqichlarda maxsus shartlar bor (qal'ani himoya qil, vaqt chegarasi va h.k.).
- Har kampaniyaning boshida va oxirida qisqa hikoya (matn va rasm).
- Tarixiy fakt kartalari (`facts.json`), manbalari bilan.
- Cheksiz mudofaa rejimi.
- **Tayyorlik mezoni:** barcha bosqichlarni bot "o'rta mahorat" bilan yuta oladi.

### 4-bosqich: Meta-progress va UI (14–16-kunlar)
- Bosh menyu, sozlamalar (ovoz, til, grafika), yaxshilanishlar daraxti, kiyimlar.
- Saqlash tizimi (versiyalangan, buzilishga chidamli).
- 4 tilga tarjima.
- O'rgatuvchi bosqich (tutorial).
- **Tayyorlik mezoni:** yangi o'yinchi tushuntirishsiz o'ynay oladi; tilni almashtirish ishlaydi.

### 5-bosqich: Grafika va ovozni sayqallash (17–19-kunlar)
- Yagona vizual uslub: fonlar (dasht, cho'l, tog', shahar), ob-havo, parallaks.
- **Musiqa:** bosh menyu, kampaniya xaritasi va har bir kampaniya uchun alohida jang musiqasi
  (dasht, Xorazm, Temuriylar, Usmoniylar ruhida: do'mbira, karnay-surnay, nog'ora ohanglari),
  g'alaba va mag'lubiyat kuylari. Musiqa sikl bo'lib uzilishsiz aylanadi.
- **Ovoz effektlari, har bir to'qnashuvga mos turli ovoz:**
  qilich bilan qilich, qilich bilan qalqon, nayza zarbasi, o'q uchishi va tegishi,
  ot dupuri va kishnashi, fil na'rasi, to'p o'qi va portlash, qal'aga zarba, qal'aning qulashi,
  oltin qazish va tangalar, askar yollash, jangchilarning hayqirig'i, qahramon maxsus kuchlari, UI tugmalari.
  Har bir ovozning 3–4 xil varianti bo'ladi va ular tasodifiy balandlik (pitch) bilan chalinadi,
  shunda ovozlar takrorlanib zeriktirmaydi.
- Ovozni boshqarish: musiqa va effektlar uchun alohida balandlik, bir vaqtda chalinadigan ovozlar soniga chegara.
- Ekran silkinishi, "juice" effektlari.
- Ikonka va loading ekrani.
- **Tayyorlik mezoni:** Play Market skrinshotlariga yaraydigan ko'rinish.

### 6-bosqich: Test va balans (20–23-kunlar)
- Har bir bosqichda minglab "bot vs bot" simulyatsiyalari: g'alaba foizi, o'rtacha davomiylik,
  eng kuchli va eng zaif birliklar. Hisobot `docs/balance-report.md` ga yoziladi.
- Unit testlar: iqtisod, zarar hisobi, saqlash, AI qarorlari.
- Performance: arzon Android telefonda 60 FPS; 150 birlikli stress-test.
- Xatolarni tuzatish va regressiya testlari.
- **Tayyorlik mezoni:** ma'lum muhim xato yo'q; qiyinlik egri chizig'i silliq.

### 7-bosqich: Monetizatsiya (24–25-kunlar)
- AdMob: faqat **ixtiyoriy (rewarded)** reklama ("2× oltin", "jangni davom ettir")
  va bosqichlar orasida kamdan-kam interstitial.
- Google Play Billing: "Reklamasiz", qahramon kiyimlari, oltin paketlari.
  Pulga g'alaba sotilmaydi, barcha kontentni o'ynab ochish mumkin.
- Test rejimdagi reklama ID'lari; haqiqiy ID'lar keyin foydalanuvchidan olinadi.
- **Tayyorlik mezoni:** test reklamalari va test xaridlar ishlaydi.

### 8-bosqich: Play Market'ga tayyorlash (26–28-kunlar)
- Imzolangan release AAB. Keystore repoga **commit qilinmaydi**; CI secret orqali ishlatiladi.
- Store listing (4 tilda): qisqa va to'liq tavsif, 8 ta skrinshot, feature graphic (1024×500),
  ikonka (512×512), qisqa promo video ssenariysi.
- Maxfiylik siyosati (GitHub Pages'da), Data Safety javoblari, kontent reytingi anketasi
  javoblari (zo'ravonlik darajasi: multfilmga xos, qonsiz).
- "Lost Centuries" YouTube kanali uchun o'yinni tanishtiruvchi video g'oyalari.
- **Tayyorlik mezoni:** `store/` papkasida yuklash uchun hamma narsa tayyor va
  `NEEDS_USER.md` da qadamma-qadam yuklash yo'riqnomasi bor.

### 9-bosqich: Chiqqandan keyin
- Firebase Analytics yoki shunga o'xshash xizmat (qaysi bosqichda o'yinchilar o'yinni tashlab ketishini ko'rish uchun).
- Yangilanishlar: Bobur, Alp Arslon, Saladin; yangi rejimlar; sharhlarga javob asosida tuzatishlar.

## 6. Qat'iy qoidalar

- Mavjud o'yinlarning nomi, personajlari, grafikasi, musiqasi va bosqichlarini nusxalama.
- Faqat original yoki CC0 assetlardan foydalan va hammasini `CREDITS.md` ga yoz.
- Kalit va sirlarni (keystore, AdMob ID, `.env`) hech qachon commit qilma.
- Tarixiy faktlar to'g'ri va manbali bo'lsin. Hech bir millat yoki dinni kamsitma.
- Bolalar ham o'ynashi mumkin: qon va shafqatsiz tasvirlar bo'lmaydi.
- Testni o'chirib qo'yib, CI'ni "yashil" qilma.
- Ish faqat belgilangan branch'da olib boriladi; PR faqat foydalanuvchi so'raganda ochiladi.

## 7. Mustaqil ish tartibi

- Har ish seansi boshida `PROGRESS.md` ni o'qi va keyingi kichik vazifani tanla.
- **Har bir ishdan keyin albatta sina:** unit testlar, headless simulyatsiya va
  o'yindan skrinshot yoki video. Muammo chiqsa, sababini top, tuzat va **qayta sina**.
  Test o'tmaguncha keyingi vazifaga o'tma. Tuzatilgan har bir xato uchun regressiya testi yoz.
- Faqat testlar o'tgandan keyin commit va push qil.
- **Har bosqich oxirida va loyiha oxirida** o'yinni to'liq o'ynab chiq
  (barcha kampaniyalar, rejimlar, menyular, tillar, saqlash, reklama va xaridlar test rejimida).
  Topilgan barcha muammolarni bartaraf et va oxirgi hisobotni `docs/final-test-report.md` ga yoz.
- Ish rejali vazifa (scheduled task) orqali, masalan har kuni bir necha marta davom ettiriladi.
- Har bosqich tugaganda foydalanuvchiga qisqa hisobot ber: nima tayyor, qanday sinab ko'rish mumkin
  (Web havola yoki APK), keyingi bosqich nima.

## 8. Foydalanuvchidan kerak bo'ladigan narsalar (vaqti kelganda)

1. GitHub repo `lost-centuries-game` (0-bosqichdan oldin).
2. Prototip va har bosqich buildini telefonda sinab, fikr bildirish.
3. Google Play Developer akkaunti (bir martalik 25$), 7-bosqichdan oldin.
4. AdMob akkaunti va reklama ID'lari (7-bosqich).
5. Release AAB'ni Play Console'ga yuklash va ichki test (8-bosqich).
   Diqqat: yangi shaxsiy akkauntlar uchun Google odatda 14 kun davomida kamida 12 ta
   testerdan iborat yopiq test talab qiladi.

## 9. Foydalanuvchi talablari: progress va monetizatsiya (2026-11-13)

**Yulduzlar va bosqichlar**
- Har bosqich 1–3 yulduz beradi: g'alaba = 1; qal'a 50%+ saqlansa = 2; tez yutish yoki qal'a 80%+ = 3.
- Keyingi kampaniyani ochish uchun yulduz kerak, lekin juda qiyin emas: taxminan har bosqichdan
  o'rtacha 2 yulduz yetarli (masalan, 2-kampaniya uchun 15/30, 3-si uchun 35/60, 4-si uchun 55/90).
- Qiyinlik silliq oshadi; har yo'qotishdan keyin maslahat ko'rsatiladi. Balans bot simulyatsiyasi bilan tekshiriladi.

**Tangalar va reklama**
- Har jang oxirida tanga (g'alaba/yulduzga qarab).
- Natija oynasida "Reklama ko'rib 2× olish" tugmasi (ixtiyoriy rewarded reklama).
- Kunlik chegara (masalan, kuniga 5 marta 2×), shunda reklama bezor qilmaydi va tangalar qadrsizlanmaydi.
- Tangalarga: yaxshilanishlar, qahramonlarni ochish, zaxira qo'shinlar.

**Xaridlar (adolatli narxlar)**
- "Zaxira qo'shin" paketlari: masalan, 100 kamonchi ≈ 4 000 so'mgacha. Paketlar jangda
  "qo'shimcha kuch" sifatida chaqiriladi (bir jangda cheklangan son, masalan 5 tagacha), shunda pul
  to'lagan o'yinchi ustun keladi, lekin o'yin "pulga yutiladigan" bo'lib qolmaydi.
- Qahramonlarni tanga bilan ham, pul bilan ham ochish mumkin (tanga yo'li uzoqroq, lekin mumkin).
- "Reklamasiz" xaridi. Kosmetika (kiyimlar) — ixtiyoriy.
- Narxlar Google Play'ning narx pog'onalari va minimal chegaralariga moslashtiriladi. "4 000 so'm" faqat misol edi
  (foydalanuvchi tasdiqladi): eng arzon paket Google Play ruxsat etgan eng past narxga yaqin bo'ladi.

## 10. Foydalanuvchi talablari: bosqichlar soni va o'yinchini ushlab qolish (2026-11-13)

**Hozir:** 4 kampaniya × 10 = 40 bosqich + cheksiz mudofaa. Kampaniya ichida keyingi bosqich g'alaba bilan
(1 ★ yetarli) ochiladi — bosqichni o'tkazib yuborib bo'lmaydi; yulduz faqat keyingi kampaniyani ochish uchun kerak.

**Reja (foydalanuvchi: "juda ko'p bosqich bo'lsin, o'yinchi chala tashlab ketmasin"):**
1. Tarixiy kampaniyalar kengaytiriladi: har qahramon 25 bosqich → 100 ta qo'lda yozilgan bosqich
   (yangi joylar, maxsus shartlar: faqat kamonchi, vaqt chegarasi, kuchli boss va h.k.).
2. "Fathlar" rejimi — avtomatik yaratiladigan 1000+ bosqich (seed asosida): qiyinlik silliq oshadi,
   har bosqich boshqacha (fon, dushman qo'shini tarkibi, shartlar, boss), har 10-bosqichda boss.
   Hammasi bir xil zerikarli takror bo'lmasligi uchun modifikatorlar aralashtiriladi.
3. Tashlab ketmaslik uchun: yulduz sandiqlari (har 10/25/50 ★ da sovg'a), kunlik mukofot (ketma-ket kunlar),
   kunlik sinov bosqichi, yutqazganda maslahat va "kuchaytirib qayta urinish", yangi qahramon/birlik
   har bir necha bosqichda ochiladi (doim yangi narsa kutilsin).
4. Qiyinlik bot simulyatsiyasi bilan tekshiriladi: hech bir bosqichda keskin "devor" bo'lmasin.
