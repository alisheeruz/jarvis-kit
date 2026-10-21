#!/usr/bin/env python3
"""Tuzatilgan matn.txt ni whisper vaqt belgilariga bog'lab, captions.json yasaydi.

Ishlatish:
  align.py <loyiha papkasi>            # words.json bor bo'lsa — ovozga moslaydi
  align.py <loyiha papkasi> --fake     # ovozsiz sinov: har so'zga taxminiy vaqt beradi

Whisper o'zbekchada xato yozadi, shuning uchun matn qo'lda tuzatiladi; bu skript tuzatilgan
so'zlarni xom so'zlar ketma-ketligiga moslaydi va mos kelmagan so'zlar vaqtini oraliqdan taqsimlaydi.
"""
import sys, json, re, difflib, os

prj = sys.argv[1]
fake = "--fake" in sys.argv

def typo(w):
    # o' g' -> o‘ g‘ (U+2018), qolgan apostroflar -> ’ (U+2019); "..." -> «...» qo'lda yoziladi
    w = re.sub(r"([oOgG])['`ʻ‘’]", "\\1\u2018", w)
    return re.sub(r"['`ʻ]", "\u2019", w)

def norm(w):
    return re.sub(r"[^a-zа-яёўқғҳ0-9]", "", w.lower().replace("\u2018", "").replace("\u2019", ""))

blocks, cur = [], []
for raw in open(os.path.join(prj, "matn.txt"), encoding="utf-8"):
    line = raw.strip()
    if line.startswith("#"): continue
    if not line:
        if cur: blocks.append(cur); cur = []
        continue
    cur.append([{"t": typo(w.replace("*", "")), "hl": "*" in w} for w in line.split()])
if cur: blocks.append(cur)

flat = [w for b in blocks for l in b for w in l]
if not flat: sys.exit("matn.txt bo'sh")

if fake:
    t = 0.3
    for b in blocks:
        for l in b:
            for w in l:
                d = 0.22 + 0.045 * len(w["t"])
                w["s"], w["e"] = round(t, 2), round(t + d, 2); t += d + 0.04
        t += 0.35
else:
    raw = json.load(open(os.path.join(prj, "words.json"), encoding="utf-8"))
    a, b_ = [norm(w["t"]) for w in raw], [norm(w["t"]) for w in flat]
    sm = difflib.SequenceMatcher(None, a, b_, autojunk=False)
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            for k in range(j2 - j1):
                flat[j1 + k]["s"], flat[j1 + k]["e"] = raw[i1 + k]["s"], raw[i1 + k]["e"]
        elif tag == "replace":
            # xom bo'lak vaqtini tuzatilgan so'zlarga harf soniga qarab bo'lamiz
            s, e = raw[i1]["s"], raw[i2 - 1]["e"]
            tot = sum(len(flat[j]["t"]) for j in range(j1, j2)) or 1
            t = s
            for j in range(j1, j2):
                d = (e - s) * len(flat[j]["t"]) / tot
                flat[j]["s"], flat[j]["e"] = round(t, 2), round(t + d, 2); t += d
    # whisper tashlab ketgan so'zlar (insert): qo'shnilar orasiga joylaymiz
    n = len(flat); i = 0
    while i < n:
        if "s" in flat[i]: i += 1; continue
        j = i
        while j < n and "s" not in flat[j]: j += 1
        s = flat[i - 1]["e"] if i else 0.0
        e = flat[j]["s"] if j < n else s + 0.35 * (j - i)
        if e - s < 0.12 * (j - i): e = s + 0.12 * (j - i)
        for k in range(i, j):
            flat[k]["s"] = round(s + (e - s) * (k - i) / (j - i), 2)
            flat[k]["e"] = round(s + (e - s) * (k - i + 1) / (j - i), 2)
        i = j
    matched = sum(x.size for x in sm.get_matching_blocks())
    print(f"mos kelgan so'zlar: {matched}/{len(flat)}")
    if matched < 0.6 * len(flat):
        print("OGOHLANTIRISH: moslik past — matn.txt ovozdagi gap bilan bir xilmi, tekshiring.")

caps = []
for b in blocks:
    ws = [w for l in b for w in l]
    caps.append({"s": ws[0]["s"], "e": ws[-1]["e"], "lines": b})
for i, c in enumerate(caps):
    nxt = caps[i + 1]["s"] if i + 1 < len(caps) else c["e"] + 0.8
    # pauzada matn biroz turib yo'qoladi; lekin keyingi blok boshlanishidan oshib ketmaydi (whisper so'z oxirlarini cho'zib beradi)
    c["e"] = round(max(c["s"] + 0.2, min(max(c["e"] + 0.1, min(nxt - 0.04, c["e"] + 0.7)), nxt - 0.02)), 2)

out = os.path.join(prj, "src", "captions.json")
json.dump(caps, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(f"{len(caps)} blok, {len(flat)} so'z, davomiyligi {caps[-1]['e']:.1f}s -> {out}")
for c in caps:
    txt = " / ".join(" ".join(w["t"] for w in l) for l in c["lines"])
    warn = "  <-- UZUN (qatorga 2-4 so'z)" if any(len(l) > 5 for l in c["lines"]) or len(c["lines"]) > 2 else ""
    print(f"  {c['s']:6.2f}-{c['e']:6.2f}  {txt}{warn}")
