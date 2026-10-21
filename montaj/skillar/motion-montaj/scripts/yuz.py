#!/usr/bin/env python3
"""Videoda yuz qayerda turganini topadi — matn/plashka yuzga tushmasligi uchun.

  yuz.py <video> [--har 0.5] [--json chiqish.json]

Video 1080x1920 ga keltirilgan bo'lishi kerak (public/main.mp4). Har --har soniyada bitta kadr
ko'riladi (YuNet). Chiqish: har oraliqda yuz chegarasi (y_tepa..y_past) va xulosa — matnni qaysi
balandlikka qo'yish xavfsiz.
"""
import argparse, json, os, subprocess, sys
import numpy as np
import cv2

FF = os.path.expanduser("~/.venvs/montaj/bin/ffmpeg")
MODEL = os.path.expanduser("~/.venvs/montaj/yunet.onnx")
W, H = 1080, 1920


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("video"); ap.add_argument("--har", type=float, default=0.5); ap.add_argument("--json")
    a = ap.parse_args()
    if not os.path.exists(MODEL):
        sys.exit(f"YuNet modeli yo'q: {MODEL}")
    det = cv2.FaceDetectorYN.create(MODEL, "", (W, H), 0.7)
    p = subprocess.Popen([FF, "-v", "error", "-i", a.video, "-vf",
                          f"fps=1/{a.har},scale={W}:{H}:force_original_aspect_ratio=increase,crop={W}:{H}",
                          "-f", "rawvideo", "-pix_fmt", "bgr24", "-"], stdout=subprocess.PIPE)
    res, i = [], 0
    while True:
        buf = p.stdout.read(W * H * 3)
        if len(buf) < W * H * 3:
            break
        _, faces = det.detect(np.frombuffer(buf, np.uint8).reshape(H, W, 3))
        t = round(i * a.har, 2); i += 1
        if faces is None or len(faces) == 0:
            res.append({"t": t, "yuz": None}); continue
        x, y, w, h = faces[np.argmax(faces[:, 2] * faces[:, 3])][:4]
        res.append({"t": t, "yuz": [int(x), int(y), int(x + w), int(y + h)]})
    p.wait()
    if a.json:
        json.dump(res, open(a.json, "w"), indent=1)
    bor = [r["yuz"] for r in res if r["yuz"]]
    print(f"{len(res)} kadr, yuz topildi: {len(bor)}")
    for r in res:
        print(f"{r['t']:6.1f}s  " + ("yuz yo'q" if not r["yuz"] else f"x {r['yuz'][0]}-{r['yuz'][2]}  y {r['yuz'][1]}-{r['yuz'][3]}"))
    if bor:
        top, bot = min(b[1] for b in bor), max(b[3] for b in bor)
        print(f"\nXULOSA: yuz y={top}..{bot} oralig'ida. Matn uchun xavfsiz: y<{max(top - 40, 0)} yoki y>{min(bot + 60, H)}"
              f" (pastki 300 px — Instagram interfeysi, y<1620 bo'lsin).")


if __name__ == "__main__":
    main()
