#!/bin/zsh
# __NAME__ watchdog — har ~45s (com.__SLUG__.jarvis.watchdog, StartInterval).
# Tekshiradi:
#   1) com.__SLUG__.jarvis launchd job yuklanganmi
#   2) jarvis-loop.sh jarayoni tirikmi
#   3) .heartbeat yangimi (loop shell tirikligi)
#   4) Telegram poller (tg/bot.pid) tirikmi VA aynan __NAME__ loop'ining avlodimi
# Biror shart buzilsa -> `launchctl kickstart -k` bilan __NAME__'ni qayta tug'diradi.
# Anti-flap: 200s ichida ikki marta qayta ishga tushirmaydi.

UID_N="$(id -u)"
SVC="gui/$UID_N/com.__SLUG__.jarvis"
PLIST="$HOME/Library/LaunchAgents/com.__SLUG__.jarvis.plist"
LOG="$HOME/jarvis/watchdog.log"
HB="$HOME/jarvis/.heartbeat"
BOTPID_FILE="$HOME/jarvis/tg/bot.pid"
LAST_RECYCLE="$HOME/jarvis/.last-recycle"
NOW="$(date +%s)"

log() { echo "[$(date '+%F %T')] $*" >> "$LOG"; }

# log faylni cheklab tur (10000 qatordan oshsa kes)
if [ -f "$LOG" ] && [ "$(wc -l < "$LOG" 2>/dev/null || echo 0)" -gt 10000 ]; then
  tail -2000 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

recycle() {
  local reason="$1" last=0
  [ -f "$LAST_RECYCLE" ] && last="$(cat "$LAST_RECYCLE" 2>/dev/null || echo 0)"
  if [ $(( NOW - last )) -lt 200 ]; then
    log "SKIP ($reason) — $(( NOW - last ))s oldin qayta tug'ilgan, kutaman"
    exit 0
  fi
  echo "$NOW" > "$LAST_RECYCLE"
  log "RECYCLE: $reason"
  pkill -9 -f "claude-plugins-official/telegram" 2>/dev/null
  rm -f "$BOTPID_FILE"
  if launchctl print "$SVC" >/dev/null 2>&1; then
    launchctl kickstart -k "$SVC" >> "$LOG" 2>&1
  else
    launchctl bootstrap "gui/$UID_N" "$PLIST" >> "$LOG" 2>&1
  fi
  exit 0
}

# --- 1) launchd job yuklanganmi ---
if ! launchctl print "$SVC" >/dev/null 2>&1; then
  log "launchd job yuklanmagan — bootstrap"
  launchctl bootstrap "gui/$UID_N" "$PLIST" >> "$LOG" 2>&1
  echo "$NOW" > "$LAST_RECYCLE"
  exit 0
fi

# --- 2) jarvis-loop.sh jarayoni bormi ---
LOOP_PIDS="$(pgrep -f 'jarvis/jarvis-loop.sh' 2>/dev/null)"
if [ -z "$LOOP_PIDS" ]; then
  recycle "jarvis-loop.sh jarayoni yo'q"
fi

# loop qancha vaqt ishlayapti (eng eski jarvis-loop.sh jarayoni; macOS ps -> lstart)
LOOP_UPTIME=999999
for lp in ${(f)LOOP_PIDS}; do
  ls_str="$(ps -p "$lp" -o lstart= 2>/dev/null)"
  [ -z "$ls_str" ] && continue
  st="$(date -j -f '%a %b %e %T %Y' "$ls_str" +%s 2>/dev/null)"
  case "$st" in ''|*[!0-9]*) continue;; esac
  up=$(( NOW - st ))
  [ "$up" -lt "$LOOP_UPTIME" ] && LOOP_UPTIME="$up"
done
# o'qib bo'lmasa 999999 qoladi -> grace berilmaydi, to'liq tekshiruv ishlaydi

# --- 3) heartbeat yangimi (fayl MTIME bo'yicha — kontent o'qish poyga xatosini bermaydi) ---
if [ ! -f "$HB" ]; then
  # yangi loop 5s ichida yaratadi — bir marta qayta tekshirib ko'ramiz
  sleep 3
  [ -f "$HB" ] || recycle "heartbeat fayli yo'q"
fi
HBM="$(stat -f %m "$HB" 2>/dev/null)"
case "$HBM" in ''|*[!0-9]*) HBM="$NOW";; esac   # stat xato bersa — bu tsiklda tinch qo'y
AGE=$(( NOW - HBM ))
if [ "$AGE" -gt 120 ]; then
  # ikkinchi o'qish bilan tasdiqlaymiz (transient xatolardan himoya)
  sleep 2
  HBM2="$(stat -f %m "$HB" 2>/dev/null || echo "$NOW")"
  case "$HBM2" in ''|*[!0-9]*) HBM2="$NOW";; esac
  if [ $(( $(date +%s) - HBM2 )) -gt 120 ]; then
    recycle "heartbeat eskirgan (${AGE}s)"
  fi
fi

# --- 4) Telegram poller __NAME__'ning avlodimi ---
# Grace: loop endi ko'tarilgan bo'lsa (bridge hali start bo'lyapti) tekshirmaymiz.
if [ "$LOOP_UPTIME" -lt 90 ]; then
  log "ok (grace) — loop ${LOOP_UPTIME}s, hb ${AGE}s, bridge start bo'lyapti"
  exit 0
fi

ancestor_is_loop() {
  local p="$1" cmd i
  for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
    [ -z "$p" ] && return 1
    [ "$p" = "1" ] && return 1
    cmd="$(ps -p "$p" -o command= 2>/dev/null)"
    case "$cmd" in *jarvis/jarvis-loop.sh*) return 0;; esac
    p="$(ps -p "$p" -o ppid= 2>/dev/null | tr -d ' ')"
  done
  return 1
}

BOTPID=""
[ -f "$BOTPID_FILE" ] && BOTPID="$(cat "$BOTPID_FILE" 2>/dev/null | tr -d ' ')"
if [ -z "$BOTPID" ] || ! kill -0 "$BOTPID" 2>/dev/null; then
  recycle "Telegram poller (bot.pid=${BOTPID:-yo'q}) o'lik"
fi
if ! ancestor_is_loop "$BOTPID"; then
  recycle "Telegram poller __NAME__'niki emas (pid=$BOTPID boshqa sessiya)"
fi

log "ok — hb ${AGE}s, poller pid=$BOTPID (__NAME__), loop=$(echo $LOOP_PIDS | tr '\n' ' ')"
exit 0
