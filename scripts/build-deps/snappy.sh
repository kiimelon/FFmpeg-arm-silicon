#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

NAME="snappy"
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
  -DSNAPPY_BUILD_TESTS=OFF \
  -DSNAPPY_BUILD_BENCHMARKS=OFF \
  2>&1 | tee "$LOG_FILE"

cmake --build "$BUILD_DIR" --parallel "$(sysctl -n hw.ncpu)" \
  2>&1 | tee -a "$LOG_FILE"

cmake --install "$BUILD_DIR" \
  2>&1 | tee -a "$LOG_FILE"

echo
echo "==== verify snappy ====" | tee -a "$LOG_FILE"

test -f "$PREFIX/include/snappy.h" \
  && echo "[ok] snappy header found" | tee -a "$LOG_FILE" \
  || { echo "[fail] missing snappy header" | tee -a "$LOG_FILE"; exit 1; }

ls "$PREFIX/lib"/libsnappy* >/dev/null 2>&1 \
  && echo "[ok] libsnappy found" | tee -a "$LOG_FILE" \
  || { echo "[fail] missing libsnappy" | tee -a "$LOG_FILE"; exit 1; }

pkg-config --modversion snappy 2>&1 | tee -a "$LOG_FILE" || true
pkg-config --libs snappy 2>&1 | tee -a "$LOG_FILE" || true
