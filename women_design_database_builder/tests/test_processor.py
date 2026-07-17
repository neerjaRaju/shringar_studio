import io
import pathlib

from PIL import Image

from builder.dedup import DuplicateIndex
from builder.processing.image_processor import hamming, perceptual_hash, process_image


def _png_bytes(w=800, h=600, color=(180, 40, 90)) -> bytes:
    img = Image.new("RGB", (w, h), color)
    # add gradient so phash is non-trivial
    for x in range(w):
        for y in range(0, h, max(1, h // 40)):
            img.putpixel((x, y), (x % 256, y % 256, (x + y) % 256))
    buf = io.BytesIO()
    img.save(buf, "PNG")
    return buf.getvalue()


def test_process_image(tmp_path: pathlib.Path):
    p = process_image(_png_bytes(), "abc123", tmp_path / "img", tmp_path / "th")
    assert p.image_path.exists() and p.image_path.suffix == ".webp"
    assert set(p.thumbnail_paths) == {512, 256, 128}
    assert all(t.exists() for t in p.thumbnail_paths.values())
    assert p.orientation == "landscape"
    assert (p.width, p.height) == (800, 600)
    assert len(p.sha256) == 64
    assert len(p.phash) == 16
    assert p.dominant_color.startswith("#")
    assert 1 <= len(p.colors) <= 5


def test_phash_similarity(tmp_path: pathlib.Path):
    a = process_image(_png_bytes(), "a", tmp_path / "i", tmp_path / "t")
    b = process_image(_png_bytes(), "b", tmp_path / "i", tmp_path / "t")
    assert hamming(a.phash, b.phash) == 0

    c = process_image(_png_bytes(color=(10, 200, 10)), "c", tmp_path / "i", tmp_path / "t")
    # same gradient dominates; dedup index must treat these as near-duplicates
    idx = DuplicateIndex(threshold=6)
    idx.add(a.sha256, a.phash)
    assert idx.is_duplicate(b.sha256, b.phash)
    assert idx.is_duplicate(a.sha256, "0" * 16)  # exact sha match


def test_duplicate_index_distinct():
    idx = DuplicateIndex(threshold=2)
    idx.add("x" * 64, "0000000000000000")
    assert not idx.is_duplicate("y" * 64, "ffffffffffffffff")
