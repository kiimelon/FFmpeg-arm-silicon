#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

if [ -z "${PKG_CONFIG_BIN:-}" ]; then
  echo "ERROR: pkg-config not found in ORIGINAL_PATH"
  exit 1
fi

NAME="twolame"
SRC_DIR="$SRC/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

echo "==> Building twolame (static library only)"
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
  --disable-frontends \
  --disable-maintainer-mode \
  --disable-dependency-tracking \
  >> "$LOG_FILE" 2>&1

{
  echo
  echo "===== build libtwolame only ====="
} >> "$LOG_FILE"

make -C libtwolame >> "$LOG_FILE" 2>&1

{
  echo
  echo "===== install static artifacts only ====="
} >> "$LOG_FILE"

mkdir -p "$PREFIX/lib" "$PREFIX/include" "$PREFIX/lib/pkgconfig"

if [ ! -f "libtwolame/.libs/libtwolame.a" ]; then
  echo "ERROR: built static library not found: libtwolame/.libs/libtwolame.a" | tee -a "$LOG_FILE"
  exit 1
fi

if [ ! -f "libtwolame/twolame.h" ]; then
  echo "ERROR: header not found: libtwolame/twolame.h" | tee -a "$LOG_FILE"
  exit 1
fi

cp -f "libtwolame/.libs/libtwolame.a" "$PREFIX/lib/"
cp -f "libtwolame/twolame.h" "$PREFIX/include/"

cat > "$PREFIX/lib/pkgconfig/twolame.pc" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: twolame
Description: MPEG Audio Layer 2 encoder library
Version: 0.4.0
Libs: -L\${libdir} -ltwolame
Cflags: -I\${includedir}
EOF

echo "==> Verifying twolame install"

find "$PREFIX/lib" -maxdepth 1 -name 'libtwolame*' -print | sort

if [ ! -f "$PREFIX/lib/libtwolame.a" ]; then
  echo "ERROR: static library not found: $PREFIX/lib/libtwolame.a"
  exit 1
fi

if [ ! -f "$PREFIX/include/twolame.h" ]; then
  echo "ERROR: header not found: $PREFIX/include/twolame.h"
  exit 1
fi

if [ ! -f "$PREFIX/lib/pkgconfig/twolame.pc" ]; then
  echo "ERROR: pkg-config file not found: $PREFIX/lib/pkgconfig/twolame.pc"
  exit 1
fi

echo
echo "===== pkg-config verify ====="
"$PKG_CONFIG_BIN" --modversion twolame
"$PKG_CONFIG_BIN" --static --libs twolame

echo
echo "==> twolame installed successfully"
ls -l "$PREFIX/lib/libtwolame.a"
ls -l "$PREFIX/include/twolame.h"
ls -l "$PREFIX/lib/pkgconfig/twolame.pc"
