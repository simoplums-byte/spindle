#!/usr/bin/env python3
"""把 docs/design/renders/discs 下的单张碟面渲染拼成一张对照图。

用法：python3 scripts/make-disc-contact-sheet.py [输出路径]
"""
import sys
from PIL import Image, ImageDraw, ImageFont

RENDERS = "docs/design/renders/discs"
ITEMS = [
    ("disc-silver@2x.png", "银色压模"),
    ("disc-hologram@2x.png", "极光全息"),
    ("disc-label@2x.png", "印刷标签"),
    ("disc-crystal@2x.png", "透明水晶"),
    ("disc-gold@2x.png", "金碟"),
    ("disc-jibuli@2x.png", "吉卜李（专属碟面）"),
]
OUT = sys.argv[1] if len(sys.argv) > 1 else f"{RENDERS}/contact-sheet@2x.png"

CELL, PAD, CAP = 384, 26, 62
COLS = 3
ROWS = (len(ITEMS) + COLS - 1) // COLS
W = COLS * CELL + (COLS + 1) * PAD
H = ROWS * (CELL + CAP) + (ROWS + 1) * PAD + 76
sheet = Image.new("RGB", (W, H), (24, 24, 26))
draw = ImageDraw.Draw(sheet)

title_font = ImageFont.truetype("/System/Library/Fonts/STHeiti Medium.ttc", 40, index=0)
cap_font = ImageFont.truetype("/System/Library/Fonts/STHeiti Medium.ttc", 24, index=0)
draw.text((PAD, 34), "Spindle 碟面样式（六款）", font=title_font, fill=(242, 240, 236))

for i, (file, label) in enumerate(ITEMS):
    col, row = i % COLS, i // COLS
    x = PAD + col * (CELL + PAD)
    y = 76 + PAD + row * (CELL + CAP)
    art = Image.open(f"{RENDERS}/{file}").convert("RGB").resize((CELL, CELL), Image.LANCZOS)
    sheet.paste(art, (x, y))
    draw.text((x + CELL / 2, y + CELL + CAP / 2 - 4), label, font=cap_font,
              fill=(226, 222, 214), anchor="mm")

sheet.save(OUT)
print(f"contact sheet -> {OUT} {sheet.size[0]}x{sheet.size[1]}")
