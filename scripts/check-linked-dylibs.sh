#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

check_one() {
  local bin="$1"
  echo "==> $bin"
  otool -L "$bin" | tail -n +2
  echo
  echo "--- local dylibs ---"
  otool -L "$bin" | grep "$PREFIX/lib" || true
  echo
  echo "--- @rpath dylibs ---"
  otool -L "$bin" | grep '@rpath' || true
  echo
}

check_one "$PREFIX/bin/ffmpeg"
check_one "$PREFIX/bin/ffprobe"
check_one "$PREFIX/bin/ffplay"
