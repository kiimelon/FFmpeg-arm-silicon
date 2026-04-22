#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

if [ -z "${PKG_CONFIG_BIN:-}" ]; then
  echo "ERROR: pkg-config not found in ORIGINAL_PATH"
  exit 1
fi

NAME="lame"
SRC_DIR="$SRC/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

echo "==> Building lame (autotools, no autoreconf)"
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
  echo "===== prepare auxiliary files ====="
} > "$LOG_FILE"

if [ ! -f "./configure" ]; then
  echo "ERROR: configure script not found in $SRC_DIR" >> "$LOG_FILE"
  exit 1
fi

AUTOMAKE_SHARE="$(PATH="$ORIGINAL_PATH" automake --print-libdir 2>/dev/null || true)"
if [ -z "$AUTOMAKE_SHARE" ] || [ ! -d "$AUTOMAKE_SHARE" ]; then
  echo "ERROR: automake libdir not found" >> "$LOG_FILE"
  exit 1
fi

for helper in compile missing install-sh depcomp; do
  if [ ! -f "$helper" ] && [ -f "$AUTOMAKE_SHARE/$helper" ]; then
    cp -f "$AUTOMAKE_SHARE/$helper" "$helper"
    chmod +x "$helper" || true
    echo "copied $helper from $AUTOMAKE_SHARE" >> "$LOG_FILE"
  fi
done

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
  --disable-frontend \
  --disable-decoder \
  --disable-analyzer-hooks \
  --disable-gtktest \
  --disable-cpml \
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

echo "==> Verifying lame install"

find "$PREFIX/lib" -maxdepth 1 -name 'libmp3lame*' -print | sort

if [ ! -f "$PREFIX/lib/libmp3lame.a" ]; then
  echo "ERROR: static library not found: $PREFIX/lib/libmp3lame.a"
  exit 1
fi

if [ ! -f "$PREFIX/include/lame/lame.h" ] && [ ! -f "$PREFIX/include/lame.h" ]; then
  echo "ERROR: header not found: $PREFIX/include/lame/lame.h or $PREFIX/include/lame.h"
  exit 1
fi

if [ ! -f "$PREFIX/lib/pkgconfig/libmp3lame.pc" ]; then
  echo "ERROR: pkg-config file not found: $PREFIX/lib/pkgconfig/libmp3lame.pc"
  exit 1
fi

echo
echo "===== pkg-config verify ====="
"$PKG_CONFIG_BIN" --modversion libmp3lame
"$PKG_CONFIG_BIN" --static --libs libmp3lame

echo
echo "==> lame installed successfully"
ls -l "$PREFIX/lib/libmp3lame.a"
if [ -f "$PREFIX/include/lame/lame.h" ]; then
  ls -l "$PREFIX/include/lame/lame.h"
else
  ls -l "$PREFIX/include/lame.h"
fi
ls -l "$PREFIX/lib/pkgconfig/libmp3lame.pc"
