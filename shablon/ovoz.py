#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ovoz.py — ovozli xabar (.oga/.ogg/.mp3/.m4a/.wav) → matn (Gemini).
Ishlatish:  python3 ~/jarvis/ovoz.py <audio-fayl>
Kalit: ~/jarvis/.env  (GEMINI_API_KEY=..., GEMINI_MODEL=gemini-flash-latest)
Faqat standart kutubxona — qo'shimcha o'rnatish kerak emas."""
import sys, os, json, base64, time, urllib.request, urllib.error

ENV = os.path.expanduser("~/jarvis/.env")
MIME = {".oga": "audio/ogg", ".ogg": "audio/ogg", ".mp3": "audio/mp3", ".m4a": "audio/mp4",
        ".wav": "audio/wav", ".aac": "audio/aac", ".flac": "audio/flac", ".mp4": "video/mp4"}

def env():
    d = {}
    if os.path.exists(ENV):
        for line in open(ENV, encoding="utf-8"):
            line = line.strip()
            if "=" in line and not line.startswith("#"):
                k, v = line.split("=", 1); d[k.strip()] = v.strip().strip('"').strip("'")
    return d

def main():
    if len(sys.argv) < 2:
        print("ishlatish: ovoz.py <audio-fayl>"); sys.exit(1)
    f = sys.argv[1]
    if not os.path.exists(f):
        print(f"fayl topilmadi: {f}"); sys.exit(1)
    e = env(); key = e.get("GEMINI_API_KEY"); model = e.get("GEMINI_MODEL", "gemini-flash-latest")
    if not key:
        print("GEMINI_API_KEY yo'q (~/jarvis/.env)"); sys.exit(1)
    mime = MIME.get(os.path.splitext(f)[1].lower(), "audio/ogg")
    data = base64.b64encode(open(f, "rb").read()).decode()
    body = {"contents": [{"parts": [
        {"text": "Bu ovozli xabarni so'zma-so'z matnga o'gir. Til: o'zbek (lotin) — agar rus yoki ingliz bo'lsa, o'sha tilda qoldir. Faqat matnni qaytar, izohsiz."},
        {"inline_data": {"mime_type": mime, "data": data}}]}],
        # 2026-09-06: transkript yarmida uzilib qolgan edi. Sabab — javob chegarasi
        # va "o'ylash" byudjeti. Endi chegara ochiq, o'ylash o'chirilgan.
        "generationConfig": {"maxOutputTokens": 16384, "temperature": 0,
                             "thinkingConfig": {"thinkingBudget": 0}}}
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"
    req = urllib.request.Request(url, data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
    backoff = [3, 8, 20, 40]
    last = None
    for i in range(len(backoff) + 1):
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                out = json.load(r)
            c = out["candidates"][0]
            # Javob bir nechta bo'lakka bo'linishi mumkin — hammasini birlashtiramiz.
            matn = "".join(x.get("text", "")
                           for x in c.get("content", {}).get("parts", []))
            sabab = c.get("finishReason", "")
            if not matn.strip():
                print(f"[bo'sh javob · finishReason={sabab}]"); sys.exit(2)
            print(matn.strip())
            # Uzilib qolgan bo'lsa JIM QOLMAYMIZ — yarim buyruq bo'yicha ish qilinmasin.
            if sabab and sabab != "STOP":
                print(f"\n[DIQQAT: transkript to'liq emas · finishReason={sabab}]")
            return
        except urllib.error.HTTPError as ex:
            last = f"Gemini xato: {ex.code} {ex.read().decode()[:300]}"
            if ex.code in (429, 500, 502, 503, 504) and i < len(backoff):
                time.sleep(backoff[i]); continue
            print(last); sys.exit(2)
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, KeyError) as ex:
            last = f"Gemini ulanish xato: {type(ex).__name__}: {ex}"
            if i < len(backoff):
                time.sleep(backoff[i]); continue
            print(last); sys.exit(2)
    print(last or "Gemini: noma'lum xato"); sys.exit(2)

if __name__ == "__main__":
    main()
