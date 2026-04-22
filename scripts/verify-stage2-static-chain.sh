#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

if [ -z "${PKG_CONFIG_BIN:-}" ]; then
  echo "ERROR: pkg-config not found in ORIGINAL_PATH"
  exit 1
fi

FAILED=0

check_file() {
  local label="$1"
  local pattern="$2"

  echo "==> checking files for $label"
  if find "$PREFIX/lib" -maxdepth 1 -name "$pattern" -print | sort; then
    :
  fi

  if ! find "$PREFIX/lib" -maxdepth 1 -name "$pattern" | grep -q .; then
    echo "ERROR: missing file pattern in $PREFIX/lib: $pattern"
    FAILED=1
  fi
  echo
}

check_header() {
  local label="$1"
  local path="$2"

  echo "==> checking header for $label"
  if [ -f "$path" ]; then
    echo "OK: $path"
  else
    echo "ERROR: missing header: $path"
    FAILED=1
  fi
  echo
}

check_pc() {
  local label="$1"
  local pkg="$2"

  echo "==> checking pkg-config for $label ($pkg)"

  if "$PKG_CONFIG_BIN" --modversion "$pkg"; then
    :
  else
    echo "ERROR: pkg-config modversion failed for $pkg"
    FAILED=1
  fi

  if "$PKG_CONFIG_BIN" --static --libs "$pkg"; then
    :
  else
    echo "ERROR: pkg-config static libs failed for $pkg"
    FAILED=1
  fi

  echo
}

echo "===== verify stage2 static chain ====="
echo "PREFIX=$PREFIX"
echo "PKG_CONFIG_BIN=$PKG_CONFIG_BIN"
echo

# zlib
check_file   "zlib"      "libz.a"
check_header "zlib"      "$PREFIX/include/zlib.h"
check_pc     "zlib"      "zlib"

# bzip2
check_file   "bzip2"     "libbz2*.a"
check_header "bzip2"     "$PREFIX/include/bzlib.h"
check_pc     "bzip2"     "bzip2"

# brotli
check_file   "brotli"    "libbrotli*.a"
check_header "brotli"    "$PREFIX/include/brotli/decode.h"
check_pc     "brotli"    "libbrotlidec"

# freetype
check_file   "freetype"  "libfreetype.a"
check_header "freetype"  "$PREFIX/include/freetype2/freetype/freetype.h"
check_pc     "freetype"  "freetype2"

# fribidi
check_file   "fribidi"   "libfribidi.a"
check_header "fribidi"   "$PREFIX/include/fribidi/fribidi.h"
check_pc     "fribidi"   "fribidi"

# harfbuzz
check_file   "harfbuzz"  "libharfbuzz.a"
check_header "harfbuzz"  "$PREFIX/include/harfbuzz/hb.h"
check_pc     "harfbuzz"  "harfbuzz"

# libass
check_file   "libass"    "libass.a"
check_header "libass"    "$PREFIX/include/ass/ass.h"
check_pc     "libass"    "libass"

if [ "$FAILED" -ne 0 ]; then
  echo "===== FAILED: stage2 static chain is incomplete ====="
  exit 1
fi

echo "===== PASS: stage2 static chain is ready for build-ffmpeg-suite ====="
