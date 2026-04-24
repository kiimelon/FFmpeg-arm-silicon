#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPT_DIR/../env.sh"
source "$SCRIPT_DIR/../build-common.sh"

NAME="x265"
SRC_DIR="$SRC/$NAME"
SOURCE_DIR="$SRC_DIR/source"
BUILD_DIR="$BUILD/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"
CMAKELISTS="$SOURCE_DIR/CMakeLists.txt"

patch_x265_cmake_policy() {
  step "Patch x265 source for CMake 4 compatibility"

  if [ ! -f "$CMAKELISTS" ]; then
    fail_step "x265 CMakeLists.txt not found: $CMAKELISTS"
    exit 1
  fi

  python3 - "$CMAKELISTS" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
text = p.read_text()
original = text

replacements = {
    "cmake_policy(SET CMP0025 OLD)": "cmake_policy(SET CMP0025 NEW)",
    "cmake_policy(SET CMP0054 OLD)": "cmake_policy(SET CMP0054 NEW)",
    "cmake_minimum_required(VERSION 2.8.9)": "cmake_minimum_required(VERSION 3.5)",
    "cmake_minimum_required(VERSION 2.8)": "cmake_minimum_required(VERSION 3.5)",
}

for old, new in replacements.items():
    text = text.replace(old, new)

if text != original:
    p.write_text(text)
PY

  say "x265 CMakeLists patched for current CMake"
  done_step "patch x265 source for CMake 4 compatibility"
}

banner_start

kv "Build system" "cmake"
kv "Source" "$SOURCE_DIR"
kv "Build" "$BUILD_DIR"
kv "Prefix" "$PREFIX"
kv "Log" "$LOG_FILE"

require_cmd_var CMAKE_BIN
require_file "$CMAKELISTS" "source directory not found or invalid"

mkdir -p "$LOGS"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

log_build_env "$LOG_FILE"

patch_x265_cmake_policy

step "Configure CMake build"
run_with_heartbeat "configure $NAME" "$LOG_FILE" \
  "$CMAKE_BIN" -S "$SOURCE_DIR" -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DENABLE_ASSEMBLY=OFF \
    -DENABLE_SHARED=OFF \
    -DENABLE_CLI=OFF \
    -DENABLE_TESTS=OFF \
    -DENABLE_HDR10_PLUS=OFF \
    -DENABLE_PPA=OFF \
    -DENABLE_CSV=OFF
done_step "configure"

step "Build CMake target"
run_with_heartbeat "build $NAME" "$LOG_FILE" \
  "$CMAKE_BIN" --build "$BUILD_DIR" --parallel "$NCPU"
done_step "build"

step "Install CMake target"
run_with_heartbeat "install $NAME" "$LOG_FILE" \
  "$CMAKE_BIN" --install "$BUILD_DIR"
done_step "install"

say "no .la residue expected for $NAME"

step "Verify installed files"
find "$PREFIX/lib" -maxdepth 1 \( -name 'libx265*' -o -name 'x265.pc' -o -name 'libx265.la' \) -print | sort

require_file "$PREFIX/lib/libx265.a" "static library not found"
require_file "$PREFIX/include/x265.h" "header not found"
require_file "$PREFIX/lib/pkgconfig/x265.pc" "pkg-config file not found"
ensure_no_file "$PREFIX/lib/libx265.la" ".la residue still exists"

print_pkg_version x265
print_pkg_static_libs x265

begin_final_verify
print_verified_file "$PREFIX/lib/libx265.a"
print_verified_file "$PREFIX/include/x265.h"
print_verified_file "$PREFIX/lib/pkgconfig/x265.pc"

banner_end