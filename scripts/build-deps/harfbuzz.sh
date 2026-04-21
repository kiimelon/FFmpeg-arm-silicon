#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

NAME="harfbuzz"
SRC_DIR="$SRC/$NAME"
BUILD_DIR="$BUILD/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

rm -rf "$BUILD_DIR"
mkdir -p "$LOGS"

meson setup "$BUILD_DIR" "$SRC_DIR" \
  --buildtype=release \
  --prefix="$PREFIX" \
  -Dfreetype=enabled \
  2>&1 | tee "$LOG_FILE"

ninja -C "$BUILD_DIR" 2>&1 | tee -a "$LOG_FILE"
ninja -C "$BUILD_DIR" install 2>&1 | tee -a "$LOG_FILE"

echo "==== verify harfbuzz ====" | tee -a "$LOG_FILE"
test -f "$PREFIX/include/harfbuzz/hb.h" \
  && echo "[ok] harfbuzz headers found" | tee -a "$LOG_FILE" \
  || { echo "[fail] harfbuzz headers missing" | tee -a "$LOG_FILE"; exit 1; }

pkg-config --modversion harfbuzz 2>&1 | tee -a "$LOG_FILE"
pkg-config --libs harfbuzz 2>&1 | tee -a "$LOG_FILE"
