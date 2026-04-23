#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"
source "$(dirname "$0")/../build-static-common.sh"

NAME="harfbuzz"
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
  -Dtests=disabled \
  -Ddocs=disabled \
  -Dbenchmark=disabled \
  -Dglib=disabled \
  -Dgobject=disabled \
  -Dcairo=disabled \
  -Dicu=disabled \
  -Dfreetype=enabled \
  -Dcoretext=disabled \
  -Dchafa=disabled \
  -Dintrospection=disabled

meson_build
meson_install

echo
echo "==> no .la residue expected for $NAME"

step "verify installed files"
find "$PREFIX/lib" -maxdepth 1 \( -name 'libharfbuzz*' -o -name 'harfbuzz*.pc' \) -print | sort

require_file "$PREFIX/lib/libharfbuzz.a" "static library not found"
require_file "$PREFIX/include/harfbuzz/hb.h" "header not found"
require_file "$PREFIX/lib/pkgconfig/harfbuzz.pc" "pkg-config file not found"

print_pkg_version harfbuzz
print_pkg_static_libs harfbuzz

begin_final_verify
print_verified_file "$PREFIX/lib/libharfbuzz.a"
print_verified_file "$PREFIX/include/harfbuzz/hb.h"
print_verified_file "$PREFIX/lib/pkgconfig/harfbuzz.pc"

banner_end
