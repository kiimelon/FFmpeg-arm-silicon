#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

NAME="x264"
SRC_DIR="$SRC/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

mkdir -p "$LOGS"
cd "$SRC_DIR"

make distclean >/dev/null 2>&1 || true

./configure \
  --prefix="$PREFIX" \
  --enable-static \
  --enable-shared \
  --disable-lavf \
  --host=arm64-apple-darwin \
  --extra-cflags="$CFLAGS" \
  --extra-ldflags="$LDFLAGS" \
  2>&1 | tee "$LOG_FILE"

make $MAKEFLAGS 2>&1 | tee -a "$LOG_FILE"
make install 2>&1 | tee -a "$LOG_FILE"

echo "==== verify x264 ====" | tee -a "$LOG_FILE"
test -f "$PREFIX/include/x264.h" \
  && echo "[ok] x264 headers found" | tee -a "$LOG_FILE" \
  || { echo "[fail] x264 headers missing" | tee -a "$LOG_FILE"; exit 1; }

pkg-config --modversion x264 2>&1 | tee -a "$LOG_FILE"
pkg-config --libs x264 2>&1 | tee -a "$LOG_FILE"
