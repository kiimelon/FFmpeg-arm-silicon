#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

if [ -z "${PKG_CONFIG_BIN:-}" ]; then
  echo "ERROR: pkg-config not found in ORIGINAL_PATH"
  exit 1
fi

NAME="libvpx"
SRC_DIR="$SRC/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

echo "==> Building libvpx"
echo "Source : $SRC_DIR"
echo "Prefix : $PREFIX"
echo "Log    : $LOG_FILE"

if [ ! -d "$SRC_DIR" ]; then
  echo "ERROR: source directory not found: $SRC_DIR"
  exit 1
fi

mkdir -p "$LOGS"
cd "$SRC_DIR"

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
} > "$LOG_FILE"

PKG_CONFIG="$PKG_CONFIG_BIN" \
PKG_CONFIG_PATH="$PKG_CONFIG_PATH" \
PKG_CONFIG_LIBDIR="$PKG_CONFIG_LIBDIR" \
CC="$CC" \
CFLAGS="$CFLAGS" \
LDFLAGS="$LDFLAGS" \
./configure \
  --prefix="$PREFIX" \
  --target=arm64-darwin20-gcc \
  --enable-vp8 \
  --enable-vp9 \
  --disable-shared \
  --enable-static \
  --disable-examples \
  --disable-tools \
  --disable-docs \
  --disable-unit-tests \
  >> "$LOG_FILE" 2>&1

{
  echo
  echo "===== build ====="
} >> "$LOG_FILE"

make $MAKEFLAGS >> "$LOG_FILE" 2>&1

{
  echo
  echo "===== install ====="
} >> "$LOG_FILE"

make install >> "$LOG_FILE" 2>&1

echo "==> Verifying libvpx install"

find "$PREFIX/lib" -maxdepth 1 -name 'libvpx*' -print | sort

if [ ! -f "$PREFIX/lib/libvpx.a" ]; then
  echo "ERROR: static library not found: $PREFIX/lib/libvpx.a"
  exit 1
fi

if [ ! -f "$PREFIX/include/vpx/vpx_codec.h" ]; then
  echo "ERROR: header not found: $PREFIX/include/vpx/vpx_codec.h"
  exit 1
fi

if [ ! -f "$PREFIX/lib/pkgconfig/vpx.pc" ]; then
  echo "ERROR: pkg-config file not found: $PREFIX/lib/pkgconfig/vpx.pc"
  exit 1
fi

echo "==> libvpx installed successfully"
ls -l "$PREFIX/lib/libvpx.a"
ls -l "$PREFIX/include/vpx/vpx_codec.h"
ls -l "$PREFIX/lib/pkgconfig/vpx.pc"

echo
echo "===== pkg-config verify ====="
"$PKG_CONFIG_BIN" --modversion vpx
"$PKG_CONFIG_BIN" --static --libs vpx
