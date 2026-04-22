#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

if [ -z "${PKG_CONFIG_BIN:-}" ]; then
  echo "ERROR: pkg-config not found in ORIGINAL_PATH"
  exit 1
fi

NAME="opus"
SRC_DIR="$SRC/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

echo "==> Building opus (autotools)"
echo "Source : $SRC_DIR"
echo "Prefix : $PREFIX"
echo "Log    : $LOG_FILE"

if [ ! -d "$SRC_DIR" ]; then
  echo "ERROR: source directory not found: $SRC_DIR"
  exit 1
fi

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
  echo "===== autoreconf ====="
} > "$LOG_FILE"

if [ -f "autogen.sh" ]; then
  PATH="$ORIGINAL_PATH" ./autogen.sh >> "$LOG_FILE" 2>&1
elif [ -f "configure.ac" ] || [ -f "configure.in" ]; then
  PATH="$ORIGINAL_PATH" autoreconf -fi >> "$LOG_FILE" 2>&1
fi

{
  echo
  echo "===== configure ====="
} >> "$LOG_FILE"

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
  --disable-extra-programs \
  --disable-doc \
  >> "$LOG_FILE" 2>&1

{
  echo
  echo "===== build ====="
} >> "$LOG_FILE"

make >> "$LOG_FILE" 2>&1

{
  echo
  echo "===== install ====="
} >> "$LOG_FILE"

make install >> "$LOG_FILE" 2>&1

echo "==> Verifying opus install"

find "$PREFIX/lib" -maxdepth 1 -name 'libopus*' -print | sort

if [ ! -f "$PREFIX/lib/libopus.a" ]; then
  echo "ERROR: static library not found: $PREFIX/lib/libopus.a"
  exit 1
fi

if [ ! -f "$PREFIX/include/opus/opus.h" ]; then
  echo "ERROR: header not found: $PREFIX/include/opus/opus.h"
  exit 1
fi

if [ ! -f "$PREFIX/lib/pkgconfig/opus.pc" ]; then
  echo "ERROR: pkg-config file not found: $PREFIX/lib/pkgconfig/opus.pc"
  exit 1
fi

echo
echo "===== pkg-config verify ====="
"$PKG_CONFIG_BIN" --modversion opus
"$PKG_CONFIG_BIN" --static --libs opus

echo
echo "==> opus installed successfully"
ls -l "$PREFIX/lib/libopus.a"
ls -l "$PREFIX/include/opus/opus.h"
ls -l "$PREFIX/lib/pkgconfig/opus.pc"
