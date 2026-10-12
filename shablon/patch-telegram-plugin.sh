#!/bin/zsh
# Telegram plugin'ga LOKAL patchlar (ikkitasi mustaqil, har biri o'z belgisi
# bilan tekshiriladi — bittasi borligi ikkinchisini qo'llashga to'sqinlik
# qilmaydi):
#   1) audio    — reply tool audio fayllarni hujjat emas, ovoz/audio sifatida yuborsin.
#   2) sole-owner — faqat jarvis-loop.sh avlodi (Stark) boshqa poller'ni
#      o'ldirishga haqli; begona (oddiy `claude`) sessiya jonli poller topsa
#      o'ldirmaydi, pid faylni bosib yozmaydi, polling qilmaydi — shu bilan
#      Stark bitta bot tokenining yagona egasi bo'lib qoladi.
# Plugin yangilanганда (versiya o'zgаrsa) qaytadan ishga tushir:
#   zsh ~/jarvis/patch-telegram-plugin.sh
set -e
BASE="$HOME/.claude/plugins/cache/claude-plugins-official/telegram"
VER_DIR="$(ls -d "$BASE"/*/ 2>/dev/null | sort -V | tail -1)"
F="${VER_DIR}server.ts"
[ -f "$F" ] || { echo "server.ts topilmadi: $F"; exit 1; }

[ -f "$F.orig.bak" ] || cp "$F" "$F.orig.bak"

NEED_AUDIO=1
grep -q "LOKAL PATCH (jarvis): audio fayllar" "$F" && NEED_AUDIO=0
NEED_OWNER=1
grep -q "LOKAL PATCH (jarvis): bir nechta Claude Code sessiyasi" "$F" && NEED_OWNER=0

if [ "$NEED_AUDIO" = 0 ] && [ "$NEED_OWNER" = 0 ]; then
  echo "ikkala patch ham allaqachon bor: $F"; exit 0
fi

NEED_AUDIO="$NEED_AUDIO" NEED_OWNER="$NEED_OWNER" python3 - "$F" <<'PY'
import os, sys
f = sys.argv[1]
s = open(f, encoding="utf-8").read()
need_audio = os.environ["NEED_AUDIO"] == "1"
need_owner = os.environ["NEED_OWNER"] == "1"

if need_audio:
    anchor = "const PHOTO_EXTS = new Set(['.jpg', '.jpeg', '.png', '.gif', '.webp'])"
    add = ("\n// LOKAL PATCH (jarvis): audio fayllar hujjat emas, ovoz/audio sifatida ketsin.\n"
           "const VOICE_EXTS = new Set(['.ogg', '.oga', '.opus'])\n"
           "const AUDIO_EXTS = new Set(['.mp3', '.m4a', '.aac', '.wav', '.flac'])")
    assert anchor in s, "anchor (PHOTO_EXTS) topilmadi — plugin tuzilishi o'zgargan"
    s = s.replace(anchor, anchor + add, 1)

    old = (
"          if (PHOTO_EXTS.has(ext)) {\n"
"            const sent = await bot.api.sendPhoto(chat_id, input, opts)\n"
"            sentIds.push(sent.message_id)\n"
"          } else {\n"
"            const sent = await bot.api.sendDocument(chat_id, input, opts)\n"
"            sentIds.push(sent.message_id)\n"
"          }")
    new = (
"          if (PHOTO_EXTS.has(ext)) {\n"
"            const sent = await bot.api.sendPhoto(chat_id, input, opts)\n"
"            sentIds.push(sent.message_id)\n"
"          } else if (VOICE_EXTS.has(ext)) {\n"
"            const sent = await bot.api.sendVoice(chat_id, input, opts)\n"
"            sentIds.push(sent.message_id)\n"
"          } else if (AUDIO_EXTS.has(ext)) {\n"
"            const sent = await bot.api.sendAudio(chat_id, input, opts)\n"
"            sentIds.push(sent.message_id)\n"
"          } else {\n"
"            const sent = await bot.api.sendDocument(chat_id, input, opts)\n"
"            sentIds.push(sent.message_id)\n"
"          }")
    assert old in s, "reply fayl-handler bloki topilmadi — plugin tuzilishi o'zgargan"
    s = s.replace(old, new, 1)
    print("audio patch qo'llandi")

if need_owner:
    anchor = (
"const INBOX_DIR = join(STATE_DIR, 'inbox')\n"
"const PID_FILE = join(STATE_DIR, 'bot.pid')\n"
"\n"
"// Telegram allows exactly one getUpdates consumer per token. If a previous\n"
"// session crashed (SIGKILL, terminal closed) its server.ts grandchild can\n"
"// survive as an orphan and hold the slot forever, so every new session sees\n"
"// 409 Conflict. Kill any stale holder before we start polling.\n"
"mkdirSync(STATE_DIR, { recursive: true, mode: 0o700 })\n"
"try {\n"
"  const stale = parseInt(readFileSync(PID_FILE, 'utf8'), 10)\n"
"  if (stale > 1 && stale !== process.pid) {\n"
"    process.kill(stale, 0)\n"
"    // PID files race with OS PID recycling — verify the holder is actually a\n"
"    // server.ts process before SIGTERM. Otherwise a recycled PID can point at\n"
"    // our own bun-run wrapper (kills our stdin → immediate self-shutdown) or\n"
"    // an unrelated user process.\n"
"    const cmd = execFileSync('ps', ['-p', String(stale), '-o', 'args='], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] })\n"
"    if (cmd.includes('server.ts')) {\n"
"      process.stderr.write(`telegram channel: replacing stale poller pid=${stale}\\n`)\n"
"      process.kill(stale, 'SIGTERM')\n"
"    }\n"
"  }\n"
"} catch {}\n"
"writeFileSync(PID_FILE, String(process.pid))")
    replacement = (
"const INBOX_DIR = join(STATE_DIR, 'inbox')\n"
"const PID_FILE = join(STATE_DIR, 'bot.pid')\n"
"\n"
"// LOKAL PATCH (jarvis): bir nechta Claude Code sessiyasi bitta bot tokenini\n"
"// bo'lishishi mumkin (Stark 24/7 jarvis-loop.sh ostida, + har qanday oddiy\n"
"// `claude` sessiyasi ham plugin global yoqilgani uchun). Faqat jarvis-loop.sh\n"
"// avlodi bo'lgan sessiyagina \"yagona egasi\" sifatida boshqalarni o'ldirishga\n"
"// haqli. Begona (jarvis bo'lmagan) sessiya jonli pollerni topsa — o'ldirmaydi,\n"
"// pid faylni ham bosib yozmaydi, shunchaki polling qilmasdan ishlayveradi.\n"
"function isJarvisOwned(): boolean {\n"
"  let pid = process.ppid\n"
"  for (let i = 0; i < 12 && pid && pid !== 1; i++) {\n"
"    let cmd: string\n"
"    try {\n"
"      cmd = execFileSync('ps', ['-p', String(pid), '-o', 'command='], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] })\n"
"    } catch { return false }\n"
"    if (cmd.includes('jarvis-loop.sh')) return true\n"
"    try {\n"
"      pid = parseInt(execFileSync('ps', ['-p', String(pid), '-o', 'ppid='], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim(), 10)\n"
"    } catch { return false }\n"
"  }\n"
"  return false\n"
"}\n"
"const IS_JARVIS = isJarvisOwned()\n"
"let ownPidFile = true\n"
"\n"
"// Telegram allows exactly one getUpdates consumer per token. If a previous\n"
"// session crashed (SIGKILL, terminal closed) its server.ts grandchild can\n"
"// survive as an orphan and hold the slot forever, so every new session sees\n"
"// 409 Conflict. Kill any stale holder before we start polling — but only if\n"
"// we are the Stark/jarvis session; a foreign session yields instead.\n"
"mkdirSync(STATE_DIR, { recursive: true, mode: 0o700 })\n"
"try {\n"
"  const stale = parseInt(readFileSync(PID_FILE, 'utf8'), 10)\n"
"  if (stale > 1 && stale !== process.pid) {\n"
"    process.kill(stale, 0)\n"
"    // PID files race with OS PID recycling — verify the holder is actually a\n"
"    // server.ts process before SIGTERM. Otherwise a recycled PID can point at\n"
"    // our own bun-run wrapper (kills our stdin → immediate self-shutdown) or\n"
"    // an unrelated user process.\n"
"    const cmd = execFileSync('ps', ['-p', String(stale), '-o', 'args='], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] })\n"
"    if (cmd.includes('server.ts')) {\n"
"      if (IS_JARVIS) {\n"
"        process.stderr.write(`telegram channel: replacing stale poller pid=${stale}\\n`)\n"
"        process.kill(stale, 'SIGTERM')\n"
"      } else {\n"
"        process.stderr.write(`telegram channel: another poller (pid=${stale}) is active and not ours to replace — running without polling\\n`)\n"
"        ownPidFile = false\n"
"      }\n"
"    }\n"
"  }\n"
"} catch {}\n"
"if (ownPidFile) writeFileSync(PID_FILE, String(process.pid))")
    assert anchor in s, "pid-lock bloki topilmadi — plugin tuzilishi o'zgargan"
    s = s.replace(anchor, replacement, 1)

    old_iife = (
"void (async () => {\n"
"  for (let attempt = 1; ; attempt++) {")
    new_iife = (
"// LOKAL PATCH (jarvis): begona (jarvis bo'lmagan) sessiya, jonli poller\n"
"// borligi sababli pid faylni olmagan bo'lsa — umuman poll qilmaydi, faqat\n"
"// chiquvchi (reply/send) toollar ishlayveradi.\n"
"if (ownPidFile) void (async () => {\n"
"  for (let attempt = 1; ; attempt++) {")
    assert old_iife in s, "polling IIFE topilmadi — plugin tuzilishi o'zgargan"
    s = s.replace(old_iife, new_iife, 1)
    print("sole-owner patch qo'llandi")

open(f, "w", encoding="utf-8").write(s)
PY

echo "Bridge'ni qayta yuklash: launchctl kickstart -k gui/$(id -u)/$(ls ~/Library/LaunchAgents | grep -m1 "\.jarvis\.plist$" | sed "s/\.plist$//")"
