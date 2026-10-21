#!/bin/zsh
# Montaj Jarvis — FAQAT TERMINAL (Telegram bot, launchd yo'q). Mijozning Mac'ida:
#   zsh ~/jarvis-kit/montaj/terminal-install.sh
# ~/brain (konstitutsiya + xotira) ni yaratadi, keyin montaj/setup.sh ni ishga tushiradi.
# Sozlama: ~/jarvis-kit/sozlama.json dan OWNER, JARVIS, BIZ, GOAL, GEMINI_API_KEY (ixtiyoriy).
# Mavjud ~/brain/CLAUDE.md ustiga YOZMAYDI.

M="${0:A:h}"
KIT="${M:h}"
SH="$KIT/shablon/montaj"
B="$HOME/brain"
PY=/usr/bin/python3
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

ok()   { print -P "%F{green}OK%f  $*"; }
xato() { print -P "%F{red}XATO%f $*"; exit 1; }
ogoh() { print -P "%F{yellow}DIQQAT%f $*"; }

# ---------------------------------------------------------------- 0) tekshiruv
[ "$(uname)" = "Darwin" ] || xato "Bu o'rnatuvchi faqat macOS uchun."
xcode-select -p >/dev/null 2>&1 || xato "Xcode Command Line Tools yo'q. Avval: xcode-select --install"
command -v claude >/dev/null || xato "Claude Code yo'q. Avval: curl -fsSL https://claude.ai/install.sh | bash   (keyin yangi Terminal oching)"
claude auth status >/dev/null 2>&1 || xato "Claude'ga login qilinmagan. Avval \`claude\` ni oching, mijoz akkaunti bilan kiring, chiqing va qayta ishga tushiring."
[ "$(uname -m)" = arm64 ] || ogoh "Bu Intel Mac — whisper va render sekin bo'ladi (Apple Silicon tavsiya)."
RAM=$(( $(sysctl -n hw.memsize) / 1073741824 ))
[ "$RAM" -ge 16 ] || ogoh "RAM ${RAM} GB — 16 GB dan kam, uzun videolarda render sekin yoki xatoli bo'lishi mumkin."
BOSH=$(( $(df -k "$HOME" | awk 'NR==2{print $4}') / 1048576 ))
[ "$BOSH" -ge 15 ] || xato "Bo'sh joy ${BOSH} GB — kamida 15 GB kerak (modellar ~3 GB + loyihalar)."
ok "macOS $(uname -m), ${RAM} GB RAM, ${BOSH} GB bo'sh, claude $(claude --version 2>/dev/null | cut -d' ' -f1)"

# ---------------------------------------------------------------- 1) sozlama
oqi() { "$PY" -c 'import json,sys; v=json.load(open(sys.argv[1])).get(sys.argv[2],""); print("" if v is None else str(v).strip())' "$KIT/sozlama.json" "$1" 2>/dev/null; }
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
BIZ="$(sora BIZ "Ish / biznes nomi")"
GOAL="$(sora GOAL "Asosiy maqsad (bir jumla)")"
GEMINI="$(oqi GEMINI_API_KEY)"
for v in "$OWNER" "$NAME" "$BIZ" "$GOAL"; do
  [ -n "$v" ] || xato "Sozlama to'liq emas: $KIT/sozlama.json da OWNER, JARVIS, BIZ, GOAL ni to'ldiring."
done
ok "Ega: $OWNER · $BIZ · yordamchi: $NAME (faqat terminal)"

# ---------------------------------------------------------------- 2) ~/brain
mkdir -p "$B/1-tizim" "$B/3-shaxsiy" "$B/9-arxiv" "$B/2-biznes"/{mijozlar,montaj,kontent,reklama,hisobotlar}
quy() {
  OWNER="$OWNER" NAME="$NAME" BIZ="$BIZ" GOAL="$GOAL" "$PY" - "$1" "$2" <<'PY'
import os, sys
s = open(sys.argv[1], encoding="utf-8").read()
for k, e in (("__OWNER__", "OWNER"), ("__NAME__", "NAME"), ("__BIZ__", "BIZ"), ("__GOAL__", "GOAL")):
    s = s.replace(k, os.environ[e])
# Telegram yo'q: rol bo'limida ID o'rniga terminal
s = s.replace("Telegram ID __TGID__", "terminal egasi")
open(sys.argv[2], "w", encoding="utf-8").write(s)
PY
}
if [ -e "$B/CLAUDE.md" ]; then
  ogoh "$B/CLAUDE.md allaqachon bor — tegmadim."
else
  quy "$SH/brain-CLAUDE.md" "$B/CLAUDE.md"
fi
stub() { [ -e "$1" ] || printf '%b\n' "$2" > "$1"; }
stub "$B/1-tizim/uslub.md"   "# Uslub\n\nFaqat o'zbekcha (lotin), har doim \"siz\", qisqa. Ega bergan \"doim / hech qachon\" qoidalari shu yerga sana bilan yoziladi."
stub "$B/1-tizim/montaj-qoidalari.md" "# Montaj qoidalari\n\nEga montajni tanqid qilsa yoki maqtasa — shu yerga sana bilan yoziladi (umumiy did). Bitta mijozga xos qoida — mijoz fayliga.\n\n- $(date '+%F') · boshlang'ich: keskin punch-zoom yo'q, matn yuzga tushmaydi, kadr doim ko'rinadi, fon musiqasi har doim (motion-montaj SKILL.md, Qat'iy saboqlar)."
stub "$B/1-tizim/kalitlar.md" "# Kalitlar xaritasi (qiymatsiz)\n\nBarcha kalitlar ~/jarvis/.env da. Bu faylda faqat nomi va nima uchunligi.\n\n- GEMINI_API_KEY — ai-broll (AI rasm/video kadrlar)"
stub "$B/1-tizim/texnik.md"  "# Tizim holati\n\n- $(date '+%F') · o'rnatildi: faqat terminal (Telegram yo'q), montaj asboblari (montaj/setup.sh)."
stub "$B/2-biznes/montaj/navbat.md" "# Montaj navbati\n\n| sana | mijoz | material | talab | holat |\n|---|---|---|---|---|"
stub "$B/2-biznes/tasklar.md" "# Tasklar"
stub "$B/3-shaxsiy/ega.md"   "# $OWNER\n\n(Ish vaqti, montaj didi, nimani yoqtirmaydi.)"
# ai-broll kalitni ~/jarvis/.env dan o'qiydi
mkdir -p "$HOME/jarvis"
[ -e "$HOME/jarvis/.env" ] || ( umask 077; printf '# %s kalitlari. Bu faylni hech kimga yubormang.\nGEMINI_API_KEY=%s\n' "$NAME" "$GEMINI" > "$HOME/jarvis/.env" )
ok "Xotira: $B"

# ishga tushirish buyrug'i: Terminalda `jarvis` deb yozsa ~/brain da Claude ochiladi
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/jarvis" <<'EOF'
#!/bin/zsh
cd "$HOME/brain" && exec claude "$@"
EOF
chmod +x "$HOME/.local/bin/jarvis"
ok "Buyruq: Terminalda  jarvis  (yoki: cd ~/brain && claude)"

# ---------------------------------------------------------------- 3) montaj asboblari
zsh "$M/setup.sh" || xato "Montaj asboblari to'liq o'rnatilmadi — yuqoridagi XATO ni tuzatib, shu skriptni qayta ishga tushiring (bor narsani qayta yuklamaydi)."

[ -n "$GEMINI" ] && "$PY" - "$KIT/sozlama.json" <<'PY'
import json, sys
p = sys.argv[1]; d = json.load(open(p)); d["GEMINI_API_KEY"] = ""; json.dump(d, open(p, "w"), ensure_ascii=False, indent=2)
PY
echo
ok "$NAME tayyor. Yangi Terminal oching va yozing:  jarvis"
echo "   Xom videolar: ~/Montaj/kirish · tayyor: ~/Montaj/tayyor"
