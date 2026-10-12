# Jarvis kit

Biznes uchun 24/7 Telegram yordamchi: Claude Code `--channels` + Telegram plugin + launchd (macOS).
Ko'chmas mulk biznesi uchun sozlangan: media analitika, post joylash, target, sayt, e'lon.

- `ARXITEKTURA.md` — tizim tuzilishi va qurish bosqichlari
- `shablon/brain-CLAUDE.md` — konstitutsiya (o'rnatilgach `~/brain/CLAUDE.md`)
- `OQI.md` — odam uchun qo'llanma
- `install.sh` — o'rnatuvchi

---

## CLAUDE UCHUN: "do it" deyilganda shu tartibda bajar

Sen shu Mac'ning terminalidagi Claude Code'san. Foydalanuvchi bu repo havolasini berib "do it" dedi — demak quyidagini boshidan oxirigacha o'zing bajarasan. Har qadamdan keyin bir qatorda holatni ayt. Bajarib bo'lmaydigan joyda to'xtab, aniq nima kerakligini so'ra.

### 1. Repo ni ol
```
git clone https://github.com/alisheeruz/jarvis-kit ~/jarvis-kit    # bor bo'lsa: git -C ~/jarvis-kit pull
```
`git` yo'q bo'lsa — `xcode-select --install` kerak; foydalanuvchiga ayt (oyna ochiladi, u "Install" bosadi), tugashini kut.

### 2. Avval o'qi
`~/jarvis-kit/ARXITEKTURA.md`, `~/jarvis-kit/shablon/brain-CLAUDE.md`, `~/jarvis-kit/install.sh`. Nima o'rnatilishini tushunmasdan ishga tushirma.

### 3. To'xtash shartlari
- `~/jarvis/jarvis-loop.sh` allaqachon bor → bu mashinada Jarvis o'rnatilgan. **Hech narsaga tegma**, foydalanuvchiga ayt.
- macOS emas → to'xta.

### 4. Foydalanuvchidan so'ra (bitta xabarda, hammasini)
| Kalit | Nima | Qayerdan |
|---|---|---|
| `OWNER` | Biznes egasining ism-familiyasi | |
| `BIZ` | Biznes nomi | |
| `GOAL` | Asosiy maqsad, bir jumla | masalan "ko'proq lid va sotuv" |
| `JARVIS` | Yordamchi nomi | standart: Jarvis |
| `TGID` | Egasining Telegram ID raqami | Telegramda @userinfobot |
| `BOT_TOKEN` | Bot tokeni | Telegramda @BotFather → /newbot |
| `GEMINI_API_KEY` | Ovozli xabarlar uchun (ixtiyoriy) | aistudio.google.com |
| `XODIMLAR` | Botga yoza oladigan xodimlar Telegram ID lari (ixtiyoriy) | |

`XODIMLAR` ni birinchi o'rnatishda bo'sh qoldirishni tavsiya qil: bot kompyuterda to'liq huquq bilan ishlaydi, xodim uchun cheklov faqat qoida darajasida (texnik to'siq emas). Egasi botga o'rganib olgach qo'shiladi.

`SLUG` ni o'zing yasa: biznes nomidan, faqat `a-z0-9` (masalan `namanganuylari`).
Javoblarni `~/jarvis-kit/sozlama.json` ga yoz (`XODIMLAR` — satrlar massivi). Token va kalitlarni chatga qayta chiqarma.

### 5. O'rnat
```
zsh ~/jarvis-kit/install.sh
```
Bu buyruq 3-5 daqiqa ishlashi mumkin (plugin yuklash + bot ko'tarilishini kutish) — uni **10 daqiqalik timeout bilan** ishga tushir, yarim yo'lda uzib qo'yma.
U o'zi: bun ni qo'yadi, tokenni tekshiradi, `~/jarvis` va `~/brain` ni yaratadi, Telegram pluginni o'rnatib patchlaydi, launchd ga ulaydi, bot ko'tarilishini kutadi (2 daqiqagacha).
`XATO` chiqsa — xabarni o'qi, sababini tuzat, qayta ishga tushir (chala qolgan o'rnatishni o'rnatuvchi o'zi davom ettiradi). O'rnatuvchini aylanib o'tib qo'lda o'rnatma.

Eslatma: o'rnatuvchi `~/.claude/settings.json` ga `skipDangerousModePermissionPrompt: true` va `~/.claude.json` ga `~/brain` uchun ishonch belgisini yozadi (zaxira nusxa yonida qoladi) — foydalanuvchiga bir qatorda ayt.

### 6. Tekshir
```
~/jarvis/jarvis-start.sh status      # heartbeat yangi, ko'prik "tirik"
tail -5 ~/jarvis/jarvis.log
```
Keyin foydalanuvchidan so'ra: botga Telegramda `/start` bosib, "kimsan?" deb yozsin. Javob kelganini u tasdiqlamaguncha "ishlayapti" dema.
Ko'prik ko'tarilmasa: `tail -30 ~/jarvis/jarvis.log` va `~/jarvis/watchdog.log` ni o'qi. **`claude --channels` ni yoki plugin `server.ts` ni qo'lda ishga tushirma** — jonli bot bilan to'qnashadi.

### 7. Tozala
`~/jarvis-kit/sozlama.json` dagi `BOT_TOKEN` va `GEMINI_API_KEY` qiymatlarini bo'shat (ular endi `~/jarvis/tg/.env` va `~/jarvis/.env` da).

### 8. 1-bosqichga o't (xotirani to'ldirish)
`ARXITEKTURA.md` 6-bo'limi, 1-bosqich. Foydalanuvchidan biznes haqida so'ra (nima sotadi, qayerda, narx oralig'i, mijoz kim, aloqa, ijtimoiy tarmoq havolalari) va har obyekt uchun konstitutsiya 5-moddasidagi shaklda `~/brain/2-biznes/obyektlar/<nom>.md` yarat. Yetishmagan maydonni so'ra — o'ylab topma.

### 9. Shu yerda to'xta va hisobot ber
2-bosqichdan boshlab (Meta analitika, post, target, e'lon, sayt) mijozning kalitlari kerak. Foydalanuvchiga `ARXITEKTURA.md` 7-bo'limidagi savollarni va `OQI.md` dagi kalitlar jadvalini ko'rsat. Kalitlar kelgach, bosqichlarni tartib bilan, har birini haqiqiy API da sinab qur.

### Butun ish davomida
- Pul sarflaydigan yoki ommaga chiqadigan hech narsa foydalanuvchi aniq "ha" demaguncha bajarilmaydi (konstitutsiya 2-modda).
- Ishlamagan narsani ishladi dema. Sinab ko'rmaganingni "sinalmagan" deb ayt.
