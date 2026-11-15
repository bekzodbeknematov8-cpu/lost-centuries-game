# Google Play — Data Safety javoblari (Play Console → App content → Data safety)

Asos: `docs/privacy-policy.md`. 7-bosqichdan keyin (AdMob + Play Billing ulanganda) amal qiladi.
AdMob ulanmasdan oldingi (hozirgi) versiya uchun: "No data collected".

| Savol | Javob |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** (AdMob SDK orqali) |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (Google SDK'lari HTTPS) |
| Do you provide a way for users to request that their data is deleted? | **Yes** — ilovani o'chirish barcha mahalliy ma'lumotni o'chiradi; email orqali so'rov |

## Yig'iladigan ma'lumot turlari

| Turi | Yig'iladi | Ulashiladi | Majburiymi | Maqsad |
|---|---|---|---|---|
| Device or other IDs (Advertising ID) | Ha | Ha (Google AdMob) | Majburiy | Advertising or marketing, Analytics |
| App interactions (ad views/clicks) | Ha | Ha (Google AdMob) | Majburiy | Advertising or marketing, Analytics |
| Diagnostics (crash logs, performance) | Ha | Ha (Google AdMob) | Majburiy | Analytics |
| Approximate location (IP orqali) | Ha | Ha (Google AdMob) | Majburiy | Advertising or marketing |
| Purchase history | Ha | Yo'q | Ixtiyoriy (faqat xarid qilsa) | App functionality |

Yig'ilmaydi: ism, email, telefon, aniq joylashuv, kontaktlar, rasmlar/video, audio, fayllar,
xabarlar, sog'liq, moliya (to'lov ma'lumotini faqat Google Play ko'radi).

## Boshqa "App content" bo'limlari
- **Ads:** Yes, my app contains ads (faqat ixtiyoriy mukofotli reklama).
- **Content rating (IARC anketasi):** Violence — fantasy/cartoon violence (qon yo'q, o'lim tasviri yo'q:
  askarlar yiqiladi va yo'qoladi); In-app purchases — Yes; Gambling — No (sandiqlar ichidagi ehtimollar
  o'yin ichida "Ehtimollar" tugmasi orqali ochiq ko'rsatiladi, real pul yutug'i yo'q).
  Kutilgan reyting: PEGI 7 / ESRB Everyone 10+.
- **Target audience:** 13+ (bolalarga yo'naltirilmagan; Families siyosatini oldini olish uchun).
- **Privacy policy URL:** `docs/privacy-policy.md` ni GitHub Pages yoki boshqa ochiq sahifaga joylash kerak.
- **App access:** hamma funksiyalar login'siz ochiq.
- **News app / COVID / Government:** No.
