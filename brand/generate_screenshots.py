"""Generate Play Store phone screenshot mockups (1080x1920).

These are polished placeholders so the listing can go live immediately;
replace with real device captures for best quality when convenient.
"""
import pathlib
from PIL import Image, ImageDraw, ImageFont

BRAND = pathlib.Path(__file__).resolve().parent
OUT = BRAND / "play_store" / "screenshots"
OUT.mkdir(parents=True, exist_ok=True)

MAROON = (142, 27, 58)
MAROON_DK = (92, 16, 38)
GOLD = (201, 162, 39)
GOLD_LT = (235, 205, 120)
CREAM = (247, 240, 228)
SURFACE = (250, 246, 242)
CARD = (255, 255, 255)
INK = (40, 25, 30)
MUTE = (120, 110, 112)

SERIF = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
SANS = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
SANSB = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def f(path, s):
    return ImageFont.truetype(path, s)


def tile(w, h, seed):
    """A decorative placeholder design tile (gold-on-maroon motif block)."""
    from PIL import ImageDraw as _D
    img = Image.new("RGB", (w, h), (MAROON if seed % 2 else MAROON_DK))
    d = _D.Draw(img)
    for i in range(6):
        r = int(min(w, h) * (0.12 + 0.06 * i))
        col = GOLD_LT if i % 2 else GOLD
        cx, cy = w // 2, h // 2
        d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=col, width=3)
    d.ellipse([w // 2 - 14, h // 2 - 14, w // 2 + 14, h // 2 + 14], fill=GOLD)
    return img


def frame(title):
    img = Image.new("RGB", (1080, 1920), SURFACE)
    d = ImageDraw.Draw(img)
    # status bar + app bar
    d.rectangle([0, 0, 1080, 150], fill=MAROON)
    d.text((40, 60), "Shringar Studio", font=f(SERIF, 46), fill=CREAM)
    d.text((900, 66), "⌕", font=f(SANS, 44), fill=GOLD_LT)
    return img, d


def rounded(img, box, radius, fill):
    ImageDraw.Draw(img).rounded_rectangle(box, radius=radius, fill=fill)


def caption_bar(d, text):
    d.rectangle([0, 150, 1080, 250], fill=MAROON_DK)
    d.text((40, 178), text, font=f(SANSB, 40), fill=GOLD_LT)


# ---- Screen 1: Home ----
img, d = frame("Home")
caption_bar(d, "300,000+ designs, fully offline")
# Design of the day banner
banner = tile(1000, 360, 1)
rb = Image.new("RGB", (1000, 360), MAROON)
rb.paste(banner, (0, 0))
img.paste(rb, (40, 290))
d.rounded_rectangle([40, 290, 1040, 650], radius=28, outline=SURFACE, width=0)
d.text((70, 560), "✨ Design of the Day", font=f(SANSB, 34), fill=CREAM)
d.text((40, 690), "Trending", font=f(SANSB, 40), fill=INK)
xs = [40, 400, 760]
for i, x in enumerate(xs):
    t = tile(280, 360, i)
    img.paste(t, (x, 750))
d.text((40, 1150), "Newest", font=f(SANSB, 40), fill=INK)
for i, x in enumerate(xs):
    t = tile(280, 360, i + 1)
    img.paste(t, (x, 1210))
# bottom nav
d.rectangle([0, 1780, 1080, 1920], fill=CARD)
for i, lbl in enumerate(["Home", "Categories", "Search", "Favorites"]):
    cx = 135 + i * 270
    d.text((cx - 40, 1835), lbl, font=f(SANS, 26), fill=(MAROON if i == 0 else MUTE))
img.save(OUT / "01_home.png")

# ---- Screen 2: Categories ----
img, d = frame("Categories")
caption_bar(d, "23 beauty & fashion categories")
cats = ["Mehndi", "Blouse", "Rangoli", "Hairstyles", "Makeup", "Nail Art",
        "Jewellery", "Lehenga", "Kurti", "Bridal Looks", "Bindi", "Footwear"]
cw, ch, gap = 480, 360, 40
for i, name in enumerate(cats):
    r, c = divmod(i, 2)
    x = 40 + c * (cw + gap)
    y = 300 + r * (ch + gap)
    if y + ch > 1760:
        break
    t = tile(cw, ch, i)
    img.paste(t, (x, y))
    d.rectangle([x, y + ch - 70, x + cw, y + ch], fill=MAROON_DK)
    d.text((x + 20, y + ch - 58), name, font=f(SANSB, 34), fill=CREAM)
img.save(OUT / "02_categories.png")

# ---- Screen 3: Detail ----
img, d = frame("Detail")
big = tile(1000, 1000, 1)
img.paste(big, (40, 180))
d.text((40, 1210), "Royal Bridal Mehndi", font=f(SERIF, 52), fill=INK)
d.text((40, 1290), "Intricate arabic bridal mehndi with dense floral vines.",
       font=f(SANS, 30), fill=MUTE)
# palette
d.text((40, 1360), "Palette", font=f(SANSB, 32), fill=INK)
for i, col in enumerate([MAROON, GOLD, GOLD_LT, (180, 70, 90), (60, 30, 40)]):
    d.ellipse([40 + i * 70, 1410, 90 + i * 70, 1460], fill=col)
# action buttons
for i, (lbl) in enumerate(["Download", "Wallpaper", "Share"]):
    x = 40 + i * 340
    rounded(img, [x, 1520, x + 300, 1620], 24, MAROON)
    d.text((x + 70, 1548), lbl, font=f(SANSB, 34), fill=CREAM)
# tags
for i, tg in enumerate(["#mehndi", "#bridal", "#arabic", "#floral"]):
    x = 40 + i * 250
    rounded(img, [x, 1680, x + 220, 1760], 40, (238, 228, 220))
    d.text((x + 30, 1702), tg, font=f(SANS, 30), fill=MAROON)
img.save(OUT / "03_detail.png")

print("screenshots generated:", sorted(p.name for p in OUT.glob("*.png")))
