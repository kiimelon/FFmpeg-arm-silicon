#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

NAME="libass"
SRC_DIR="$SRC/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

mkdir -p "$LOGS"
cd "$SRC_DIR"

make distclean >/dev/null 2>&1 || true

if [ ! -x "./configure" ]; then
  autoreconf -fiv 2>&1 | tee "$LOG_FILE"
else
  : > "$LOG_FILE"
fi

./configure \
  --prefix="$PREFIX" \
  --host=arm-apple-darwin \
  2>&1 | tee -a "$LOG_FILE"

make $MAKEFLAGS 2>&1 | tee -a "$LOG_FILE"
make install 2>&1 | tee -a "$LOG_FILE"

echo "==== verify libass ====" | tee -a "$LOG_FILE"
test -f "$PREFIX/include/ass/ass.h" \
  && echo "[ok] libass headers found" | tee -a "$LOG_FILE" \
  || { echo "[fail] libass headers missing" | tee -a "$LOG_FILE"; exit 1; }

pkg-config --modversion libass 2>&1 | tee -a "$LOG_FILE"
pkg-config --libs libass 2>&1 | tee -a "$LOG_FILE"
