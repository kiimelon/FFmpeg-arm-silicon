#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"
source "$(dirname "$0")/../build-static-common.sh"

NAME="sdl2"
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
  -DSDL_SHARED=OFF \
  -DSDL_STATIC=ON \
  -DSDL_TEST=OFF \
  -DSDL_TESTS=OFF \
  -DSDL2_DISABLE_INSTALL_DOCS=ON \
  -DCMAKE_PREFIX_PATH="$PREFIX" \
  -DCMAKE_FIND_ROOT_PATH="$PREFIX"

cmake_build
cmake_install

echo
echo "==> no .la residue expected for $NAME"

step "verify installed files"
find "$PREFIX/lib" -maxdepth 1 \( -name 'libSDL2*' -o -name 'sdl2.pc' -o -name 'SDL2.pc' \) -print | sort

require_file "$PREFIX/lib/libSDL2.a" "static library not found"
require_any_file "header not found" \
  "$PREFIX/include/SDL2/SDL.h" \
  "$PREFIX/include/SDL.h"
require_any_file "pkg-config file not found" \
  "$PREFIX/lib/pkgconfig/sdl2.pc" \
  "$PREFIX/lib/pkgconfig/SDL2.pc"

if [ -f "$PREFIX/lib/pkgconfig/sdl2.pc" ]; then
  SDL2_PC_NAME="sdl2"
  SDL2_PC_FILE="$PREFIX/lib/pkgconfig/sdl2.pc"
else
  SDL2_PC_NAME="SDL2"
  SDL2_PC_FILE="$PREFIX/lib/pkgconfig/SDL2.pc"
fi

print_pkg_version "$SDL2_PC_NAME"
print_pkg_static_libs "$SDL2_PC_NAME"

begin_final_verify
print_verified_file "$PREFIX/lib/libSDL2.a"
print_first_existing_file \
  "$PREFIX/include/SDL2/SDL.h" \
  "$PREFIX/include/SDL.h"
print_verified_file "$SDL2_PC_FILE"

banner_end
