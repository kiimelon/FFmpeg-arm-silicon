#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

if [ -z "${CMAKE_BIN:-}" ]; then
  echo "ERROR: cmake not found in ORIGINAL_PATH"
  exit 1
fi

BROTLI_SRC="$SRC/brotli"
BROTLI_BUILD_DIR="$BUILD/brotli"
BROTLI_BUILD_LOG="$LOGS/brotli-build.log"
BROTLI_INSTALL_LOG="$LOGS/brotli-install.log"

echo "==> Building brotli (CMake)"
echo "Source : $BROTLI_SRC"
echo "Build  : $BROTLI_BUILD_DIR"
echo "Prefix : $PREFIX"
echo "Logs   : $LOGS"

if [ ! -d "$BROTLI_SRC" ]; then
  echo "ERROR: source directory not found: $BROTLI_SRC"
  exit 1
fi

rm -rf "$BROTLI_BUILD_DIR"
mkdir -p "$BROTLI_BUILD_DIR"

{
  echo "ROOT=$ROOT"
  echo "SRC=$SRC"
  echo "BUILD=$BUILD"
  echo "PREFIX=$PREFIX"
  echo "PATH=$PATH"
  echo "ORIGINAL_PATH=$ORIGINAL_PATH"
  echo "CC=$CC"
  echo "CFLAGS=$CFLAGS"
  echo "CXX=$CXX"
  echo "CXXFLAGS=$CXXFLAGS"
  echo "LDFLAGS=$LDFLAGS"
  echo "MAKEFLAGS=$MAKEFLAGS"
  echo "CMAKE_BIN=$CMAKE_BIN"
  echo
  echo "===== cmake configure ====="
} > "$BROTLI_BUILD_LOG"

"$CMAKE_BIN" -S "$BROTLI_SRC" -B "$BROTLI_BUILD_DIR" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET" \
  -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
  -DCMAKE_C_COMPILER="$CC" \
  -DCMAKE_CXX_COMPILER="$CXX" \
  -DCMAKE_C_FLAGS="$CFLAGS" \
  -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
  -DBUILD_SHARED_LIBS=OFF \
  -DBROTLI_DISABLE_TESTS=ON \
  >> "$BROTLI_BUILD_LOG" 2>&1

"$CMAKE_BIN" --build "$BROTLI_BUILD_DIR" >> "$BROTLI_BUILD_LOG" 2>&1

{
  echo "===== cmake install ====="
} > "$BROTLI_INSTALL_LOG"

"$CMAKE_BIN" --install "$BROTLI_BUILD_DIR" >> "$BROTLI_INSTALL_LOG" 2>&1

echo "==> Verifying brotli install"

if [ ! -f "$PREFIX/include/brotli/decode.h" ]; then
  echo "ERROR: header not found: $PREFIX/include/brotli/decode.h"
  exit 1
fi

if [ ! -f "$PREFIX/lib/pkgconfig/libbrotlidec.pc" ]; then
  echo "ERROR: pkg-config file not found: $PREFIX/lib/pkgconfig/libbrotlidec.pc"
  exit 1
fi

echo "==> brotli installed successfully"
ls -l "$PREFIX/include/brotli/decode.h"
ls -l "$PREFIX/lib/pkgconfig/libbrotlidec.pc"

find "$PREFIX/lib" -maxdepth 1 \( -name 'libbrotli*.a' -o -name 'libbrotli*.dylib' \) -print
