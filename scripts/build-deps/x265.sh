#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

if [ -z "${CMAKE_BIN:-}" ]; then
  echo "ERROR: cmake not found in ORIGINAL_PATH"
  exit 1
fi

X265_SRC="$SRC/x265"
X265_BUILD_DIR="$BUILD/x265"
X265_LOG="$LOGS/x265-build.log"

echo "==> Building x265 (CMake)"
echo "Source : $X265_SRC"
echo "Build  : $X265_BUILD_DIR"
echo "Prefix : $PREFIX"
echo "Log    : $X265_LOG"

if [ ! -d "$X265_SRC" ]; then
  echo "ERROR: source directory not found: $X265_SRC"
  exit 1
fi

# x265 uses the source tree's build/linux layout
if [ -d "$X265_SRC/source" ]; then
  X265_SRC_REAL="$X265_SRC/source"
else
  X265_SRC_REAL="$X265_SRC"
fi

rm -rf "$X265_BUILD_DIR"
mkdir -p "$X265_BUILD_DIR" "$LOGS"

{
  echo "ROOT=$ROOT"
  echo "SRC=$SRC"
  echo "BUILD=$BUILD"
  echo "PREFIX=$PREFIX"
  echo "PATH=$PATH"
  echo "ORIGINAL_PATH=$ORIGINAL_PATH"
  echo "CC=$CC"
  echo "CXX=$CXX"
  echo "CFLAGS=$CFLAGS"
  echo "CXXFLAGS=$CXXFLAGS"
  echo "LDFLAGS=$LDFLAGS"
  echo "MAKEFLAGS=$MAKEFLAGS"
  echo "CMAKE_BIN=$CMAKE_BIN"
  echo
  echo "===== cmake configure ====="
} > "$X265_LOG"

"$CMAKE_BIN" -S "$X265_SRC_REAL" -B "$X265_BUILD_DIR" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET" \
  -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
  -DCMAKE_C_COMPILER="$CC" \
  -DCMAKE_CXX_COMPILER="$CXX" \
  -DCMAKE_C_FLAGS="$CFLAGS" \
  -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
  -DENABLE_SHARED=OFF \
  -DENABLE_CLI=OFF \
  -DENABLE_ASSEMBLY=ON \
  >> "$X265_LOG" 2>&1

"$CMAKE_BIN" --build "$X265_BUILD_DIR" >> "$X265_LOG" 2>&1
"$CMAKE_BIN" --install "$X265_BUILD_DIR" >> "$X265_LOG" 2>&1

echo "==> Verifying x265 install"

find "$PREFIX/lib" -maxdepth 1 -name 'libx265*' -print | sort

if [ ! -f "$PREFIX/lib/libx265.a" ]; then
  echo "ERROR: static library not found: $PREFIX/lib/libx265.a"
  exit 1
fi

if [ ! -f "$PREFIX/include/x265.h" ]; then
  echo "ERROR: header not found: $PREFIX/include/x265.h"
  exit 1
fi

if [ ! -f "$PREFIX/lib/pkgconfig/x265.pc" ]; then
  echo "ERROR: pkg-config file not found: $PREFIX/lib/pkgconfig/x265.pc"
  exit 1
fi

echo "==> x265 installed successfully"
ls -l "$PREFIX/lib/libx265.a"
ls -l "$PREFIX/include/x265.h"
ls -l "$PREFIX/lib/pkgconfig/x265.pc"
