# Ikonka

Manba: `icon.svg` (loyiha ildizida). Android ikonkalarini qayta yaratish:

```
G=assets/icons
node tools/icon/render_icon.js icon.svg "[[192,\"$G/icon_192.png\",\"transparent\"],[512,\"store/icon_512.png\",\"transparent\"]]"
node tools/icon/render_icon.js tools/icon/icon_bg.svg "[[432,\"$G/adaptive_bg_432.png\",\"#000\"]]"
node tools/icon/render_icon.js tools/icon/icon_fg.svg "[[432,\"$G/adaptive_fg_432.png\",\"transparent\"]]"
```
(Playwright + Chromium kerak.)
