#!/bin/zsh
# Ovoz/video fayldan so'zma-so'z vaqt belgilari bilan o'zbekcha transkripsiya.
# Ishlatish: transcribe.sh <audio yoki video> <loyiha papkasi>
# Natija: <loyiha>/public/audio.m4a, <loyiha>/words.json, <loyiha>/xom_matn.txt
set -e
IN="$1"; PRJ="$2"
V=~/.venvs/montaj
[ -x "$V/bin/ffmpeg" ] || { echo "~/.venvs/montaj topilmadi (ffmpeg + faster-whisper kerak)"; exit 1; }
mkdir -p "$PRJ/public"
"$V/bin/ffmpeg" -v error -y -i "$IN" -vn -ac 2 -ar 44100 -c:a aac -b:a 160k "$PRJ/public/audio.m4a"
"$V/bin/ffmpeg" -v error -y -i "$IN" -vn -ac 1 -ar 16000 "$PRJ/_asr.wav"
"$V/bin/python" - "$PRJ" <<'PY'
import sys, json
from faster_whisper import WhisperModel
prj = sys.argv[1]
m = WhisperModel("hostmepanda/whisper-large-v3-turbo-uzbek-ct2", device="cpu", compute_type="int8")
segs, _ = m.transcribe(prj + "/_asr.wav", language="uz", word_timestamps=True, vad_filter=True,
                       vad_parameters=dict(min_silence_duration_ms=300), beam_size=5, condition_on_previous_text=False)
words, lines = [], []
for s in segs:
    lines.append(f"[{s.start:6.2f}-{s.end:6.2f}] {s.text.strip()}")
    words += [{"s": round(w.start, 2), "e": round(w.end, 2), "t": w.word.strip()} for w in s.words]
json.dump(words, open(prj + "/words.json", "w"), ensure_ascii=False)
open(prj + "/xom_matn.txt", "w").write("\n".join(lines) + "\n")
print("\n".join(lines)); print(f"\n{len(words)} so'z -> {prj}/words.json")
PY
rm -f "$PRJ/_asr.wav"
