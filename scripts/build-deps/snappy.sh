#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

if [ -z "${CMAKE_BIN:-}" ]; then
  echo "ERROR: cmake not found in ORIGINAL_PATH"
  exit 1
fi

SNAPPY_SRC="$SRC/snappy"
SNAPPY_BUILD_DIR="$BUILD/snappy"
SNAPPY_BUILD_LOG="$LOGS/snappy-build.log"
SNAPPY_INSTALL_LOG="$LOGS/snappy-install.log"

echo "==> Building snappy (CMake)"
echo "Source : $SNAPPY_SRC"
echo "Build  : $SNAPPY_BUILD_DIR"
echo "Prefix : $PREFIX"
echo "Logs   : $LOGS"

if [ ! -d "$SNAPPY_SRC" ]; then
  echo "ERROR: source directory not found: $SNAPPY_SRC"
  exit 1
fi

rm -rf "$SNAPPY_BUILD_DIR"
mkdir -p "$SNAPPY_BUILD_DIR"
mkdir -p "$PREFIX/lib/pkgconfig"

{
  echo "ROOT=$ROOT"
  echo "SRC=$SRC"
  echo "BUILD=$BUILD"
  echo "PREFIX=$PREFIX"
  echo "PATH=$PATH"
  echo "ORIGINAL_PATH=$ORIGINAL_PATH"
  echo "CC=$CC"
  echo "CFLAGS=$CFLAGS"
  echo "CXX=$CXX"
  echo "CXXFLAGS=$CXXFLAGS"
  echo "LDFLAGS=$LDFLAGS"
  echo "MAKEFLAGS=$MAKEFLAGS"
  echo "CMAKE_BIN=$CMAKE_BIN"
  echo
  echo "===== cmake configure ====="
} > "$SNAPPY_BUILD_LOG"

"$CMAKE_BIN" -S "$SNAPPY_SRC" -B "$SNAPPY_BUILD_DIR" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET" \
  -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
  -DCMAKE_C_COMPILER="$CC" \
  -DCMAKE_CXX_COMPILER="$CXX" \
  -DCMAKE_C_FLAGS="$CFLAGS" \
  -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
  -DBUILD_SHARED_LIBS=OFF \
  -DSNAPPY_BUILD_TESTS=OFF \
  -DSNAPPY_BUILD_BENCHMARKS=OFF \
  >> "$SNAPPY_BUILD_LOG" 2>&1

"$CMAKE_BIN" --build "$SNAPPY_BUILD_DIR" >> "$SNAPPY_BUILD_LOG" 2>&1

{
  echo "===== cmake install ====="
} > "$SNAPPY_INSTALL_LOG"

"$CMAKE_BIN" --install "$SNAPPY_BUILD_DIR" >> "$SNAPPY_INSTALL_LOG" 2>&1

# Provide pkg-config metadata if upstream does not install one.
if [ ! -f "$PREFIX/lib/pkgconfig/snappy.pc" ]; then
  cat > "$PREFIX/lib/pkgconfig/snappy.pc" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: snappy
Description: fast compressor/decompressor
Version: 1.2.2
Libs: -L\${libdir} -lsnappy
Cflags: -I\${includedir}
EOF
fi

echo "==> Verifying snappy install"

if [ ! -f "$PREFIX/include/snappy.h" ]; then
  echo "ERROR: header not found: $PREFIX/include/snappy.h"
  exit 1
fi

if [ ! -f "$PREFIX/lib/pkgconfig/snappy.pc" ]; then
  echo "ERROR: pkg-config file not found: $PREFIX/lib/pkgconfig/snappy.pc"
  exit 1
fi

echo "==> snappy installed successfully"
ls -l "$PREFIX/include/snappy.h"
ls -l "$PREFIX/lib/pkgconfig/snappy.pc"

find "$PREFIX/lib" -maxdepth 1 \( -name 'libsnappy*.a' -o -name 'libsnappy*.dylib' \) -print
