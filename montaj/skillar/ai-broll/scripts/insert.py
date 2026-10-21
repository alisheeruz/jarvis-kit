#!/usr/bin/env python3
"""Tayyor b-roll kadrlarni asosiy video (yoki ovoz) ustiga plan.json dagi vaqtlar bo'yicha qo'yadi.

  insert.py <loyiha> [--draft]

plan.json: {"main": "asosiy.mp4" yoki "ovoz.m4a", "layout": "full" | "split", "shots": [{"id", "start", "end", "move"}]}
Har kadr uchun shots/<id>.mp4 ishlatiladi; u bo'lmasa shots/<id>.png animate.py bilan jonlantiriladi.
  full  — b-roll butun ekranni yopadi, kirish/chiqishda 0.2s eriydi.
  split — b-roll yuqori yarmida, gapiruvchi pastki yarmida (kadr ichidagi yuz ko'rinib turadi).
Ovoz doim asosiy fayldan olinadi. Natija: <loyiha>/out/final.mp4
"""
import json, os, subprocess, sys

FF = os.path.expanduser("~/.venvs/montaj/bin/ffmpeg")
HERE = os.path.dirname(os.path.abspath(__file__))
W, H, FPS, XF = 1080, 1920, 30, 0.2

def probe(path):
    r = subprocess.run([FF, "-hide_banner", "-i", path], capture_output=True, text=True).stderr
    dur = next(l for l in r.splitlines() if "Duration:" in l).split("Duration:")[1].split(",")[0].strip()
    h, m, s = dur.split(":")
    return int(h) * 3600 + int(m) * 60 + float(s), "Video:" in r

def main():
    prj = sys.argv[1]; draft = "--draft" in sys.argv
    plan = json.load(open(os.path.join(prj, "plan.json"), encoding="utf-8"))
    main_f = os.path.join(prj, plan["main"]); total, has_video = probe(main_f)
    split = plan.get("layout", "full") == "split"
    bw, bh = (W, H // 2) if split else (W, H)
    os.makedirs(os.path.join(prj, "out"), exist_ok=True)
    clips = []
    for s in plan["shots"]:
        dur = round(s["end"] - s["start"], 3)
        mp4 = os.path.join(prj, "shots", f"{s['id']}.mp4"); png = os.path.join(prj, "shots", f"{s['id']}.png")
        if not os.path.exists(mp4):
            if not os.path.exists(png):
                print(f"  {s['id']}: fayl yo'q — o'tkazib yuborildi"); continue
            mp4 = os.path.join(prj, "shots", f"{s['id']}_anim.mp4")
            subprocess.run([sys.executable if "montaj" in sys.executable else os.path.expanduser("~/.venvs/montaj/bin/python"),
                            os.path.join(HERE, "animate.py"), png, mp4, "--dur", str(dur), "--move", s.get("move", "in"),
                            "--size", f"{bw}x{bh}"] + (["--dust"] if s.get("dust") else []), check=True)
        clips.append((s, mp4, dur))
    if not clips: sys.exit("Birorta ham kadr topilmadi (shots/ bo'sh).")

    cmd = [FF, "-v", "error", "-y"]
    if has_video: cmd += ["-i", main_f]
    else: cmd += ["-f", "lavfi", "-t", f"{total}", "-i", f"color=c=black:s={W}x{H}:r={FPS}", "-i", main_f]
    n0 = 1 if has_video else 2
    for _, mp4, dur in clips: cmd += ["-stream_loop", "-1", "-t", f"{dur}", "-i", mp4]
    fg = [f"[0:v]scale={W}:{H}:force_original_aspect_ratio=increase,crop={W}:{H},fps={FPS},setsar=1[base]"]
    last = "base"
    if split:
        # b-roll paytida gapiruvchi pastki yarimga tushadi: asosiy kadrning markaziy bo'lagi kesib olinadi
        fg.append(f"[0:v]scale={W}:{H}:force_original_aspect_ratio=increase,crop={W}:{H},crop={W}:{H//2}:0:{plan.get('split_y', H//5)},fps={FPS},setsar=1[low]")
        en = "+".join(f"between(t,{s['start']},{s['end']})" for s, _, _ in clips)
        fg.append(f"[{last}][low]overlay=0:{H//2}:enable='{en}'[b0]"); last = "b0"
    for i, (s, _, dur) in enumerate(clips):
        fade = "" if split else f",fade=t=in:st=0:d={XF}:alpha=1,fade=t=out:st={max(0, dur - XF):.3f}:d={XF}:alpha=1"
        fg.append(f"[{n0 + i}:v]scale={bw}:{bh}:force_original_aspect_ratio=increase,crop={bw}:{bh},fps={FPS},setsar=1,format=yuva420p{fade},setpts=PTS-STARTPTS+{s['start']}/TB[c{i}]")
        fg.append(f"[{last}][c{i}]overlay=0:0:enable='between(t,{s['start']},{s['end']})':eof_action=pass[v{i}]"); last = f"v{i}"
    out = os.path.join(prj, "out", "final_draft.mp4" if draft else "final.mp4")
    cmd += ["-filter_complex", ";".join(fg), "-map", f"[{last}]", "-map", f"{0 if has_video else 1}:a?", "-t", f"{total}",
            "-c:v", "libx264", "-crf", "26" if draft else "18", "-preset", "veryfast" if draft else "medium", "-pix_fmt", "yuv420p",
            "-c:a", "aac", "-b:a", "192k", out]
    subprocess.run(cmd, check=True)
    print(out, f"{total:.1f}s, {len(clips)} ta b-roll, joylashuv: {'split' if split else 'full'}")

if __name__ == "__main__":
    main()
