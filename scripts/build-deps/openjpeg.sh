#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"
source "$(dirname "$0")/../build-static-common.sh"

NAME="openjpeg"
SRC_DIR="$SRC/$NAME"
BUILD_DIR="$BUILD/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"
LA_FILE="$PREFIX/lib/libopenjp2.la"

banner_start

echo "==> Building $NAME (cmake)"
echo "Source : $SRC_DIR"
echo "Build  : $BUILD_DIR"
echo "Prefix : $PREFIX"
echo "Log    : $LOG_FILE"

require_file "$SRC_DIR/CMakeLists.txt" "source directory not found or invalid"

mkdir -p "$LOGS"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

log_build_env "$LOG_FILE"

cmake_configure \
  -S "$SRC_DIR" -B "$BUILD_DIR" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_CODEC=OFF \
  -DBUILD_JPIP=OFF \
  -DBUILD_JPWL=OFF \
  -DBUILD_TESTING=OFF \
  -DCMAKE_PREFIX_PATH="$PREFIX" \
  -DCMAKE_FIND_ROOT_PATH="$PREFIX"

cmake_build
cmake_install

remove_one_la "$LA_FILE"

step "verify installed files"
find "$PREFIX/lib" -maxdepth 1 \( -name 'libopenjp2*' -o -name 'libopenjp2.pc' \) -print | sort

require_file "$PREFIX/lib/libopenjp2.a" "static library not found"
require_any_file "header not found" \
  "$PREFIX/include/openjpeg-2.5/openjpeg.h" \
  "$PREFIX/include/openjpeg-2.4/openjpeg.h" \
  "$PREFIX/include/openjpeg-2.3/openjpeg.h"
require_file "$PREFIX/lib/pkgconfig/libopenjp2.pc" "pkg-config file not found"
ensure_no_file "$LA_FILE" ".la residue still exists"

print_pkg_version libopenjp2
print_pkg_static_libs libopenjp2

begin_final_verify
print_verified_file "$PREFIX/lib/libopenjp2.a"
print_first_existing_file \
  "$PREFIX/include/openjpeg-2.5/openjpeg.h" \
  "$PREFIX/include/openjpeg-2.4/openjpeg.h" \
  "$PREFIX/include/openjpeg-2.3/openjpeg.h"
print_verified_file "$PREFIX/lib/pkgconfig/libopenjp2.pc"

banner_end
