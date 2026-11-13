# Jarayon

## Holat: 0-bosqich ✅ tugadi · 1-bosqich (prototip) ✅ asosiy qismi tayyor

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
