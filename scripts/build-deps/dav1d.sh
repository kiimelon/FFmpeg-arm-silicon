#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

if [ -z "${MESON_BIN:-}" ]; then
  if [ -n "${ORIGINAL_PATH:-}" ] && PATH="$ORIGINAL_PATH" command -v meson >/dev/null 2>&1; then
    export MESON_BIN="$(PATH="$ORIGINAL_PATH" command -v meson)"
  else
    echo "ERROR: meson not found in ORIGINAL_PATH"
    exit 1
  fi
fi

if [ -z "${NINJA_BIN:-}" ]; then
  if [ -n "${ORIGINAL_PATH:-}" ] && PATH="$ORIGINAL_PATH" command -v ninja >/dev/null 2>&1; then
    export NINJA_BIN="$(PATH="$ORIGINAL_PATH" command -v ninja)"
  else
    echo "ERROR: ninja not found in ORIGINAL_PATH"
    exit 1
  fi
fi

if [ -z "${PKG_CONFIG_BIN:-}" ]; then
  echo "ERROR: pkg-config not found in ORIGINAL_PATH"
  exit 1
fi

NAME="dav1d"
SRC_DIR="$SRC/$NAME"
BUILD_DIR="$BUILD/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

MESON_PATH="$(dirname "$MESON_BIN")"
NINJA_PATH="$(dirname "$NINJA_BIN")"
TOOL_PATH="$MESON_PATH:$NINJA_PATH:$PATH"

echo "==> Building dav1d (Meson)"
echo "Source : $SRC_DIR"
echo "Build  : $BUILD_DIR"
echo "Prefix : $PREFIX"
echo "Log    : $LOG_FILE"

if [ ! -d "$SRC_DIR" ]; then
  echo "ERROR: source directory not found: $SRC_DIR"
  exit 1
fi

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD" "$LOGS"

{
  echo "ROOT=$ROOT"
  echo "SRC=$SRC"
  echo "BUILD=$BUILD"
  echo "PREFIX=$PREFIX"
  echo "PATH=$PATH"
  echo "ORIGINAL_PATH=$ORIGINAL_PATH"
  echo "TOOL_PATH=$TOOL_PATH"
  echo "CC=$CC"
  echo "CFLAGS=$CFLAGS"
  echo "LDFLAGS=$LDFLAGS"
  echo "MESON_BIN=$MESON_BIN"
  echo "NINJA_BIN=$NINJA_BIN"
  echo "PKG_CONFIG_BIN=$PKG_CONFIG_BIN"
  echo "PKG_CONFIG_PATH=$PKG_CONFIG_PATH"
  echo "PKG_CONFIG_LIBDIR=$PKG_CONFIG_LIBDIR"
  echo
  echo "===== meson setup ====="
} > "$LOG_FILE"

CC="$CC" \
CFLAGS="$CFLAGS" \
LDFLAGS="$LDFLAGS" \
PKG_CONFIG="$PKG_CONFIG_BIN" \
PKG_CONFIG_PATH="$PKG_CONFIG_PATH" \
PKG_CONFIG_LIBDIR="$PKG_CONFIG_LIBDIR" \
PATH="$TOOL_PATH" \
"$MESON_BIN" setup "$BUILD_DIR" "$SRC_DIR" \
  --buildtype=release \
  --prefix="$PREFIX" \
  --default-library=static \
  -Denable_tools=false \
  -Denable_tests=false \
  >> "$LOG_FILE" 2>&1

{
  echo
  echo "===== build ====="
} >> "$LOG_FILE"

PATH="$TOOL_PATH" "$NINJA_BIN" -C "$BUILD_DIR" >> "$LOG_FILE" 2>&1

{
  echo
  echo "===== install ====="
} >> "$LOG_FILE"

PATH="$TOOL_PATH" "$NINJA_BIN" -C "$BUILD_DIR" install >> "$LOG_FILE" 2>&1

echo "==> Verifying dav1d install"

find "$PREFIX/lib" -maxdepth 1 -name 'libdav1d*' -print | sort

if [ ! -f "$PREFIX/lib/libdav1d.a" ]; then
  echo "ERROR: static library not found: $PREFIX/lib/libdav1d.a"
  exit 1
fi

if [ ! -f "$PREFIX/include/dav1d/dav1d.h" ]; then
  echo "ERROR: header not found: $PREFIX/include/dav1d/dav1d.h"
  exit 1
fi

if [ ! -f "$PREFIX/lib/pkgconfig/dav1d.pc" ]; then
  echo "ERROR: pkg-config file not found: $PREFIX/lib/pkgconfig/dav1d.pc"
  exit 1
fi

echo "==> dav1d installed successfully"
ls -l "$PREFIX/lib/libdav1d.a"
ls -l "$PREFIX/include/dav1d/dav1d.h"
ls -l "$PREFIX/lib/pkgconfig/dav1d.pc"

echo
echo "===== pkg-config verify ====="
"$PKG_CONFIG_BIN" --modversion dav1d
"$PKG_CONFIG_BIN" --static --libs dav1d
