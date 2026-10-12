# Jarvis arxitekturasi (ko'chmas mulk biznesi)

Bu hujjat tizim qanday tuzilganini va qanday tartibda qurilishini belgilaydi. Mijoz Mac'ida terminaldagi Claude shu hujjat va `~/brain/CLAUDE.md` (konstitutsiya) bo'yicha ishlaydi.

## 1. Umumiy ko'rinish

```
 Ega / xodim (Telegram)
        │  xabar, ovoz, rasm
        ▼
 Telegram bot  ◄──────────────────────────────┐
        │ long-polling                        │ reply / reaction
        ▼                                     │
 bun server.ts  (telegram plugin, MCP ko'prik)│
        │                                     │
        ▼                                     │
 claude --channels   ← doimiy sessiya ────────┘
   ├─ JARVIS.md        mashina + kanal qoidalari (system prompt)
   ├─ ~/brain/CLAUDE.md konstitutsiya (avtomatik yuklanadi)
   ├─ ~/brain/**        xotira: obyektlar, lidlar, kontent, reklama
   └─ ~/jarvis/*.py     qo'llar: Meta, e'lon, sayt, ovoz skriptlari
        │
        ▼
 Tashqi dunyo: Meta Graph API · Telegram kanal · sayt hostingi · CRM

 Qo'riqchilar (launchd):
   com.<slug>.jarvis           loop — claude qulasa qayta ochadi
   com.<slug>.jarvis.watchdog  har 45s: heartbeat + ko'prik tirikmi
   com.<slug>.<vazifa>         jadval bo'yicha ishlar (4-bosqich)
```

## 2. To'rt qatlam

| Qatlam | Qayerda | Vazifasi | Kim o'zgartiradi |
|---|---|---|---|
| **Konstitutsiya** | `~/brain/CLAUDE.md` | Nima mumkin, nima mumkin emas, xotira tuzilishi | Faqat ega |
| **Mashina** | `~/jarvis/JARVIS.md`, `jarvis-loop.sh`, watchdog, plist | Telegram xulqi, 24/7 tiriklik | O'rnatuvchi (siz) |
| **Xotira** | `~/brain/1-tizim`, `2-biznes`, `3-shaxsiy` | Biznes haqidagi barcha fakt va tarix | Jarvis (har ishdan keyin) |
| **Qo'llar** | `~/jarvis/*.py` + `~/jarvis/.env` | Tashqi tizimlar bilan ishlaydigan skriptlar | Terminaldagi Claude quradi |

Tamoyil: **Claude o'ylaydi, skript bajaradi.** Jarvis API ni har safar qo'lda chaqirmaydi — tayyor, sinalgan skriptni ishga tushiradi. Shunda natija bir xil, xato kam, token tejaladi.

## 3. Qo'llar (skriptlar) — kelishuv

Har skript `~/jarvis/` da, faqat Python standart kutubxonasi, kalitlarni `~/jarvis/.env` dan o'qiydi.

| Skript | Buyruqlar | Kalitlar |
|---|---|---|
| `meta.py` | `profil` · `postlar [kun]` · `reklama [kun]` · `kampaniyalar` | `META_TOKEN`, `META_ACT`, `IG_USER_ID`, `FB_PAGE_ID` |
| `joyla.py` | `instagram <rasm-url> <matn-fayl>` · `facebook ...` · `kanal <chat> <matn-fayl> [rasmlar]` | + `instagram_content_publish`, `pages_manage_posts` |
| `target.py` | `yarat <reja.json>` (PAUSED) · `yoq <id>` · `toxtat <id>` · `byudjet <id> <summa>` | + `ads_management` |
| `elon.py` | `tayyorla <obyekt>` (matn) · `joyla <obyekt> <platforma>` | platformaga qarab |
| `sayt.py` | `yig` (obyekt fayllaridan sayt) · `preview` · `jonli` | hosting tokeni |
| `ovoz.py` | `<audio-fayl>` → matn | `GEMINI_API_KEY` (tayyor) |

Har skript uchun majburiy:
1. **Yozuvchi buyruq `--ha` bayrog'isiz hech narsa o'zgartirmaydi** — faqat nima qilishini ko'rsatadi (dry-run). Jarvis `--ha` ni faqat ega tasdiqlagandan keyin qo'shadi.
2. Chiqish — qisqa matn yoki JSON; xato bo'lsa `rc≠0` va tushunarli sabab ("token muddati tugagan").
3. Kalit qiymati hech qachon chiqishga yozilmaydi.
4. Pul sarflaydigan har amal `~/jarvis/amallar.log` ga yoziladi: sana, nima, summa, kim tasdiqlagan.
5. `target.py` da qattiq chegara: `.env` dagi `KUNLIK_BYUDJET_MAX` dan oshiq byudjet rad etiladi — Jarvis xato qilsa ham pul ketmaydi.

## 4. Ma'lumot oqimlari

**Obyekt → hamma joyga.** `2-biznes/obyektlar/<nom>.md` — yagona manba. E'lon, post, reklama, sayt shundan olinadi. Narx o'zgarsa bitta fayl o'zgaradi, keyin Jarvis qayerlarga joylanganini ko'rsatadi.

**Tasdiq zanjiri** (post, e'lon, reklama, sayt — bir xil):
```
so'rov → qoralama (lokal) → egaga ko'rsatish → "ha" → skript --ha → natijani tekshirish → faylga yozish → havola egaga
```

**Analitika:** `meta.py` → raqamlar → Jarvis xulosa qiladi → `hisobotlar/` → Telegram.

**Lid:** ega/xodim lid haqida yozadi (yoki CRM dan keladi) → `mijozlar/<oy>.md` → keyingi qadam `tasklar.md` ga.

## 5. Xavfsizlik chegaralari

- Kirish: faqat `~/jarvis/tg/access.json` dagi Telegram ID lar. Ega — to'liq, xodim — cheklangan (konstitutsiya 8-modda).
- Pul: uch qavat himoya — konstitutsiya taqiqi, `--ha` bayrog'i, `KUNLIK_BYUDJET_MAX`.
- Kalitlar: faqat `~/jarvis/.env` (chmod 600). `~/brain` ga kalit yozilmaydi.
- Meta tokeni: System User, faqat shu biznesning sahifa va kabinetiga ruxsat bilan.
- Zaxira: `~/brain` — har kuni nusxa (iCloud/Time Machine yoki git, 4-bosqich).

## 6. Qurish tartibi

Har bosqich tugagach sinab ko'riladi, keyin keyingisiga o'tiladi.

**0-bosqich — poydevor** (`zsh install.sh`)
Bot tirik, Telegramdan javob beradi, konstitutsiya va papkalar joyida.
Tekshiruv: botga "kimsan va nima qila olasan?" — konstitutsiyaga mos javob.

**1-bosqich — xotirani to'ldirish** (kalit kerak emas)
Terminalga: "`~/brain/CLAUDE.md` ni o'qi. Men biznes haqida aytaman, sen `1-tizim/biznes.md`, `uslub.md`, `kalitlar.md`, `texnik.md` va har obyekt uchun 5-moddadagi shaklda fayl yarat. Yetishmagan maydonni so'ra, o'ylab topma."
Tekshiruv: botdan biror obyekt narxini so'rash — fayldagi bilan bir xil.

**2-bosqich — ko'zlar: analitika** (Meta token, faqat o'qish)
Terminalga: "`~/jarvis-kit/ARXITEKTURA.md` 3-bo'limi bo'yicha `~/jarvis/meta.py` ni yoz. Kalitlar `.env` da. Har buyruqni haqiqiy API da sinab, natijani ko'rsat."
Tekshiruv: botdan "oxirgi 7 kun Instagram qanday?" — raqamlar Instagram ilovasidagi bilan mos.

**3-bosqich — qo'llar: joylash va target** (yozish ruxsatlari)
Terminalga: "`joyla.py` va `target.py` ni 3-bo'limdagi kelishuv bo'yicha yoz: `--ha` siz dry-run, `KUNLIK_BYUDJET_MAX` chegarasi, `amallar.log`. Sinov: bitta test post va bitta PAUSED kampaniya, keyin ikkalasini o'chir."
Tekshiruv: botga "shu obyektga post tayyorla" → qoralama → "ha" → post chiqdi, havola keldi. Tasdiqsiz chiqmasligini ham sinang.

**4-bosqich — e'lon, sayt, jadval**
- `elon.py`: avval Telegram kanal, keyin mijoz aytgan platformalar.
- `sayt.py`: obyekt fayllaridan statik sayt, hosting tanlangach deploy.
- Jadval (launchd): ertalabki brifing (kechagi lidlar, reklama sarfi, bugungi tasklar), haftalik hisobot, `~/brain` zaxirasi.

**5-bosqich — topshirish**
Egaga 20 daqiqalik ko'rsatuv: nima so'rash mumkin, tasdiq qanday ishlaydi, bot jim bo'lsa nima qilish (`jarvis-start.sh status / restart`).

## 7. Hali hal qilinmagan savollar (mijozdan)

1. Instagram Business akkauntmi va Facebook Page ga ulanganmi? Reklama kabineti va karta bormi?
2. E'lon qaysi platformalarga: Telegram kanal, OLX, uybor, boshqa?
3. Sayt: domen bormi, qayerda turadi?
4. CRM ishlatadimi (Uysot, amoCRM) yoki lidlar Telegram/telefonda?
5. Xodimlar ham botga yozadimi — kimlar?
6. Kunlik reklama byudjetining yuqori chegarasi (`KUNLIK_BYUDJET_MAX`).
