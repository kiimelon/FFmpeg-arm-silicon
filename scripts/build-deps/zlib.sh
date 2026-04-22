#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

ZLIB_SRC="$SRC/zlib"
ZLIB_BUILD_LOG="$LOGS/zlib-build.log"
ZLIB_INSTALL_LOG="$LOGS/zlib-install.log"

echo "==> Building zlib"
echo "Source : $ZLIB_SRC"
echo "Prefix : $PREFIX"
echo "Logs   : $LOGS"

if [ ! -d "$ZLIB_SRC" ]; then
  echo "ERROR: source directory not found: $ZLIB_SRC"
  exit 1
fi

cd "$ZLIB_SRC"

make distclean >/dev/null 2>&1 || true
make clean >/dev/null 2>&1 || true

{
  echo "ROOT=$ROOT"
  echo "SRC=$SRC"
  echo "PREFIX=$PREFIX"
  echo "PATH=$PATH"
  echo "ORIGINAL_PATH=$ORIGINAL_PATH"
  echo "CC=$CC"
  echo "CXX=$CXX"
  echo "CFLAGS=$CFLAGS"
  echo "CXXFLAGS=$CXXFLAGS"
  echo "LDFLAGS=$LDFLAGS"
  echo "MAKEFLAGS=$MAKEFLAGS"
  echo
  echo "===== configure ====="
} > "$ZLIB_BUILD_LOG"

CHOST=arm-apple-darwin \
CC="$CC" \
CFLAGS="$CFLAGS" \
LDFLAGS="$LDFLAGS" \
./configure --prefix="$PREFIX" >> "$ZLIB_BUILD_LOG" 2>&1

make >> "$ZLIB_BUILD_LOG" 2>&1
make install > "$ZLIB_INSTALL_LOG" 2>&1

echo "==> Verifying zlib install"

if [ ! -f "$PREFIX/lib/libz.a" ]; then
  echo "ERROR: static library not found: $PREFIX/lib/libz.a"
  exit 1
fi

if [ ! -f "$PREFIX/include/zlib.h" ]; then
  echo "ERROR: header not found: $PREFIX/include/zlib.h"
  exit 1
fi

if [ ! -f "$PREFIX/lib/pkgconfig/zlib.pc" ]; then
  echo "ERROR: pkg-config file not found: $PREFIX/lib/pkgconfig/zlib.pc"
  exit 1
fi

echo "==> zlib installed successfully"
ls -l "$PREFIX/lib/libz.a"
ls -l "$PREFIX/include/zlib.h"
ls -l "$PREFIX/lib/pkgconfig/zlib.pc"
