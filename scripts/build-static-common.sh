#!/usr/bin/env bash

banner_start() {
  echo
  echo "***** build static lib: $NAME start *****"
}

banner_end() {
  echo
  echo "***** build static lib: $NAME end *****"
}

step() {
  echo
  echo "==> $1"
}

say() {
  echo "[$NAME] $1"
}

done_step() {
  echo "==> $1 done"
}

require_cmd_var() {
  local var_name="$1"
  local value="${!var_name:-}"

  if [ -z "$value" ]; then
    echo "ERROR: required command path variable is empty: $var_name"
    exit 1
  fi
}

require_file() {
  local file="$1"
  local message="${2:-required file not found}"
  if [ ! -f "$file" ]; then
    echo "ERROR: $message: $file"
    exit 1
  fi
}

require_any_file() {
  local message="$1"
  shift

  local f
  for f in "$@"; do
    if [ -f "$f" ]; then
      return 0
    fi
  done

  echo "ERROR: $message"
  for f in "$@"; do
    echo "  missing: $f"
  done
  exit 1
}

remove_one_la() {
  local file="$1"
  if [ -f "$file" ]; then
    step "removing $file"
    rm -f "$file"
    echo "==> $file removed"
  else
    echo
    echo "==> no .la residue found for $NAME"
  fi
}

remove_many_la() {
  local found=0
  local f

  step "removing .la residue"

  for f in "$@"; do
    if [ -f "$f" ]; then
      echo "==> removing $f"
      rm -f "$f"
      echo "==> $f removed"
      found=1
    fi
  done

  if [ "$found" -eq 0 ]; then
    echo "==> no .la residue found for $NAME"
  fi
}

ensure_no_file() {
  local file="$1"
  local message="${2:-unexpected file still exists}"
  if [ -f "$file" ]; then
    echo "ERROR: $message: $file"
    exit 1
  fi
}

ensure_no_many_files() {
  local found=0
  local f

  for f in "$@"; do
    if [ -f "$f" ]; then
      found=1
    fi
  done

  if [ "$found" -eq 1 ]; then
    echo "ERROR: unexpected .la residue still exists"
    for f in "$@"; do
      [ -f "$f" ] && echo "  residue: $f"
    done
    exit 1
  fi
}

print_pkg_version() {
  local pkg="$1"
  local version
  version="$("$PKG_CONFIG_BIN" --modversion "$pkg")"
  echo
  echo "==> checking $pkg version: $version"
}

print_pkg_static_libs() {
  local pkg="$1"
  echo "==> checking static link flags:"
  "$PKG_CONFIG_BIN" --static --libs "$pkg"
}

log_build_env() {
  local logfile="$1"
  {
    echo "ROOT=$ROOT"
    echo "SRC=$SRC"
    echo "PREFIX=$PREFIX"
    echo "BUILD=$BUILD"
    echo "LOGS=$LOGS"
    echo "PATH=$PATH"
    echo "ORIGINAL_PATH=$ORIGINAL_PATH"
    echo "CC=$CC"
    echo "CFLAGS=$CFLAGS"
    [ -n "${CXX:-}" ] && echo "CXX=$CXX"
    [ -n "${CXXFLAGS:-}" ] && echo "CXXFLAGS=$CXXFLAGS"
    [ -n "${CMAKE_BIN:-}" ] && echo "CMAKE_BIN=$CMAKE_BIN"
    [ -n "${MESON_BIN:-}" ] && echo "MESON_BIN=$MESON_BIN"
    [ -n "${NINJA_BIN:-}" ] && echo "NINJA_BIN=$NINJA_BIN"
    echo "LDFLAGS=$LDFLAGS"
    echo "MAKEFLAGS=$MAKEFLAGS"
    echo "PKG_CONFIG_BIN=$PKG_CONFIG_BIN"
    echo "PKG_CONFIG_PATH=$PKG_CONFIG_PATH"
    echo "PKG_CONFIG_LIBDIR=$PKG_CONFIG_LIBDIR"
    echo
  } > "$logfile"
}

begin_final_verify() {
  echo
  echo "==> verifying installed files:"
}

print_verified_file() {
  local file="$1"
  ls -l "$file"
}

print_first_existing_file() {
  local f
  for f in "$@"; do
    if [ -f "$f" ]; then
      ls -l "$f"
      return 0
    fi
  done

  echo "ERROR: none of the candidate files exist"
  for f in "$@"; do
    echo "  missing: $f"
  done
  exit 1
}

print_verified_files() {
  begin_final_verify
  local f
  for f in "$@"; do
    ls -l "$f"
  done
}

run_with_heartbeat() {
  local label="$1"
  local logfile="$2"
  shift 2

  local interval=3
  local heartbeat_pid=""
  local cmd_pid=""
  local status=0

  (
    while true; do
      sleep "$interval"
      echo "==> still running: $label ..."
    done
  ) &
  heartbeat_pid=$!

  "$@" >> "$logfile" 2>&1 &
  cmd_pid=$!

  wait "$cmd_pid" || status=$?

  kill "$heartbeat_pid" >/dev/null 2>&1 || true
  wait "$heartbeat_pid" 2>/dev/null || true

  return "$status"
}

cmake_configure() {
  require_cmd_var CMAKE_BIN
  step "configure cmake build"
  run_with_heartbeat "configure $NAME" "$LOG_FILE" \
    "$CMAKE_BIN" "$@"
  done_step "configure"
}

cmake_build() {
  require_cmd_var CMAKE_BIN
  step "running make"
  run_with_heartbeat "build $NAME" "$LOG_FILE" \
    "$CMAKE_BIN" --build "$BUILD_DIR"
  done_step "build"
}

cmake_install() {
  require_cmd_var CMAKE_BIN
  step "running make install"
  run_with_heartbeat "install $NAME" "$LOG_FILE" \
    "$CMAKE_BIN" --install "$BUILD_DIR"
  done_step "install"
}

meson_configure() {
  require_cmd_var MESON_BIN
  step "configure meson build"
  run_with_heartbeat "configure $NAME" "$LOG_FILE" \
    "$MESON_BIN" setup "$BUILD_DIR" "$SRC_DIR" "$@"
  done_step "configure"
}

meson_build() {
  require_cmd_var MESON_BIN
  step "running make"
  run_with_heartbeat "build $NAME" "$LOG_FILE" \
    "$MESON_BIN" compile -C "$BUILD_DIR"
  done_step "build"
}

meson_install() {
  require_cmd_var MESON_BIN
  step "running make install"
  run_with_heartbeat "install $NAME" "$LOG_FILE" \
    "$MESON_BIN" install -C "$BUILD_DIR"
  done_step "install"
}
