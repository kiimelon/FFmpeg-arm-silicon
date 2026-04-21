#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

NAME="libsoxr"
SRC_DIR="$SRC/$NAME"
BUILD_DIR="$BUILD/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$LOGS"

cmake -S "$SRC_DIR" -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DBUILD_SHARED_LIBS=ON \
  -DWITH_OPENMP=OFF \
  -DBUILD_TESTS=OFF \
  2>&1 | tee "$LOG_FILE"

cmake --build "$BUILD_DIR" --parallel "$(sysctl -n hw.ncpu)" \
  2>&1 | tee -a "$LOG_FILE"

cmake --install "$BUILD_DIR" \
  2>&1 | tee -a "$LOG_FILE"

echo
echo "==== verify libsoxr ====" | tee -a "$LOG_FILE"

test -f "$PREFIX/include/soxr.h" \
  && echo "[ok] libsoxr header found" | tee -a "$LOG_FILE" \
  || { echo "[fail] missing libsoxr header" | tee -a "$LOG_FILE"; exit 1; }

ls "$PREFIX/lib"/libsoxr* >/dev/null 2>&1 \
  && echo "[ok] libsoxr found" | tee -a "$LOG_FILE" \
  || { echo "[fail] missing libsoxr" | tee -a "$LOG_FILE"; exit 1; }

pkg-config --modversion soxr 2>&1 | tee -a "$LOG_FILE" || true
pkg-config --libs soxr 2>&1 | tee -a "$LOG_FILE" || true
