---
name: motion-montaj
description: Reels'ni motion-dizayn darajasida montaj qilish — gapiruvchi video ustiga plashka-subtitr, yirik tipografika, "matn odam orqasida" effekti, zoom-kesimlar, grafik kesma sahnalar (UI kartochka, qidiruv qatori, raqamlar), shuningdek yuzsiz eksplayner (qog'oz fon, yorliq, grafik, muhr, stiker). Foydalanuvchi "montaj qil", "reference'dagidek montaj", "motion grafika qo'sh", "subtitr va effektlar", "videoni zo'r qil", "eksplayner video yasa" desa yoki xom video berib reels so'rasa ishlat. Oddiy kesim + subtitr yetarli emas — bu foydalanuvchi reference darajasini kutadi. AI kadrlar kerak bo'lsa `ai-broll`, chiziqli animatsiya kerak bo'lsa `bashar-uslub` bilan birga ishlatiladi.
---

# Motion-montaj

Xom videoni (yoki faqat ovozni) reference videolar (tahlili `references/tahlil.md` da) darajasidagi reelsga
aylantiradi. Montaj kod bilan yig'iladi: Remotion + tayyor komponentlar (`template/src/kit.jsx`).
Reference tahlili va har uslubning retsepti: `references/tahlil.md` — **yangi videoni
boshlashdan oldin o'qing**, chunki uslub tanlash shu yerdan.

Foydalanuvchining bu boradagi talabi qat'iy: birinchi urinishdayoq motion-dizayn bo'lishi kerak.
"Kesdim, rang berdim, subtitr qo'ydim" — rad etilgan variant. Har 2–4 soniyada ekranda nimadir
o'zgarishi shart.

## Qat'iy saboqlar (pastdagi har qanday qoidadan ustun)

Bular real mijoz tanqididan chiqqan — buzilsa video rad etiladi:

1. **Keskin punch zoom-in YO'Q** (1.0 → 1.3–1.5 zoom-kesim "xunuk" deb rad etilgan).
   Ko'pi bilan butun videoda bitta sekin 1.0 → 1.07. Kliplar ulanishi qisqa oq flash +
   whoosh SFX bilan yashiriladi.
2. **Matn hech qachon yuzga tushmaydi.** Renderdan oldin
   `~/.venvs/montaj/bin/python $SK/scripts/yuz.py public/main.mp4` — yuz qayerdaligini
   chiqaradi; plashka/sarlavha yuzdan pastga (selfi kadrda y≈1500, iyakdan past) yoki
   yuqoriga qo'yiladi.
3. **Kadr doim ko'rinib tursin.** Gapiruvchi reelsda to'liq ekranli grafik va terilib
   chiqadigan uzun matn ("mashin yozuv") emas — grafik faqat ustki qatlam yoki **50/50 split**
   (tepada material, pastda yuz, subtitr chegarada y=960).
4. **Fon musiqasi har doim** — `~/Montaj/musiqa` dan (ovozdan −18…−22 dB past). Kesim,
   flash, sarlavha chiqishida SFX — `~/Montaj/sfx` dan (whoosh, swoosh, hit, riser).
   Papka bo'sh bo'lsa egaga ayt, musiqasiz topshirma.
5. **Freeze-kadr qo'yma** — telefon burilishi tabiiy qoladi ("video qotyapti" deb rad etilgan).
6. **Retushda tekis rang bilan bo'yama** — asl yorug'lik-soyani saqlab rangni o'zgartir.
7. Topshirishdan oldin to'liq o'lchamdagi 3–4 kadrni o'zing tanqidiy ko'r.

Mijozning (yoki uning mijozining) o'z "doim / hech qachon" qoidalari `~/brain/1-tizim/uslub.md`
va `~/brain/2-biznes/mijozlar/<nom>.md` da — ular shu ro'yxatdan ham ustun.

## Ish tartibi

### 1. Loyiha

```bash
SK=~/.claude/skills/motion-montaj; PRJ=~/Montaj/loyihalar/<nom>
mkdir -p "$PRJ" && cp -R "$SK/template/." "$PRJ/" && (cd "$PRJ" && npm install)
"$SK/scripts/prep.sh" <xom video> "$PRJ" [boshlanish_s] [tugash_s]   # -> public/main.mp4 (1080x1920, 30fps)
```

- Bir nechta dubl bo'lsa: keng/yuqoridan olingan dubl — asosiy; yon dubl faqat 3–4 joyda
  xilma-xillik uchun. Kesim ro'yxati va S-Log3 rang berish: `~/.venvs/montaj/pipeline`
  (`cuts.py`, `lut.py`). `prep.sh` ga rang berilgan, kesilgan master beriladi.
- Transkripsiya va so'z vaqtlari: `~/.claude/skills/bashar-uslub/scripts/transcribe.sh public/main.mp4 "$PRJ"`,
  keyin matnni `matn.txt` ga tuzatib `align.py "$PRJ"` → `src/captions.json`. Plashka-subtitr
  uchun blok qatorlari **1–3 so'z** bo'lsin.

### 2. Montaj rejasi

Kod yozishdan oldin vaqt jadvalini tuzing (soniya | ekranda nima | qaysi komponent). Qoidalar
reference'lardan:

- **0–3 s — ilgak.** Eng kuchli vizual shu yerda: yirik so'z odam orqasida, raqam, yoki darhol
  grafik. Oddiy gapirayotgan kadr bilan boshlamang.
- **Ritm: har 2–4 soniyada o'zgarish** — zoom-kesim, yangi plashka uslubi, kartochka, kesma
  sahna. 5 soniyadan uzoq "faqat yuz + subtitr" bo'lmasin.
- **Kesma sahnalar vaqtning 25–40% i.** Gap mavhum tushuncha, ro'yxat, raqam yoki jarayon
  haqida bo'lganda yuz o'rniga 2–5 soniyalik grafik ekran. Qolgan vaqt — yuz.
- ~~Zoom-kesim urg'uli so'zda~~ — rad etilgan (qat'iy saboq 1). Ritm uchun o'rniga: 50/50
  split, kartochka, plashka uslubini almashtirish, flash + whoosh.
- **Bitta mavzu, bitta urg'u rangi** butun videoda. Shrift juftligi ham bitta: tor bosh harfli
  (sarlavha) + grotesk (matn), ba'zan kursiv serif (urg'u so'z).
- **Subtitr hech qachon grafik bilan bir vaqtda turmaydi**: yirik sarlavha yoki kesma sahna
  paytida `PillCaptions` `skip` oraliqlari bilan o'chiriladi.
- Oxirgi 3–4 soniya — chaqiriq: `NameCard` yoki yirik so'z + ko'rsatma.

### 3. Yig'ish — `src/edit.jsx`

Namuna `edit.jsx` to'rtta usulni ham ko'rsatadi (odam orqasidagi sarlavha, plashkalar, kesma
sahna, eksplayner) — tuzilishni o'shandan oling. Qatlam tartibi = yozilish tartibi; hamma vaqt
soniyada; har element `<At from={..} to={..}>` ichida.

| Komponent | Nima | Qaysi reference |
|---|---|---|
| `Theme name=` | lime / blue / red / paper / violet / dark | hammasi |
| `Footage` | asosiy video; `punches` zoom-kesimlar, `dim` qoraytirish | 1, 3, 7, 9 |
| `Person` | odam kesimi — undan oldingi qatlamlar odam orqasida qoladi | 3, 7 |
| `Pill`, `PillCaptions` | 1–3 so'zli plashka-subtitr, ko'krak balandligida | 1, 9 |
| `BigWord` | yirik tor sarlavha + mayda izoh + kursiv so'z | 1, 3, 7 |
| `Kinetic` | so'zlar birin-ketin chiqadigan tipografika | 6 |
| `Cutaway` | to'liq ekranli grafik sahna (ichiga boshqa komponentlar) | 1, 2, 8, 9 |
| `TypeLine`, `SearchBar`, `Cursor` | terilayotgan matn, qidiruv qatori, sichqoncha | 1, 2, 8 |
| `Card`, `Media` | suzuvchi kartochka; ichida rasm/video/b-roll | 1, 9 |
| `Stat` | sanab chiqadigan katta raqam | 4, 9 |
| `NameCard` | avatar + ism + tugma (chaqiriq) | 1 |
| `PaperBg`, `Tape`, `Stamp` | qog'oz fon, yirtilgan yorliq, muhr | 4 |
| `Chart`, `Bars` | chizilib chiqadigan grafik, ustunlar | 4 |
| `Sticker` | shaffof PNG personaj/buyum | 4, 6 |

Parametrlar har komponent ustidagi izohda. To'plamda yo'q narsa kerak bo'lsa (toggle, telefon
ramkasi, taymer...) — loyihaning `edit.jsx` ida `usePop`, `ease`, `useT`, `useTheme` yordamida
yozing; ko'p ishlatilsa skilldagi `kit.jsx` ga qo'shing.

**Matn odam orqasida** (eng "qimmat" ko'rinadigan effekt):

```bash
~/.venvs/montaj/bin/python "$SK/scripts/matte.py" "$PRJ/public/main.mp4" "$PRJ/public/person.webm" --start 0 --end 3
```

1 soniya video ≈ 12 soniya hisob, shuning uchun faqat kerakli bo'lakka (odatda ilgak, 2–4 s).
`edit.jsx` da tartib: `Footage` → `BigWord` → `Person`. Matte bo'lagi videoning boshidan
boshlanmasa, `Person` ni o'sha `At from` ichiga qo'ying (fayl 0-kadrdan o'ynaydi). Effekt
ishlashi uchun: odam kadr markazida, so'z bosh-yelka balandligida va odamdan kengroq bo'lsin —
aks holda so'z to'liq yopilib qoladi. Matte oralig'ida keskin zoom-kesim qo'ymang yoki
`Person` ga ham xuddi shu `punches` ni bering.

**Yuzsiz eksplayner** (4- va 6-reference): `Footage` o'rniga ovoz (`<Audio>`), butun video
`PaperBg`/`Cutaway` sahnalaridan iborat. Personaj va buyum rasmlari `ai-broll` skilli bilan
yasalib (`sticker.py`), `public/` ga qo'yiladi va `Sticker` bilan chiqariladi.

### 4. Tekshirish va render

```bash
cd "$PRJ"
npx remotion still src/index.jsx Reel out/k.png --frame=<kadr>   # har sahnadan bittadan
npm run render                                                   # -> out/reel.mp4
```

Renderdan oldin har sahnadan kadr chiqarib o'zingiz ko'ring. Tekshiriladigan narsalar:

- matn yuzni yopmayaptimi; plashka ko'krak balandligidami (wide kadrda `y` ni kadrga qarab
  qo'ying — odam kichik bo'lsa plashka ham yuqoriroq);
- pastki 300 px va yuqori 200 px da muhim narsa yo'qmi (Instagram interfeysi);
- uzun o'zbekcha so'z kadrdan chiqib ketmaganmi (`BigWord` da `size` ni kamaytiring);
- kesma sahna tugashi bilan keyingi sahna darhol boshlanadimi (orada 1–2 kadr "yalang'och"
  video ko'rinib qolmasin: `to` va keyingi `from` bir xil bo'lsin).

Render tugagach soniyada bir kadrlik jadval (`ffmpeg ... fps=1,tile`) bilan butun videoni
ko'ring, ovoz-subtitr mosligini 3 joyda tekshiring. Keyin foydalanuvchiga: fayl yo'li,
davomiyligi, qaysi effektlar ishlatilgani va nimaga ishonchingiz komil emasligi. Tayyor
videoni `~/Montaj/tayyor/` ga ko'chiring va Telegram reply tool bilan (`files`) egaga yuboring.
Telegram bot 50 MB dan katta fayl yubora olmaydi: kattaroq bo'lsa `-crf 21–23` bilan qayta
siqing (1080x1920, 60 s gacha odatda 30–45 MB) yoki yo'lini aytib AirDrop'ni taklif qiling.

## Tez sinov

```bash
cp -R ~/.claude/skills/motion-montaj/template /tmp/mm && cd /tmp/mm && npm install && npm run render
```

Videosiz, namuna fon bilan 14 soniyalik namuna chiqadi (`namuna.mp4` — xuddi shu, haqiqiy
video ustida).
