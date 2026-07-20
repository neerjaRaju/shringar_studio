"""Generate the splash logo (lotus mandala, transparent) at all densities and
write them into the Flutter Android drawable tree."""
import math
import pathlib
from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
RES = ROOT / "shringar_studio_flutter" / "android" / "app" / "src" / "main" / "res"

MAROON_DK = (92, 16, 38)
GOLD = (201, 162, 39)
GOLD_LT = (235, 205, 120)
MAROON = (142, 27, 58)


def petal(tile, color, outline):
    p = Image.new("RGBA", (tile, tile), (0, 0, 0, 0))
    d = ImageDraw.Draw(p)
    w = tile * 0.26
    cx = tile / 2
    d.ellipse([cx - w / 2, tile * 0.06, cx + w / 2, tile * 0.62],
              fill=color, outline=outline, width=max(2, tile // 90))
    return p


def mandala(size):
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cx = cy = size / 2
    for count, tile, color, phase in [
        (16, size, GOLD, 0.0),
        (16, int(size * 0.74), GOLD_LT, math.pi / 16),
        (8, int(size * 0.52), GOLD, 0.0),
    ]:
        base = petal(tile, color, MAROON_DK)
        for i in range(count):
            ang = phase + i * (2 * math.pi / count)
            rot = base.rotate(-math.degrees(ang), resample=Image.BICUBIC, expand=True)
            r = tile * 0.30
            px = cx + r * math.sin(ang) - rot.width / 2
            py = cy - r * math.cos(ang) - rot.height / 2
            canvas.alpha_composite(rot, (int(px), int(py)))
    d = ImageDraw.Draw(canvas)
    for rr, col in [(0.20, GOLD_LT), (0.15, MAROON), (0.09, GOLD)]:
        r = size * rr
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col, outline=MAROON_DK,
                  width=max(2, size // 120))
    return canvas


# Android 12 splash icon lives inside a ~2/3 safe circle; keep the motif compact.
SIZES = {"mdpi": 192, "hdpi": 288, "xhdpi": 384, "xxhdpi": 576, "xxxhdpi": 768}
for dens, px in SIZES.items():
    d = RES / f"drawable-{dens}"
    d.mkdir(parents=True, exist_ok=True)
    img = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    m = mandala(int(px * 0.7))
    img.alpha_composite(m, ((px - m.width) // 2, (px - m.height) // 2))
    img.save(d / "splash_logo.png")

# a default (mdpi) copy in plain drawable/ for the layer-list fallback
(RES / "drawable").mkdir(parents=True, exist_ok=True)
img = Image.new("RGBA", (384, 384), (0, 0, 0, 0))
m = mandala(269)
img.alpha_composite(m, ((384 - m.width) // 2, (384 - m.height) // 2))
img.save(RES / "drawable" / "splash_logo.png")
print("splash logos generated")
