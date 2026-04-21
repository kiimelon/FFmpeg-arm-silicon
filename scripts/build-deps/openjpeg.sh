#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

NAME="openjpeg"
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
  -DBUILD_CODEC=OFF \
  -DBUILD_JPIP=OFF \
  -DBUILD_JPWL=OFF \
  -DBUILD_DOC=OFF \
  -DBUILD_THIRDPARTY=OFF \
  -DBUILD_TESTING=OFF \
  2>&1 | tee "$LOG_FILE"

cmake --build "$BUILD_DIR" --parallel "$(sysctl -n hw.ncpu)" \
  2>&1 | tee -a "$LOG_FILE"

cmake --install "$BUILD_DIR" \
  2>&1 | tee -a "$LOG_FILE"

echo
echo "==== verify openjpeg ====" | tee -a "$LOG_FILE"

test -f "$PREFIX/include/openjpeg-2.5/openjpeg.h" \
  && echo "[ok] openjpeg header found" | tee -a "$LOG_FILE" \
  || { echo "[fail] missing openjpeg header" | tee -a "$LOG_FILE"; exit 1; }

ls "$PREFIX/lib"/libopenjp2* >/dev/null 2>&1 \
  && echo "[ok] libopenjp2 found" | tee -a "$LOG_FILE" \
  || { echo "[fail] missing libopenjp2" | tee -a "$LOG_FILE"; exit 1; }

pkg-config --modversion libopenjp2 2>&1 | tee -a "$LOG_FILE" || true
pkg-config --libs libopenjp2 2>&1 | tee -a "$LOG_FILE" || true
