#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

NAME="libwebp"
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
  -DWEBP_BUILD_ANIM_UTILS=OFF \
  -DWEBP_BUILD_CWEBP=OFF \
  -DWEBP_BUILD_DWEBP=OFF \
  -DWEBP_BUILD_GIF2WEBP=OFF \
  -DWEBP_BUILD_IMG2WEBP=OFF \
  -DWEBP_BUILD_VWEBP=OFF \
  -DWEBP_BUILD_WEBPINFO=OFF \
  -DWEBP_BUILD_WEBPMUX=OFF \
  -DWEBP_BUILD_EXTRAS=OFF \
  -DWEBP_BUILD_LIBWEBPMUX=ON \
  -DWEBP_BUILD_LIBWEBPDEMUX=ON \
  2>&1 | tee "$LOG_FILE"

cmake --build "$BUILD_DIR" --parallel "$(sysctl -n hw.ncpu)" \
  2>&1 | tee -a "$LOG_FILE"

cmake --install "$BUILD_DIR" \
  2>&1 | tee -a "$LOG_FILE"

echo
echo "==== verify libwebp ====" | tee -a "$LOG_FILE"

test -f "$PREFIX/include/webp/decode.h" \
  && echo "[ok] libwebp headers found" | tee -a "$LOG_FILE" \
  || { echo "[fail] missing libwebp headers" | tee -a "$LOG_FILE"; exit 1; }

ls "$PREFIX/lib"/libwebp* >/dev/null 2>&1 \
  && echo "[ok] libwebp found" | tee -a "$LOG_FILE" \
  || { echo "[fail] missing libwebp" | tee -a "$LOG_FILE"; exit 1; }

pkg-config --modversion libwebp 2>&1 | tee -a "$LOG_FILE" || true
pkg-config --libs libwebp 2>&1 | tee -a "$LOG_FILE" || true
