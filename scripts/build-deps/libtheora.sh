#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

NAME="libtheora"
SRC_DIR="$SRC/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

mkdir -p "$LOGS"
cd "$SRC_DIR"

make distclean >/dev/null 2>&1 || true

if [ ! -x "./configure" ]; then
  ./autogen.sh 2>&1 | tee "$LOG_FILE"
else
  : > "$LOG_FILE"
fi

./configure \
  --prefix="$PREFIX" \
  --host=arm-apple-darwin \
  --disable-asm \
  --disable-examples \
  CFLAGS="$CFLAGS -Wno-error" \
  2>&1 | tee -a "$LOG_FILE"

make $MAKEFLAGS 2>&1 | tee -a "$LOG_FILE"
make install 2>&1 | tee -a "$LOG_FILE"

echo
echo "==== verify libtheora ====" | tee -a "$LOG_FILE"

test -f "$PREFIX/include/theora/theoraenc.h" \
  && echo "[ok] libtheora header found" | tee -a "$LOG_FILE" \
  || { echo "[fail] missing libtheora header" | tee -a "$LOG_FILE"; exit 1; }

ls "$PREFIX/lib"/libtheora* >/dev/null 2>&1 \
  && echo "[ok] libtheora found" | tee -a "$LOG_FILE" \
  || { echo "[fail] missing libtheora" | tee -a "$LOG_FILE"; exit 1; }

pkg-config --modversion theora 2>&1 | tee -a "$LOG_FILE"
pkg-config --libs theora 2>&1 | tee -a "$LOG_FILE"
