#!/usr/bin/env python3
"""Personaj rasmini "stiker"ga aylantiradi: fonni olib tashlaydi, oq kontur va yumshoq soya qo'shadi.

  sticker.py <rasm> <chiqish.png> [--stroke 12] [--no-shadow]

Personajni bir xil, tekis (oq yoki yashil) fonda generatsiya qiling — kesish toza chiqadi.
"""
import argparse, os, sys
from PIL import Image, ImageFilter, ImageChops

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("img"); ap.add_argument("out"); ap.add_argument("--stroke", type=int, default=12)
    ap.add_argument("--no-shadow", action="store_true")
    a = ap.parse_args()
    from rembg import remove
    cut = remove(Image.open(a.img).convert("RGBA"))
    bbox = cut.getchannel("A").point(lambda v: 255 if v > 20 else 0).getbbox()
    cut = cut.crop(bbox)
    pad = a.stroke * 3
    canvas = Image.new("RGBA", (cut.width + pad * 2, cut.height + pad * 2), (0, 0, 0, 0))
    canvas.paste(cut, (pad, pad))
    alpha = canvas.getchannel("A").point(lambda v: 255 if v > 60 else 0)
    grown = alpha.filter(ImageFilter.MaxFilter(a.stroke * 2 + 1)).filter(ImageFilter.GaussianBlur(1.2))
    out = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    if not a.no_shadow:
        sh = ImageChops.offset(grown.filter(ImageFilter.GaussianBlur(a.stroke)), 0, a.stroke // 2)
        out.paste((0, 0, 0, 110), (0, 0), sh)
    out.paste((255, 255, 255, 255), (0, 0), grown)
    out = Image.alpha_composite(out, canvas)
    out.save(a.out); print(a.out, out.size)

if __name__ == "__main__":
    main()
