#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

echo "==> Verifying ffmpeg suite"

if [ ! -x "$PREFIX/bin/ffmpeg" ]; then
  echo "ERROR: ffmpeg not found"
  exit 1
fi

if [ ! -x "$PREFIX/bin/ffprobe" ]; then
  echo "ERROR: ffprobe not found"
  exit 1
fi

if [ ! -x "$PREFIX/bin/ffplay" ]; then
  echo "ERROR: ffplay not found"
  exit 1
fi

echo
echo "===== versions ====="
"$PREFIX/bin/ffmpeg" -version
echo
"$PREFIX/bin/ffprobe" -version
echo
"$PREFIX/bin/ffplay" -version
echo

echo "===== encoder checks ====="
"$PREFIX/bin/ffmpeg" -hide_banner -encoders | grep -E 'libx264|libmp3lame|libtheora|libtwolame|libvpx' || true
echo

echo "===== filter checks ====="
"$PREFIX/bin/ffmpeg" -hide_banner -filters | grep subtitles || true
echo

echo "===== linked libraries ====="
otool -L "$PREFIX/bin/ffmpeg" || true
echo
otool -L "$PREFIX/bin/ffprobe" || true
echo
otool -L "$PREFIX/bin/ffplay" || true
echo

echo "==> PASS: fftools basic verification finished"
