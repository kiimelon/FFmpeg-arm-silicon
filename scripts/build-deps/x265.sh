#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

NAME="x265"
SRC_DIR="$SRC/$NAME"
SOURCE_DIR="$SRC_DIR/source"
BUILD_DIR="$BUILD/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$LOGS"

cmake -S "$SOURCE_DIR" -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  2>&1 | tee "$LOG_FILE"

cmake --build "$BUILD_DIR" --parallel "$(sysctl -n hw.ncpu)" \
  2>&1 | tee -a "$LOG_FILE"

cmake --install "$BUILD_DIR" \
  2>&1 | tee -a "$LOG_FILE"

echo "==== verify x265 ====" | tee -a "$LOG_FILE"
ls "$PREFIX/lib"/libx265* >/dev/null 2>&1 \
  && echo "[ok] libx265 found" | tee -a "$LOG_FILE" \
  || { echo "[fail] libx265 missing" | tee -a "$LOG_FILE"; exit 1; }

pkg-config --modversion x265 2>&1 | tee -a "$LOG_FILE"
pkg-config --libs x265 2>&1 | tee -a "$LOG_FILE"
