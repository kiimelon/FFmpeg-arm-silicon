#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

if [ -z "${PKG_CONFIG_BIN:-}" ]; then
  echo "ERROR: pkg-config not found in ORIGINAL_PATH"
  exit 1
fi

NAME="libtheora"
SRC_DIR="$SRC/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

echo "==> Building libtheora (autotools)"
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
rm -f config.cache

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
  NOCONFIGURE=1 PATH="$ORIGINAL_PATH" ./autogen.sh >> "$LOG_FILE" 2>&1
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
  --disable-examples \
  --disable-oggtest \
  --disable-vorbistest \
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

echo "==> Verifying libtheora install"

find "$PREFIX/lib" -maxdepth 1 -name 'libtheora*' -print | sort

if [ ! -f "$PREFIX/lib/libtheora.a" ] && [ ! -f "$PREFIX/lib/libtheoradec.a" ]; then
  echo "ERROR: static theora libraries not found"
  exit 1
fi

if [ ! -f "$PREFIX/include/theora/theora.h" ]; then
  echo "ERROR: header not found: $PREFIX/include/theora/theora.h"
  exit 1
fi

if [ ! -f "$PREFIX/lib/pkgconfig/theora.pc" ]; then
  echo "ERROR: pkg-config file not found: $PREFIX/lib/pkgconfig/theora.pc"
  exit 1
fi

echo
echo "===== pkg-config verify ====="
"$PKG_CONFIG_BIN" --modversion theora
"$PKG_CONFIG_BIN" --static --libs theora

echo
echo "==> libtheora installed successfully"
find "$PREFIX/lib" -maxdepth 1 -name 'libtheora*' -print | sort
ls -l "$PREFIX/include/theora/theora.h"
ls -l "$PREFIX/lib/pkgconfig/theora.pc"
