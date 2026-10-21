#!/bin/zsh
# Xom videoni loyiha uchun tayyorlaydi: 1080x1920, 30 kadr/s, kerak bo'lsa bo'lak kesib oladi.
# Ishlatish: prep.sh <xom video> <loyiha papkasi> [boshlanish_s] [tugash_s]
# Natija: <loyiha>/public/main.mp4  (S-Log3 material bo'lsa avval ~/.venvs/montaj/pipeline dagi LUT bilan rang bering)
set -e
IN="$1"; PRJ="$2"; SS="${3:-0}"; TO="$4"
FF=~/.venvs/montaj/bin/ffmpeg
mkdir -p "$PRJ/public"
CUT=(); [ -n "$TO" ] && CUT=(-to "$TO")
"$FF" -v error -y -ss "$SS" "${CUT[@]}" -i "$IN" \
  -vf "fps=30,scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,setsar=1" \
  -c:v libx264 -crf 16 -preset fast -pix_fmt yuv420p -c:a aac -b:a 192k "$PRJ/public/main.mp4"
"$FF" -hide_banner -i "$PRJ/public/main.mp4" 2>&1 | grep Duration
