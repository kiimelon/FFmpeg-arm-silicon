#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

NAME="zimg"
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
  2>&1 | tee -a "$LOG_FILE"

make $MAKEFLAGS 2>&1 | tee -a "$LOG_FILE"
make install 2>&1 | tee -a "$LOG_FILE"

echo
echo "==== verify zimg ====" | tee -a "$LOG_FILE"

test -f "$PREFIX/include/zimg.h" \
  && echo "[ok] zimg header found" | tee -a "$LOG_FILE" \
  || { echo "[fail] missing zimg header" | tee -a "$LOG_FILE"; exit 1; }

ls "$PREFIX/lib"/libzimg* >/dev/null 2>&1 \
  && echo "[ok] libzimg found" | tee -a "$LOG_FILE" \
  || { echo "[fail] missing libzimg" | tee -a "$LOG_FILE"; exit 1; }

pkg-config --modversion zimg 2>&1 | tee -a "$LOG_FILE"
pkg-config --libs zimg 2>&1 | tee -a "$LOG_FILE"
