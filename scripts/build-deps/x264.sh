#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

if [ -z "${PKG_CONFIG_BIN:-}" ]; then
  echo "ERROR: pkg-config not found in ORIGINAL_PATH"
  exit 1
fi

X264_SRC="$SRC/x264"
X264_LOG="$LOGS/x264-build.log"

echo "==> Building x264"
echo "Source : $X264_SRC"
echo "Prefix : $PREFIX"
echo "Log    : $X264_LOG"

if [ ! -d "$X264_SRC" ]; then
  echo "ERROR: source directory not found: $X264_SRC"
  exit 1
fi

cd "$X264_SRC"

make distclean >/dev/null 2>&1 || true
make clean >/dev/null 2>&1 || true

{
  echo "ROOT=$ROOT"
  echo "SRC=$SRC"
  echo "PREFIX=$PREFIX"
  echo "PATH=$PATH"
  echo "ORIGINAL_PATH=$ORIGINAL_PATH"
  echo "CC=$CC"
  echo "CFLAGS=$CFLAGS"
  echo "LDFLAGS=$LDFLAGS"
  echo "MAKEFLAGS=$MAKEFLAGS"
  echo "PKG_CONFIG_BIN=$PKG_CONFIG_BIN"
  echo "PKG_CONFIG_PATH=$PKG_CONFIG_PATH"
  echo "PKG_CONFIG_LIBDIR=$PKG_CONFIG_LIBDIR"
  echo
  echo "===== configure ====="
} > "$X264_LOG"

PKG_CONFIG="$PKG_CONFIG_BIN" \
PKG_CONFIG_PATH="$PKG_CONFIG_PATH" \
PKG_CONFIG_LIBDIR="$PKG_CONFIG_LIBDIR" \
CC="$CC" \
CFLAGS="$CFLAGS" \
LDFLAGS="$LDFLAGS" \
./configure \
  --prefix="$PREFIX" \
  --enable-static \
  --disable-shared \
  --disable-cli \
  >> "$X264_LOG" 2>&1

{
  echo
  echo "===== build ====="
} >> "$X264_LOG"

make >> "$X264_LOG" 2>&1

{
  echo
  echo "===== install ====="
} >> "$X264_LOG"

make install >> "$X264_LOG" 2>&1

echo "==> Verifying x264 install"

find "$PREFIX/lib" -maxdepth 1 -name 'libx264*' -print | sort

if [ ! -f "$PREFIX/lib/libx264.a" ]; then
  echo "ERROR: static library not found: $PREFIX/lib/libx264.a"
  exit 1
fi

if [ ! -f "$PREFIX/include/x264.h" ]; then
  echo "ERROR: header not found: $PREFIX/include/x264.h"
  exit 1
fi

if [ ! -f "$PREFIX/lib/pkgconfig/x264.pc" ]; then
  echo "ERROR: pkg-config file not found: $PREFIX/lib/pkgconfig/x264.pc"
  exit 1
fi

echo "==> x264 installed successfully"
ls -l "$PREFIX/lib/libx264.a"
ls -l "$PREFIX/include/x264.h"
ls -l "$PREFIX/lib/pkgconfig/x264.pc"
