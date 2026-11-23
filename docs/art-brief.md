# Jahongirlar — rassom uchun texnik topshiriq / Art brief

> O'zbekcha qism — buyurtmachi uchun. **English section below** — send it to the artist.

## O'zbekcha (qisqa)

**Nima kerak:** yon tomondan ko'rinadigan (2D, side-view) yarim realistik, qo'lda chizilgan uslubdagi
jangchilar, sarkardalar, qal'a va fonlar. Davr: XII–XVI asr Markaziy Osiyo, Eron, Anado'lu, Hindiston.
Qon yo'q (o'yin hamma yosh uchun).

**Ro'yxat (minimal to'plam):**
- 7 askar: ishchi, qilichboz, nayzachi, kamonchi, otliq, miltiqchi, jangovar fil (kajavasi bilan).
- 6 sarkarda (hammasi otda): Chingizxon, Jaloliddin Manguberdi, Amir Temur, Boyazid Yildirim, Zahiriddin Bobur, Alp Arslon.
- 1 umumiy "dushman sardori" (otda).
- Qal'a: 2 xil (o'yinchi / dushman), har biri 3 holatda (butun, shikastlangan, vayron).
- Fonlar: 4 relyef (dasht, cho'l, tog', yashil vodiy), har biri 3 qatlam.

**Qayerdan rassom topish:** Fiverr, Upwork, ArtStation, Telegram'dagi o'zbek rassomlar guruhlari.
Qidiruv so'zlari: "2D game character sprite sheet", "side view medieval soldier animation".
**Taxminiy narx:** to'liq to'plam $500–2000 (rassom tajribasiga qarab). Arzonroq boshlash uchun avval
**1 ta askar** (masalan, qilichboz) buyurtma qiling: uslub yoqsa, qolganini davom ettiring.

**Shartnomada albatta:** asar original (boshqa o'yindan ko'chirilmagan, AI orqali boshqa o'yin uslubini
nusxalamagan); o'yinda tijorat maqsadida foydalanish huquqi to'liq sizga o'tadi; manba fayllar (PSD/Krita) beriladi.

**Tayyor bo'lgach:** fayllarni menga yuboring (yoki GitHub'dagi `assets/sprites/` papkasiga yuklang) —
men o'yinga ulayman. Hozirgi kodda chizilgan grafika zaxira sifatida qoladi: rasmi bor askar rasm bilan,
yo'g'i eski usulda chiziladi, shuning uchun bo'lib-bo'lib topshirsa ham bo'ladi.

---

## English — Art brief for the artist

**Game:** *Jahongirlar* — a 2D side-view strategy battle game for Android (Godot 4). Two armies march from
their fortresses toward each other along one horizontal battlefield. Historical setting: Central Asia, Iran,
Anatolia and India, 12th–16th centuries. **No blood or gore** (all-ages): defeated units fall and fade out.

**Style:** semi-realistic, hand-painted 2D, readable on a phone screen (units are ~90–140 px tall on screen).
Historically grounded clothing and gear: lamellar armour, quilted kaftans, spired helmets with aventails,
turbans, composite bows, sabres. Original work only — do not copy or trace any existing game.

### Deliverables

| Group | Items |
|---|---|
| Units (7) | worker (with pickaxe and gold sack), swordsman (sabre + small round shield), spearman (spear + large shield), archer (composite bow), cavalry (rider with sabre on horse), musketeer (matchlock), war elephant (with howdah and driver) |
| Commanders (6, mounted) | Genghis Khan, Jalal al-Din Mingburnu, Amir Timur, Bayezid I, Babur, Alp Arslan + 1 generic enemy commander |
| Fortress | 2 designs (player / enemy) × 3 damage states (intact, damaged, ruined) |
| Backgrounds | 4 terrains (steppe, desert, mountains, green valley) × 3 parallax layers (far, middle, near ground) |

### Animations (per unit and commander)

| Animation | Frames | Notes |
|---|---|---|
| idle | 4–6 | breathing / slight motion, loops |
| walk (or gallop for mounted) | 8 | loops |
| attack | 6 | sword swing / spear thrust / bow draw-and-release / musket fire / elephant trunk swing |
| hurt | 2 | short flinch |
| death | 6–8 | falls to the ground, **no blood** |
| worker only: mine | 6 | pickaxe strike |
| commanders only: ability | 6–8 | one special pose per commander |

### Technical format

- **Facing right.** The game mirrors sprites for the enemy side.
- **PNG with transparency**, one horizontal sprite sheet per animation, equal frame sizes.
- Frame size: infantry **256×256**, mounted / commanders **384×384**, elephant **512×512**.
  The **anchor is the bottom-center of each frame (feet on the ground)**. Keep the same anchor in all frames.
- **Team colours:** deliver clothing/banner areas as a **separate greyscale "colour mask" layer**
  (`*_mask.png`, same size as the frames). The game tints it per side (blue/red) and for unlockable outfits.
  If that is not possible, deliver two colour variants (blue and red).
- Backgrounds: **2048×720** per layer, horizontally **seamless (tileable)**, transparent where the layer above shows through.
- Fortress: **512×640** per state, anchor bottom-center.
- File naming: `<id>_<animation>.png` and `<id>_<animation>_mask.png`, for example `swordsman_walk.png`,
  `temur_attack.png`, `castle_player_damaged.png`, `bg_desert_far.png`.
  Unit ids: `worker, swordsman, spearman, archer, cavalry, musketeer, elephant`;
  commander ids: `chingiz, jaloliddin, temur, boyazid, bobur, alp, sardor`.
- Also deliver the **source files** (PSD / Krita / Aseprite) with layers.

### Rights

All artwork must be original. The client receives full commercial rights to use, modify and publish it in the game
and its store pages (Google Play) worldwide.

### Suggested first milestone

One unit (**swordsman**) with all animations + colour mask. That confirms the style and the technical format
before the rest of the set is produced.
