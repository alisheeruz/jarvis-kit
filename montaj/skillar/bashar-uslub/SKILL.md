---
name: bashar-uslub
description: Ovozli lavha (ma'ruza, hikoya, podkast parchasi, o'z ovozi) ustiga @bashar.uz uslubidagi animatsion Reels yasash — to'q zumrad fon, yupqa chiziqli yoki siluetli illyustratsiya, yuzsiz qahramonlar, so'zma-so'z ochiladigan subtitr, kesimsiz silliq sahnalar. Foydalanuvchi "bashar uslubida video", "ma'ruzaga animatsiya", "ovozga illyustratsiyali reels", "yuzsiz (faceless) reels", "audio ustiga chizma video" yoki shunga o'xshash narsa so'raganda ishlat — kanal nomini aytmasa ham. Kamera oldida gapirilgan videoni montaj qilish uchun EMAS (u boshqa pipeline).
---

# Bashar uslubidagi animatsion Reels

Bu skill bitta ovozli lavhadan (30–90 soniya) tayyor 1080×1920 reels yasaydi. Usul @bashar.uz
akkauntining 12 ta reelsini kadrma-kadr tahlil qilib olingan (raqamlar va kuzatuvlar:
`references/tahlil.md`). Video kod bilan chiziladi (Remotion + SVG), shuning uchun rasm generatori
ham, montaj dasturi ham kerak emas.

Uslubning mohiyati uch narsada: **ovoz hamma narsani olib boradi**, **rasm har bir gapni
so'zma-so'z emas, ma'nosini ko'rsatadi**, **ekran hech qachon qotib qolmaydi va hech qachon
keskin kesilmaydi**. Qolgan hamma qoida shu uchtadan kelib chiqadi.

## Nima kerak

- Ovoz fayli (mp3/m4a/wav yoki video). Foydalanuvchi bermagan bo'lsa — so'rang; matndan o'zingiz
  ovoz yasamang.
- `~/.venvs/montaj` (ffmpeg + o'zbekcha whisper) va Node.js. Ikkalasi shu Mac'da bor.

Ovoz birovning ma'ruzasi bo'lsa, foydalanuvchiga bir marta eslating: muallif ruxsati yoki hech
bo'lmasa manba ko'rsatilishi kerak. Logotip va akkaunt nomi foydalanuvchining o'ziniki bo'ladi —
bashar.uz belgisini ko'chirmang.

## Ish tartibi

### 1. Loyiha ochish va transkripsiya

```bash
SK=~/.claude/skills/bashar-uslub            # skill papkasi (boshqa joyda bo'lsa o'sha yo'l)
PRJ=~/Montaj/loyihalar/<mavzu-nomi>
mkdir -p "$PRJ" && cp -R "$SK/template/." "$PRJ/" && (cd "$PRJ" && npm install)
"$SK/scripts/transcribe.sh" <ovoz-fayl> "$PRJ"     # 1 daqiqa ovoz ≈ 1–2 daqiqa
```

Natija: `public/audio.m4a`, `words.json` (so'z vaqtlari), `xom_matn.txt`.

### 2. Matnni tuzatish va subtitr bloklariga bo'lish — `matn.txt`

Whisper o'zbekchani ko'p xato yozadi ("kofir" → "kobir", "to'rini" → "to'g'rini"), shuning uchun
`xom_matn.txt` ni ma'nosiga qarab tuzatib, `matn.txt` ga yozing. Oyat, hadis, duo va ismlarda
taxmin qilmang: ishonchingiz komil bo'lmasa foydalanuvchidan so'rang — diniy matndagi bitta xato
butun videoni yaroqsiz qiladi.

Bloklash qoidalari (referensda o'lchangan):

- Bir blok = ekranda bir vaqtda turadigan matn: **1–2 qator, qatorda 2–4 so'z**, jami 3–8 so'z.
- Blok nafas/ma'no chegarasida tugaydi (vergul, nuqta, pauza). Gapni o'rtasidan uzmang.
- Har blokda **1–2 kalit so'z** `*yulduzcha*` bilan belgilanadi — ma'noni ko'taradigan so'z
  (kim, nima, qancha, qarama-qarshilik: *musulmon* / *kofir*, *6 soat* / *8 soat*).
  Hammasini belgilasangiz, urg'u yo'qoladi.
- Ko'chirma gaplar «...» ichida. Raqamlar raqam bilan ("8 soat").
- Og'zaki "e-e", takror va chala so'zlarni yozmang; lekin gap tartibini o'zgartirmang, aks holda
  vaqtga moslash buziladi.

```bash
python3 "$SK/scripts/align.py" "$PRJ"     # -> src/captions.json + bloklar vaqti bilan ro'yxat
```

Skript "mos kelgan so'zlar: N/M" deb chiqaradi. 60% dan past bo'lsa matn ovozdan uzoqlashgan —
qayta ko'ring. Chiqqan ro'yxatdagi vaqtlar keyingi qadam uchun kerak.

### 3. Sahnalar rejasi (storyboard)

Kod yozishdan oldin jadval tuzing: har sahna qaysi bloklarni qamraydi, nima chiziladi, nima
harakatlanadi, urg'u (yorug'lik) qayerda.

- **Sahna uzunligi 3–7 soniya**, ya'ni 1–3 blok. 45 soniyali videoda 8–12 sahna.
- **Birinchi sahna 0-kadrdan to'liq ko'rinishi kerak** (birinchi 1 soniyada bo'sh fon bo'lmasin):
  birinchi sahnadagi asosiy obyektlarga `at={0}` bering, `dur` ni qisqartiring.
- Har sahna **bitta fikr, bitta asosiy obyekt**. Mayda detal ko'p bo'lsa telefon ekranida
  o'qilmaydi.
- Rasm gapning **ma'nosini** beradi, ro'yxatini emas. "Rizqida baraka bo'ladi" → to'lib,
  porlayotgan savat; "6 soat o'rniga 8 soat ishlayapsiz" → strelkasi aylanayotgan soat va ishlab
  turgan odam.
- Qarama-qarshilikni **simmetriya** bilan ko'rsating: ikki qayiq, ikki odam, to'la va bo'sh savat —
  biri yorqin chiziqda (`C.ink`), ikkinchisi xira (`C.line`).
- **Yorug'lik = ma'no cho'qqisi.** Kadr deyarli bir rangda; sarg'ish nur (`Glow`, `glow`, `fill`,
  `lit`) faqat eng muhim narsada va kerakli so'z aytilgan paytda yonadi. Har sahnada nur bo'lsa,
  hech qaysisi ta'sir qilmaydi.
- Odamlar **yuzsiz**: chiziqli figura yoki qora siluet, do'ppi va uzun to'n. Payg'ambarlar,
  sahobalar, farishtalar va g'ayb narsalar odam shaklida **chizilmaydi** — o'rniga nur, eshik,
  yo'l, bo'sh joy ishlatiladi (referensda ham shunday: farishta o'rniga yorug'lik chizig'i).
- Oxirgi sahna xulosa gapda sekin yaqinlashadi va tinchiydi. Ekranda "obuna bo'ling" yozuvi
  yo'q — kanal buni ishlatmaydi, video xulosa gapning o'zida tugaydi.

### 4. Sahnalarni yozish — `src/scenes.jsx`

Namuna fayl ichida 3 ta tayyor sahna bor — tuzilishni o'shandan oling. Har sahna React
komponenti; `src/draw.jsx` dagi bo'laklardan yig'iladi:

| Bo'lak | Nima uchun |
|---|---|
| `Person` (`pose`: stand / kneel / sit, `flip`, `solid`) | odam; `solid` = qora siluet |
| `Water`, `Hills`, `Horizon`, `Hatch`, `Road` | suv, tog', ufq, yer shtrixi, yo'l |
| `Tree`, `Cypress`, `Sun`, `Dust` | tabiat; `Dust` har sahnada bo'lsin |
| `Boat`, `Basket`, `Book`, `Clock`, `Lamp`, `Stone` | buyumlar |
| `Arch`, `House`, `Mosque` | bino; `open`, `glow`, `lit` bilan jonlanadi |
| `Glow`, `Measure` | nur dog'i; "chizma" uslubidagi o'lchov chizig'i |
| `Ink`, `G`, `v` | o'z shaklingiz uchun: chizilib chiqadigan yo'l, guruh, vaqt bo'yicha qiymat |

Kutubxonada yo'q narsa kerak bo'lsa (tuya, quduq, tarozi, qush...), `Ink` bilan SVG yo'l
chizib, shu loyihaning `scenes.jsx` ichida yangi bo'lak yozing: 3–8 ta oddiy yo'l yetadi, uslub
ataylab sodda. Ko'p loyihada takrorlansa — skilldagi `template/src/draw.jsx` ga qo'shing.

Qoidalar:

- Kanvas 1080×1920. **Rasm zonasi y = 280…1250**, undan pasti subtitrniki (y≈1445), tepada
  logotip (y 161–243). Obyektlarni x = 60…1020 ichida tuting.
- `at` — sahna boshidan necha kadr keyin chizila boshlashi (30 kadr = 1 soniya). Obyektlarni
  gapda tilga olinish tartibida, 4–10 kadr farq bilan chiqaring.
- **Har sahnada kamida bitta narsa doimiy harakatda**: kamera (`cam`), `Dust`, suv, quyosh,
  soat strelkasi yoki `v()` bilan surilayotgan obyekt. Qotib turgan kadr = tomoshabin ketadi.
- Harakat **sekin**. Kamera masshtabi sahna davomida 5–10% dan ko'p o'zgarmasin.
- Sahnalar `from`/`to` (soniya) `align.py` chiqargan blok vaqtlariga teng bo'ladi; orasi ochiq
  qolmasin. O'tish avtomatik: 14 kadrlik blur-erish. Keskin kesim yo'q.
- Gradient `id` lari butun videoda takrorlanmasin (`id="s1"`, `id="g2"` ...), aks holda nurlar
  aralashadi.

`src/project.js` da: `audio: 'audio.m4a'`, `watermark` (akkaunt nomi), `logo` (bor bo'lsa
`public/` ga qo'yilgan oq PNG), `style`.

**Ikki uslub.** `style: 'line'` — yupqa chiziqli "chizma" (ramka burchaklari bilan); referensdagi
eng ko'p ko'rilgan video (926K) shu uslubda va u kod bilan eng toza chiqadi — sukut bo'yicha shuni
ishlating. `style: 'flat'` — ramkasiz, obyektlar `solid` siluet va rangli to'ldirish bilan;
iliqroq ko'rinadi, lekin har sahnaga ko'proq qo'l mehnati (fon shakllari, rang) kerak.

### 5. Tekshirish va render

```bash
cd "$PRJ"
npx remotion still src/index.jsx Reel out/k.png --frame=<kadr>   # har sahnadan bitta kadr
npm run render                                                   # -> out/reel.mp4
```

Renderdan **oldin** har sahnaning o'rtasidan bitta kadr chiqarib, o'zingiz ko'ring (Read bilan).
Tekshiriladigan narsalar:

- obyektlar subtitr zonasiga (y > 1250) yoki logotip ustiga chiqmaganmi;
- shakllar o'qiladimi — bir qarashda nima ekanligi tushunarli bo'lishi kerak;
- nur faqat kerakli joydami;
- subtitr 2 qatordan oshmaganmi, kalit so'z rangi to'g'ri so'zdami.

Render tugagach videodan 2 soniyada bir kadr olib (ffmpeg `fps=1/2,tile`) umumiy jadvalni
ko'ring va ovoz bilan subtitr mosligini kamida 3 joyda tekshiring. Shundan keyingina
foydalanuvchiga bering: fayl yo'li, davomiyligi, va nimani o'zi tekshirishi kerakligi (diniy
matn imlosi, ismlar).

## Kontent bo'yicha (video nega ishlaydi)

Foydalanuvchi lavha tanlashda yordam so'rasa yoki bir nechta variantdan birini tanlash kerak
bo'lsa — `references/tahlil.md` ni o'qing. Qisqasi:

- **30–55 soniya**, bitta tugallangan fikr. Hikoya (qissa) bo'lsa 75–90 soniyagacha chiqsa bo'ladi.
- **Birinchi gap — ilgak**, kirish so'zisiz: hikoya boshi ("Bir musulmon bilan kofir baliq
  ovlagani chiqibdi"), to'g'ridan-to'g'ri murojaat ("Sen qabrning ertangi egasisan") yoki
  hammaga tegishli dard ("Hozir 99 foiz odamning g'ami — pul topish"). "Assalomu alaykum, bugun..."
  kesib tashlanadi.
- Lavha **xulosa gapda** tugaydi, undan keyingi izoh kesiladi.
- Post matni (caption) va chaqiriq yo'q; kanal kuniga 8–10 ta reels chiqaradi — hajm ham
  strategiyaning bir qismi.

## Tez sinov

Ovozsiz, namuna matn bilan shablon ishlashini tekshirish:

```bash
cp -R ~/.claude/skills/bashar-uslub/template /tmp/sinov && cd /tmp/sinov && npm install
python3 ~/.claude/skills/bashar-uslub/scripts/align.py . --fake && npm run render
```
