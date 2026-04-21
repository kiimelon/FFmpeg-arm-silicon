#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

NAME="libvpx"
SRC_DIR="$SRC/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

mkdir -p "$LOGS"
cd "$SRC_DIR"

make distclean >/dev/null 2>&1 || true

./configure \
  --prefix="$PREFIX" \
  --target=arm64-darwin20-gcc \
  --enable-vp8 \
  --enable-vp9 \
  --enable-shared \
  --enable-static \
  --disable-examples \
  --disable-tools \
  --disable-docs \
  --disable-unit-tests \
  2>&1 | tee "$LOG_FILE"

make $MAKEFLAGS 2>&1 | tee -a "$LOG_FILE"
make install 2>&1 | tee -a "$LOG_FILE"

echo "==== fix libvpx install_name ====" | tee -a "$LOG_FILE"

for dylib in "$PREFIX"/lib/libvpx*.dylib; do
  [ -e "$dylib" ] || continue
  install_name_tool -id "$dylib" "$dylib"
  otool -D "$dylib" 2>&1 | tee -a "$LOG_FILE"
done

echo "==== verify libvpx ====" | tee -a "$LOG_FILE"
ls "$PREFIX/lib"/libvpx* >/dev/null 2>&1 \
  && echo "[ok] libvpx found" | tee -a "$LOG_FILE" \
  || { echo "[fail] libvpx missing" | tee -a "$LOG_FILE"; exit 1; }

pkg-config --modversion vpx 2>&1 | tee -a "$LOG_FILE"
pkg-config --libs vpx 2>&1 | tee -a "$LOG_FILE"
