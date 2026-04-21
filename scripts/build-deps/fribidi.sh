#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

NAME="fribidi"
SRC_DIR="$SRC/$NAME"
BUILD_DIR="$BUILD/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

rm -rf "$BUILD_DIR"
mkdir -p "$LOGS"

meson setup "$BUILD_DIR" "$SRC_DIR" \
  --buildtype=release \
  --prefix="$PREFIX" \
  -Ddocs=false \
  2>&1 | tee "$LOG_FILE"

ninja -C "$BUILD_DIR" 2>&1 | tee -a "$LOG_FILE"
ninja -C "$BUILD_DIR" install 2>&1 | tee -a "$LOG_FILE"

echo "==== verify fribidi ====" | tee -a "$LOG_FILE"
test -f "$PREFIX/include/fribidi/fribidi.h" \
  && echo "[ok] fribidi headers found" | tee -a "$LOG_FILE" \
  || { echo "[fail] fribidi headers missing" | tee -a "$LOG_FILE"; exit 1; }

pkg-config --modversion fribidi 2>&1 | tee -a "$LOG_FILE"
pkg-config --libs fribidi 2>&1 | tee -a "$LOG_FILE"
