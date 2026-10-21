#!/usr/bin/env python3
"""Videodan odamni kesib, alfa-kanalli klip yasaydi ("matn odam orqasida" effekti uchun).

  matte.py <video> <chiqish.webm> [--start 0] [--end 5] [--model isnet-general-use]

Faqat matn odam orqasida turadigan bo'lak uchun ishlating: 1 soniya video ≈ 30–60 soniya hisob.
Chiqish 1080x1920, 30 kadr/s, VP9 + alfa; Remotion'da <Person src="..."/> bilan qo'yiladi.
<video> allaqachon 1080x1920 ga keltirilgan asosiy fayl (public/main.mp4) bo'lishi kerak — aks holda kesim siljiydi.
"""
import argparse, os, subprocess, sys, time
import numpy as np
from PIL import Image, ImageFilter

FF = os.path.expanduser("~/.venvs/montaj/bin/ffmpeg")
W, H, FPS = 1080, 1920, 30

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("video"); ap.add_argument("out")
    ap.add_argument("--start", type=float, default=0); ap.add_argument("--end", type=float, default=5)
    ap.add_argument("--model", default="isnet-general-use")
    a = ap.parse_args()
    from rembg import new_session, remove
    ses = new_session(a.model)
    n = round((a.end - a.start) * FPS)
    src = subprocess.Popen([FF, "-v", "error", "-ss", str(a.start), "-t", str(a.end - a.start), "-i", a.video,
                            "-vf", f"fps={FPS},scale={W}:{H}:force_original_aspect_ratio=increase,crop={W}:{H}",
                            "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], stdout=subprocess.PIPE)
    dst = subprocess.Popen([FF, "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgba", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-",
                            "-c:v", "libvpx-vp9", "-pix_fmt", "yuva420p", "-b:v", "0", "-crf", "24", "-row-mt", "1", "-auto-alt-ref", "0", a.out],
                           stdin=subprocess.PIPE)
    t0 = time.time(); i = 0
    while True:
        buf = src.stdout.read(W * H * 3)
        if len(buf) < W * H * 3: break
        fr = Image.frombuffer("RGB", (W, H), buf)
        # maska yarim o'lchamda hisoblanadi (2-3 baravar tez), keyin kattalashtirib, cheti yumshatiladi
        m = remove(fr.resize((W // 2, H // 2), Image.BILINEAR), session=ses, only_mask=True)
        m = m.resize((W, H), Image.BICUBIC).filter(ImageFilter.GaussianBlur(1.5))
        dst.stdin.write(np.dstack([np.asarray(fr), np.asarray(m)]).tobytes())
        i += 1
        if i % 30 == 0: print(f"  {i}/{n} kadr, {time.time() - t0:.0f}s", flush=True)
    dst.stdin.close(); dst.wait()
    print(a.out, f"{i} kadr, {time.time() - t0:.0f}s")

if __name__ == "__main__":
    main()
