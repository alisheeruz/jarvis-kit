#!/bin/zsh
# __NAME__ ni qo'l bilan boshqarish. Bot Terminalsiz, launchd ostida ishlaydi:
#   com.__SLUG__.jarvis (KeepAlive) -> caffeinate -> jarvis-loop.sh -> script(PTY) -> claude --channels
#
#   ./jarvis-start.sh status          holat
#   ./jarvis-start.sh restart         qayta ishga tushirish (suhbat davom etadi)
#   ./jarvis-start.sh yangi-sessiya   toza suhbat bilan qayta ishga tushirish
#                                     (bot reaksiya berib, javob yozmay qo'ysa — kontekst shishgan)
#   ./jarvis-start.sh stop            to'xtatish (watchdog ham)
#   ./jarvis-start.sh log             jonli log
L="$HOME/Library/LaunchAgents"
SVC="com.__SLUG__.jarvis"
UID_N="$(id -u)"

toxtat() {
  launchctl bootout "gui/$UID_N/$SVC.watchdog" 2>/dev/null
  launchctl bootout "gui/$UID_N/$SVC" 2>/dev/null
  pkill -f "jarvis/jarvis-loop.sh" 2>/dev/null
  pkill -9 -f "cache/claude-plugins-official/telegram" 2>/dev/null
  rm -rf "$HOME/jarvis/.loop.lock"
  sleep 2
}
boshla() {
  launchctl bootstrap "gui/$UID_N" "$L/$SVC.plist"
  launchctl bootstrap "gui/$UID_N" "$L/$SVC.watchdog.plist"
}

case "${1:-status}" in
  status)
    launchctl print "gui/$UID_N/$SVC" 2>/dev/null | grep -E "state =|pid =|last exit code" || echo "launchd job yuklanmagan"
    echo "--- heartbeat ---"
    if [ -f "$HOME/jarvis/.heartbeat" ]; then
      echo "$(( $(date +%s) - $(cat "$HOME/jarvis/.heartbeat") )) s oldin"
    else echo "yo'q"; fi
    echo "--- telegram ko'prik ---"
    BP="$(cat "$HOME/jarvis/tg/bot.pid" 2>/dev/null)"
    if [ -n "$BP" ] && kill -0 "$BP" 2>/dev/null; then echo "tirik (pid $BP)"; else echo "O'LIK"; fi
    echo "--- oxirgi log ---"
    tail -5 "$HOME/jarvis/jarvis.log" 2>/dev/null
    ;;
  restart)
    toxtat; boshla
    echo "qayta ishga tushdi"
    ;;
  yangi-sessiya)
    toxtat
    rm -f "$HOME/jarvis/.started"
    # eski transkriptlar arxivga: aks holda keyingi --continue yana eskisini ochadi
    P="$HOME/.claude/projects/$(echo "$HOME/brain" | sed 's#[/.]#-#g')"
    if [ -d "$P" ]; then
      A="$HOME/.claude/sessiya-arxiv/$(date '+%F-%H%M')"; mkdir -p "$A"
      mv "$P"/*.jsonl "$A"/ 2>/dev/null
    fi
    boshla
    echo "toza sessiya bilan ishga tushdi"
    ;;
  stop)
    toxtat
    echo "to'xtatildi"
    ;;
  log)
    tail -f "$HOME/jarvis/jarvis.log" "$HOME/jarvis/watchdog.log"
    ;;
esac
