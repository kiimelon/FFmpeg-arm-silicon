#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

NAME="libzmq"
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
  --without-docs \
  --disable-Werror \
  2>&1 | tee -a "$LOG_FILE"

make $MAKEFLAGS 2>&1 | tee -a "$LOG_FILE"
make install 2>&1 | tee -a "$LOG_FILE"

echo
echo "==== verify libzmq ====" | tee -a "$LOG_FILE"

test -f "$PREFIX/include/zmq.h" \
  && echo "[ok] libzmq header found" | tee -a "$LOG_FILE" \
  || { echo "[fail] missing libzmq header" | tee -a "$LOG_FILE"; exit 1; }

ls "$PREFIX/lib"/libzmq* >/dev/null 2>&1 \
  && echo "[ok] libzmq found" | tee -a "$LOG_FILE" \
  || { echo "[fail] missing libzmq" | tee -a "$LOG_FILE"; exit 1; }

pkg-config --modversion libzmq 2>&1 | tee -a "$LOG_FILE"
pkg-config --libs libzmq 2>&1 | tee -a "$LOG_FILE"
