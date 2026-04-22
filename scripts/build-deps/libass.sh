#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

if [ -z "${PKG_CONFIG_BIN:-}" ]; then
  echo "ERROR: pkg-config not found in ORIGINAL_PATH"
  exit 1
fi

LIBASS_SRC="$SRC/libass"
LIBASS_LOG="$LOGS/libass-build.log"

echo "==> Building libass (autotools)"
echo "Source : $LIBASS_SRC"
echo "Prefix : $PREFIX"
echo "Log    : $LIBASS_LOG"

if [ ! -d "$LIBASS_SRC" ]; then
  echo "ERROR: source directory not found: $LIBASS_SRC"
  exit 1
fi

cd "$LIBASS_SRC"

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
  echo "CXX=$CXX"
  echo "CXXFLAGS=$CXXFLAGS"
  echo "LDFLAGS=$LDFLAGS"
  echo "MAKEFLAGS=$MAKEFLAGS"
  echo "PKG_CONFIG_BIN=$PKG_CONFIG_BIN"
  echo "PKG_CONFIG_PATH=$PKG_CONFIG_PATH"
  echo "PKG_CONFIG_LIBDIR=$PKG_CONFIG_LIBDIR"
  echo
  echo "===== autoreconf ====="
} > "$LIBASS_LOG"

if [ -f "autogen.sh" ]; then
  PATH="$ORIGINAL_PATH" ./autogen.sh >> "$LIBASS_LOG" 2>&1
elif [ -f "configure.ac" ] || [ -f "configure.in" ]; then
  PATH="$ORIGINAL_PATH" autoreconf -fi >> "$LIBASS_LOG" 2>&1
fi

{
  echo
  echo "===== configure ====="
} >> "$LIBASS_LOG"

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
  >> "$LIBASS_LOG" 2>&1

{
  echo
  echo "===== build ====="
} >> "$LIBASS_LOG"

make >> "$LIBASS_LOG" 2>&1

{
  echo
  echo "===== install ====="
} >> "$LIBASS_LOG"

make install >> "$LIBASS_LOG" 2>&1

echo "==> Verifying libass install"

find "$PREFIX/lib" -maxdepth 1 -name 'libass*' -print | sort

if [ ! -f "$PREFIX/lib/libass.a" ]; then
  echo "ERROR: static library not found: $PREFIX/lib/libass.a"
  exit 1
fi

if [ ! -f "$PREFIX/include/ass/ass.h" ]; then
  echo "ERROR: header not found: $PREFIX/include/ass/ass.h"
  exit 1
fi

if [ ! -f "$PREFIX/lib/pkgconfig/libass.pc" ]; then
  echo "ERROR: pkg-config file not found: $PREFIX/lib/pkgconfig/libass.pc"
  exit 1
fi

echo "==> libass installed successfully"
ls -l "$PREFIX/lib/libass.a"
ls -l "$PREFIX/include/ass/ass.h"
ls -l "$PREFIX/lib/pkgconfig/libass.pc"
