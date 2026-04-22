#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

DISABLED_DIR="$PREFIX/lib/_disabled_dylibs"
mkdir -p "$DISABLED_DIR"

move_matches() {
  local pattern="$1"
  local moved=0

  for f in "$PREFIX"/lib/$pattern; do
    if [ -e "$f" ] || [ -L "$f" ]; then
      echo "moving $(basename "$f")"
      mv "$f" "$DISABLED_DIR/"
      moved=1
    fi
  done

  if [ "$moved" -eq 0 ]; then
    echo "no matches for $pattern"
  fi
}

echo "PREFIX=$PREFIX"
echo "DISABLED_DIR=$DISABLED_DIR"
echo

# Core subtitle/text stack
move_matches 'libfreetype*.dylib'
move_matches 'libharfbuzz*.dylib'
move_matches 'libfribidi*.dylib'
move_matches 'libass*.dylib'

# WebP / image helpers
move_matches 'libwebp*.dylib'
move_matches 'libwebpmux*.dylib'
move_matches 'libsharpyuv*.dylib'

# Common codec/libs currently showing up as dylibs
move_matches 'libsnappy*.dylib'
move_matches 'libdav1d*.dylib'
move_matches 'libvpx*.dylib'
move_matches 'libmp3lame*.dylib'
move_matches 'libopus*.dylib'
move_matches 'libtheora*.dylib'
move_matches 'libogg*.dylib'
move_matches 'libtwolame*.dylib'
move_matches 'libx264*.dylib'
move_matches 'libsoxr*.dylib'
move_matches 'libzimg*.dylib'
move_matches 'libzmq*.dylib'
move_matches 'libxml2*.dylib'
move_matches 'libz*.dylib'

# ffplay / SDL2
move_matches 'libSDL2*.dylib'

echo
echo "==> remaining dylibs in $PREFIX/lib"
ls "$PREFIX/lib"/*.dylib 2>/dev/null || true

echo
echo "==> moved dylibs in $DISABLED_DIR"
ls "$DISABLED_DIR"/*.dylib 2>/dev/null || true
