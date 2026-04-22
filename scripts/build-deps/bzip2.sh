#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

if [ -z "${CMAKE_BIN:-}" ]; then
  echo "ERROR: cmake not found in ORIGINAL_PATH"
  exit 1
fi

BZIP2_SRC="$SRC/bzip2"
BZIP2_BUILD_DIR="$BUILD/bzip2"
BZIP2_BUILD_LOG="$LOGS/bzip2-build.log"
BZIP2_INSTALL_LOG="$LOGS/bzip2-install.log"

echo "==> Building bzip2 (CMake)"
echo "Source : $BZIP2_SRC"
echo "Build  : $BZIP2_BUILD_DIR"
echo "Prefix : $PREFIX"
echo "Logs   : $LOGS"

if [ ! -d "$BZIP2_SRC" ]; then
  echo "ERROR: source directory not found: $BZIP2_SRC"
  exit 1
fi

rm -rf "$BZIP2_BUILD_DIR"
mkdir -p "$BZIP2_BUILD_DIR"
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
} > "$BZIP2_BUILD_LOG"

"$CMAKE_BIN" -S "$BZIP2_SRC" -B "$BZIP2_BUILD_DIR" \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET" \
  -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
  -DCMAKE_C_COMPILER="$CC" \
  -DCMAKE_C_FLAGS="$CFLAGS" \
  -DENABLE_SHARED_LIB=OFF \
  -DENABLE_STATIC_LIB=ON \
  >> "$BZIP2_BUILD_LOG" 2>&1

"$CMAKE_BIN" --build "$BZIP2_BUILD_DIR" >> "$BZIP2_BUILD_LOG" 2>&1

{
  echo "===== cmake install ====="
} > "$BZIP2_INSTALL_LOG"

"$CMAKE_BIN" --install "$BZIP2_BUILD_DIR" >> "$BZIP2_INSTALL_LOG" 2>&1

# Overwrite pkg-config metadata so it matches the actual installed static library.
cat > "$PREFIX/lib/pkgconfig/bzip2.pc" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: bzip2
Description: lossless, block-sorting data compression
Version: 1.0.8
Libs: -L\${libdir} -lbz2_static
Cflags: -I\${includedir}
EOF

echo "==> Verifying bzip2 install"

if [ ! -f "$PREFIX/lib/libbz2_static.a" ]; then
  echo "ERROR: static library not found: $PREFIX/lib/libbz2_static.a"
  exit 1
fi

if [ ! -f "$PREFIX/include/bzlib.h" ]; then
  echo "ERROR: header not found: $PREFIX/include/bzlib.h"
  exit 1
fi

if [ ! -f "$PREFIX/lib/pkgconfig/bzip2.pc" ]; then
  echo "ERROR: pkg-config file not found: $PREFIX/lib/pkgconfig/bzip2.pc"
  exit 1
fi

echo "==> bzip2 installed successfully"
ls -l "$PREFIX/lib/libbz2_static.a"
ls -l "$PREFIX/include/bzlib.h"
ls -l "$PREFIX/lib/pkgconfig/bzip2.pc"
