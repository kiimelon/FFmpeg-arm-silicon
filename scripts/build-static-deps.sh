#!/usr/bin/env bash
set -euo pipefail

rm -rf ~/FFmpeg-arm-silicon/build-static
rm -rf ~/FFmpeg-arm-silicon/logs-static
rm -rf ~/FFmpeg-arm-silicon/local-static
mkdir -p ~/FFmpeg-arm-silicon/build-static
mkdir -p ~/FFmpeg-arm-silicon/logs-static
mkdir -p ~/FFmpeg-arm-silicon/local-static

source "$(dirname "$0")/env.sh"
source "$(dirname "$0")/build-static-common.sh"
source "$(dirname "$0")/deps-list.sh"

NAME="build-static-deps"
LOG_FILE="$LOGS/build-static-deps.log"

deps_banner_start() {
  echo
  echo "***** build static dependencies start *****"
}

deps_banner_end() {
  echo
  echo "***** build static dependencies end *****"
}

build_dep() {
  local dep_name="$1"
  local script_path="$ROOT/scripts/build-deps/$dep_name.sh"

  step "build dependency: $dep_name"
  echo "[deps] script : $script_path"

  if [ ! -f "$script_path" ]; then
    echo "ERROR: build script not found: $script_path"
    exit 1
  fi

  bash "$script_path" 2>&1 | tee -a "$LOG_FILE"

  done_step "build dependency: $dep_name"
}

deps_banner_start

echo "==> Building static dependencies"
echo "Source root : $SRC"
echo "Build root  : $BUILD"
echo "Prefix      : $PREFIX"
echo "Log         : $LOG_FILE"

mkdir -p "$BUILD" "$PREFIX" "$LOGS"
: > "$LOG_FILE"

{
  echo "ROOT=$ROOT"
  echo "SRC=$SRC"
  echo "BUILD=$BUILD"
  echo "PREFIX=$PREFIX"
  echo "LOGS=$LOGS"
  echo "ORIGINAL_PATH=$ORIGINAL_PATH"
  echo "PATH=$PATH"
  echo "PKG_CONFIG_PATH=$PKG_CONFIG_PATH"
  echo "PKG_CONFIG_LIBDIR=$PKG_CONFIG_LIBDIR"
  echo "CC=$CC"
  echo "CXX=$CXX"
  echo "CFLAGS=$CFLAGS"
  echo "CXXFLAGS=$CXXFLAGS"
  [ -n "${CMAKE_BIN:-}" ] && echo "CMAKE_BIN=$CMAKE_BIN"
  [ -n "${MESON_BIN:-}" ] && echo "MESON_BIN=$MESON_BIN"
  [ -n "${NINJA_BIN:-}" ] && echo "NINJA_BIN=$NINJA_BIN"
  echo "LDFLAGS=$LDFLAGS"
  echo "MAKEFLAGS=$MAKEFLAGS"
  echo
} >> "$LOG_FILE"

step "check required directories"
[ -d "$SRC" ] || { echo "ERROR: source root not found: $SRC"; exit 1; }
[ -d "$ROOT/scripts/build-deps" ] || { echo "ERROR: build-deps directory not found: $ROOT/scripts/build-deps"; exit 1; }
done_step "check required directories"

step "count dependencies"
echo "[deps] total: ${#DEPS_LIST[@]}"
done_step "count dependencies"

for dep in "${DEPS_LIST[@]}"; do
  IFS='|' read -r dep_name _ <<< "$dep"
  build_dep "$dep_name"
done

step "final verify"
find "$PREFIX/lib" -maxdepth 1 -type f \( -name '*.a' -o -name '*.pc' -o -name '*.la' \) | sort

if find "$PREFIX/lib" -maxdepth 1 -type f -name '*.la' | grep -q .; then
  echo "ERROR: .la residue still exists under $PREFIX/lib"
  find "$PREFIX/lib" -maxdepth 1 -type f -name '*.la' | sort
  exit 1
fi

echo "[deps] no .la residue found under $PREFIX/lib"
done_step "final verify"

deps_banner_end
