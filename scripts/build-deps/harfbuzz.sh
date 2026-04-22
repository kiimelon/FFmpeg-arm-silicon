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

HARFBUZZ_SRC="$SRC/harfbuzz"
HARFBUZZ_BUILD_DIR="$BUILD/harfbuzz"
HARFBUZZ_LOG="$LOGS/harfbuzz-build.log"

MESON_PATH="$(dirname "$MESON_BIN")"
NINJA_PATH="$(dirname "$NINJA_BIN")"
TOOL_PATH="$MESON_PATH:$NINJA_PATH:$PATH"

echo "==> Building harfbuzz (Meson)"
echo "Source : $HARFBUZZ_SRC"
echo "Build  : $HARFBUZZ_BUILD_DIR"
echo "Prefix : $PREFIX"
echo "Log    : $HARFBUZZ_LOG"

if [ ! -d "$HARFBUZZ_SRC" ]; then
  echo "ERROR: source directory not found: $HARFBUZZ_SRC"
  exit 1
fi

rm -rf "$HARFBUZZ_BUILD_DIR"
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
  echo "CXX=$CXX"
  echo "CFLAGS=$CFLAGS"
  echo "CXXFLAGS=$CXXFLAGS"
  echo "LDFLAGS=$LDFLAGS"
  echo "MAKEFLAGS=$MAKEFLAGS"
  echo "MESON_BIN=$MESON_BIN"
  echo "NINJA_BIN=$NINJA_BIN"
  echo "PKG_CONFIG_BIN=${PKG_CONFIG_BIN:-unset}"
  echo "PKG_CONFIG_PATH=$PKG_CONFIG_PATH"
  echo "PKG_CONFIG_LIBDIR=$PKG_CONFIG_LIBDIR"
  echo
  echo "===== meson setup ====="
} > "$HARFBUZZ_LOG"

CC="$CC" \
CXX="$CXX" \
CFLAGS="$CFLAGS" \
CXXFLAGS="$CXXFLAGS" \
LDFLAGS="$LDFLAGS" \
PKG_CONFIG="$PKG_CONFIG_BIN" \
PKG_CONFIG_PATH="$PKG_CONFIG_PATH" \
PKG_CONFIG_LIBDIR="$PKG_CONFIG_LIBDIR" \
PATH="$TOOL_PATH" \
"$MESON_BIN" setup "$HARFBUZZ_BUILD_DIR" "$HARFBUZZ_SRC" \
  --prefix="$PREFIX" \
  --buildtype=release \
  --default-library=static \
  -Dfreetype=enabled \
  -Dglib=disabled \
  -Dgobject=disabled \
  -Dicu=disabled \
  -Dcairo=disabled \
  -Dchafa=disabled \
  -Ddocs=disabled \
  -Dtests=disabled \
  -Dintrospection=disabled \
  -Dbenchmark=disabled \
  -Dfontations=disabled \
  >> "$HARFBUZZ_LOG" 2>&1

PATH="$TOOL_PATH" "$MESON_BIN" compile -C "$HARFBUZZ_BUILD_DIR" >> "$HARFBUZZ_LOG" 2>&1
PATH="$TOOL_PATH" "$MESON_BIN" install -C "$HARFBUZZ_BUILD_DIR" >> "$HARFBUZZ_LOG" 2>&1

echo "==> Verifying harfbuzz install"

find "$PREFIX/lib" -maxdepth 1 -name 'libharfbuzz*' -print | sort

if [ ! -f "$PREFIX/lib/libharfbuzz.a" ]; then
  echo "ERROR: static library not found: $PREFIX/lib/libharfbuzz.a"
  exit 1
fi

if [ ! -f "$PREFIX/include/harfbuzz/hb.h" ]; then
  echo "ERROR: header not found: $PREFIX/include/harfbuzz/hb.h"
  exit 1
fi

if [ ! -f "$PREFIX/lib/pkgconfig/harfbuzz.pc" ]; then
  echo "ERROR: pkg-config file not found: $PREFIX/lib/pkgconfig/harfbuzz.pc"
  exit 1
fi

echo "==> harfbuzz installed successfully"
ls -l "$PREFIX/lib/libharfbuzz.a"
ls -l "$PREFIX/include/harfbuzz/hb.h"
ls -l "$PREFIX/lib/pkgconfig/harfbuzz.pc"
