"""Generate Shringar Studio brand + Play Store assets.

Outputs:
  brand/logo_master.png              1024 transparent motif
  brand/play_store/icon_512.png      512 hi-res Play icon
  brand/play_store/feature_graphic.png  1024x500
  app launcher icons (legacy + adaptive) written into the Flutter res tree
"""
import math
import os
import pathlib

from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parent.parent
FLUTTER_RES = ROOT / "shringar_studio_flutter" / "android" / "app" / "src" / "main" / "res"
BRAND = ROOT / "brand"
STORE = BRAND / "play_store"
STORE.mkdir(parents=True, exist_ok=True)

MAROON = (142, 27, 58)      # #8E1B3A
MAROON_DK = (92, 16, 38)
GOLD = (201, 162, 39)       # #C9A227
GOLD_LT = (235, 205, 120)
CREAM = (247, 240, 228)

FONT_SERIF_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
FONT_SANS = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"


def radial_bg(size, inner, outer):
    """Vertical-ish radial gradient background."""
    img = Image.new("RGB", (size, size), outer)
    cx = cy = size / 2
    maxd = math.hypot(cx, cy)
    px = img.load()
    for y in range(size):
        for x in range(0, size, 1):
            d = math.hypot(x - cx, y - cy) / maxd
            t = min(1.0, d)
            px[x, y] = tuple(int(inner[i] * (1 - t) + outer[i] * t) for i in range(3))
    return img


def petal(tile, color, outline=None):
    """A single tall petal centered in a transparent square tile."""
    p = Image.new("RGBA", (tile, tile), (0, 0, 0, 0))
    d = ImageDraw.Draw(p)
    w = tile * 0.26
    cx = tile / 2
    d.ellipse([cx - w / 2, tile * 0.06, cx + w / 2, tile * 0.62],
              fill=color, outline=outline, width=max(2, tile // 90))
    return p


def mandala(size, petal_color=GOLD, hi=GOLD_LT, center=GOLD):
    """Draw a lotus/mandala motif on a transparent canvas of `size`."""
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cx = cy = size / 2

    rings = [
        (16, size, petal_color, 0.0),
        (16, int(size * 0.74), hi, math.pi / 16),
        (8, int(size * 0.52), petal_color, 0.0),
    ]
    for count, tile, color, phase in rings:
        base = petal(tile, color, outline=MAROON_DK)
        for i in range(count):
            ang = phase + i * (2 * math.pi / count)
            rot = base.rotate(-math.degrees(ang), resample=Image.BICUBIC, expand=True)
            # position so petal base sits near center
            r = tile * 0.30
            px = cx + r * math.sin(ang) - rot.width / 2
            py = cy - r * math.cos(ang) - rot.height / 2
            canvas.alpha_composite(rot, (int(px), int(py)))

    d = ImageDraw.Draw(canvas)
    # inner concentric circles + bindi dot
    for rr, col in [(0.20, GOLD_LT), (0.15, MAROON), (0.09, GOLD)]:
        r = size * rr
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col, outline=MAROON_DK,
                  width=max(2, size // 120))
    return canvas


def icon(size, rounded=True, bleed_bg=True):
    """Square app icon: maroon gradient bg + centered mandala."""
    bg = radial_bg(size, MAROON, MAROON_DK) if bleed_bg else Image.new("RGB", (size, size), MAROON)
    img = bg.convert("RGBA")
    m = mandala(int(size * 0.62))
    img.alpha_composite(m, ((size - m.width) // 2, (size - m.height) // 2))
    if rounded:
        mask = Image.new("L", (size, size), 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, size, size], radius=int(size * 0.22), fill=255)
        out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        out.paste(img, (0, 0), mask)
        return out
    return img


def foreground(size):
    """Adaptive-icon foreground: motif only, centered in the 66% safe zone."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    m = mandala(int(size * 0.50))
    img.alpha_composite(m, ((size - m.width) // 2, (size - m.height) // 2))
    return img


def font(path, sz):
    return ImageFont.truetype(path, sz)


def centered_text(d, cx, y, text, fnt, fill):
    b = d.textbbox((0, 0), text, font=fnt)
    d.text((cx - (b[2] - b[0]) / 2, y), text, font=fnt, fill=fill)


# ---- 1. master logo (transparent) ----
mandala(1024).save(BRAND / "logo_master.png")

# ---- 2. Play hi-res icon 512 (full square, no rounding for Play) ----
icon(512, rounded=False).convert("RGB").save(STORE / "icon_512.png")

# ---- 3. legacy launcher icons + adaptive foregrounds ----
LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
FG = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
for dens, px in LEGACY.items():
    d = FLUTTER_RES / f"mipmap-{dens}"
    d.mkdir(parents=True, exist_ok=True)
    ic = icon(px, rounded=True)
    ic.save(d / "ic_launcher.png")
    ic.save(d / "ic_launcher_round.png")
for dens, px in FG.items():
    d = FLUTTER_RES / f"mipmap-{dens}"
    d.mkdir(parents=True, exist_ok=True)
    foreground(px).save(d / "ic_launcher_foreground.png")

# ---- 4. adaptive icon xml + background color ----
anydpi = FLUTTER_RES / "mipmap-anydpi-v26"
anydpi.mkdir(parents=True, exist_ok=True)
adaptive_xml = (
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '    <background android:drawable="@color/ic_launcher_background"/>\n'
    '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
    '</adaptive-icon>\n'
)
(anydpi / "ic_launcher.xml").write_text(adaptive_xml)
(anydpi / "ic_launcher_round.xml").write_text(adaptive_xml)
valdir = FLUTTER_RES / "values"
valdir.mkdir(parents=True, exist_ok=True)
(valdir / "ic_launcher_background.xml").write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
    '    <color name="ic_launcher_background">#8E1B3A</color>\n</resources>\n'
)

# ---- 5. feature graphic 1024x500 ----
fg = Image.new("RGB", (1024, 500), MAROON_DK)
fg = Image.new("RGB", (1024, 500))
# horizontal gradient maroon -> darker
for x in range(1024):
    t = x / 1024
    col = tuple(int(MAROON[i] * (1 - t) + MAROON_DK[i] * t) for i in range(3))
    for y in range(500):
        fg.putpixel((x, y), col)
fg = fg.convert("RGBA")
m = mandala(360)
fg.alpha_composite(m, (70, 70))
d = ImageDraw.Draw(fg)
d.text((470, 150), "Shringar", font=font(FONT_SERIF_BOLD, 92), fill=GOLD_LT)
d.text((472, 250), "Studio", font=font(FONT_SERIF_BOLD, 92), fill=CREAM)
d.text((476, 375), "Mehndi · Fashion · Beauty Designs",
       font=font(FONT_SANS, 27), fill=GOLD)
fg.convert("RGB").save(STORE / "feature_graphic.png")

print("assets generated")
