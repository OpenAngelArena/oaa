"""Draw OAA item tier pips (the 5 dots in the top-right corner) on an item icon.

    python scripts/item-tier-pips.py <icon.png> <out_dir> <name> [--tiers 1-5]

writes <out_dir>/<name>_1.png .. <name>_5.png. The icon is scaled to 88x64 first
(Valve's newer icons come in at 86x62 or similar). Needs Pillow (pip install pillow).

Layout measured from the modern 5-tier icons (e.g. unused/khanda_4.png):
black box in the top-right corner (slanted bottom-left edge), 5x5 pips with soft
corners, top row x 67/75/83 at y 1-5, bottom row x 71/79 at y 7-11; lit grey 216
(corners 144, bottom-left 150), unlit grey 87 (corners 43). Fill order zigzags:
tier 1 top-left, 2 bottom-left, 3 top-middle, 4 bottom-right, 5 top-right.
"""
import os
import sys

from PIL import Image

W, H = 88, 64
# (x, y) top-left corner of each pip, in fill order
PIPS = [(67, 1), (71, 7), (75, 1), (79, 7), (83, 1)]
# first black column per row of the box (rows 0-12)
BOX_LEFT = [66] * 9 + [67, 68, 69, 70]


def pip_pixels(lit):
    full, corner, corner_bl = (216, 144, 150) if lit else (87, 43, 43)
    rows = []
    for y in range(5):
        row = []
        for x in range(5):
            if (x, y) in ((0, 0), (4, 0), (4, 4)):
                row.append(corner)
            elif (x, y) == (0, 4):
                row.append(corner_bl)
            else:
                row.append(full)
        rows.append(row)
    return rows


def draw(icon, tier):
    im = icon.copy()
    px = im.load()
    for y, left in enumerate(BOX_LEFT):
        for x in range(left, W):
            px[x, y] = (0, 0, 0, 255)
    for i, (x0, y0) in enumerate(PIPS):
        rows = pip_pixels(i < tier)
        for dy, row in enumerate(rows):
            for dx, g in enumerate(row):
                px[x0 + dx, y0 + dy] = (g, g, g, 255)
    return im


def main(argv):
    if len(argv) < 4:
        print(__doc__)
        return 1
    src, out_dir, name = argv[1], argv[2], argv[3]
    tiers = range(1, 6)
    if '--tiers' in argv:
        a, b = argv[argv.index('--tiers') + 1].split('-')
        tiers = range(int(a), int(b) + 1)
    icon = Image.open(src).convert('RGBA')
    if icon.size != (W, H):
        icon = icon.resize((W, H), Image.LANCZOS)
    os.makedirs(out_dir, exist_ok=True)
    for t in tiers:
        out = os.path.join(out_dir, '%s_%d.png' % (name, t))
        draw(icon, t).save(out, optimize=True)
        print('OK', out)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
