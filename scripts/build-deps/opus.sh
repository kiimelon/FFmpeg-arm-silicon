#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

NAME="opus"
SRC_DIR="$SRC/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

mkdir -p "$LOGS"
cd "$SRC_DIR"

make distclean >/dev/null 2>&1 || true

./autogen.sh 2>&1 | tee "$LOG_FILE"

./configure \
  --prefix="$PREFIX" \
  --host=arm-apple-darwin \
  --disable-asm \
  2>&1 | tee -a "$LOG_FILE"

make $MAKEFLAGS 2>&1 | tee -a "$LOG_FILE"
make install 2>&1 | tee -a "$LOG_FILE"

echo "==== verify opus ====" | tee -a "$LOG_FILE"
test -f "$PREFIX/include/opus/opus.h" \
  && echo "[ok] opus headers found" | tee -a "$LOG_FILE" \
  || { echo "[fail] opus headers missing" | tee -a "$LOG_FILE"; exit 1; }

pkg-config --modversion opus 2>&1 | tee -a "$LOG_FILE"
pkg-config --libs opus 2>&1 | tee -a "$LOG_FILE"
