#!/bin/zsh
# __NAME__ 24/7 dvigateli — HEADLESS. Terminal KERAK EMAS.
# launchd (com.__SLUG__.jarvis, KeepAlive) buni tirik saqlaydi va qulasa qayta ochadi.
# com.__SLUG__.jarvis.watchdog har ~45s tekshiradi: heartbeat + Telegram egaligi
# buzilgan bo'lsa -> launchctl kickstart -k bilan shu loop qayta tug'iladi.
# TTY: `script -q /dev/null` claude interaktiv rejimini terminalsiz ishlatadi.

NODE_BIN="$(ls -d $HOME/.nvm/versions/node/*/bin 2>/dev/null | sort -V | tail -1)"
export PATH="$HOME/.local/bin:$HOME/.bun/bin:${NODE_BIN:+$NODE_BIN:}/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export TELEGRAM_STATE_DIR="$HOME/jarvis/tg"
export CI=1                                          # interaktiv bo'lmagan muhitni bildirish
unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN
# Ixtiyoriy: `claude setup-token` tokeni (Keychain login ishlamasa shu ishlatiladi)
[ -s "$HOME/jarvis/.claude-token" ] && export CLAUDE_CODE_OAUTH_TOKEN="$(cat "$HOME/jarvis/.claude-token")"

LOG="$HOME/jarvis/jarvis.log"
HEARTBEAT="$HOME/jarvis/.heartbeat"

# --- Bitta nusxa kafolati (launchd ustidan qo'shimcha himoya) ---
LOCK="$HOME/jarvis/.loop.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  OLDPID="$(cat "$LOCK/pid" 2>/dev/null)"
  if [ -n "$OLDPID" ] && kill -0 "$OLDPID" 2>/dev/null; then
    echo "[__NAME__] boshqa loop ($OLDPID) ishlayapti — chiqaman $(date '+%F %T')" >> "$LOG"
    exit 0
  fi
  rm -rf "$LOCK"; mkdir "$LOCK" 2>/dev/null || { echo "[__NAME__] lock xato $(date '+%F %T')" >> "$LOG"; exit 1; }
fi
echo $$ > "$LOCK/pid"

# --- Fon heartbeat yozuvchi: loop shell tirikligini watchdog'ga bildiradi ---
( while true; do date '+%s' > "$HEARTBEAT"; sleep 15; done ) &
HB_WRITER=$!

cleanup() { kill "$HB_WRITER" 2>/dev/null; rm -rf "$LOCK"; }
trap cleanup EXIT INT TERM

cd "$HOME/brain" || exit 1
echo "[__NAME__] HEADLESS loop boshlandi $(date '+%F %T') pid=$$ ppid=$PPID" >> "$LOG"

# --- Begona Telegram poller'larni tozalash: __NAME__ yagona egasi bo'lsin ---
sweep_foreign() {
  # Bu loop'ning avlodi BO'LMAGAN har qanday telegram plugin bridge (server.ts) ni o'ldir.
  local p cmd
  for p in $(pgrep -f "claude-plugins-official/telegram" 2>/dev/null); do
    # avlod zanjirini yuqoriga yur — jarvis-loop.sh ko'rinsa, o'zimizniki
    local q="$p" own=0 i
    for i in 1 2 3 4 5 6 7 8 9 10; do
      [ -z "$q" ] && break
      [ "$q" = "1" ] && break
      cmd="$(ps -p "$q" -o command= 2>/dev/null)"
      case "$cmd" in *jarvis/jarvis-loop.sh*) own=1; break;; esac
      q="$(ps -p "$q" -o ppid= 2>/dev/null | tr -d ' ')"
    done
    if [ "$own" -eq 0 ]; then
      echo "[__NAME__] begona telegram bridge o'ldirildi pid=$p $(date '+%F %T')" >> "$LOG"
      kill -9 "$p" 2>/dev/null
    fi
  done
  # o'lik bot.pid / eskirgan .in_use yozuvlarini tozalash
  local bp="$HOME/jarvis/tg/bot.pid"
  if [ -f "$bp" ]; then
    local sp; sp="$(cat "$bp" 2>/dev/null | tr -d ' ')"
    [ -n "$sp" ] && ! kill -0 "$sp" 2>/dev/null && rm -f "$bp"
  fi
  local f n
  for f in "$HOME"/.claude/plugins/cache/claude-plugins-official/telegram/*/.in_use/*(N); do
    n="$(basename "$f")"
    case "$n" in *[!0-9]*) continue;; esac
    kill -0 "$n" 2>/dev/null || rm -f "$f"
  done
}

# --- "QAYTDIM" xabari: sessiya emas, LOOP yuboradi ---------------------------
# Restart eski claude sessiyasini o'ldiradi, shuning uchun xabarni loop o'zi
# Bot API orqali yuboradi. 10 daqiqalik throttle — crash-loop bo'lsa spam bo'lmasin.
QAYTDIM_STAMP="$HOME/jarvis/.qaytdim"
EGA_ID="__TGID__"
qaytdim_yubor() {
  local now prev tok i
  now=$(date '+%s')
  prev=$(cat "$QAYTDIM_STAMP" 2>/dev/null || echo 0)
  [ $(( now - prev )) -lt 600 ] && return 0
  tok="$(grep -m1 '^TELEGRAM_BOT_TOKEN=' "$HOME/jarvis/tg/.env" 2>/dev/null | cut -d= -f2- | tr -d ' \r')"
  [ -z "$tok" ] && return 0
  # bot ko'prigi ko'tarilguncha kut (maks 120s) — erta xabar bermaylik
  i=0
  while [ $i -lt 120 ]; do
    pgrep -f "claude-plugins-official/telegram" >/dev/null 2>&1 && break
    sleep 1; i=$(( i + 1 ))
  done
  pgrep -f "claude-plugins-official/telegram" >/dev/null 2>&1 || {
    echo "[__NAME__] qaytdim: ko'prik ko'tarilmadi $(date '+%F %T')" >> "$LOG"; return 0; }
  sleep 8
  curl -s -m 25 "https://api.telegram.org/bot${tok}/sendMessage" \
    --data-urlencode "chat_id=${EGA_ID}" \
    --data-urlencode "text=Qaytdim. Tizim ko'tarildi, yozishingiz mumkin." >/dev/null 2>&1
  echo "$now" > "$QAYTDIM_STAMP"
  echo "[__NAME__] qaytdim xabari yuborildi $(date '+%F %T')" >> "$LOG"
}

BACKOFF=15
while true; do
  date '+%s' > "$HEARTBEAT"
  # orfan plugin MCP jarayonlarini tozalash
  pkill -9 -f "cache/claude-plugins-official/telegram" 2>/dev/null
  sleep 1
  sweep_foreign

  # Suhbat o'z ID si bilan yuritiladi (--continue EMAS): aks holda ~/brain da ochilgan
  # terminal sessiyasi "oxirgi suhbat" bo'lib qolib, bot o'shani davom ettirib yuborardi.
  # Transkript fayli bor bo'lsa --resume, yo'q bo'lsa (birinchi marta yoki hali xabar
  # kelmagan) --session-id. Teskarisi ikkalasida ham claude darrov xato bilan chiqadi.
  SID="$(cat "$HOME/jarvis/.session-id" 2>/dev/null | tr -d ' \n')"
  if [ -z "$SID" ]; then
    SID="$(uuidgen | tr 'A-Z' 'a-z')"; echo "$SID" > "$HOME/jarvis/.session-id"
  fi
  if ls "$HOME"/.claude/projects/*/"$SID".jsonl >/dev/null 2>&1; then
    SESS=(--resume "$SID")
  else
    SESS=(--session-id "$SID")
  fi

  # claude ko'tarilgach fonda "qaytdim" xabari ketadi
  qaytdim_yubor &

  T0=$(date '+%s')
  # script(1) PTY beradi; TUI chiqishi logni to'ldirmasin -> /dev/null
  # AskUserQuestion taqiqlangan: headless rejimda u sessiyani abadiy qotiradi.
  /usr/bin/script -q /dev/null \
    claude "${SESS[@]}" \
    --channels plugin:telegram@claude-plugins-official \
    --append-system-prompt-file "$HOME/jarvis/JARVIS.md" \
    --dangerously-skip-permissions \
    --disallowedTools AskUserQuestion >/dev/null 2>&1
  RC=$?
  DUR=$(( $(date '+%s') - T0 ))

  # claude 30s dan tez chiqsa (login yo'q, plugin yo'q...) — har 5s da spam qilmaymiz
  if [ "$DUR" -lt 30 ]; then
    echo "[__NAME__] claude ${DUR}s da chiqdi rc=$RC $(date '+%F %T') — ${BACKOFF}s kutaman" >> "$LOG"
    sleep "$BACKOFF"
    BACKOFF=$(( BACKOFF * 2 )); [ "$BACKOFF" -gt 120 ] && BACKOFF=120
  else
    BACKOFF=15
    echo "[__NAME__] claude chiqdi $(date '+%F %T') rc=$RC — 5s keyin qayta" >> "$LOG"
    sleep 5
  fi
done
