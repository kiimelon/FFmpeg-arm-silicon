#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

NAME="dav1d"
SRC_DIR="$SRC/$NAME"
BUILD_DIR="$BUILD/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

rm -rf "$BUILD_DIR"
mkdir -p "$LOGS"

meson setup "$BUILD_DIR" "$SRC_DIR" \
  --buildtype=release \
  --prefix="$PREFIX" \
  2>&1 | tee "$LOG_FILE"

ninja -C "$BUILD_DIR" 2>&1 | tee -a "$LOG_FILE"
ninja -C "$BUILD_DIR" install 2>&1 | tee -a "$LOG_FILE"

echo "==== verify dav1d ====" | tee -a "$LOG_FILE"
ls "$PREFIX/lib"/libdav1d* >/dev/null 2>&1 \
  && echo "[ok] libdav1d found" | tee -a "$LOG_FILE" \
  || { echo "[fail] libdav1d missing" | tee -a "$LOG_FILE"; exit 1; }

pkg-config --modversion dav1d 2>&1 | tee -a "$LOG_FILE"
pkg-config --libs dav1d 2>&1 | tee -a "$LOG_FILE"
