#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

NAME="freetype"
SRC_DIR="$SRC/$NAME"
BUILD_DIR="$BUILD/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$LOGS"

cmake -S "$SRC_DIR" -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DBUILD_SHARED_LIBS=ON \
  2>&1 | tee "$LOG_FILE"

cmake --build "$BUILD_DIR" --parallel "$(sysctl -n hw.ncpu)" \
  2>&1 | tee -a "$LOG_FILE"

cmake --install "$BUILD_DIR" \
  2>&1 | tee -a "$LOG_FILE"

echo "==== verify freetype ====" | tee -a "$LOG_FILE"
test -f "$PREFIX/include/freetype2/freetype/freetype.h" \
  && echo "[ok] freetype headers found" | tee -a "$LOG_FILE" \
  || { echo "[fail] freetype headers missing" | tee -a "$LOG_FILE"; exit 1; }

pkg-config --modversion freetype2 2>&1 | tee -a "$LOG_FILE"
pkg-config --libs freetype2 2>&1 | tee -a "$LOG_FILE"
