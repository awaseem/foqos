# Foqos DMG Background

`background.svg` is the editable source for the Finder window shown when the Foqos DMG opens.
Finder places the real Foqos app and Applications folder icons over `background.png`.

After editing the SVG, regenerate the Retina PNG with `librsvg` (`brew install librsvg`):

```bash
rsvg-convert --width 1320 --height 800 --output background.png background.svg
sips -s dpiWidth 144 -s dpiHeight 144 background.png
```

The PNG must remain 1320 × 800 pixels at 144 DPI so Finder displays it in the configured
660 × 400 point window.
