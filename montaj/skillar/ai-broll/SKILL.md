---
name: ai-broll
description: Reels/video uchun AI yordamida b-roll yasash — ssenariy yoki tayyor videodan b-roll rejasi tuzish, rasm va harakat promptlarini yozish, generatsiya qilish (Gemini/Veo API yoki qo'lda Kling/Midjourney/Runway), kadrlarni jonlantirish va videoga vaqt bo'yicha qo'yish. Foydalanuvchi "b-roll yasa", "AI b-roll", "videoga AI kadrlar qo'sh", "gapirayotgan videoni boyit", "AI bilan illyustratsiya/perebivka", "ovozga AI rasmlar", "stiker personajli video" yoki "o'zimni boshqa dunyoga ko'chir (zombi, kovboy...)" desa ishlat — "b-roll" so'zini aytmasa ham. Kod bilan chiziladigan chiziqli animatsiya kerak bo'lsa bu emas, `bashar-uslub` skilli.
---

# AI b-roll

B-roll — asosiy gap ustiga qo'yiladigan, gapning ma'nosini ko'rsatadigan kadr. Bu skill uni AI
bilan yasaydi: reja → promptlar → generatsiya → jonlantirish → videoga qo'yish. Usullar
3 ta reference videodan olingan (tahlil: `references/tahlil.md`).

Ishni boshlashdan oldin foydalanuvchi qaysi natijani xohlayotganini aniqlang — uch usul bor va
ular bir-biriga o'xshamaydi:

| Usul | Ko'rinishi | Qachon | Nima kerak |
|---|---|---|---|
| **A. Jonli illyustratsiya** | Bir uslubdagi AI rasmlar, har biri sekin harakatda (mato hilpiraydi, odam yuradi, tutun ko'tariladi), ustida subtitr | Ovoz bor, yuz yo'q: ma'ruza, hikoya, audio kitob, podkast | rasm + image-to-video generator |
| **B. Stiker-kollaj** | AI fon ustida oq konturli "stiker" personajlar, yozuvli plashkalar, hisob tablosi | Tushuntirish, taqqoslash, "kim haq?" formatlari, raqam va faktlar | rasm generator + `sticker.py` |
| **C. Dunyoni almashtirish** | Gapiruvchining o'zi boshqa dunyoda (zombi apokalipsisi, yovvoyi g'arb, mafiya kabineti), ko'pincha ekran ikkiga bo'lingan: tepada AI, pastda asl kadr | Kamera oldida gapirilgan video; "nimani xohlasang o'sha bo'lasan" turidagi ilgak | video-to-video generator (faqat qo'lda) |

Foydalanuvchi aytmagan bo'lsa: ovoz + yuz yo'q → A; gapiruvchi video + tushuntirish → A yoki B
kadrlarini `full` qo'yish; "o'zimni ... qilib ko'rsat" → C.

## 0. Avval generator bor-yo'qligini tekshiring

```bash
SK=~/.claude/skills/ai-broll; PY=~/.venvs/montaj/bin/python
$PY $SK/scripts/gen.py check
```

- **OK** chiqsa — API rejimi: rasmlar avtomatik yasaladi.
- **KVOTA YO'Q (429)** chiqsa (2026-10-05 holati shunday: `~/jarvis/.env` dagi Gemini kalitida
  rasm/video limiti 0) — foydalanuvchiga uch yo'lni ayting va tanlatib oling:
  1. Google AI Studio'da billing yoqish (keyin hammasi avtomatik);
  2. **qo'lda rejim** — skill promptlarni tayyorlaydi, foydalanuvchi ularni o'zi ishlatadigan
     servisga (Gemini ilovasi, Midjourney, Kling, Higgsfield, Runway) qo'yib, natijani `shots/`
     ga tashlaydi;
  3. video generator umuman bo'lmasa — rasmlar `animate.py` bilan (kamera harakati + zarrachalar)
     jonlantiriladi. Bu reference darajasidan pastroq: kadr ichida hech narsa qimirlamaydi.

Video generatsiya (Veo) pullik va bir klip sezilarli turadi. `gen.py video` ni **faqat
foydalanuvchi rozi bo'lgandan keyin** ishga tushiring, oldin nechta klip yasalishini ayting.
`gen.py` dagi Veo qismi hali real kvotada sinalmagan — birinchi ishlatishda bitta kadrdan boshlang.

## 1. Loyiha va vaqt belgilari

```bash
PRJ=~/Montaj/loyihalar/<nom>; mkdir -p $PRJ/shots
cp <asosiy video yoki ovoz> $PRJ/
```

B-roll gapga bog'lanadi, shuning uchun so'zma-so'z vaqt kerak. O'zbekcha transkripsiya:
`~/.claude/skills/bashar-uslub/scripts/transcribe.sh <fayl> $PRJ` (natija `words.json`,
`xom_matn.txt`). Whisper xato yozadi — vaqtlarni oling, matnni ma'nosidan tushuning.

## 2. Reja — `plan.json`

Namuna: `references/plan-namuna.json`. Har kadr (shot) uchun:

```json
{"id": "k03", "start": 7.9, "end": 12.4, "line": "erkakning ko'zi boshqalarida bo'ladi",
 "method": "animate", "move": "in", "dust": true,
 "image_prompt": "...", "motion_prompt": "..."}
```

Yuqori darajada: `main` (asosiy fayl), `layout` (`full` yoki `split`), `style` (hamma kadrga
qo'shiladigan uslub bloki), `refs` (izchillik uchun namuna rasmlar), `aspect`.

Kadr tanlash qoidalari (reference'larda o'lchangan):

- **Kadr uzunligi 3–6 soniya.** Bitta gap bo'lagi = bitta kadr. 2 soniyadan qisqa AI kadr
  o'qilmaydi, 7 soniyadan uzuni zeriktiradi.
- **Hammasini yopmang.** Gapiruvchi videoda b-roll vaqtning 40–60% ini egallasin; ilgak (birinchi
  1–2 soniya) va xulosa gapda yuz ko'rinib tursin. Faqat ovoz bo'lsa (A usul) — 100%.
- **Mavhum gapni aniq narsaga aylantiring.** "E'tibor bermaydi" → ko'chada ketayotgan yolg'iz
  odam orqasi; "sovuqchilik boshlanadi" → muzlagan deraza ostida bir-biridan uzoq o'tirgan ikki
  kishi. Gapdagi so'zni chizmang, his-tuyg'uni chizing.
- **Bir kadr — bitta harakat.** Qo'l sandiqdan mato ko'taradi; eshik ochiladi; choy quyiladi.
  Ko'p narsa bo'layotgan kadrni generator buzadi, tomoshabin esa ulgurmaydi.
- **Kadr turini almashtiring:** umumiy plan → detal (qo'l, buyum) → siluet → umumiy. Ketma-ket
  ikki bir xil plan qo'ymang.
- **Yuzlardan qoching** (A usulda): orqadan, siluet, qo'l, buyum. AI yuzlari kadrdan kadrga
  o'zgaradi va diniy mavzuda nojo'ya ko'rinadi. Reference shunday qiladi.
- Oxirgi kadr — chaqiriqqa xizmat qiladi: mahsulot, kitob, telefon ekrani.

## 3. Promptlar

Prompt formulalari va uchala usul uchun tayyor uslub bloklari: `references/promptlar.md` —
**prompt yozishdan oldin o'qing.** Asosiy qoidalar:

- Promptlar **inglizcha** yoziladi (generatorlar shunda aniqroq ishlaydi).
- **Uslub bloki bitta va o'zgarmas** (`plan.json` → `style`): palitra, yorug'lik, texnika.
  Kadr promptida faqat mazmun bo'ladi. Videoning "bir qo'ldan chiqqan" ko'rinishi shundan.
- Rasm prompti tartibi: plan turi → kim/nima → nima qilyapti → qayerda → yorug'lik manbai.
- Harakat prompti: **bitta sekin harakat + kamera**, 1–2 gap. "Slow push-in. The fabric
  ripples gently in the wind, dust particles float in the light." Qolgani qimirlamasin deb
  yozing — aks holda generator hamma narsani qimirlatadi.
- Rasmda matn so'ramang (o'zbekcha harflarni buzadi). Yozuvlar montajda qo'shiladi.
- Subtitr joyi: A usulda rasmning pastki ~35% i qorong'i va bo'sh bo'lsin ("lower third fades
  into deep shadow, empty").
- Personaj takrorlansa (B usul): avval bitta "personaj varag'i" yasab, uni `refs` ga qo'ying.

## 4. Generatsiya

```bash
$PY $SK/scripts/gen.py image $PRJ      # API: shots/k01.png ...
$PY $SK/scripts/gen.py prompts $PRJ    # qo'lda: promptlar.md -> foydalanuvchiga
$PY $SK/scripts/gen.py video $PRJ      # API, PULLIK: shots/k01.mp4 (rozilikdan keyin)
```

Har chiqqan rasmni **o'zingiz ko'ring** (Read) va saralang. Yaroqsiz kadr belgilari: ortiqcha
barmoq/qo'l, buzilgan yuz, tasodifiy yozuv, uslubdan chiqib ketgan rang, subtitr zonasidagi
obyekt. Yaroqsizini o'chirib, promptni aniqlashtirib qayta yasang — bitta yomon kadr butun
videoni "AI axlati"ga aylantiradi. Qo'lda rejimda foydalanuvchi fayllarni `shots/` ga tashlagach
ham xuddi shunday tekshiring.

**B usul (stiker):** personajni tekis oq fonda generatsiya qiling, keyin

```bash
$PY $SK/scripts/sticker.py shots/ota.png shots/ota_st.png --stroke 12
```

Fon kadrlari odatdagidek yasaladi. Stikerlar, plashkalar va tablo fon ustiga montajda
teriladi — hozircha tayyor skript yo'q: Remotion (`bashar-uslub/template` asosida) yoki
ffmpeg overlay bilan loyihaga qarab yig'ing. Stiker "pop" bo'lib (0.15s da 0 → 110% → 100%)
chiqsin, har 1–3 soniyada ekranda nimadir o'zgarsin.

**C usul (dunyoni almashtirish):** API'da yo'q, faqat qo'lda. `plan.json` da
`"method": "restyle"` va `restyle_prompt` bering; asl kadr bo'lagini kesib bering:

```bash
~/.venvs/montaj/bin/ffmpeg -ss <start> -to <end> -i $PRJ/<asosiy> -c:v libx264 -crf 16 -an $PRJ/shots/k01_src.mp4
```

Foydalanuvchi uni video-to-video servisiga (Runway Aleph, Luma Modify, Kling, Higgsfield)
yuklaydi. Natija `shots/k01.mp4` — davomiyligi asl bo'lak bilan bir xil bo'lishi shart, chunki
lab harakati ovozga mos turishi kerak. `layout: "split"` bilan qo'ying.

## 5. Videoga qo'yish

```bash
$PY $SK/scripts/insert.py $PRJ --draft   # tez qoralama
$PY $SK/scripts/insert.py $PRJ           # yakuniy -> out/final.mp4
```

`shots/<id>.mp4` bo'lsa o'sha, bo'lmasa `shots/<id>.png` avtomatik jonlantiriladi (`move`:
in/out/left/right/up/down, `dust`). Ovoz doim asosiy fayldan. `main` faqat ovoz bo'lsa, b-roll
qora fon ustiga teriladi — kadrlar orasida bo'shliq qoldirmang.

Qoralamadan soniyada bir kadr olib (`fps=1,tile`) ko'ring: kadr gapga mos vaqtda chiqyaptimi,
ketma-ket kadrlar uslubi birmi, `split` da yuz kesilmaganmi (`split_y` bilan suring). Subtitr
bu skriptda yo'q — kerak bo'lsa `~/.venvs/montaj/pipeline` yoki `bashar-uslub` subtitr qismi.

## Foydalanuvchiga topshirish

Fayl yo'li, davomiyligi, nechta kadr AI/nechta zaxira animatsiya ekanini ayting. Qaysi kadrlar
sizga ham shubhali ko'ringan bo'lsa — yashirmay ko'rsating. Birovning yuzi yoki ovozi AI bilan
o'zgartirilgan bo'lsa, o'sha odamning roziligi kerakligini eslating.
