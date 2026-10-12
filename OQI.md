# Jarvis kit — mijoz Mac'iga o'rnatish

Stark arxitekturasi (Claude Code `--channels` + Telegram plugin + launchd loop + watchdog), mijozga moslab tozalangan.
Har mijoz uchun faqat `sozlama.json` to'ldiriladi.

## Mijozdan oldindan olinadigan narsalar
1. **Claude obunasi** — mijozning o'z akkaunti (Max tavsiya: bot 24/7 ishlaydi, Pro limiti tez tugaydi).
2. **Telegram bot** — mijoz @BotFather da yaratadi, tokenni beradi.
3. **Egasining Telegram ID si** — @userinfobot ga yozib oladi. Xodimlar ham yozsa — ularning ID lari.
4. **Gemini API kaliti** (ixtiyoriy, ovozli xabarlar uchun) — aistudio.google.com, bepul.
5. Mac: doim yoniq, tokka ulangan, **qopqog'i ochiq**, foydalanuvchi tizimga kirgan holda.
   System Settings → Battery → "Prevent automatic sleeping on power adapter" yoqilsin.

## O'rnatish (mijoz Mac'ida, ~15 daqiqa)
```
xcode-select --install                          # bo'lmasa
curl -fsSL https://claude.ai/install.sh | bash  # Claude Code, keyin yangi Terminal
claude                                          # mijoz akkaunti bilan login, keyin /exit
```
`jarvis-kit` papkasini Mac'ga ko'chiring, `sozlama.json` ni to'ldiring (OWNER, TGID, BOT_TOKEN, GEMINI_API_KEY, XODIMLAR), keyin:
```
zsh jarvis-kit/install.sh
```
O'rnatuvchi o'zi: bun ni qo'yadi, tokenni tekshiradi, `~/jarvis` va `~/brain` ni yaratadi, Telegram pluginni o'rnatib patchlaydi, launchd ga ulaydi va bot ko'tarilganini kutadi.
Ega botga `/start` bosadi — tayyor.

Boshqarish: `~/jarvis/jarvis-start.sh status | restart | yangi-sessiya | stop | start | log`

O'rnatgandan keyin `sozlama.json` ni Mac'dan o'chiring (ichida bot token bor).

## Bot nimani biladi (1-bosqich — o'rnatilgan zahoti)
- Telegramdan 24/7 javob, ovozli xabarni tushunadi, rasm o'qiydi
- `~/brain` da xotira: obyektlar, kontent, reklama, hisobotlar
- Post / e'lon / reklama matni va kontent-plan qoralamasi, sayt qurish (lokal)
- Tasdiq qoidasi: pul sarflanadigan va ommaga chiqadigan har ish faqat egasi "ha" degach

## 2-bosqich — integratsiyalar (kalitlar `~/jarvis/.env` ga)
| Ish | Kerak | Izoh |
|---|---|---|
| Media analitika | Meta System User tokeni: `instagram_basic`, `instagram_manage_insights`, `pages_read_engagement`, `ads_read` | Instagram **Business/Creator** akkaunt va Facebook Page ga ulangan bo'lishi shart |
| Post joylash | + `instagram_content_publish`, `pages_manage_posts` | Rasm/video ochiq URL da turishi kerak (Graph API talabi) |
| Target yoqish | + `ads_management`, reklama kabineti `act_...`, kartasi ulangan | Kampaniya PAUSED yaratiladi, ega "yoq" degach ACTIVE |
| Sayt | domen + hosting (Netlify bepul yoki mijoz serveri) | |
| E'lon joylash | qaysi platforma? | Telegram kanal — bot admin qilinsa bo'ldi. OLX / uybor — ochiq API cheklangan, alohida ko'rish kerak |
| CRM (bo'lsa) | Uysot / amoCRM tokeni | |

Meta tokenini olish: business.facebook.com → Settings → Users → System users → Add → Generate token (muddatsiz). App "Live" rejimda bo'lsin.

## Ma'lum cheklovlar
- Mac qayta yonganda bot faqat foydalanuvchi tizimga kirgandan keyin ko'tariladi. Avtomatik kirish: System Settings → Users & Groups → "Automatically log in as" (FileVault yoqilgan bo'lsa bu imkoniyat yo'q — parolni qo'lda kiritish kerak).
- Xodimlar uchun cheklov faqat qoida darajasida: bot kompyuterda to'liq huquq bilan ishlaydi. Ishonchsiz odamni ruxsat ro'yxatiga qo'shmang.
- Mac uxlasa yoki o'chsa — bot ham jim. Jiddiy ishlasa keyin VPS ga ko'chirish (Stark kabi) to'g'ri yo'l.
- Bot bir necha hafta ishlab, reaksiya berib javob yozmay qo'ysa — `jarvis-start.sh yangi-sessiya` (kontekst shishgan).
- Plugin yangilansa: `zsh ~/jarvis/patch-telegram-plugin.sh` ni qayta ishga tushiring.
- `~/.claude/settings.json` ga `skipDangerousModePermissionPrompt: true` yoziladi (zaxira nusxa yonida qoladi).
