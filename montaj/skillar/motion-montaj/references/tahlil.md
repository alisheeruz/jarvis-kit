# Reference videolar tahlili (2026-10-05)

9 ta video soniyada 1 kadr bilan ko'rib chiqildi. Ular 4 turga bo'linadi. Har birining
retsepti — qaysi komponentlar bilan qayta yasalishi — shu yerda.

| # | Fayl | Uzunlik | Tur | Mavzu (Theme) |
|---|---|---|---|---|
| 1 | `AQMGn…` | 55s | Gapiruvchi + grafik kesmalar | lime |
| 2 | `AQMSm…` | 22s | Sof UI-animatsiya | dark |
| 3 | `AQNao…` | 28s | Gapiruvchi: "xom / montaj qilingan" taqqoslash | har xil |
| 4 | `AQNARA…` | 59s | Yuzsiz eksplayner (qog'oz kollaj) | paper |
| 5 | `AQNHC…` | 26s | bashar.uz — alohida skill (`bashar-uslub`) | — |
| 6 | `AQNmG…` | 52s | Yuzsiz eksplayner (monoxrom kollaj + tipografika) | violet |
| 7 | `AQNUdg…` | 29s | Gapiruvchi: jurnal uslubi, egri matnlar | red |
| 8 | `AQNwv…` | 12s | Sof UI-animatsiya (kvadrat) | dark → och |
| 9 | `AQOBh…` | 59s | Gapiruvchi + ko'k "shisha" grafika (kvadrat) | blue |

## A. Gapiruvchi + motion-dizayn (1, 3, 7, 9)

Asos — kamera oldidagi bitta dubl. Ustiga:

- **Plashka-subtitr** (1, 9): bir vaqtda 1–2 so'z, ko'krak balandligida, kichik yumaloq (laym)
  yoki to'rtburchak "shisha" (ko'k) plashkada. To'liq jumla hech qachon ekranda turmaydi.
  → `PillCaptions`.
- **Zoom-kesimlar** (1): umumiy → yirik plan → umumiy, har 2–4 soniyada, urg'uli so'zda.
  → `Footage punches`.
- **Yirik sarlavha** (1: "GRAFIK DIZAYN"; 3: "Scripts", "LEG", "GYMS"; 7): tor bosh harfli
  shrift, bitta urg'u rangi, ko'pincha yorug'lik (glow) bilan. Yonida mayda izoh va kursiv
  so'z. 3-videoda sarlavha **odam orqasida** turadi. → `BigWord` (+ `Person`).
- **Kesma sahnalar** (1, 9): 2–5 soniyaga yuz o'rniga och gradient fonli grafik ekran:
  terilayotgan matn, qidiruv/chat qatori, suzuvchi kartochkalar (ichida skrinshot yoki
  b-roll video), sichqoncha bosishi, telefon. 1-videoda vaqtning ~35% i shu.
  → `Cutaway` + `TypeLine`, `SearchBar`, `Card`, `Media`, `Cursor`.
- **Raqam ekrani** (9: "5.7% yaxshiroq"): to'liq ekran rangli fon, katta raqam, ostida izoh,
  yonida portret. → `Cutaway` + `Stat`.
- **Kadrni rang bilan bo'yash** (1: yashil tus + kartochka; 9: ko'k tus): chaqiriq paytida
  video xiralashadi, ustiga ism kartochkasi. → `Footage dim` + `NameCard`.
- **7-video** (jurnal uslubi): matn egri chiziq bo'ylab, yuz bo'laklari kattalashtirilgan
  kvadratlarda, qizil tusli kadrlar, pul/qog'oz kollaji. Eng murakkabi — to'plamda qisman
  (`BigWord rotate`, `Card` + `Media`); egri matn va yuz-kollaj loyihada qo'lda yoziladi.

**3-videoning darsi** ("Raw" va "Edited" yonma-yon): farq rangda emas. Montaj qilingan
variantda (1) odam kichraytirilib, tepada sarlavhaga joy ochilgan; (2) fon tusi urg'u rangiga
bo'yalgan; (3) sarlavhada 2–3 xil o'lcham va shrift; (4) atrofda mayda dekor (piksel
kvadratlar, pufakchalar). Ya'ni "oddiy subtitr" o'rniga **kompozitsiya** qilinadi.

## B. Yuzsiz eksplayner — qog'oz kollaj (4)

"3 yil oldin… endi esa…" — moliyaviy tushuntirish, 59 soniya, yuz yo'q.

- 6 xil fon navbatlashadi: sariq nurli, och qog'oz, to'q ko'k, qora. Fon almashishi = yangi bo'lim.
- Bitta takrorlanuvchi **stiker personaj** (oq konturli) — pozasi bo'limdan bo'limga o'zgaradi.
- **Yirtilgan yorliqlar**: "1-TUZOQ", "2-TUZOQ", "YECHIM" — bo'lim sarlavhasi, tepada.
- **Qog'oz varaqdagi grafiklar**: zinapoya chiziq (daromad/xarajat), tushuvchi egri chiziq,
  ustunlar (3,5% → 13,6%). Chiziqlar ko'z oldida chizilib chiqadi.
- **Sanab chiqadigan raqamlar**: "2 238 596 → 10 000 000", "$15 208 → $100 000+".
- **Muhr** ("NEGA?"), qo'lda chizilgan aylana va strelkalar, manba ko'rsatilgan mayda yozuv.
- Har 1–2 soniyada yangi element. Oxirida savol va "Izohda yozing ↓".

→ `PaperBg`, `Tape`, `Sticker`, `Chart`, `Bars`, `Stat`, `Stamp`. Personaj: `ai-broll` + `sticker.py`.

## C. Yuzsiz eksplayner — monoxrom kollaj (6)

Eynshteyn haqidagi esse, 52 soniya. Butun video **bitta binafsha gradient fon** ustida.

- Oq-qora kesilgan fotosuratlar (odam, soat, mashina, lampochka) — bitta-ikkita obyekt markazda,
  sekin aylanadi/kattalashadi.
- **Kinetik tipografika**: har ibora alohida chiqadi; kalit so'z katta tor bosh harfda
  ("FLOW STATE", "SHORTCUT"), bog'lovchilar yonida mayda kursivda. Matn obyekt atrofida
  joylashadi, markazga emas.
- Bir rang + bir shrift juftligi = juda toza ko'rinish. Subtitr yo'q — tipografikaning o'zi subtitr.

→ `Theme violet` + `Cutaway streaks={false}` + `Kinetic` + `Sticker`.

## D. Sof UI-animatsiya (2, 8)

Mahsulot/xizmat reklamasi, 12–22 soniya, odam yo'q.

- Qorong'i gradient fon, markazda bitta element: terilayotgan ibora → qidiruv qatoriga
  aylanadi → sichqoncha bosadi → natija kartochkalari → logotip.
- Har o'tish blur + masshtab bilan; element hech qachon "paydo bo'lib qolmaydi", doim
  oldingisidan o'sib chiqadi.
- 8-videoda qorong'idan och fonga o'tish = "muammo → yechim".

→ `Theme dark` + `Cutaway` + `TypeLine`, `SearchBar`, `Cursor`, `Card`.

## Hammasiga xos qoidalar

1. **Bitta urg'u rangi.** Laym, ko'k, qizil, binafsha — har videoda faqat bittasi.
2. **Har 2–4 soniyada o'zgarish**, lekin element chiqishi doim silliq (pop, blur, chizilish).
3. **Ekranda bir vaqtda kam matn**: 1–5 so'z. Uzun jumla bo'laklab beriladi.
4. **Ierarxiya o'lchamda**: kalit so'z juda katta, qolgani juda kichik. O'rtacha o'lcham deyarli yo'q.
5. **Markaz band emas** — yuz yoki asosiy obyekt uchun; matn tepada yoki ko'krakda.
6. **Dekor mayda va kam**: piksel kvadratlar, nuqtalar, ingichka chiziqlar — fonni "tirik"
   qiladi, e'tiborni olmaydi.
