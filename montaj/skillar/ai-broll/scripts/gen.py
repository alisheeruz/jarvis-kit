#!/usr/bin/env python3
"""AI b-roll generatori: reja (plan.json) bo'yicha rasm va video yasaydi.

  gen.py check                 # kalit va kvota ishlayaptimi (bitta arzon so'rov)
  gen.py image <loyiha>        # har kadr uchun rasm  -> <loyiha>/shots/<id>.png
  gen.py video <loyiha>        # rasmni jonlantiradi  -> <loyiha>/shots/<id>.mp4  (PULLIK: Veo)
  gen.py prompts <loyiha>      # qo'lda generatsiya uchun <loyiha>/promptlar.md

Kalit: ~/jarvis/.env ichidagi GEMINI_API_KEY (yoki muhitdagi GEMINI_API_KEY).
Tayyor fayllar qayta yasalmaydi: kadrni yangilash uchun shots/<id>.png ni o'chiring.
"""
import base64, json, os, sys, time, urllib.request, urllib.error

API = "https://generativelanguage.googleapis.com/v1beta"
IMAGE_MODEL = os.environ.get("BROLL_IMAGE_MODEL", "gemini-3.1-flash-image")
VIDEO_MODEL = os.environ.get("BROLL_VIDEO_MODEL", "veo-3.1-fast-generate-preview")


def key():
    k = os.environ.get("GEMINI_API_KEY")
    p = os.path.expanduser("~/jarvis/.env")
    if not k and os.path.exists(p):
        for line in open(p):
            if line.startswith("GEMINI_API_KEY="):
                k = line.split("=", 1)[1].strip().strip("\"'")
    if not k:
        sys.exit("GEMINI_API_KEY topilmadi (~/jarvis/.env). Qo'lda rejim: gen.py prompts <loyiha>")
    return k


def call(path, body=None, raw=False):
    url = path if path.startswith("http") else f"{API}/{path}"
    req = urllib.request.Request(url, data=json.dumps(body).encode() if body is not None else None,
                                 headers={"x-goog-api-key": key(), "content-type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=300) as r:
            data = r.read()
            return data if raw else json.loads(data)
    except urllib.error.HTTPError as e:
        msg = e.read().decode(errors="replace")
        try: msg = json.loads(msg)["error"]["message"].split("\n")[0]
        except Exception: msg = msg[:300]
        if e.code == 429:
            raise SystemExit(f"KVOTA YO'Q (429): {msg}\n"
                             "-> Bu kalitda rasm/video uchun bepul limit 0. Yo'llari: (1) aistudio.google.com da billing yoqish, "
                             "(2) qo'lda rejim: gen.py prompts <loyiha>, (3) zaxira: animate.py bilan mavjud rasmlarni jonlantirish.")
        raise SystemExit(f"API xato {e.code}: {msg}")


def load(prj):
    plan = json.load(open(os.path.join(prj, "plan.json"), encoding="utf-8"))
    os.makedirs(os.path.join(prj, "shots"), exist_ok=True)
    return plan


def full_prompt(plan, shot):
    # Uslub bloki har kadrga bir xil qo'shiladi — kadrlar bir oiladan ko'rinishi shundan.
    return f"{shot['image_prompt'].strip()}\n\nStyle: {plan['style'].strip()}\nVertical 9:16 composition. No text, no letters, no watermark, no logo."


def img_part(path):
    mime = "image/png" if path.lower().endswith(".png") else "image/jpeg"
    return {"inlineData": {"mimeType": mime, "data": base64.b64encode(open(path, "rb").read()).decode()}}


def cmd_image(prj):
    plan = load(prj)
    for s in plan["shots"]:
        out = os.path.join(prj, "shots", f"{s['id']}.png")
        if os.path.exists(out) or s.get("method") == "restyle":
            continue
        parts = [{"text": full_prompt(plan, s)}]
        # refs: personaj/uslub izchilligi uchun namunaviy rasmlar (loyiha papkasiga nisbatan yo'l)
        for ref in (plan.get("refs") or []) + (s.get("refs") or []):
            parts.append(img_part(os.path.join(prj, ref)))
        d = call(f"models/{IMAGE_MODEL}:generateContent", {
            "contents": [{"parts": parts}],
            "generationConfig": {"responseModalities": ["IMAGE"], "imageConfig": {"aspectRatio": plan.get("aspect", "9:16")}}})
        blob = next((p["inlineData"]["data"] for p in d["candidates"][0]["content"]["parts"] if "inlineData" in p), None)
        if not blob:
            print(f"  {s['id']}: rasm qaytmadi (filtr?) — promptni yumshating"); continue
        open(out, "wb").write(base64.b64decode(blob)); print(f"  {s['id']}: {out}")


def cmd_video(prj):
    plan = load(prj)
    todo = [s for s in plan["shots"] if s.get("motion_prompt") and s.get("method") == "animate"
            and not os.path.exists(os.path.join(prj, "shots", f"{s['id']}.mp4"))]
    print(f"{len(todo)} ta klip yasaladi ({VIDEO_MODEL}). Bu PULLIK — narxni ai.google.dev/pricing dan tekshiring.")
    for s in todo:
        img = os.path.join(prj, "shots", f"{s['id']}.png")
        if not os.path.exists(img):
            print(f"  {s['id']}: avval rasm kerak (gen.py image)"); continue
        im = img_part(img)["inlineData"]
        op = call(f"models/{VIDEO_MODEL}:predictLongRunning", {
            "instances": [{"prompt": s["motion_prompt"], "image": {"bytesBase64Encoded": im["data"], "mimeType": im["mimeType"]}}],
            "parameters": {"aspectRatio": plan.get("aspect", "9:16")}})
        while not op.get("done"):
            time.sleep(10); op = call(op["name"])
        try:
            uri = op["response"]["generateVideoResponse"]["generatedSamples"][0]["video"]["uri"]
        except Exception:
            print(f"  {s['id']}: video qaytmadi: {json.dumps(op)[:300]}"); continue
        out = os.path.join(prj, "shots", f"{s['id']}.mp4")
        open(out, "wb").write(call(uri, raw=True)); print(f"  {s['id']}: {out}")


def cmd_prompts(prj):
    plan = load(prj)
    L = [f"# AI b-roll promptlari — {plan.get('title', '')}", "",
         "Har kadr uchun: (1) rasm promptini rasm generatoriga (Gemini / Midjourney / ChatGPT) bering, format 9:16;",
         "(2) chiqqan rasmni video generatoriga (Kling / Veo / Runway / Higgsfield) yuklab, harakat promptini bering;",
         f"(3) natijani `shots/` papkasiga jadvaldagi nom bilan saqlang.", ""]
    for s in plan["shots"]:
        L += [f"## {s['id']} — {s['start']}–{s['end']}s — {s.get('method', 'animate')}", f"Gap: «{s.get('line', '')}»", ""]
        if s.get("method") == "restyle":
            L += ["**Video-to-video prompt** (asl kadr bo'lagi: `shots/" + s["id"] + "_src.mp4`):", "```", s["restyle_prompt"], "```",
                  f"Saqlash: `shots/{s['id']}.mp4`", ""]
            continue
        L += ["**Rasm prompti:**", "```", full_prompt(plan, s), "```", f"Saqlash: `shots/{s['id']}.png`", ""]
        if s.get("motion_prompt"):
            L += ["**Harakat prompti (image-to-video):**", "```", s["motion_prompt"], "```", f"Saqlash: `shots/{s['id']}.mp4`", ""]
    out = os.path.join(prj, "promptlar.md"); open(out, "w", encoding="utf-8").write("\n".join(L)); print(out)


def cmd_check():
    call(f"models/{IMAGE_MODEL}:generateContent", {
        "contents": [{"parts": [{"text": "A plain teal square."}]}],
        "generationConfig": {"responseModalities": ["IMAGE"], "imageConfig": {"aspectRatio": "1:1"}}})
    print(f"OK: {IMAGE_MODEL} ishlayapti.")


if __name__ == "__main__":
    a = sys.argv[1:]
    if not a or a[0] not in ("check", "image", "video", "prompts") or (a[0] != "check" and len(a) < 2):
        sys.exit(__doc__)
    {"check": cmd_check, "image": cmd_image, "video": cmd_video, "prompts": cmd_prompts}[a[0]](*a[1:2])
