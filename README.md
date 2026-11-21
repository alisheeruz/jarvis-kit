# Jarvis kit

Biznes uchun 24/7 Telegram yordamchi: Claude Code `--channels` + Telegram plugin + launchd (macOS) yoki systemd (Linux server / Windows WSL2 — `server/`, `windows/`, pastdagi W bo'limi).
Uch profil (`sozlama.json` → `PROFIL`):
- `kochmas-mulk` — media analitika, post joylash, target, sayt, e'lon.
- `montaj` — asosan video montaj (Remotion motion-montaj, o'zbek whisper subtitr, musiqa/SFX), qo'shimcha SMM va marketing. Shablonlar: `shablon/montaj/`, asboblar: `montaj/setup.sh`.
- `travel` — turizm kompaniyasi uchun to'liq marketing va sotuv: tur fayllari, lidlar voronkasi, copywriting, kontent-plan, target, analitika, videografiya/montaj (`montaj/setup.sh` bilan). Shablonlar: `shablon/travel/`.

- `ARXITEKTURA.md` — tizim tuzilishi va qurish bosqichlari
- `shablon/brain-CLAUDE.md` — konstitutsiya (o'rnatilgach `~/brain/CLAUDE.md`)
- `OQI.md` — odam uchun qo'llanma
- `install.sh` — o'rnatuvchi

---

## CLAUDE UCHUN: "do it" deyilganda shu tartibda bajar

Sen shu Mac'ning terminalidagi Claude Code'san. Foydalanuvchi bu repo havolasini berib "do it" dedi — demak quyidagini boshidan oxirigacha o'zing bajarasan. Har qadamdan keyin bir qatorda holatni ayt. Bajarib bo'lmaydigan joyda to'xtab, aniq nima kerakligini so'ra.

### W. Windows noutbuk yoki Linux server (Mac emas)
Mijozda Mac bo'lmasa, Jarvis Linux'da ishlaydi: Windows'da **WSL2 Ubuntu** ichida (noutbukning o'zi server bo'ladi) yoki VPS'da. Miya va shablonlar Mac'dagi bilan bir xil, faqat launchd o'rniga systemd (`server/`).

**Windows'da odam qiladigan qism (Claude'dan OLDIN):**
1. PowerShell → "Run as administrator":
   ```
   irm https://raw.githubusercontent.com/alisheeruz/jarvis-kit/main/windows/ornatish.ps1 -OutFile $env:TEMP\jarvis.ps1; Set-ExecutionPolicy -Scope Process Bypass -Force; & $env:TEMP\jarvis.ps1
   ```
   Birinchi marta WSL o'rnatiladi → kompyuter qayta yoqiladi → Ubuntu foydalanuvchi/parol so'raydi → buyruq **yana bir marta** ishga tushiriladi (systemd, avto-yonish, uyqusiz rejim).
2. `wsl -u root` → Ubuntu ichida: `curl -fsSL https://claude.ai/install.sh | bash && source ~/.bashrc` (429/xato bersa — pastdagi GCS aylanma yo'li, `darwin-arm64` o'rniga `linux-x64`).
3. `claude` → mijoz akkaunti bilan login (havola Windows brauzerida ochiladi, kod qaytarib qo'yiladi) → shu repo havolasi + "do it".

**Claude qiladigan qism (root, WSL yoki server ichida):**
1. `ps -p 1 -o comm=` → `systemd` bo'lishi shart. Bo'lmasa — WSL'da `windows/ornatish.ps1` qayta ishga tushirilishi kerak, egaga ayt.
2. 1-2 qadam (repo, o'qish) — `install.sh` o'rniga `server/install-server.sh` va `server/` ni o'qi. `~/jarvis/jarvis-loop.sh` bor bo'lsa — to'xta.
3. 4-qadam (sozlama so'rash) xuddi shunday.
4. `bash ~/jarvis-kit/server/install-server.sh` — 10 daqiqalik timeout bilan. U o'zi: apt paketlari, Toshkent vaqt zonasi, bun, `~/jarvis` + `~/brain`, plugin + patch, headless sozlamalar, `<slug>-jarvis.service` + `<slug>-jarvis-watchdog.timer`.
5. Montaj kerak bo'lsa (`montaj`, `travel`): `zsh ~/jarvis-kit/montaj/setup.sh` fonda (Linux'da Chrome kutubxonalarini ham qo'yadi). `montaj-media.zip` — Windows'da Downloads'ga tashlansa: `cp /mnt/c/Users/<user>/Downloads/montaj-media.zip ~/` keyin setup.sh. Render CPU'da, Mac'dan sekinroq.
5c. Metodika skillari (`travel`): o'rnatuvchi `travel-skillar.zip` beradi (repo'da yo'q). Windows Downloads'ga tashlansa: `mkdir -p ~/.claude/skills && unzip -oq /mnt/c/Users/<user>/Downloads/travel-skillar.zip -d ~/.claude/skills` → `ls ~/.claude/skills` da 5 ta papka. Keyin `~/jarvis/jarvis-start.sh restart` (bot skillarni ko'rsin).
6. Tekshir: `~/jarvis/jarvis-start.sh status`, `journalctl -u <slug>-jarvis -n 30`. Ega botga "kimsan?" yozib javob olmaguncha "ishlayapti" dema. Keyin 7-9 qadamlar.

Windows cheklovlari (egaga ayt): noutbuk tokka ulangan tursin (batareyada uxlashi mumkin); qayta yonganda Jarvis faqat Windows'ga kirilgandan keyin ishlaydi (avto-kirish: `netplwiz`); Windows Update qayta yoqsa ham shu. Login token yangilanmay qolsa: Ubuntu'da `claude setup-token` → chiqqan tokenni `~/jarvis/.claude-token` ga yoz (chmod 600) → `~/jarvis/jarvis-start.sh restart`.

### 0. Telegramsiz (faqat terminal) montaj rejimi
Foydalanuvchi "faqat terminal", "Telegram kerak emas" desa — pastdagi 3-9 qadamlar O'RNIGA shu:
1. Repo ni ol (1-qadam), `ARXITEKTURA.md`, `shablon/montaj/brain-CLAUDE.md`, `montaj/terminal-install.sh`, `montaj/setup.sh` ni o'qi.
2. `~/brain/CLAUDE.md` allaqachon bor bo'lsa — to'xta, ayt.
3. Bitta xabarda so'ra: `OWNER`, `BIZ`, `GOAL`, `JARVIS` (nom), `GEMINI_API_KEY` (ixtiyoriy, AI kadrlar uchun). `~/jarvis-kit/sozlama.json` ga yoz (`PROFIL`: `montaj`).
4. `montaj-media.zip` (musiqa + SFX) `~/Downloads` yoki `~/Desktop` da bormi — so'ra; yo'q bo'lsa AirDrop qilinishini kut.
5. `zsh ~/jarvis-kit/montaj/terminal-install.sh` — **fonda**, 10-25 daqiqa (~3 GB). `XATO` bo'lsa sababini tuzat va qayta ishga tushir.
6. Tekshir: `~/Montaj/loyihalar/_sinov/out/reel.mp4` bor va `open` bilan ochiladi.
7. Egaga ayt: yangi Terminal → `jarvis` (bu `~/brain` da Claude ochadi). Keyin 8-qadamdagi `montaj` profili bo'yicha xotirani to'ldir va sinov montaji qil (ega bergan qisqa video bilan).

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
| `PROFIL` | `kochmas-mulk`, `montaj` yoki `travel` | ish turiga qarab: montajchi/SMM → `montaj`, turizm kompaniyasi → `travel` |
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

### 5b. `PROFIL=montaj` va `PROFIL=travel`: montaj asboblari
`travel` uchun ixtiyoriy, lekin ega video/reels ham so'rasa kerak (Mac talabi pastda).
Avval so'ra: `montaj-media.zip` (musiqa + SFX, o'rnatuvchi beradi) shu Mac'ning `~/Downloads` yoki `~/Desktop` ida bormi? Bo'lmasa — AirDrop qilishini so'ra (zipsiz ham o'rnatiladi, keyin qayta ishga tushirsa qo'shiladi).
```
zsh ~/jarvis-kit/montaj/setup.sh
```
10-25 daqiqa, ~3 GB yuklaydi (python 3.12, ffmpeg, o'zbek whisper, rembg, node, Remotion) — **fonda** ishga tushir va tugashini kut. Oxirida namuna video render qilinadi (`~/Montaj/loyihalar/_sinov/out/reel.mp4`) — shu fayl bo'lmasa montaj ishlamaydi. Mac: Apple Silicon (M1+), kamida 16 GB RAM, 20 GB bo'sh joy tavsiya; kam bo'lsa egaga ayt.

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
**`montaj` profili:** egadan uning mijozlari/brendlari haqida so'ra va har biriga konstitutsiya 5-moddasidagi shaklda `~/brain/2-biznes/mijozlar/<nom>.md` yarat; egasining montaj didini (namuna reelslar havolasi, nima yoqadi, nima yoqmaydi) `~/brain/1-tizim/montaj-qoidalari.md` ga yoz. Keyin sinov: ega botga 20 MB gacha qisqa video yuborib "montaj qil" desin — tayyor video Telegramga qaytishini u tasdiqlasin.

**`travel` profili:** egadan so'ra: kompaniya nima sotadi (yo'nalishlar, mavsum, narx oralig'i, mijoz portreti, aloqa, IG/TG havolalar, raqobatchilar) → `~/brain/1-tizim/biznes.md`; brend (ohang, ranglar, logotip) → `1-tizim/brend.md`; reklama va postda narx qaysi valyutada ko'rsatiladi → `1-tizim/uslub.md`. Keyin hozir sotuvdagi har tur uchun konstitutsiya 5-moddasidagi shaklda `~/brain/2-biznes/turlar/<yo'nalish>-<YYYY-MM>.md` yarat (ega narx jadvali skrinshotini tashlasa — o'qib to'ldir, yetishmaganini so'ra). Sinov: ega botga "Antaliya turiga post va reels ssenariysi yoz" desin — matndagi har fakt tur faylidan kelganini tekshir.

**`kochmas-mulk` profili:**
`ARXITEKTURA.md` 6-bo'limi, 1-bosqich. Foydalanuvchidan biznes haqida so'ra (nima sotadi, qayerda, narx oralig'i, mijoz kim, aloqa, ijtimoiy tarmoq havolalari) va har obyekt uchun konstitutsiya 5-moddasidagi shaklda `~/brain/2-biznes/obyektlar/<nom>.md` yarat. Yetishmagan maydonni so'ra — o'ylab topma.

### 9. Shu yerda to'xta va hisobot ber
2-bosqichdan boshlab (Meta analitika, post, target, e'lon, sayt) mijozning kalitlari kerak. Foydalanuvchiga `ARXITEKTURA.md` 7-bo'limidagi savollarni va `OQI.md` dagi kalitlar jadvalini ko'rsat. Kalitlar kelgach, bosqichlarni tartib bilan, har birini haqiqiy API da sinab qur.

### Butun ish davomida
- Pul sarflaydigan yoki ommaga chiqadigan hech narsa foydalanuvchi aniq "ha" demaguncha bajarilmaydi (konstitutsiya 2-modda).
- Ishlamagan narsani ishladi dema. Sinab ko'rmaganingni "sinalmagan" deb ayt.
