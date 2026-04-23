#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"
source "$(dirname "$0")/../build-static-common.sh"

NAME="brotli"
SRC_DIR="$SRC/$NAME"
BUILD_DIR="$BUILD/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

banner_start

echo "==> Building $NAME (cmake)"
echo "Source : $SRC_DIR"
echo "Build  : $BUILD_DIR"
echo "Prefix : $PREFIX"
echo "Log    : $LOG_FILE"

if [ ! -d "$SRC_DIR" ]; then
  echo "ERROR: source directory not found: $SRC_DIR"
  exit 1
fi

mkdir -p "$LOGS"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

log_build_env "$LOG_FILE"

step "configure cmake build"
cmake -S "$SRC_DIR" -B "$BUILD_DIR" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DBUILD_SHARED_LIBS=OFF \
  -DBROTLI_DISABLE_TESTS=ON \
  -DBROTLI_BUNDLED_MODE=OFF \
  -DCMAKE_PREFIX_PATH="$PREFIX" \
  -DCMAKE_FIND_ROOT_PATH="$PREFIX" \
  >> "$LOG_FILE" 2>&1
done_step "configure"

step "running make"
cmake --build "$BUILD_DIR" >> "$LOG_FILE" 2>&1
done_step "build"

step "running make install"
cmake --install "$BUILD_DIR" >> "$LOG_FILE" 2>&1
done_step "install"

echo
echo "==> no .la residue expected for $NAME"

step "verify installed files"
find "$PREFIX/lib" -maxdepth 1 \( -name 'libbrotli*' -o -name 'brotli*.pc' \) -print | sort

require_file "$PREFIX/lib/libbrotlicommon.a" "static library not found"
require_file "$PREFIX/lib/libbrotlidec.a" "static library not found"
require_file "$PREFIX/lib/libbrotlienc.a" "static library not found"
require_file "$PREFIX/include/brotli/decode.h" "header not found"
require_file "$PREFIX/lib/pkgconfig/libbrotlicommon.pc" "pkg-config file not found"
require_file "$PREFIX/lib/pkgconfig/libbrotlidec.pc" "pkg-config file not found"
require_file "$PREFIX/lib/pkgconfig/libbrotlienc.pc" "pkg-config file not found"

print_pkg_version libbrotlicommon
print_pkg_static_libs libbrotlicommon
print_pkg_version libbrotlidec
print_pkg_static_libs libbrotlidec
print_pkg_version libbrotlienc
print_pkg_static_libs libbrotlienc

begin_final_verify
print_verified_file "$PREFIX/lib/libbrotlicommon.a"
print_verified_file "$PREFIX/lib/libbrotlidec.a"
print_verified_file "$PREFIX/lib/libbrotlienc.a"
print_verified_file "$PREFIX/include/brotli/decode.h"
print_verified_file "$PREFIX/lib/pkgconfig/libbrotlicommon.pc"
print_verified_file "$PREFIX/lib/pkgconfig/libbrotlidec.pc"
print_verified_file "$PREFIX/lib/pkgconfig/libbrotlienc.pc"

banner_end
