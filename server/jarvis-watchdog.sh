#!/bin/zsh
# __NAME__ watchdog (Linux) — __SLUG__-jarvis-watchdog.timer har 60s ishga tushiradi.
# Tekshiradi: servis faolmi, .heartbeat yangimi, Telegram poller (tg/bot.pid) tirikmi va
# aynan jarvis-loop.sh avlodimi. Buzilgan bo'lsa -> systemctl restart. Anti-flap: 200s.
SVC="__SLUG__-jarvis.service"
LOG="$HOME/jarvis/watchdog.log"
HB="$HOME/jarvis/.heartbeat"
BOTPID_FILE="$HOME/jarvis/tg/bot.pid"
LAST_RECYCLE="$HOME/jarvis/.last-recycle"
NOW="$(date +%s)"
log() { echo "[$(date '+%F %T')] $*" >> "$LOG"; }
if [ -f "$LOG" ] && [ "$(wc -l < "$LOG")" -gt 10000 ]; then tail -2000 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"; fi

recycle() {
  local last=0
  [ -f "$LAST_RECYCLE" ] && last="$(cat "$LAST_RECYCLE" 2>/dev/null || echo 0)"
  if [ $(( NOW - last )) -lt 200 ]; then log "SKIP ($1) — $(( NOW - last ))s oldin qayta tug'ilgan"; exit 0; fi
  echo "$NOW" > "$LAST_RECYCLE"
  log "RECYCLE: $1"
  pkill -9 -f "claude-plugins-official/telegram" 2>/dev/null
  rm -f "$BOTPID_FILE"
  systemctl restart "$SVC" >> "$LOG" 2>&1
  exit 0
}

# 0) ega "stop" qilgan bo'lsa (servis o'chirilgan) — tegmaymiz
systemctl is-enabled -q "$SVC" 2>/dev/null || { log "servis o'chirilgan (disabled) — tekshirmayman"; exit 0; }
# 1) servis faolmi
systemctl is-active -q "$SVC" || recycle "servis faol emas"
# 2) grace: servis endi ko'tarilgan bo'lsa (bridge start bo'lyapti) tekshirmaymiz
START="$(date -d "$(systemctl show -p ActiveEnterTimestamp --value "$SVC")" +%s 2>/dev/null || echo 0)"
UP=$(( NOW - START ))
[ "$UP" -lt 150 ] && { log "ok (grace) — servis ${UP}s"; exit 0; }
# 3) heartbeat
if [ -f "$HB" ]; then AGE=$(( NOW - $(stat -c %Y "$HB") )); else AGE=99999; fi
[ "$AGE" -gt 120 ] && recycle "heartbeat eskirgan (${AGE}s)"
# 4) Telegram poller tirik va bizniki
ancestor_is_loop() {
  local p="$1" cmd i
  for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
    [ -z "$p" ] || [ "$p" = 1 ] && return 1
    cmd="$(ps -p "$p" -o args= 2>/dev/null)"
    case "$cmd" in *jarvis/jarvis-loop.sh*) return 0;; esac
    p="$(ps -p "$p" -o ppid= 2>/dev/null | tr -d ' ')"
  done
  return 1
}
BOTPID="$(cat "$BOTPID_FILE" 2>/dev/null | tr -d ' ')"
{ [ -n "$BOTPID" ] && kill -0 "$BOTPID" 2>/dev/null; } || recycle "Telegram poller (bot.pid=${BOTPID:-yo'q}) o'lik"
ancestor_is_loop "$BOTPID" || recycle "Telegram poller __NAME__'niki emas (pid=$BOTPID)"
log "ok — hb ${AGE}s, poller pid=$BOTPID, servis ${UP}s"
