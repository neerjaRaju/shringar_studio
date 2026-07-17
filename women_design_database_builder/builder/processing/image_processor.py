"""Image processing: WebP conversion, compression, thumbnails, hashes,
dominant colors, orientation and dimensions."""
from __future__ import annotations

import hashlib
import io
import pathlib
from collections import Counter
from dataclasses import dataclass, field

from PIL import Image


@dataclass
class ProcessedImage:
    image_path: pathlib.Path
    thumbnail_paths: dict[int, pathlib.Path]
    width: int
    height: int
    orientation: str
    sha256: str
    phash: str
    dominant_color: str
    colors: list[str] = field(default_factory=list)


def _orientation(w: int, h: int) -> str:
    if abs(w - h) <= max(w, h) * 0.05:
        return "square"
    return "portrait" if h > w else "landscape"


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def perceptual_hash(img: Image.Image, hash_size: int = 8) -> str:
    """dHash — difference hash. 64-bit hex string."""
    gray = img.convert("L").resize((hash_size + 1, hash_size), Image.LANCZOS)
    px = list(gray.getdata())
    bits = 0
    for row in range(hash_size):
        for col in range(hash_size):
            left = px[row * (hash_size + 1) + col]
            right = px[row * (hash_size + 1) + col + 1]
            bits = (bits << 1) | (1 if left > right else 0)
    return f"{bits:016x}"


def hamming(a: str, b: str) -> int:
    return bin(int(a, 16) ^ int(b, 16)).count("1")


def dominant_colors(img: Image.Image, count: int = 5) -> list[str]:
    """Top-N colors as hex strings, via adaptive palette quantization."""
    small = img.convert("RGB").resize((96, 96), Image.LANCZOS)
    pal = small.quantize(colors=max(count, 8), method=Image.Quantize.FASTOCTREE)
    palette = pal.getpalette() or []
    counts = Counter(pal.getdata())
    out: list[str] = []
    for idx, _ in counts.most_common(count):
        r, g, b = palette[idx * 3 : idx * 3 + 3]
        out.append(f"#{r:02x}{g:02x}{b:02x}")
    return out


def process_image(
    raw: bytes,
    design_id: str,
    images_dir: pathlib.Path,
    thumbs_dir: pathlib.Path,
    *,
    quality: int = 82,
    thumb_quality: int = 75,
    thumb_sizes: tuple[int, ...] = (512, 256, 128),
    max_edge: int = 1000,
) -> ProcessedImage:
    img = Image.open(io.BytesIO(raw))
    img.load()
    if img.mode not in ("RGB", "RGBA"):
        img = img.convert("RGB")

    # Hard cap: never store an image whose longest side exceeds `max_edge`,
    # regardless of the size requested from the provider.
    if max_edge and max(img.width, img.height) > max_edge:
        img.thumbnail((max_edge, max_edge), Image.LANCZOS)

    images_dir.mkdir(parents=True, exist_ok=True)
    thumbs_dir.mkdir(parents=True, exist_ok=True)

    # full-size WebP -----------------------------------------------------
    image_path = images_dir / f"{design_id}.webp"
    img.save(image_path, "WEBP", quality=quality, method=6)

    # thumbnails ----------------------------------------------------------
    thumb_paths: dict[int, pathlib.Path] = {}
    for size in thumb_sizes:
        thumb = img.copy()
        thumb.thumbnail((size, size), Image.LANCZOS)
        tdir = thumbs_dir / str(size)
        tdir.mkdir(parents=True, exist_ok=True)
        tpath = tdir / f"{design_id}.webp"
        thumb.save(tpath, "WEBP", quality=thumb_quality, method=6)
        thumb_paths[size] = tpath

    colors = dominant_colors(img)
    return ProcessedImage(
        image_path=image_path,
        thumbnail_paths=thumb_paths,
        width=img.width,
        height=img.height,
        orientation=_orientation(img.width, img.height),
        sha256=sha256_bytes(image_path.read_bytes()),
        phash=perceptual_hash(img),
        dominant_color=colors[0] if colors else "#000000",
        colors=colors,
    )
