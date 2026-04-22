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

NAME="freetype"
SRC_DIR="$SRC/$NAME"
BUILD_DIR="$BUILD/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

echo "==> Building freetype"
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
  -DCMAKE_PREFIX_PATH="$PREFIX" \
  -DZLIB_ROOT="$PREFIX" \
  -DBZIP2_ROOT="$PREFIX" \
  -DBROTLIDEC_ROOT="$PREFIX" \
  -DBUILD_SHARED_LIBS=OFF \
  >> "$LOG_FILE" 2>&1

"$CMAKE_BIN" --build "$BUILD_DIR" --parallel "$NCPU" \
  >> "$LOG_FILE" 2>&1

"$CMAKE_BIN" --install "$BUILD_DIR" \
  >> "$LOG_FILE" 2>&1

echo "===== verify freetype =====" >> "$LOG_FILE"

if [ -f "$PREFIX/include/freetype2/freetype/freetype.h" ]; then
  echo "[ok] freetype headers found" >> "$LOG_FILE"
else
  echo "[fail] freetype headers missing" >> "$LOG_FILE"
  exit 1
fi

"$PKG_CONFIG_BIN" --print-errors --exists freetype2 >> "$LOG_FILE" 2>&1
"$PKG_CONFIG_BIN" --modversion freetype2 >> "$LOG_FILE" 2>&1
"$PKG_CONFIG_BIN" --libs freetype2 >> "$LOG_FILE" 2>&1

echo "==> freetype installed successfully"
ls -l "$PREFIX/include/freetype2/freetype/freetype.h"
ls -l "$PREFIX/lib/pkgconfig/freetype2.pc"
