#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

if [ -z "${CMAKE_BIN:-}" ]; then
  echo "ERROR: cmake not found in ORIGINAL_PATH"
  exit 1
fi

if [ -z "${PKG_CONFIG_BIN:-}" ]; then
  echo "ERROR: pkg-config not found in ORIGINAL_PATH"
  exit 1
fi

NAME="freetype"
SRC_DIR="$SRC/$NAME"
BUILD_DIR="$BUILD/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"
MODULES_CFG="$SRC_DIR/modules.cfg"

echo "==> Building freetype (CMake, static, hvf removed)"
echo "Source : $SRC_DIR"
echo "Build  : $BUILD_DIR"
echo "Prefix : $PREFIX"
echo "Log    : $LOG_FILE"

if [ ! -d "$SRC_DIR" ]; then
  echo "ERROR: source directory not found: $SRC_DIR"
  exit 1
fi

if [ ! -f "$MODULES_CFG" ]; then
  echo "ERROR: modules.cfg not found: $MODULES_CFG"
  exit 1
fi

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$LOGS"

{
  echo "ROOT=$ROOT"
  echo "SRC=$SRC"
  echo "BUILD=$BUILD"
  echo "PREFIX=$PREFIX"
  echo "PATH=$PATH"
  echo "ORIGINAL_PATH=$ORIGINAL_PATH"
  echo "CC=$CC"
  echo "CXX=$CXX"
  echo "CFLAGS=$CFLAGS"
  echo "CXXFLAGS=$CXXFLAGS"
  echo "LDFLAGS=$LDFLAGS"
  echo "MAKEFLAGS=$MAKEFLAGS"
  echo "CMAKE_BIN=$CMAKE_BIN"
  echo "PKG_CONFIG_BIN=$PKG_CONFIG_BIN"
  echo "PKG_CONFIG_PATH=$PKG_CONFIG_PATH"
  echo "PKG_CONFIG_LIBDIR=$PKG_CONFIG_LIBDIR"
  echo "MODULES_CFG=$MODULES_CFG"
  echo
  echo "===== patch modules.cfg ====="
} > "$LOG_FILE"

cp "$MODULES_CFG" "$MODULES_CFG.bak"

if grep -q '^FONT_MODULES += hvf$' "$MODULES_CFG"; then
  sed -i.bak '/^FONT_MODULES += hvf$/d' "$MODULES_CFG"
  echo "Removed hvf from modules.cfg" >> "$LOG_FILE"
else
  echo "hvf entry not found; continuing" >> "$LOG_FILE"
fi

echo >> "$LOG_FILE"
echo "===== modules.cfg after patch =====" >> "$LOG_FILE"
grep -n 'hvf\|FONT_MODULES' "$MODULES_CFG" >> "$LOG_FILE" || true

echo >> "$LOG_FILE"
echo "===== cmake configure =====" >> "$LOG_FILE"

"$CMAKE_BIN" -S "$SRC_DIR" -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET" \
  -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
  -DCMAKE_C_COMPILER="$CC" \
  -DCMAKE_C_FLAGS="$CFLAGS" \
  -DBUILD_SHARED_LIBS=OFF \
  -DFT_DISABLE_HVF=ON \
  -DFT_DISABLE_HARFBUZZ=ON \
  -DFT_REQUIRE_ZLIB=ON \
  -DFT_REQUIRE_BZIP2=ON \
  -DFT_REQUIRE_BROTLI=ON \
  -DFT_WITH_ZLIB=ON \
  -DFT_WITH_BZIP2=ON \
  -DFT_WITH_BROTLI=ON \
  -DFT_WITH_HARFBUZZ=OFF \
  -DFT_WITH_PNG=OFF \
  -DFT_WITH_HVF=OFF \
  -DCMAKE_DISABLE_FIND_PACKAGE_PNG=TRUE \
  -DCMAKE_DISABLE_FIND_PACKAGE_HarfBuzz=TRUE \
  -DCMAKE_DISABLE_FIND_PACKAGE_HarfBuzzSubset=TRUE \
  -DCMAKE_DISABLE_FIND_PACKAGE_HVF=TRUE \
  >> "$LOG_FILE" 2>&1

{
  echo
  echo "===== build ====="
} >> "$LOG_FILE"

"$CMAKE_BIN" --build "$BUILD_DIR" --parallel "$NCPU" >> "$LOG_FILE" 2>&1

{
  echo
  echo "===== install ====="
} >> "$LOG_FILE"

"$CMAKE_BIN" --install "$BUILD_DIR" >> "$LOG_FILE" 2>&1

echo "==> Verifying freetype install"

find "$PREFIX/lib" -maxdepth 1 -name 'libfreetype*' -print | sort

if [ ! -f "$PREFIX/lib/libfreetype.a" ]; then
  echo "ERROR: static library not found: $PREFIX/lib/libfreetype.a"
  exit 1
fi

if [ ! -f "$PREFIX/include/freetype2/freetype/freetype.h" ]; then
  echo "ERROR: header not found: $PREFIX/include/freetype2/freetype/freetype.h"
  exit 1
fi

if [ ! -f "$PREFIX/lib/pkgconfig/freetype2.pc" ]; then
  echo "ERROR: pkg-config file not found: $PREFIX/lib/pkgconfig/freetype2.pc"
  exit 1
fi

echo
echo "===== unresolved HVF symbol check ====="
if nm -gU "$PREFIX/lib/libfreetype.a" 2>/dev/null | grep -q ' U _HVF_'; then
  echo "ERROR: libfreetype.a still contains unresolved HVF symbols"
  nm -gU "$PREFIX/lib/libfreetype.a" | grep ' U _HVF_' | head -20
  exit 1
else
  echo "OK: no unresolved HVF symbols found in libfreetype.a"
fi

echo
echo "===== pkg-config verify ====="
"$PKG_CONFIG_BIN" --modversion freetype2
"$PKG_CONFIG_BIN" --static --libs freetype2

echo
echo "==> freetype installed successfully"
ls -l "$PREFIX/lib/libfreetype.a"
ls -l "$PREFIX/include/freetype2/freetype/freetype.h"
ls -l "$PREFIX/lib/pkgconfig/freetype2.pc"
