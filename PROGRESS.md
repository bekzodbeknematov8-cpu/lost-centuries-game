# Jarayon

### Foydalanuvchi talablari (navbatdagi ishlar uchun MUHIM)
- Bosqichlar yulduz bilan ochiladi, lekin juda qiyin emas; qiziqarlilik saqlansin (PLAN.md §9).
- Jang oxiri: tangani 2× qilish uchun rewarded reklama, kunlik chegara bilan.
- Zaxira qo'shin paketlari (masalan, 100 kamonchi ≤ 4 000 so'm), adolatli narxlar, pulga yutiladigan o'yin bo'lmasin.


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


## Holat: 0–2-bosqich ✅ · 3-bosqich (kampaniya) ✅ asosiy qismi · keyingi: cheksiz mudofaa, so'ng 4-bosqich

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
