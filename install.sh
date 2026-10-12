#!/bin/zsh
# Jarvis o'rnatuvchi (macOS). Mijozning Mac'ida, mijozning foydalanuvchisi ostida ishga tushiriladi:
#   zsh install.sh
# Sozlamalar shu papkadagi sozlama.json dan olinadi; bo'sh qolganlari so'raladi.
# Mavjud ~/jarvis ustiga YOZMAYDI (boshqa Jarvis o'rnatilgan mashinani buzmaslik uchun).

KIT="${0:A:h}"
SH="$KIT/shablon"
J="$HOME/jarvis"
B="$HOME/brain"
PY=/usr/bin/python3
export PATH="$HOME/.local/bin:$HOME/.bun/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

ok()   { print -P "%F{green}OK%f  $*"; }
xato() { print -P "%F{red}XATO%f $*"; exit 1; }
ogoh() { print -P "%F{yellow}DIQQAT%f $*"; }

# ---------------------------------------------------------------- 0) tekshiruv
[ "$(uname)" = "Darwin" ] || xato "Bu o'rnatuvchi faqat macOS uchun."
# $J/.kit-chala = shu o'rnatuvchining o'zi boshlab, tugata olmagan o'rnatish — uni davom ettirish mumkin.
CHALA="$J/.kit-chala"
if [ ! -e "$CHALA" ]; then
  [ -e "$J/jarvis-loop.sh" ] && xato "$J/jarvis-loop.sh allaqachon bor — bu mashinada Jarvis o'rnatilgan. To'xtadim, hech narsaga tegmadim."
  ls "$HOME/Library/LaunchAgents" 2>/dev/null | grep -q '\.jarvis\.plist$' && xato "LaunchAgents ichida boshqa *.jarvis.plist bor. To'xtadim."
else
  ogoh "Tugallanmagan o'rnatish topildi — davom ettiryapman."
fi
xcode-select -p >/dev/null 2>&1 || xato "Xcode Command Line Tools yo'q. Avval: xcode-select --install"
command -v claude >/dev/null || xato "Claude Code yo'q. Avval: curl -fsSL https://claude.ai/install.sh | bash   (keyin yangi Terminal oching)"
if ! command -v bun >/dev/null; then
  echo "bun o'rnatilmoqda..."
  curl -fsSL https://bun.sh/install | bash >/dev/null 2>&1
  command -v bun >/dev/null || xato "bun o'rnatilmadi. Qo'lda: curl -fsSL https://bun.sh/install | bash"
fi
ok "macOS, python3, claude $(claude --version 2>/dev/null | cut -d' ' -f1), bun $(bun --version)"

claude auth status >/dev/null 2>&1 || xato "Claude'ga login qilinmagan. Avval Terminalda \`claude\` ni oching, mijozning akkaunti bilan kiring, chiqing va install.sh ni qayta ishga tushiring."
ok "Claude login bor"

# ---------------------------------------------------------------- 1) sozlama
oqi() { "$PY" -c 'import json,sys; v=json.load(open(sys.argv[1])).get(sys.argv[2],""); print(" ".join(map(str,v)) if isinstance(v,list) else ("" if v is None else str(v).strip()))' "$KIT/sozlama.json" "$1" 2>/dev/null; }
sora() {
  local v; v="$(oqi "$1")"
  while [ -z "$v" ]; do
    printf "%s: " "$2" >&2
    read -r v || { print -u2 "\nKiritish uzildi — sozlama.json ni to'ldiring."; exit 1; }
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
XODIMLAR="$(oqi XODIMLAR)"

# sora() $(...) ichida ishlaydi — undagi exit faqat ichki qobiqni to'xtatadi, shuning uchun bu yerda tekshiramiz
for v in "$OWNER" "$NAME" "$BIZ" "$GOAL" "$TGID" "$TOKEN"; do
  [ -n "$v" ] || xato "Sozlama to'liq emas. $KIT/sozlama.json da OWNER, JARVIS, BIZ, GOAL, SLUG, TGID, BOT_TOKEN ni to'ldiring."
done
[ -n "$SLUG" ] || xato "SLUG bo'sh (faqat a-z va 0-9)."
case "$TGID" in ''|*[!0-9]*) xato "Telegram ID faqat raqam bo'lishi kerak: '$TGID'";; esac

BOTUSER="$(curl -s -m 20 "https://api.telegram.org/bot${TOKEN}/getMe" | "$PY" -c 'import json,sys; d=json.load(sys.stdin); print(d["result"]["username"] if d.get("ok") else "")' 2>/dev/null)"
[ -n "$BOTUSER" ] || xato "Bot token ishlamadi (getMe). Tokenni tekshiring yoki internetni."
ok "Bot: @$BOTUSER · ega: $OWNER ($TGID) · $BIZ"

# ---------------------------------------------------------------- 2) fayllar
mkdir -p "$J/tg/inbox" "$B/1-tizim" "$B/3-shaxsiy" "$B/9-arxiv" \
         "$B/2-biznes/obyektlar" "$B/2-biznes/kontent" "$B/2-biznes/reklama" \
         "$B/2-biznes/hisobotlar" "$B/2-biznes/sayt" "$B/2-biznes/mijozlar"
touch "$CHALA"

quy() {   # quy <shablon> <manzil> — __KALIT__ larni almashtirib yozadi
  OWNER="$OWNER" NAME="$NAME" BIZ="$BIZ" GOAL="$GOAL" SLUG="$SLUG" TGID="$TGID" UY="$HOME" \
  "$PY" - "$1" "$2" <<'PY'
import os, sys
s = open(sys.argv[1], encoding="utf-8").read()
for k, e in (("__OWNER__", "OWNER"), ("__NAME__", "NAME"), ("__BIZ__", "BIZ"), ("__GOAL__", "GOAL"),
             ("__SLUG__", "SLUG"), ("__TGID__", "TGID"), ("__HOME__", "UY")):
    s = s.replace(k, os.environ[e])
open(sys.argv[2], "w", encoding="utf-8").write(s)
PY
}

quy "$SH/jarvis-loop.sh"     "$J/jarvis-loop.sh"
quy "$SH/jarvis-watchdog.sh" "$J/jarvis-watchdog.sh"
quy "$SH/jarvis-start.sh"    "$J/jarvis-start.sh"
quy "$SH/JARVIS.md"          "$J/JARVIS.md"
cp  "$SH/ovoz.py" "$SH/patch-telegram-plugin.sh" "$J/"
chmod +x "$J"/*.sh "$J"/*.py
[ -e "$B/CLAUDE.md" ] || quy "$SH/brain-CLAUDE.md" "$B/CLAUDE.md"
[ -e "$B/1-tizim/biznes.md" ] || printf '# %s\n\nEgasi: %s\nMaqsad: %s\n\n(Bu faylni to'"'"'ldiring: nima sotiladi, qayerda, narx oralig'"'"'i, kim mijoz, aloqa raqamlari, ijtimoiy tarmoq havolalari.)\n' "$BIZ" "$OWNER" "$GOAL" > "$B/1-tizim/biznes.md"

stub() { [ -e "$1" ] || printf '%b\n' "$2" > "$1"; }
stub "$B/1-tizim/uslub.md"   "# Uslub\n\nFaqat o'zbekcha (lotin), har doim \"siz\", qisqa. Ega bergan \"doim / hech qachon\" qoidalari shu yerga sana bilan yoziladi."
stub "$B/1-tizim/kalitlar.md" "# Kalitlar xaritasi (qiymatsiz)\n\nBarcha kalitlar ~/jarvis/.env da. Bu faylda faqat nomi va nima uchunligi yoziladi."
stub "$B/1-tizim/texnik.md"  "# Tizim holati\n\n- $(date '+%F') · o'rnatildi: Telegram bot, ovoz. Meta, e'lon, sayt — hali ulanmagan."
stub "$B/2-biznes/tasklar.md" "# Tasklar"
stub "$B/3-shaxsiy/ega.md"   "# $OWNER\n\n(Ish vaqti, qanday xabar yoqadi, nimani yoqtirmaydi.)"

umask 077
printf 'TELEGRAM_BOT_TOKEN=%s\n' "$TOKEN" > "$J/tg/.env"
[ -e "$J/.env" ] || {
  printf '# %s kalitlari. Bu faylni hech kimga yubormang.\nGEMINI_API_KEY=%s\nGEMINI_MODEL=gemini-flash-latest\n\n# Meta (Instagram/Facebook/reklama) — 2-bosqichda to'"'"'ldiriladi\nMETA_TOKEN=\nMETA_ACT=\nIG_USER_ID=\nFB_PAGE_ID=\n\n# Reklama kunlik byudjetining qattiq chegarasi (target.py shundan oshirmaydi)\nKUNLIK_BYUDJET_MAX=\n' "$NAME" "$GEMINI" > "$J/.env"
}
TGID="$TGID" XODIMLAR="$XODIMLAR" BOTUSER="$BOTUSER" "$PY" - "$J/tg/access.json" <<'PY'
import json, os, sys
ids = [os.environ["TGID"]] + [x for x in os.environ["XODIMLAR"].split() if x.isdigit()]
json.dump({"dmPolicy": "allowlist", "allowFrom": ids, "groups": {}, "pending": {},
           "mentionPatterns": ["@" + os.environ["BOTUSER"]], "ackReaction": "👀"},
          open(sys.argv[1], "w", encoding="utf-8"), ensure_ascii=False, indent=2)
PY
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
  ogoh "Plugin patchi tushmadi (plugin versiyasi yangilangan bo'lishi mumkin). Bot ishlaydi, lekin shu Mac'da boshqa \`claude\` oynasi ochilsa bot 1-2 daqiqaga uzilishi mumkin."
fi

# ---------------------------------------------------------------- 4) claude sozlamalari
# Headless sessiya hech qanday dialogda qotmasligi kerak: xavfli-rejim tasdig'i va ~/brain ishonch oynasi.
B="$B" "$PY" - <<'PY'
import json, os, shutil, time
def yukla(p):
    try:
        return json.load(open(p, encoding="utf-8"))
    except FileNotFoundError:
        return {}
def saqla(p, d):
    if os.path.exists(p):
        shutil.copy2(p, p + ".jarvis-bak-" + time.strftime("%Y%m%d-%H%M%S"))
    os.makedirs(os.path.dirname(p), exist_ok=True)
    json.dump(d, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
h = os.path.expanduser("~")
p = h + "/.claude/settings.json"; s = yukla(p)
if s.get("skipDangerousModePermissionPrompt") is not True:
    s["skipDangerousModePermissionPrompt"] = True; saqla(p, s)
p = h + "/.claude.json"; c = yukla(p)
pr = c.setdefault("projects", {}).setdefault(os.environ["B"], {})
if pr.get("hasTrustDialogAccepted") is not True or c.get("hasCompletedOnboarding") is not True:
    pr["hasTrustDialogAccepted"] = True; c["hasCompletedOnboarding"] = True; saqla(p, c)
PY
[ $? -eq 0 ] || xato "Claude sozlamalarini yozib bo'lmadi (~/.claude/settings.json yoki ~/.claude.json buzuq JSON?)."
ok "Claude sozlamalari"

# ---------------------------------------------------------------- 5) launchd
L="$HOME/Library/LaunchAgents"; mkdir -p "$L"
quy "$SH/jarvis.plist"          "$L/com.$SLUG.jarvis.plist"
quy "$SH/jarvis.watchdog.plist" "$L/com.$SLUG.jarvis.watchdog.plist"
U="$(id -u)"
# qayta urinishda eski nusxa yuklangan bo'lishi mumkin
launchctl bootout "gui/$U/com.$SLUG.jarvis.watchdog" 2>/dev/null
launchctl bootout "gui/$U/com.$SLUG.jarvis" 2>/dev/null
launchctl bootstrap "gui/$U" "$L/com.$SLUG.jarvis.plist" || xato "launchd: jarvis yuklanmadi"
ok "launchd: com.$SLUG.jarvis"

echo "Bot ko'tarilishini kutyapman (2 daqiqagacha)..."
i=0
while [ $i -lt 150 ]; do
  BP="$(cat "$J/tg/bot.pid" 2>/dev/null)"
  [ -n "$BP" ] && kill -0 "$BP" 2>/dev/null && break
  sleep 3; i=$(( i + 3 ))
done
if [ -n "$BP" ] && kill -0 "$BP" 2>/dev/null; then
  # watchdog ko'prik ko'tarilgandan KEYIN ulanadi — aks holda start paytida botni behuda qayta tug'diradi
  launchctl bootstrap "gui/$U" "$L/com.$SLUG.jarvis.watchdog.plist" || xato "launchd: watchdog yuklanmadi"
  rm -f "$CHALA"
  ok "$NAME ishlayapti (watchdog ulandi). Telegramda @$BOTUSER ga yozing."
  echo "   Eslatma: ega avval botga /start bosishi kerak — aks holda bot unga yoza olmaydi."
  echo "   Boshqarish: ~/jarvis/jarvis-start.sh status | restart | yangi-sessiya | stop | log"
else
  ogoh "Ko'prik 150s ichida ko'tarilmadi. Tekshirish: tail -20 ~/jarvis/jarvis.log . Sababni tuzatib, install.sh ni qayta ishga tushirish mumkin."
  exit 1
fi
