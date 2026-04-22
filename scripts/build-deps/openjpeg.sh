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

NAME="openjpeg"
SRC_DIR="$SRC/$NAME"
BUILD_DIR="$BUILD/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

echo "==> Building openjpeg (CMake)"
echo "Source : $SRC_DIR"
echo "Build  : $BUILD_DIR"
echo "Prefix : $PREFIX"
echo "Log    : $LOG_FILE"

if [ ! -d "$SRC_DIR" ]; then
  echo "ERROR: source directory not found: $SRC_DIR"
  exit 1
fi

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$LOGS"

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
  -DBUILD_CODEC=OFF \
  -DBUILD_JPIP=OFF \
  -DBUILD_JPWL=OFF \
  -DBUILD_DOC=OFF \
  -DBUILD_THIRDPARTY=OFF \
  -DBUILD_TESTING=OFF \
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
echo "==> Verifying openjpeg install"

find "$PREFIX/lib" -maxdepth 1 -name 'libopenjp2*' -print | sort

if [ ! -f "$PREFIX/lib/libopenjp2.a" ]; then
  echo "ERROR: static library not found: $PREFIX/lib/libopenjp2.a"
  exit 1
fi

if [ ! -f "$PREFIX/include/openjpeg-2.5/openjpeg.h" ]; then
  echo "ERROR: header not found: $PREFIX/include/openjpeg-2.5/openjpeg.h"
  exit 1
fi

if [ ! -f "$PREFIX/lib/pkgconfig/libopenjp2.pc" ]; then
  echo "ERROR: pkg-config file not found: $PREFIX/lib/pkgconfig/libopenjp2.pc"
  exit 1
fi

echo
echo "===== pkg-config verify ====="
"$PKG_CONFIG_BIN" --modversion libopenjp2
"$PKG_CONFIG_BIN" --static --libs libopenjp2

echo
echo "==> openjpeg installed successfully"
ls -l "$PREFIX/lib/libopenjp2.a"
ls -l "$PREFIX/include/openjpeg-2.5/openjpeg.h"
ls -l "$PREFIX/lib/pkgconfig/libopenjp2.pc"
