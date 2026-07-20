"""Build launcher icons + splash from the user-supplied logo.

Source: brand/logo_source.png (the uploaded Shringar badge, black corners).
Produces transparent-corner launcher icons (legacy + adaptive), a white-splash
logo with transparent corners, and the 512 Play icon.
"""
import pathlib
from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
RES = ROOT / "shringar_studio_flutter" / "android" / "app" / "src" / "main" / "res"
BRAND = ROOT / "brand"
STORE = BRAND / "play_store"

src = Image.open(BRAND / "logo_source.png").convert("RGBA")
S = min(src.size)
src = src.crop((0, 0, S, S)) if src.width != src.height else src

# --- sample the badge pink (used for adaptive background) ---
pink = src.getpixel((int(S * 0.06), int(S * 0.5)))[:3]
# if that spot is dark (outside round-rect), step inward
if sum(pink) < 120:
    pink = src.getpixel((int(S * 0.12), int(S * 0.5)))[:3]
PINK_HEX = "#%02X%02X%02X" % pink
print("badge pink:", PINK_HEX)


def rounded_mask(size, radius_frac=0.22):
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).rounded_rectangle(
        [0, 0, size, size], radius=int(size * radius_frac), fill=255)
    return m


def transparent_corners(img):
    """Drop the near-black corners outside the rounded square -> transparent."""
    img = img.copy()
    px = img.load()
    w, h = img.size
    # apply a rounded-rect alpha mask matching the artwork's corner radius
    mask = rounded_mask(w, 0.22)
    img.putalpha(mask)
    return img


def fill_corners_pink(img):
    """Replace the transparent/black corners with the badge pink (full-bleed)."""
    base = Image.new("RGBA", img.size, pink + (255,))
    rr = transparent_corners(img)
    base.alpha_composite(rr)
    return base


def resize(img, n):
    return img.resize((n, n), Image.LANCZOS)


logo_rounded = transparent_corners(src)        # transparent corners
logo_fullbleed = fill_corners_pink(src)        # pink to the edges

# ---- legacy launcher icons (transparent corners) ----
LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
for dens, n in LEGACY.items():
    d = RES / f"mipmap-{dens}"; d.mkdir(parents=True, exist_ok=True)
    resize(logo_rounded, n).save(d / "ic_launcher.png")
    resize(logo_rounded, n).save(d / "ic_launcher_round.png")

# ---- adaptive foreground (full-bleed pink so any mask shape looks clean) ----
FG = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
for dens, n in FG.items():
    d = RES / f"mipmap-{dens}"; d.mkdir(parents=True, exist_ok=True)
    resize(logo_fullbleed, n).save(d / "ic_launcher_foreground.png")

# ---- adaptive background colour = badge pink ----
(RES / "values" / "ic_launcher_background.xml").write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
    f'    <color name="ic_launcher_background">{PINK_HEX}</color>\n</resources>\n'
)

# ---- splash logo (transparent corners), sits on the white splash ----
SPLASH = {"mdpi": 192, "hdpi": 288, "xhdpi": 384, "xxhdpi": 576, "xxxhdpi": 768}
for dens, n in SPLASH.items():
    d = RES / f"drawable-{dens}"; d.mkdir(parents=True, exist_ok=True)
    resize(logo_rounded, n).save(d / "splash_logo.png")
resize(logo_rounded, 512).save(RES / "drawable" / "splash_logo.png")

# ---- 512 Play hi-res icon (flattened onto pink, no alpha) ----
STORE.mkdir(parents=True, exist_ok=True)
resize(logo_fullbleed, 512).convert("RGB").save(STORE / "icon_512.png")

# ---- master logo for reference ----
logo_rounded.save(BRAND / "logo_master.png")
print("launcher + splash assets rebuilt from uploaded logo")
