#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

if [ -z "${CMAKE_BIN:-}" ]; then
  echo "ERROR: cmake not found in ORIGINAL_PATH"
  exit 1
fi

SDL2_SRC="$SRC/SDL"
SDL2_BUILD_DIR="$BUILD/SDL2"
SDL2_LOG="$LOGS/sdl2-build.log"

echo "==> Building SDL2 (CMake)"
echo "Source : $SDL2_SRC"
echo "Build  : $SDL2_BUILD_DIR"
echo "Prefix : $PREFIX"
echo "Log    : $SDL2_LOG"

if [ ! -d "$SDL2_SRC" ]; then
  echo "ERROR: source directory not found: $SDL2_SRC"
  exit 1
fi

rm -rf "$SDL2_BUILD_DIR"
mkdir -p "$BUILD" "$LOGS"

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
} > "$SDL2_LOG"

"$CMAKE_BIN" -S "$SDL2_SRC" -B "$SDL2_BUILD_DIR" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET" \
  -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
  -DCMAKE_C_COMPILER="$CC" \
  -DCMAKE_C_FLAGS="$CFLAGS" \
  -DSDL_SHARED=OFF \
  -DSDL_STATIC=ON \
  -DSDL_TEST=OFF \
  -DSDL_TEST_LIBRARY=OFF \
  >> "$SDL2_LOG" 2>&1

"$CMAKE_BIN" --build "$SDL2_BUILD_DIR" >> "$SDL2_LOG" 2>&1
"$CMAKE_BIN" --install "$SDL2_BUILD_DIR" >> "$SDL2_LOG" 2>&1

echo "==> Verifying SDL2 install"

find "$PREFIX/lib" -maxdepth 1 -name 'libSDL2*' -print | sort

if [ ! -f "$PREFIX/lib/libSDL2.a" ]; then
  echo "ERROR: static library not found: $PREFIX/lib/libSDL2.a"
  exit 1
fi

if [ ! -f "$PREFIX/include/SDL2/SDL.h" ]; then
  echo "ERROR: header not found: $PREFIX/include/SDL2/SDL.h"
  exit 1
fi

if [ ! -f "$PREFIX/lib/pkgconfig/sdl2.pc" ]; then
  echo "ERROR: pkg-config file not found: $PREFIX/lib/pkgconfig/sdl2.pc"
  exit 1
fi

echo "==> SDL2 installed successfully"
ls -l "$PREFIX/lib/libSDL2.a"
ls -l "$PREFIX/include/SDL2/SDL.h"
ls -l "$PREFIX/lib/pkgconfig/sdl2.pc"
