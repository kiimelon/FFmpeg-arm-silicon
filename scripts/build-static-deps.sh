#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPT_DIR/env.sh"
source "$SCRIPT_DIR/build-common.sh"
source "$SCRIPT_DIR/deps-list.sh"

NAME="build-static-deps"
LOG_FILE="$LOGS/build-static-deps.log"

reset_static_outputs() {
  step "Reset static build outputs"

  say "remove: $BUILD"
  rm -rf "$BUILD"

  say "remove: $LOGS"
  rm -rf "$LOGS"

  say "remove: $PREFIX"
  rm -rf "$PREFIX"

  say "create: $BUILD"
  mkdir -p "$BUILD"

  say "create: $LOGS"
  mkdir -p "$LOGS"

  say "create: $PREFIX"
  mkdir -p "$PREFIX"

  done_step "reset static build outputs"
}

log_static_deps_env() {
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
}

require_static_deps_inputs() {
  step "Check required directories"

  if [ ! -d "$SRC" ]; then
    fail_step "source root not found: $SRC"
    exit 1
  fi

  if [ ! -d "$ROOT/scripts/build-deps" ]; then
    fail_step "build-deps directory not found: $ROOT/scripts/build-deps"
    exit 1
  fi

  done_step "check required directories"
}

build_dep() {
  local dep_name="$1"
  local script_path="$ROOT/scripts/build-deps/$dep_name.sh"

  step "Build static dependency: $dep_name"

  say "script: $script_path"

  if [ ! -f "$script_path" ]; then
    fail_step "build script not found: $script_path"
    exit 1
  fi

  bash "$script_path" 2>&1 | tee -a "$LOG_FILE"

  done_step "build dependency: $dep_name"
}

print_group_summary() {
  local group_name="$1"
  shift

  echo
  echo "Summary: $group_name"

  local dep_name
  for dep_name in "$@"; do
    printf "  %-16s PASS\n" "$dep_name"
  done
}

build_group() {
  local group_id="$1"
  local group_name="$2"
  local group_var="DEPS_ORDER_${group_id}"

  local group_deps=()
  eval "group_deps=(\"\${${group_var}[@]}\")"

  stage "Build group: $group_name"

  local dep_name
  for dep_name in "${group_deps[@]}"; do
    build_dep "$dep_name"
  done

  print_group_summary "$group_name" "${group_deps[@]}"
}

verify_static_deps_output() {
  step "Final verify"

  say "installed static libraries and pkg-config files:"
  find "$PREFIX/lib" -maxdepth 1 -type f \( -name '*.a' -o -name '*.pc' -o -name '*.la' \) | sort

  if find "$PREFIX/lib" -maxdepth 1 -type f -name '*.la' | grep -q .; then
    fail_step ".la residue still exists under $PREFIX/lib"
    find "$PREFIX/lib" -maxdepth 1 -type f -name '*.la' | sort
    exit 1
  fi

  say "no .la residue found under $PREFIX/lib"
  done_step "final verify"
}

stage "Stage 2: Building static dependencies"

kv "Source root" "$SRC"
kv "Build root" "$BUILD"
kv "Prefix" "$PREFIX"
kv "Log file" "$LOG_FILE"

reset_static_outputs

: > "$LOG_FILE"
log_static_deps_env

require_static_deps_inputs

step "Count dependencies"
say "total source entries: ${#DEPS_LIST[@]}"
say "total build entries : ${#DEPS_ORDER[@]}"
done_step "count dependencies"

for i in "${!DEPS_GROUP_IDS[@]}"; do
  group_id="${DEPS_GROUP_IDS[$i]}"
  group_name="${DEPS_GROUP_NAMES[$i]}"

  build_group "$group_id" "$group_name"
done

verify_static_deps_output

stage "Static dependencies completed"
