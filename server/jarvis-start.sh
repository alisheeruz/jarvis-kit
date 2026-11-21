#!/bin/zsh
# __NAME__ ni qo'l bilan boshqarish (Linux server, systemd):
#   ./jarvis-start.sh status          holat
#   ./jarvis-start.sh restart         qayta ishga tushirish (suhbat davom etadi)
#   ./jarvis-start.sh yangi-sessiya   toza suhbat bilan qayta ishga tushirish
#                                     (bot reaksiya berib, javob yozmay qo'ysa — kontekst shishgan)
#   ./jarvis-start.sh stop            to'xtatish (watchdog ham) — qayta yoqish: start
#   ./jarvis-start.sh start           to'xtatilganni yoqish
#   ./jarvis-start.sh log             jonli log
# restart bitta `systemctl restart` bilan: buyruqni systemd bajaradi, shuning uchun bot o'zi
# chaqirsa ham (o'zini o'ldirsa ham) qayta yoqilish yo'qolmaydi.
SVC="__SLUG__-jarvis"
case "${1:-status}" in
  status)
    systemctl --no-pager -n 0 status "$SVC.service" | head -4
    echo "--- watchdog: $(systemctl is-active "$SVC-watchdog.timer")"
    echo "--- heartbeat: $([ -f "$HOME/jarvis/.heartbeat" ] && echo "$(( $(date +%s) - $(stat -c %Y "$HOME/jarvis/.heartbeat") )) s oldin" || echo yo\'q)"
    BP="$(cat "$HOME/jarvis/tg/bot.pid" 2>/dev/null)"
    echo "--- telegram ko'prik: $([ -n "$BP" ] && kill -0 "$BP" 2>/dev/null && echo "tirik (pid $BP)" || echo "O'LIK")"
    echo "--- oxirgi log ---"; tail -5 "$HOME/jarvis/jarvis.log" 2>/dev/null ;;
  restart)
    systemctl restart "$SVC.service"; echo "qayta ishga tushdi" ;;
  start)
    systemctl enable --now "$SVC.service" "$SVC-watchdog.timer" >/dev/null 2>&1; echo "ishga tushdi" ;;
  yangi-sessiya)
    [ -f "$HOME/jarvis/.session-id" ] && mv "$HOME/jarvis/.session-id" "$HOME/jarvis/.session-id.eski-$(date '+%F-%H%M')"
    systemctl restart "$SVC.service"; echo "toza sessiya bilan ishga tushdi" ;;
  stop)
    systemctl disable --now "$SVC-watchdog.timer" "$SVC.service" >/dev/null 2>&1
    pkill -9 -f "cache/claude-plugins-official/telegram" 2>/dev/null
    rm -rf "$HOME/jarvis/.loop.lock"; echo "to'xtatildi" ;;
  log)
    tail -f "$HOME/jarvis/jarvis.log" "$HOME/jarvis/watchdog.log" ;;
esac
