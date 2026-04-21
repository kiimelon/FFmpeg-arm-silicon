#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

NAME="libxml2"
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
  --without-python \
  --without-lzma \
  2>&1 | tee -a "$LOG_FILE"

make $MAKEFLAGS 2>&1 | tee -a "$LOG_FILE"
make install 2>&1 | tee -a "$LOG_FILE"

echo
echo "==== verify libxml2 ====" | tee -a "$LOG_FILE"

test -f "$PREFIX/include/libxml2/libxml/parser.h" \
  && echo "[ok] libxml2 header found" | tee -a "$LOG_FILE" \
  || { echo "[fail] missing libxml2 header" | tee -a "$LOG_FILE"; exit 1; }

ls "$PREFIX/lib"/libxml2* >/dev/null 2>&1 \
  && echo "[ok] libxml2 found" | tee -a "$LOG_FILE" \
  || { echo "[fail] missing libxml2" | tee -a "$LOG_FILE"; exit 1; }

pkg-config --modversion libxml-2.0 2>&1 | tee -a "$LOG_FILE"
pkg-config --libs libxml-2.0 2>&1 | tee -a "$LOG_FILE"
