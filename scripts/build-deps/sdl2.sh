#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

NAME="SDL"
SRC_DIR="$SRC/$NAME"
BUILD_DIR="$BUILD/sdl2"
LOG_FILE="$LOGS/sdl2-build.log"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$LOGS"

cmake -S "$SRC_DIR" -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DSDL_SHARED=ON \
  -DSDL_STATIC=ON \
  2>&1 | tee "$LOG_FILE"

cmake --build "$BUILD_DIR" --parallel "$(sysctl -n hw.ncpu)" \
  2>&1 | tee -a "$LOG_FILE"

cmake --install "$BUILD_DIR" \
  2>&1 | tee -a "$LOG_FILE"

echo "==== verify sdl2 ====" | tee -a "$LOG_FILE"
pkg-config --modversion sdl2 2>&1 | tee -a "$LOG_FILE" || true
pkg-config --libs sdl2 2>&1 | tee -a "$LOG_FILE" || true
ls "$PREFIX/lib"/libSDL2* >/dev/null 2>&1 \
  && echo "[ok] libSDL2 found" | tee -a "$LOG_FILE" \
  || { echo "[fail] libSDL2 missing" | tee -a "$LOG_FILE"; exit 1; }
