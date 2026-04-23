#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"
source "$(dirname "$0")/../build-static-common.sh"

NAME="snappy"
SRC_DIR="$SRC/$NAME"
BUILD_DIR="$BUILD/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"
PC_FILE="$PREFIX/lib/pkgconfig/snappy.pc"

banner_start

echo "==> Building $NAME (cmake)"
echo "Source : $SRC_DIR"
echo "Build  : $BUILD_DIR"
echo "Prefix : $PREFIX"
echo "Log    : $LOG_FILE"

require_cmd_var CMAKE_BIN
require_file "$SRC_DIR/CMakeLists.txt" "source directory not found or invalid"

mkdir -p "$LOGS"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

log_build_env "$LOG_FILE"

cmake_configure \
  -S "$SRC_DIR" -B "$BUILD_DIR" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DBUILD_SHARED_LIBS=OFF \
  -DSNAPPY_BUILD_TESTS=OFF \
  -DSNAPPY_BUILD_BENCHMARKS=OFF \
  -DCMAKE_PREFIX_PATH="$PREFIX" \
  -DCMAKE_FIND_ROOT_PATH="$PREFIX"

cmake_build
cmake_install

echo
echo "==> no .la residue expected for $NAME"

step "ensure pkg-config file"
mkdir -p "$PREFIX/lib/pkgconfig"

if [ ! -f "$PC_FILE" ]; then
  cat > "$PC_FILE" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: snappy
Description: Fast compressor/decompressor library
Version: 1.2.2
Libs: -L\${libdir} -lsnappy
Cflags: -I\${includedir}
EOF
  echo "==> $PC_FILE written"
else
  echo "==> $PC_FILE already installed"
fi
done_step "ensure pkg-config file"

step "verify installed files"
find "$PREFIX/lib" -maxdepth 1 \( -name 'libsnappy*' -o -name 'snappy.pc' \) -print | sort

require_file "$PREFIX/lib/libsnappy.a" "static library not found"
require_file "$PREFIX/include/snappy.h" "header not found"
require_file "$PC_FILE" "pkg-config file not found"

print_pkg_version snappy
print_pkg_static_libs snappy

begin_final_verify
print_verified_file "$PREFIX/lib/libsnappy.a"
print_verified_file "$PREFIX/include/snappy.h"
print_verified_file "$PC_FILE"

banner_end
