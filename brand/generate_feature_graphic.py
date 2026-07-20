"""Feature graphic (1024x500) using the uploaded Shringar logo badge."""
import pathlib
from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
BRAND = ROOT / "brand"
STORE = BRAND / "play_store"
STORE.mkdir(parents=True, exist_ok=True)

MAROON = (142, 27, 58)
MAROON_DK = (92, 16, 38)
GOLD = (201, 162, 39)
GOLD_LT = (235, 205, 120)
CREAM = (247, 240, 228)

SERIF = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
SANS = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"


def font(p, s):
    return ImageFont.truetype(p, s)


# horizontal gradient background (deep pink/maroon)
W, H = 1024, 500
fg = Image.new("RGB", (W, H))
for x in range(W):
    t = x / W
    col = tuple(int(MAROON[i] * (1 - t) + MAROON_DK[i] * t) for i in range(3))
    for y in range(H):
        fg.putpixel((x, y), col)
fg = fg.convert("RGBA")

# logo badge on the left (transparent corners)
logo = Image.open(BRAND / "logo_master.png").convert("RGBA")
size = 430
logo = logo.resize((size, size), Image.LANCZOS)
fg.alpha_composite(logo, (35, (H - size) // 2))

d = ImageDraw.Draw(fg)
d.text((510, 150), "Shringar", font=font(SERIF, 92), fill=GOLD_LT)
d.text((512, 250), "Studio", font=font(SERIF, 92), fill=CREAM)
d.text((516, 375), "Mehndi · Fashion · Beauty Designs",
       font=font(SANS, 27), fill=GOLD)

fg.convert("RGB").save(STORE / "feature_graphic.png")
print("feature graphic regenerated with uploaded logo")
