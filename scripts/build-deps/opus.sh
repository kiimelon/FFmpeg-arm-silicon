#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"
source "$(dirname "$0")/../build-static-common.sh"

NAME="opus"
SRC_DIR="$SRC/$NAME"
BUILD_DIR="$BUILD/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"
LA_FILE="$PREFIX/lib/libopus.la"
PC_FILE="$PREFIX/lib/pkgconfig/opus.pc"

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
  -DOPUS_BUILD_PROGRAMS=OFF \
  -DOPUS_BUILD_TESTING=OFF \
  -DBUILD_TESTING=OFF \
  -DCMAKE_PREFIX_PATH="$PREFIX" \
  -DCMAKE_FIND_ROOT_PATH="$PREFIX"

cmake_build
cmake_install

remove_one_la "$LA_FILE"

step "verify installed files"
find "$PREFIX/lib" -maxdepth 1 -name 'libopus*' -print | sort

require_file "$PREFIX/lib/libopus.a" "static library not found"
require_file "$PREFIX/include/opus/opus.h" "header not found"
require_file "$PC_FILE" "pkg-config file not found"
ensure_no_file "$LA_FILE" ".la residue still exists"

print_pkg_version opus
print_pkg_static_libs opus

print_verified_files \
  "$PREFIX/lib/libopus.a" \
  "$PREFIX/include/opus/opus.h" \
  "$PC_FILE"

banner_end
