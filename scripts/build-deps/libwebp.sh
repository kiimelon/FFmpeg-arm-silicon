#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

if [ -z "${CMAKE_BIN:-}" ]; then
  echo "ERROR: cmake not found in ORIGINAL_PATH"
  exit 1
fi

if [ -z "${PKG_CONFIG_BIN:-}" ]; then
  echo "ERROR: pkg-config not found in ORIGINAL_PATH"
  exit 1
fi

NAME="libwebp"
SRC_DIR="$SRC/$NAME"
BUILD_DIR="$BUILD/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

echo "==> Building libwebp (CMake)"
echo "Source : $SRC_DIR"
echo "Build  : $BUILD_DIR"
echo "Prefix : $PREFIX"
echo "Log    : $LOG_FILE"

if [ ! -d "$SRC_DIR" ]; then
  echo "ERROR: source directory not found: $SRC_DIR"
  exit 1
fi

rm -rf "$BUILD_DIR"
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
  echo "PKG_CONFIG_BIN=$PKG_CONFIG_BIN"
  echo "PKG_CONFIG_PATH=$PKG_CONFIG_PATH"
  echo "PKG_CONFIG_LIBDIR=$PKG_CONFIG_LIBDIR"
  echo
  echo "===== cmake configure ====="
} > "$LOG_FILE"

"$CMAKE_BIN" -S "$SRC_DIR" -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET" \
  -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
  -DCMAKE_C_COMPILER="$CC" \
  -DCMAKE_C_FLAGS="$CFLAGS" \
  -DBUILD_SHARED_LIBS=OFF \
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
  >> "$LOG_FILE" 2>&1

{
  echo
  echo "===== build ====="
} >> "$LOG_FILE"

"$CMAKE_BIN" --build "$BUILD_DIR" --parallel "$NCPU" >> "$LOG_FILE" 2>&1

{
  echo
  echo "===== install ====="
} >> "$LOG_FILE"

"$CMAKE_BIN" --install "$BUILD_DIR" >> "$LOG_FILE" 2>&1

echo
echo "==> Verifying libwebp install"

test -f "$PREFIX/include/webp/decode.h" \
  && echo "[ok] libwebp headers found" \
  || { echo "[fail] missing libwebp headers"; exit 1; }

find "$PREFIX/lib" -maxdepth 1 -name 'libwebp*' -print | sort

if [ ! -f "$PREFIX/lib/libwebp.a" ]; then
  echo "ERROR: static library not found: $PREFIX/lib/libwebp.a"
  exit 1
fi

if [ ! -f "$PREFIX/lib/pkgconfig/libwebp.pc" ]; then
  echo "ERROR: pkg-config file not found: $PREFIX/lib/pkgconfig/libwebp.pc"
  exit 1
fi

echo
echo "===== pkg-config verify ====="
"$PKG_CONFIG_BIN" --modversion libwebp
"$PKG_CONFIG_BIN" --static --libs libwebp

# Optional related libraries that FFmpeg may indirectly touch via webp stack.
if [ -f "$PREFIX/lib/pkgconfig/libwebpmux.pc" ]; then
  "$PKG_CONFIG_BIN" --modversion libwebpmux
  "$PKG_CONFIG_BIN" --static --libs libwebpmux
fi

if [ -f "$PREFIX/lib/pkgconfig/libwebpdemux.pc" ]; then
  "$PKG_CONFIG_BIN" --modversion libwebpdemux
  "$PKG_CONFIG_BIN" --static --libs libwebpdemux
fi

echo
echo "==> libwebp installed successfully"
ls -l "$PREFIX/include/webp/decode.h"
ls -l "$PREFIX/lib/libwebp.a"
ls -l "$PREFIX/lib/pkgconfig/libwebp.pc"
