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

FRIBIDI_SRC="$SRC/fribidi"
FRIBIDI_BUILD_DIR="$BUILD/fribidi"
FRIBIDI_LOG="$LOGS/fribidi-build.log"

MESON_PATH="$(dirname "$MESON_BIN")"
NINJA_PATH="$(dirname "$NINJA_BIN")"
TOOL_PATH="$MESON_PATH:$NINJA_PATH:$PATH"

echo "==> Building fribidi (Meson)"
echo "Source : $FRIBIDI_SRC"
echo "Build  : $FRIBIDI_BUILD_DIR"
echo "Prefix : $PREFIX"
echo "Log    : $FRIBIDI_LOG"

if [ ! -d "$FRIBIDI_SRC" ]; then
  echo "ERROR: source directory not found: $FRIBIDI_SRC"
  exit 1
fi

rm -rf "$FRIBIDI_BUILD_DIR"
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
  echo
  echo "===== meson setup ====="
} > "$FRIBIDI_LOG"

CC="$CC" \
CFLAGS="$CFLAGS" \
LDFLAGS="$LDFLAGS" \
PATH="$TOOL_PATH" \
"$MESON_BIN" setup "$FRIBIDI_BUILD_DIR" "$FRIBIDI_SRC" \
  --prefix="$PREFIX" \
  --buildtype=release \
  --default-library=static \
  -Dbin=false \
  -Ddocs=false \
  -Dtests=false \
  >> "$FRIBIDI_LOG" 2>&1

PATH="$TOOL_PATH" "$MESON_BIN" compile -C "$FRIBIDI_BUILD_DIR" >> "$FRIBIDI_LOG" 2>&1
PATH="$TOOL_PATH" "$MESON_BIN" install -C "$FRIBIDI_BUILD_DIR" >> "$FRIBIDI_LOG" 2>&1

echo "==> Verifying fribidi install"

find "$PREFIX/lib" -maxdepth 1 -name 'libfribidi*' -print | sort

if [ ! -f "$PREFIX/lib/libfribidi.a" ]; then
  echo "ERROR: static library not found: $PREFIX/lib/libfribidi.a"
  exit 1
fi

if [ ! -f "$PREFIX/include/fribidi/fribidi.h" ]; then
  echo "ERROR: header not found: $PREFIX/include/fribidi/fribidi.h"
  exit 1
fi

if [ ! -f "$PREFIX/lib/pkgconfig/fribidi.pc" ]; then
  echo "ERROR: pkg-config file not found: $PREFIX/lib/pkgconfig/fribidi.pc"
  exit 1
fi

echo "==> fribidi installed successfully"
ls -l "$PREFIX/lib/libfribidi.a"
ls -l "$PREFIX/include/fribidi/fribidi.h"
ls -l "$PREFIX/lib/pkgconfig/fribidi.pc"
