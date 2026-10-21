#!/bin/zsh
# Montaj qo'llari: python muhit (ffmpeg, o'zbek whisper, rembg, yuz aniqlash), node + Remotion,
# skillar (~/.claude/skills), ~/Montaj papkalari, musiqa/SFX. install.sh PROFIL=montaj bo'lsa chaqiradi,
# alohida ham ishlaydi:  zsh montaj/setup.sh
# Qayta ishga tushirish xavfsiz — bor narsani qayta yuklamaydi. Birinchi marta ~3 GB yuklaydi, 10-25 daqiqa.

M="${0:A:h}"
KIT="${M:h}"
V="$HOME/.venvs/montaj"
LB="$HOME/.local/bin"
export PATH="$LB:/opt/homebrew/bin:/usr/local/bin:$PATH"

ok()   { print -P "%F{green}OK%f  $*"; }
xato() { print -P "%F{red}XATO%f $*"; exit 1; }
ogoh() { print -P "%F{yellow}DIQQAT%f $*"; }
mkdir -p "$LB"

# ---------------------------------------------------------------- 1) python muhit
if ! command -v uv >/dev/null; then
  echo "uv o'rnatilmoqda..."
  curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh >/dev/null 2>&1
  command -v uv >/dev/null || xato "uv o'rnatilmadi. Qo'lda: curl -LsSf https://astral.sh/uv/install.sh | sh"
fi
[ -x "$V/bin/python" ] || uv venv --python 3.12 "$V" >/dev/null 2>&1 || xato "python 3.12 muhit yaratilmadi ($V)"
echo "Python paketlari (birinchi marta 2-5 daqiqa)..."
uv pip install --python "$V/bin/python" -q faster-whisper imageio-ffmpeg pillow numpy "rembg[cpu]" opencv-python-headless \
  || xato "python paketlari o'rnatilmadi (internetni tekshiring, keyin qayta ishga tushiring)"
FFX="$("$V/bin/python" -c 'import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())')"
[ -x "$FFX" ] || xato "ffmpeg binari topilmadi"
ln -sf "$FFX" "$V/bin/ffmpeg"
command -v ffmpeg >/dev/null || ln -sf "$FFX" "$LB/ffmpeg"
"$V/bin/ffmpeg" -hide_banner -encoders 2>/dev/null | grep -q libvpx-vp9 || ogoh "ffmpeg da VP9 yo'q — 'matn odam orqasida' effekti ishlamaydi"
ok "python muhit: $V (ffmpeg, whisper, rembg, opencv)"

# ---------------------------------------------------------------- 2) node (Remotion uchun)
nodever() { "$1" -v 2>/dev/null | tr -d v | cut -d. -f1; }
NODE=""
for n in "$(command -v node)" $HOME/.nvm/versions/node/*/bin/node(N) /opt/homebrew/bin/node /usr/local/bin/node "$HOME/.local/node/bin/node"; do
  [ -x "$n" ] && [ "$(nodever "$n")" -ge 18 ] 2>/dev/null && { NODE="$n"; break; }
done
if [ -z "$NODE" ]; then
  NV=v22.12.0; ARCH=$([ "$(uname -m)" = arm64 ] && echo arm64 || echo x64)
  echo "node $NV yuklanmoqda..."
  T="$(mktemp -d)"
  curl -fsSL "https://nodejs.org/dist/$NV/node-$NV-darwin-$ARCH.tar.gz" | tar -xz -C "$T" || xato "node yuklanmadi"
  rm -rf "$HOME/.local/node"; mv "$T/node-$NV-darwin-$ARCH" "$HOME/.local/node"; rm -rf "$T"
  NODE="$HOME/.local/node/bin/node"
fi
# launchd ostidagi bot nvm/brew ni ko'rmasligi mumkin — ~/.local/bin ga bog'laymiz
for b in node npm npx; do [ -e "$LB/$b" ] || ln -sf "${NODE:h}/$b" "$LB/$b"; done
ok "node $("$NODE" -v) (${NODE})"

# ---------------------------------------------------------------- 3) skillar
mkdir -p "$HOME/.claude/skills"
for s in "$M"/skillar/*(/); do
  d="$HOME/.claude/skills/${s:t}"
  if [ -d "$d" ] && ! diff -rq "$s" "$d" >/dev/null 2>&1; then
    mv "$d" "$d.bak-$(date +%Y%m%d-%H%M%S)"; ogoh "eski ${s:t} skilli zaxiraga ko'chirildi"
  fi
  [ -d "$d" ] || cp -R "$s" "$d"
done
chmod +x "$HOME"/.claude/skills/{motion-montaj,bashar-uslub,ai-broll}/scripts/* 2>/dev/null
ok "skillar: $(ls "$M/skillar" | tr '\n' ' ')→ ~/.claude/skills"

# ---------------------------------------------------------------- 4) papkalar + musiqa/SFX
mkdir -p "$HOME/Montaj"/{kirish,loyihalar,tayyor,musiqa,sfx}
ZIP=""
for z in "$KIT/montaj-media.zip" "$HOME/Downloads/montaj-media.zip" "$HOME/Desktop/montaj-media.zip"; do
  [ -f "$z" ] && { ZIP="$z"; break; }
done
if [ -n "$ZIP" ]; then
  ditto -x -k "$ZIP" "$HOME/Montaj" || xato "$ZIP ochilmadi"
  ok "musiqa/SFX: $ZIP → ~/Montaj ($(find "$HOME/Montaj/musiqa" -type f \( -iname '*.mp3' -o -iname '*.m4a' -o -iname '*.wav' \) | wc -l | tr -d ' ') musiqa, $(find "$HOME/Montaj/sfx" -type f \( -iname '*.mp3' -o -iname '*.wav' -o -iname '*.m4a' \) | wc -l | tr -d ' ') sfx)"
elif [ -z "$(ls -A "$HOME/Montaj/sfx")" ]; then
  ogoh "montaj-media.zip topilmadi — ~/Montaj/musiqa va ~/Montaj/sfx bo'sh. Keyin zipni Downloads ga tashlab setup.sh ni qayta ishga tushiring."
fi

# ---------------------------------------------------------------- 5) modellar (birinchi montaj kutib qolmasin)
[ -s "$V/yunet.onnx" ] || curl -fsSL -o "$V/yunet.onnx" \
  "https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx" \
  || ogoh "YuNet (yuz aniqlash) modeli yuklanmadi"
echo "O'zbek whisper va rembg modellari (birinchi marta ~2 GB)..."
"$V/bin/python" - <<'PY' || xato "modellar yuklanmadi"
from faster_whisper import WhisperModel
WhisperModel("hostmepanda/whisper-large-v3-turbo-uzbek-ct2", device="cpu", compute_type="int8")
from rembg import new_session
new_session("isnet-general-use")
import cv2, os
cv2.FaceDetectorYN.create(os.path.expanduser("~/.venvs/montaj/yunet.onnx"), "", (1080, 1920))
PY
ok "modellar: whisper-uz, rembg, YuNet"

# ---------------------------------------------------------------- 6) Remotion sinov render
S="$HOME/Montaj/loyihalar/_sinov"
if [ -s "$S/out/reel.mp4" ]; then
  ok "Remotion sinovi avval o'tgan ($S/out/reel.mp4)"
else
  echo "Remotion sinov render (3-8 daqiqa)..."
  rm -rf "$S"; mkdir -p "$S"; cp -R "$HOME/.claude/skills/motion-montaj/template/." "$S/"
  ( cd "$S" && npm install --silent >/dev/null 2>&1 && npx remotion render src/index.jsx Reel out/reel.mp4 --crf 23 >"$S/render.log" 2>&1 )
  [ -s "$S/out/reel.mp4" ] || xato "Remotion render ishlamadi — $S/render.log ni o'qing"
  ok "Remotion: namuna render $S/out/reel.mp4"
fi

ok "Montaj tayyor. Xom video: ~/Montaj/kirish · loyihalar: ~/Montaj/loyihalar · tayyor: ~/Montaj/tayyor"
