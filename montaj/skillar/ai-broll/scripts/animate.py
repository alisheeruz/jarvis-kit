#!/usr/bin/env python3
"""Harakatsiz rasmni jonli b-roll klipga aylantiradi (video generatori bo'lmaganda zaxira yo'l).

  animate.py <rasm> <chiqish.mp4> [--dur 5] [--move in|out|left|right|up|down] [--amount 0.08]
             [--dust] [--size 1080x1920] [--fps 30]

Kamera sekin yaqinlashadi/suriladi (subpiksel aniqlikda, titrashsiz), --dust havoda suzuvchi
yorug' zarrachalar qo'shadi. Rasm kadrga "cover" usulida joylanadi (chetlari kesiladi).
"""
import argparse, math, os, random, subprocess, sys
from PIL import Image, ImageDraw, ImageFilter

FF = os.path.expanduser("~/.venvs/montaj/bin/ffmpeg")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("img"); ap.add_argument("out")
    ap.add_argument("--dur", type=float, default=5); ap.add_argument("--move", default="in")
    ap.add_argument("--amount", type=float, default=0.08); ap.add_argument("--dust", action="store_true")
    ap.add_argument("--size", default="1080x1920"); ap.add_argument("--fps", type=int, default=30)
    a = ap.parse_args()
    W, H = map(int, a.size.split("x"))
    src = Image.open(a.img).convert("RGB")
    # cover + harakat uchun zaxira chet
    k = max(W / src.width, H / src.height) * (1 + a.amount + 0.02)
    src = src.resize((math.ceil(src.width * k), math.ceil(src.height * k)), Image.LANCZOS)
    n = max(2, round(a.dur * a.fps))
    rnd = random.Random(a.img)
    dust = [(rnd.random(), rnd.random(), 1.5 + rnd.random() * 3, 0.2 + rnd.random() * 0.6, rnd.random() * 6.28) for _ in range(40)]
    p = subprocess.Popen([FF, "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(a.fps),
                          "-i", "-", "-c:v", "libx264", "-crf", "17", "-preset", "medium", "-pix_fmt", "yuv420p", a.out], stdin=subprocess.PIPE)
    for i in range(n):
        t = i / (n - 1); e = 0.5 - 0.5 * math.cos(math.pi * t)  # silliq boshlanish va to'xtash
        zmax = 1 + a.amount + 0.02
        z = {"in": 1 + a.amount * e, "out": 1 + a.amount * (1 - e)}.get(a.move, 1 + a.amount)
        vw, vh = W * zmax / z, H * zmax / z                 # ko'rinadigan oyna (kattalashtirilgan rasm piksellarida)
        cx, cy = src.width / 2, src.height / 2
        dx = (src.width - vw) / 2; dy = (src.height - vh) / 2
        if a.move == "left": cx += dx * (1 - 2 * e)
        if a.move == "right": cx -= dx * (1 - 2 * e)
        if a.move == "up": cy += dy * (1 - 2 * e)
        if a.move == "down": cy -= dy * (1 - 2 * e)
        fr = src.transform((W, H), Image.AFFINE, (vw / W, 0, cx - vw / 2, 0, vh / H, cy - vh / 2), Image.BICUBIC)
        if a.dust:
            layer = Image.new("RGBA", (W, H), (0, 0, 0, 0)); d = ImageDraw.Draw(layer)
            for x, y, r, sp, ph in dust:
                px = (x * W + math.sin(i / 40 * sp + ph) * 30) % W
                py = (y * H - i * sp * 1.2) % H
                al = int(90 + 80 * math.sin(i / 14 + ph))
                d.ellipse((px - r, py - r, px + r, py + r), fill=(255, 226, 170, max(0, al)))
            fr = Image.alpha_composite(fr.convert("RGBA"), layer.filter(ImageFilter.GaussianBlur(1.2))).convert("RGB")
        p.stdin.write(fr.tobytes())
    p.stdin.close(); p.wait()
    print(a.out, f"{a.dur}s", a.move)

if __name__ == "__main__":
    main()
