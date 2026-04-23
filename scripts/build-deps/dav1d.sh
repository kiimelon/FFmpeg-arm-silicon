#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"
source "$(dirname "$0")/../build-static-common.sh"

NAME="dav1d"
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
  -Denable_tools=false \
  -Denable_tests=false \
  -Denable_examples=false \
  -Denable_docs=false

meson_build
meson_install

echo
echo "==> no .la residue expected for $NAME"

step "verify installed files"
find "$PREFIX/lib" -maxdepth 1 \( -name 'libdav1d*' -o -name 'dav1d.pc' \) -print | sort

require_file "$PREFIX/lib/libdav1d.a" "static library not found"
require_file "$PREFIX/include/dav1d/dav1d.h" "header not found"
require_file "$PREFIX/lib/pkgconfig/dav1d.pc" "pkg-config file not found"

print_pkg_version dav1d
print_pkg_static_libs dav1d

begin_final_verify
print_verified_file "$PREFIX/lib/libdav1d.a"
print_verified_file "$PREFIX/include/dav1d/dav1d.h"
print_verified_file "$PREFIX/lib/pkgconfig/dav1d.pc"

banner_end
