#!/bin/bash
# Jarvis o'rnatuvchi — Linux server (Ubuntu 22.04+/Debian 12+, root). Mijozning o'z VPS'ida:
#   bash ~/jarvis-kit/server/install-server.sh
# Sozlamalar ~/jarvis-kit/sozlama.json dan. Mavjud ~/jarvis ustiga YOZMAYDI.
# Mac'dagi install.sh bilan bir xil miya (~/brain) va shablonlar; farqi: launchd o'rniga systemd.

KIT="$(cd "$(dirname "$0")/.." && pwd)"
SRV="$KIT/server"
SH="$KIT/shablon"
J="$HOME/jarvis"
B="$HOME/brain"
export PATH="$HOME/.local/bin:$HOME/.bun/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

ok()   { printf '\033[32mOK\033[0m  %s\n' "$*"; }
xato() { printf '\033[31mXATO\033[0m %s\n' "$*"; exit 1; }
ogoh() { printf '\033[33mDIQQAT\033[0m %s\n' "$*"; }

# ---------------------------------------------------------------- 0) tekshiruv
[ "$(uname)" = Linux ] || xato "Bu o'rnatuvchi Linux server uchun. Mac uchun: zsh install.sh"
[ "$(id -u)" = 0 ] || xato "root ostida ishga tushiring (sudo -i)."
WSL=0; grep -qi microsoft /proc/version 2>/dev/null && WSL=1
if [ "$(ps -p 1 -o comm= 2>/dev/null)" != systemd ]; then
  [ "$WSL" = 1 ] && xato "WSL'da systemd yoqilmagan. Windows'da windows/ornatish.ps1 ni ishga tushiring (yoki /etc/wsl.conf ga [boot] systemd=true yozib, PowerShell'da: wsl --shutdown)."
  xato "systemd yo'q — bu mashinada ishlamaydi."
fi
CHALA="$J/.kit-chala"
if [ ! -e "$CHALA" ]; then
  [ -e "$J/jarvis-loop.sh" ] && xato "$J/jarvis-loop.sh allaqachon bor — bu serverda Jarvis o'rnatilgan. To'xtadim, hech narsaga tegmadim."
  ls /etc/systemd/system/*-jarvis.service >/dev/null 2>&1 && xato "/etc/systemd/system da boshqa *-jarvis.service bor. To'xtadim."
else
  ogoh "Tugallanmagan o'rnatish topildi — davom ettiryapman."
fi

if command -v apt-get >/dev/null; then
  echo "Tizim paketlari..."
  DEBIAN_FRONTEND=noninteractive apt-get update -qq >/dev/null 2>&1
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq zsh git curl unzip python3 ca-certificates procps util-linux >/dev/null 2>&1 \
    || xato "apt-get install ishlamadi (internet yoki apt qulfi). Qayta urinib ko'ring."
fi
for c in zsh git curl unzip python3 script; do command -v $c >/dev/null || xato "$c yo'q"; done
PY="$(command -v python3)"

# Vaqt zonasi: hisobot va "ertalab" Toshkent vaqti bilan bo'lsin
[ "$(timedatectl show -p Timezone --value 2>/dev/null)" = Asia/Tashkent ] || timedatectl set-timezone Asia/Tashkent 2>/dev/null || ogoh "vaqt zonasi o'rnatilmadi"

command -v claude >/dev/null || xato "Claude Code yo'q. Avval: curl -fsSL https://claude.ai/install.sh | bash   (keyin: source ~/.bashrc)"
if ! command -v bun >/dev/null; then
  echo "bun o'rnatilmoqda..."
  curl -fsSL https://bun.sh/install | bash >/dev/null 2>&1
  command -v bun >/dev/null || xato "bun o'rnatilmadi. Qo'lda: curl -fsSL https://bun.sh/install | bash"
fi
ln -sf "$(command -v bun)" /usr/local/bin/bun 2>/dev/null
ln -sf "$(readlink -f "$(command -v claude)")" /usr/local/bin/claude 2>/dev/null
ok "$(. /etc/os-release; echo "$PRETTY_NAME"), claude $(claude --version 2>/dev/null | cut -d' ' -f1), bun $(bun --version)"

if [ -s "$J/.claude-token" ]; then
  ok "Claude: uzoq muddatli token (~/jarvis/.claude-token)"
else
  claude auth status >/dev/null 2>&1 || xato "Claude'ga login qilinmagan. Serverda \`claude\` ni oching, mijoz akkaunti bilan kiring (havolani kompyuter brauzerida oching, kodni qaytarib qo'ying), keyin qayta ishga tushiring."
  ok "Claude login bor"
fi

# ---------------------------------------------------------------- 1) sozlama
oqi() { "$PY" -c 'import json,sys; v=json.load(open(sys.argv[1])).get(sys.argv[2],""); print(" ".join(map(str,v)) if isinstance(v,list) else ("" if v is None else str(v).strip()))' "$KIT/sozlama.json" "$1" 2>/dev/null; }
sora() {
  local v; v="$(oqi "$1")"
  while [ -z "$v" ]; do
    printf "%s: " "$2" >&2
    read -r v || { echo "Kiritish uzildi — sozlama.json ni to'ldiring." >&2; exit 1; }
  done
  echo "$v"
}
OWNER="$(sora OWNER "Egasining ism-familiyasi")"
NAME="$(sora JARVIS "Yordamchi nomi (masalan Jarvis)")"
BIZ="$(sora BIZ "Biznes nomi")"
GOAL="$(sora GOAL "Asosiy maqsad (bir jumla)")"
SLUG="$(sora SLUG "Qisqa nom (lotin, bo'shliqsiz)" | tr -cd 'a-z0-9')"
TGID="$(sora TGID "Egasining Telegram ID raqami (@userinfobot dan)")"
TOKEN="$(sora BOT_TOKEN "Bot token (@BotFather dan)")"
GEMINI="$(oqi GEMINI_API_KEY)"
PROFIL="$(oqi PROFIL)"; PROFIL="${PROFIL:-kochmas-mulk}"
case "$PROFIL" in
  kochmas-mulk) SHP="$SH" ;;
  montaj)       SHP="$SH/montaj" ;;
  travel)       SHP="$SH/travel" ;;
  *) xato "PROFIL noto'g'ri: '$PROFIL' (kochmas-mulk, montaj yoki travel)" ;;
esac
XODIMLAR="$(oqi XODIMLAR)"
for v in "$OWNER" "$NAME" "$BIZ" "$GOAL" "$TGID" "$TOKEN"; do
  [ -n "$v" ] || xato "Sozlama to'liq emas. $KIT/sozlama.json da OWNER, JARVIS, BIZ, GOAL, SLUG, TGID, BOT_TOKEN ni to'ldiring."
done
[ -n "$SLUG" ] || xato "SLUG bo'sh (faqat a-z va 0-9)."
case "$TGID" in ''|*[!0-9]*) xato "Telegram ID faqat raqam bo'lishi kerak: '$TGID'";; esac

BOTUSER="$(curl -s -4 -m 20 "https://api.telegram.org/bot${TOKEN}/getMe" | "$PY" -c 'import json,sys; d=json.load(sys.stdin); print(d["result"]["username"] if d.get("ok") else "")' 2>/dev/null)"
[ -n "$BOTUSER" ] || xato "Bot token ishlamadi (getMe). Tokenni tekshiring yoki internetni."
ok "Bot: @$BOTUSER · ega: $OWNER ($TGID) · $BIZ · profil: $PROFIL"

# ---------------------------------------------------------------- 2) fayllar
mkdir -p "$J/tg/inbox" "$B/1-tizim" "$B/3-shaxsiy" "$B/9-arxiv" \
         "$B/2-biznes/kontent" "$B/2-biznes/reklama" "$B/2-biznes/hisobotlar" "$B/2-biznes/mijozlar"
case "$PROFIL" in
  montaj) mkdir -p "$B/2-biznes/montaj" ;;
  travel) mkdir -p "$B/2-biznes/montaj" "$B/2-biznes/turlar" "$B/2-biznes/sotuv" "$B/2-biznes/kontent/ssenariylar" ;;
  *)      mkdir -p "$B/2-biznes/obyektlar" "$B/2-biznes/sayt" ;;
esac
touch "$CHALA"

quy() {
  OWNER="$OWNER" NAME="$NAME" BIZ="$BIZ" GOAL="$GOAL" SLUG="$SLUG" TGID="$TGID" UY="$HOME" \
  "$PY" - "$1" "$2" <<'PYEOF'
import os, sys
s = open(sys.argv[1], encoding="utf-8").read()
for k, e in (("__OWNER__", "OWNER"), ("__NAME__", "NAME"), ("__BIZ__", "BIZ"), ("__GOAL__", "GOAL"),
             ("__SLUG__", "SLUG"), ("__TGID__", "TGID"), ("__HOME__", "UY")):
    s = s.replace(k, os.environ[e])
# Mac'ga xos qatorlar serverga moslanadi
s = s.replace("launchd `com." + os.environ["SLUG"] + ".jarvis`", "systemd `" + os.environ["SLUG"] + "-jarvis.service`")
s = s.replace("Kompyuter yoniq, tokka ulangan va qopqog'i ochiq tursin.", "Bu Linux server, 24/7 yoniq.")
s = s.replace("Kompyuter yoniq, tokka ulangan, qopqog'i ochiq tursin.", "Bu Linux server, 24/7 yoniq.")
open(sys.argv[2], "w", encoding="utf-8").write(s)
PYEOF
}
quy "$SRV/jarvis-loop.sh"     "$J/jarvis-loop.sh"
quy "$SRV/jarvis-watchdog.sh" "$J/jarvis-watchdog.sh"
quy "$SRV/jarvis-start.sh"    "$J/jarvis-start.sh"
quy "$SHP/JARVIS.md"          "$J/JARVIS.md"
cat >> "$J/JARVIS.md" <<'MD'

## SERVER (Linux)
- Bu mashina Linux (server yoki Windows ichidagi WSL). Ega senga Telegram orqali yozadi. "AirDrop", "Finder", "open" bu yerda YO'Q. Fayl Telegram (20 MB gacha) yoki havola (Google Drive) orqali keladi.
- Tayyor faylni egaga faqat reply tool `files` bilan yuborasan (50 MB gacha); kattasi bo'lsa siq.
- Servis: `systemctl status __SLUG__-jarvis`. Qayta ishga tushirish faqat `~/jarvis/jarvis-start.sh restart` (oldin ogohlantir).
MD
if [ "$WSL" = 1 ]; then
  WU="$(/mnt/c/Windows/System32/cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r')"
  WH="/mnt/c/Users/$WU"; [ -d "$WH" ] || WH="/mnt/c/Users"
  DESK="$WH/Desktop"; [ -d "$WH/OneDrive/Desktop" ] && DESK="$WH/OneDrive/Desktop"
  cat >> "$J/JARVIS.md" <<MD
- **Bu aslida egasining Windows noutbugi** (WSL2 Ubuntu ichida ishlaysan). Windows fayllari: \`$DESK\` (ish stoli), \`$WH/Downloads\` (Linux yo'li). Ega "ish stolidagi faylni ol" desa — shu yerdan ol; katta videolarni shu papkaga tashlashi mumkin (Telegram 20 MB cheklovi yo'q). Tayyor faylni egaga ko'rsatish uchun nusxasini \`$DESK/Jarvis\` ga ham qo'y.
- Noutbuk uxlasa yoki o'chsa — sen ham jimsan. Uzoq jim qolgan bo'lsang, bu shundan.
- Windows fayllarida hech narsani o'chirma va ko'chirma (faqat nusxa ol).
MD
  mkdir -p "$DESK/Jarvis" 2>/dev/null
fi
sed -i "s/__SLUG__/$SLUG/g" "$J/JARVIS.md"
cp "$SH/ovoz.py" "$SH/patch-telegram-plugin.sh" "$J/"
chmod +x "$J"/*.sh "$J"/*.py
[ -e "$B/CLAUDE.md" ] || quy "$SHP/brain-CLAUDE.md" "$B/CLAUDE.md"
[ -e "$B/1-tizim/biznes.md" ] || printf '# %s\n\nEgasi: %s\nMaqsad: %s\n\n(Bu faylni to'"'"'ldiring: nima sotiladi, qayerda, narx oralig'"'"'i, kim mijoz, aloqa raqamlari, ijtimoiy tarmoq havolalari.)\n' "$BIZ" "$OWNER" "$GOAL" > "$B/1-tizim/biznes.md"

stub() { [ -e "$1" ] || printf '%b\n' "$2" > "$1"; }
D="$(date '+%F')"; OY="$(date '+%Y-%m')"
stub "$B/1-tizim/uslub.md"    "# Uslub\n\nFaqat o'zbekcha (lotin), har doim \"siz\", qisqa. Ega bergan \"doim / hech qachon\" qoidalari shu yerga sana bilan yoziladi."
stub "$B/1-tizim/kalitlar.md" "# Kalitlar xaritasi (qiymatsiz)\n\nBarcha kalitlar ~/jarvis/.env da. Bu faylda faqat nomi va nima uchunligi yoziladi."
stub "$B/1-tizim/texnik.md"   "# Tizim holati\n\n- $D · o'rnatildi (Linux server, systemd): Telegram bot, ovoz. Montaj asboblari: montaj/setup.sh dan keyin. Meta — hali ulanmagan."
if [ "$PROFIL" = montaj ] || [ "$PROFIL" = travel ]; then
  stub "$B/1-tizim/montaj-qoidalari.md" "# Montaj qoidalari\n\nEga videoni tanqid qilsa yoki maqtasa — shu yerga sana bilan yoziladi.\n\n- $D · boshlang'ich: keskin punch-zoom yo'q, matn yuzga tushmaydi, kadr doim ko'rinadi, fon musiqasi har doim (motion-montaj SKILL.md, Qat'iy saboqlar)."
  stub "$B/2-biznes/montaj/navbat.md" "# Montaj navbati\n\n| sana | mavzu | material | talab | holat |\n|---|---|---|---|---|"
fi
if [ "$PROFIL" = travel ]; then
  stub "$B/1-tizim/brend.md" "# Brend\n\n(Ovoz ohangi, ranglar hex, shrift, logotip yo'li, IG/TG havolalar. Ega bilan birinchi suhbatda to'ldiriladi.)"
  stub "$B/2-biznes/mijozlar/lidlar-$OY.md" "# Lidlar $OY\n\n| sana | ism | telefon | manba | qiziqish | bosqich | keyingi qadam + sana | izoh |\n|---|---|---|---|---|---|---|---|"
  stub "$B/2-biznes/sotuv/skriptlar.md" "# Sotuv skriptlari\n\n(Ega bilan birga to'ldiriladi: birinchi javob, narx so'raganda, 'qimmat', 'o'ylab ko'raman', 'boshqasida arzon', avans so'rash.)"
  stub "$B/2-biznes/kontent/reja.md" "# Kontent-plan\n\n| sana | format | mavzu | qaysi tur | CTA | holat |\n|---|---|---|---|---|---|"
fi
stub "$B/2-biznes/tasklar.md" "# Tasklar"
stub "$B/3-shaxsiy/ega.md"    "# $OWNER\n\n(Ish vaqti, qanday xabar yoqadi, nimani yoqtirmaydi.)"

umask 077
printf 'TELEGRAM_BOT_TOKEN=%s\n' "$TOKEN" > "$J/tg/.env"
[ -e "$J/.env" ] || printf '# %s kalitlari. Bu faylni hech kimga yubormang.\nGEMINI_API_KEY=%s\nGEMINI_MODEL=gemini-flash-latest\n\n# Meta (Instagram/Facebook/reklama) — 2-bosqichda\nMETA_TOKEN=\nMETA_ACT=\nIG_USER_ID=\nFB_PAGE_ID=\n\n# Reklama kunlik byudjetining qattiq chegarasi\nKUNLIK_BYUDJET_MAX=\n' "$NAME" "$GEMINI" > "$J/.env"
TGID="$TGID" XODIMLAR="$XODIMLAR" BOTUSER="$BOTUSER" "$PY" - "$J/tg/access.json" <<'PYEOF'
import json, os, sys
ids = [os.environ["TGID"]] + [x for x in os.environ["XODIMLAR"].split() if x.isdigit()]
json.dump({"dmPolicy": "allowlist", "allowFrom": ids, "groups": {}, "pending": {},
           "mentionPatterns": ["@" + os.environ["BOTUSER"]], "ackReaction": "👀"},
          open(sys.argv[1], "w", encoding="utf-8"), ensure_ascii=False, indent=2)
PYEOF
umask 022
ok "Fayllar: $J va $B"

# ---------------------------------------------------------------- 3) plugin
claude plugin marketplace list 2>/dev/null | grep -q "claude-plugins-official" \
  || claude plugin marketplace add anthropics/claude-plugins-official >/dev/null 2>&1
claude plugin install telegram@claude-plugins-official >/dev/null 2>&1
ls -d "$HOME"/.claude/plugins/cache/claude-plugins-official/telegram/*/server.ts >/dev/null 2>&1 \
  || xato "Telegram plugin o'rnatilmadi. Qo'lda: claude plugin install telegram@claude-plugins-official"
ok "Telegram plugin o'rnatildi"
if zsh "$J/patch-telegram-plugin.sh" >/dev/null 2>&1; then
  ok "Plugin patchlari qo'yildi (yagona egalik + ovoz)"
else
  ogoh "Plugin patchi tushmadi (plugin versiyasi yangilangan bo'lishi mumkin). Bot ishlaydi, lekin serverda boshqa \`claude\` oynasi ochilsa bot 1-2 daqiqaga uzilishi mumkin."
fi

# ---------------------------------------------------------------- 4) claude sozlamalari (headless: hech qanday dialog yo'q)
B="$B" "$PY" - <<'PYEOF'
import json, os, shutil, time
def yukla(p):
    try: return json.load(open(p, encoding="utf-8"))
    except FileNotFoundError: return {}
def saqla(p, d):
    if os.path.exists(p): shutil.copy2(p, p + ".jarvis-bak-" + time.strftime("%Y%m%d-%H%M%S"))
    os.makedirs(os.path.dirname(p), exist_ok=True)
    json.dump(d, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
h = os.path.expanduser("~")
p = h + "/.claude/settings.json"; s = yukla(p); o = dict(s)
s["skipDangerousModePermissionPrompt"] = True
s.setdefault("theme", "dark")
s.setdefault("enabledPlugins", {})["telegram@claude-plugins-official"] = True
if s != o: saqla(p, s)
p = h + "/.claude.json"; c = yukla(p); o = json.dumps(c, sort_keys=True)
c["hasCompletedOnboarding"] = True
for d in (os.environ["B"], h + "/jarvis", h):
    c.setdefault("projects", {}).setdefault(d, {})["hasTrustDialogAccepted"] = True
if json.dumps(c, sort_keys=True) != o: saqla(p, c)
PYEOF
[ $? -eq 0 ] || xato "Claude sozlamalarini yozib bo'lmadi (~/.claude/settings.json yoki ~/.claude.json buzuq JSON?)."
ok "Claude sozlamalari"

# ---------------------------------------------------------------- 5) systemd
U=/etc/systemd/system
quy "$SRV/jarvis.service"          "$U/$SLUG-jarvis.service"
quy "$SRV/jarvis-watchdog.service" "$U/$SLUG-jarvis-watchdog.service"
quy "$SRV/jarvis-watchdog.timer"   "$U/$SLUG-jarvis-watchdog.timer"
systemctl daemon-reload
systemctl enable --now "$SLUG-jarvis.service" >/dev/null 2>&1 || xato "systemd: $SLUG-jarvis.service yoqilmadi (journalctl -u $SLUG-jarvis)"
ok "systemd: $SLUG-jarvis.service"

echo "Bot ko'tarilishini kutyapman (2 daqiqagacha)..."
i=0
while [ $i -lt 150 ]; do
  BP="$(cat "$J/tg/bot.pid" 2>/dev/null)"
  [ -n "$BP" ] && kill -0 "$BP" 2>/dev/null && break
  sleep 3; i=$(( i + 3 ))
done
if [ -n "$BP" ] && kill -0 "$BP" 2>/dev/null; then
  systemctl enable --now "$SLUG-jarvis-watchdog.timer" >/dev/null 2>&1 || xato "systemd: watchdog taymeri yoqilmadi"
  rm -f "$CHALA"
  ok "$NAME ishlayapti (watchdog ulandi). Telegramda @$BOTUSER ga yozing."
  echo "   Eslatma: ega avval botga /start bosishi kerak."
  echo "   Boshqarish: ~/jarvis/jarvis-start.sh status | restart | yangi-sessiya | stop | start | log"
  { [ "$PROFIL" = montaj ] || [ "$PROFIL" = travel ]; } && echo "   Montaj asboblari hali o'rnatilmagan: zsh $KIT/montaj/setup.sh   (10-25 daqiqa)"
  exit 0
else
  ogoh "Ko'prik 150s ichida ko'tarilmadi. Tekshirish: tail -20 ~/jarvis/jarvis.log . Sababni tuzatib, install-server.sh ni qayta ishga tushirish mumkin."
  exit 1
fi
