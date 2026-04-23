#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"
source "$(dirname "$0")/../build-static-common.sh"

NAME="fribidi"
SRC_DIR="$SRC/$NAME"
BUILD_DIR="$BUILD/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

banner_start

echo "==> Building $NAME (meson)"
echo "Source : $SRC_DIR"
echo "Build  : $BUILD_DIR"
echo "Prefix : $PREFIX"
echo "Log    : $LOG_FILE"

require_file "$SRC_DIR/meson.build" "source directory not found or invalid"

mkdir -p "$LOGS"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

log_build_env "$LOG_FILE"

meson_configure \
  --prefix="$PREFIX" \
  --default-library=static \
  -Ddocs=false \
  -Dbin=false \
  -Dtests=false

meson_build
meson_install

echo
echo "==> no .la residue expected for $NAME"

step "verify installed files"
find "$PREFIX/lib" -maxdepth 1 \( -name 'libfribidi*' -o -name 'fribidi.pc' \) -print | sort

require_file "$PREFIX/lib/libfribidi.a" "static library not found"
require_file "$PREFIX/include/fribidi/fribidi.h" "header not found"
require_file "$PREFIX/lib/pkgconfig/fribidi.pc" "pkg-config file not found"

print_pkg_version fribidi
print_pkg_static_libs fribidi

begin_final_verify
print_verified_file "$PREFIX/lib/libfribidi.a"
print_verified_file "$PREFIX/include/fribidi/fribidi.h"
print_verified_file "$PREFIX/lib/pkgconfig/fribidi.pc"

banner_end
