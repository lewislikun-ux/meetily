#!/bin/bash
# T1 spike: transcription quality matrix for SME Centre recordings.
# Usage: ./transcribe_matrix.sh <audio-or-video-file> [label]
#
# Converts the input to 16 kHz mono WAV, then runs the pass matrix used to
# pick production transcription settings for the CRM (division/hq minutes
# pipeline). Local only - nothing leaves this Mac.
#
# Passes:
#   v3-auto-tr  large-v3, auto language + translate (the app's "Auto Detect (Translate to English)")
#   v3-en       large-v3, English only (baseline for en-SG)
#   v3-zh-tr    large-v3, Mandarin forced + translate (mixed-meeting candidate)
#
# Notes: turbo is intentionally absent - turbo does not translate (verified 12 Oct).
set -e
IN="$1"
if [ -z "$IN" ] || [ ! -f "$IN" ]; then echo "usage: $0 <audiofile> [label]"; exit 1; fi
LABEL="${2:-$(basename "$IN" | tr ' .' '__')}"
WS="$HOME/.hermes/cache/scratch/whisper-cpp-test"
MODELS="$HOME/Library/Application Support/com.meetily.ai/models"
OUT="$HOME/.hermes/cache/scratch/t1-matrix"
[ -x "$WS/build/bin/whisper-cli" ] || { echo "whisper-cli missing at $WS/build/bin"; exit 1; }
mkdir -p "$OUT"
WAV="$OUT/$LABEL-16k.wav"

echo "== converting to 16 kHz mono wav =="
ffmpeg -y -v error -i "$IN" -ar 16000 -ac 1 "$WAV"
ls -la "$WAV"

run() {
  NAME="$1"; shift
  echo; echo "=== PASS: $NAME ==="
  { /usr/bin/time -p "$WS/build/bin/whisper-cli" -f "$WAV" -nt -t 8 "$@"; } 2>&1 | tee "$OUT/$LABEL-$NAME.txt"
}

run v3-auto-tr -m "$MODELS/ggml-large-v3.bin" -l auto -tr
run v3-en      -m "$MODELS/ggml-large-v3.bin" -l en
run v3-zh-tr   -m "$MODELS/ggml-large-v3.bin" -l zh -tr

echo; echo "== outputs in $OUT =="
ls -la "$OUT"
