#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"
source "$(dirname "$0")/../build-static-common.sh"

NAME="libsoxr"
SRC_DIR="$SRC/$NAME"
BUILD_DIR="$BUILD/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

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
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_TESTS=OFF \
  -DWITH_OPENMP=OFF \
  -DWITH_LSR_BINDINGS=OFF \
  -DCMAKE_PREFIX_PATH="$PREFIX" \
  -DCMAKE_FIND_ROOT_PATH="$PREFIX"

cmake_build
cmake_install

echo
echo "==> no .la residue expected for $NAME"

step "verify installed files"
find "$PREFIX/lib" -maxdepth 1 \( -name 'libsoxr*' -o -name 'soxr.pc' \) -print | sort

require_file "$PREFIX/lib/libsoxr.a" "static library not found"
require_file "$PREFIX/include/soxr.h" "header not found"
require_file "$PREFIX/lib/pkgconfig/soxr.pc" "pkg-config file not found"

print_pkg_version soxr
print_pkg_static_libs soxr

begin_final_verify
print_verified_file "$PREFIX/lib/libsoxr.a"
print_verified_file "$PREFIX/include/soxr.h"
print_verified_file "$PREFIX/lib/pkgconfig/soxr.pc"

banner_end
