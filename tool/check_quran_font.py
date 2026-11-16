"""Check that a font has a glyph for every character the Quran text uses.

Usage:
    python tool/check_quran_font.py fonts/AmiriQuran-Regular.ttf

Reads the font's character map (cmap formats 4 and 12) with the standard
library only, collects every code point in assets/quran_master.json, and
lists any the font cannot draw. It also checks the characters the reader
adds for display: the end-of-ayah sign U+06DD, Arabic-Indic digits and the
no-break space.

Coverage is necessary, not sufficient: a font can contain a glyph and still
position marks badly. Visual review on a device is still required.

Exit status: 0 when nothing is missing, 1 otherwise.
"""
import json
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "assets" / "quran_master.json"

# Added by the reader at display time, never stored in the text.
DISPLAY_EXTRAS = {0x06DD, 0x00A0, *range(0x0660, 0x066A)}

# Invisible in the data and not expected to have a glyph.
IGNORED = {0xFEFF}


def cmap_code_points(font_path: Path) -> set[int]:
    data = font_path.read_bytes()
    num_tables = struct.unpack_from(">H", data, 4)[0]
    cmap_offset = None
    for i in range(num_tables):
        tag, _, offset, _ = struct.unpack_from(">4sIII", data, 12 + 16 * i)
        if tag == b"cmap":
            cmap_offset = offset
            break
    if cmap_offset is None:
        raise ValueError("font has no cmap table")

    points: set[int] = set()
    count = struct.unpack_from(">H", data, cmap_offset + 2)[0]
    for i in range(count):
        _, _, sub = struct.unpack_from(">HHI", data, cmap_offset + 4 + 8 * i)
        base = cmap_offset + sub
        fmt = struct.unpack_from(">H", data, base)[0]
        if fmt == 4:
            seg_x2 = struct.unpack_from(">H", data, base + 6)[0]
            seg = seg_x2 // 2
            ends = struct.unpack_from(f">{seg}H", data, base + 14)
            starts = struct.unpack_from(f">{seg}H", data, base + 16 + seg_x2)
            deltas = struct.unpack_from(f">{seg}h", data, base + 16 + 2 * seg_x2)
            range_base = base + 16 + 3 * seg_x2
            offsets = struct.unpack_from(f">{seg}H", data, range_base)
            for k in range(seg):
                for cp in range(starts[k], ends[k] + 1):
                    if cp == 0xFFFF:
                        continue
                    if offsets[k] == 0:
                        glyph = (cp + deltas[k]) & 0xFFFF
                    else:
                        at = range_base + 2 * k + offsets[k] + 2 * (cp - starts[k])
                        glyph = struct.unpack_from(">H", data, at)[0]
                        if glyph:
                            glyph = (glyph + deltas[k]) & 0xFFFF
                    if glyph:
                        points.add(cp)
        elif fmt == 12:
            groups = struct.unpack_from(">I", data, base + 12)[0]
            for g in range(groups):
                start, end, glyph = struct.unpack_from(">III", data, base + 16 + 12 * g)
                for cp in range(start, end + 1):
                    if glyph + (cp - start):
                        points.add(cp)
    return points


def data_code_points() -> set[int]:
    quran = json.loads(DATA.read_text(encoding="utf-8"))
    points: set[int] = set()
    for surah in quran:
        for ayah in surah["ayahs"]:
            points.update(ord(c) for c in ayah["text"])
    return points


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    font = Path(sys.argv[1])
    have = cmap_code_points(font)
    text = data_code_points() - IGNORED
    missing_text = sorted(text - have)
    missing_extras = sorted(DISPLAY_EXTRAS - have)

    print(f"Font: {font.name}")
    print(f"Code points in the Quran text: {len(text)}")
    print(f"Missing from the font (text): {len(missing_text)}")
    for cp in missing_text:
        print(f"  U+{cp:04X}")
    print(f"Missing from the font (added for display): {len(missing_extras)}")
    for cp in missing_extras:
        print(f"  U+{cp:04X}")
    return 1 if missing_text or missing_extras else 0


if __name__ == "__main__":
    sys.exit(main())
