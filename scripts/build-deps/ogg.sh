#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

NAME="libogg"
SRC_DIR="$SRC/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

mkdir -p "$LOGS"
cd "$SRC_DIR"

make distclean >/dev/null 2>&1 || true

autoreconf -fiv 2>&1 | tee "$LOG_FILE"

./configure \
  --prefix="$PREFIX" \
  --host=arm-apple-darwin \
  2>&1 | tee -a "$LOG_FILE"

make $MAKEFLAGS 2>&1 | tee -a "$LOG_FILE"
make install 2>&1 | tee -a "$LOG_FILE"

echo "==== verify libogg ====" | tee -a "$LOG_FILE"
test -f "$PREFIX/include/ogg/ogg.h" \
  && echo "[ok] libogg headers found" | tee -a "$LOG_FILE" \
  || { echo "[fail] libogg headers missing" | tee -a "$LOG_FILE"; exit 1; }

pkg-config --modversion ogg 2>&1 | tee -a "$LOG_FILE"
pkg-config --libs ogg 2>&1 | tee -a "$LOG_FILE"
