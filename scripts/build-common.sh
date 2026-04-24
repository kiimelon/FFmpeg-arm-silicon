#!/usr/bin/env bash

# ==================================================
# Common output helpers
# ==================================================

stage() {
  echo
  echo "=================================================="
  echo "$1"
  echo "=================================================="
}

step() {
  echo
  echo "=====> $1"
}

say() {
  local prefix="${NAME:-common}"
  echo "[$prefix] $1"
}

done_step() {
  echo "[done] $1"
}

skip_step() {
  echo "[skip] $1"
}

fail_step() {
  echo "[error] $1"
}

kv() {
  local key="$1"
  local value="$2"

  printf "[info] %-18s %s\n" "$key:" "$value"
}

banner_start() {
  local name="${NAME:-unknown}"

  echo
  echo "=================================================="
  echo "Build static dependency: $name"
  echo "=================================================="
}

banner_end() {
  local name="${NAME:-unknown}"

  echo
  echo "=================================================="
  echo "Build static dependency finished: $name"
  echo "=================================================="
}

# ==================================================
# Required checks
# ==================================================

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

# ==================================================
# Cleanup helpers
# ==================================================

remove_one_la() {
  local file="$1"

  if [ -f "$file" ]; then
    step "Remove .la residue"
    say "removing $file"
    rm -f "$file"
    done_step "$file removed"
  else
    say "no .la residue found"
  fi
}

remove_many_la() {
  local found=0
  local f

  step "Remove .la residue"

  for f in "$@"; do
    if [ -f "$f" ]; then
      say "removing $f"
      rm -f "$f"
      done_step "$f removed"
      found=1
    fi
  done

  if [ "$found" -eq 0 ]; then
    say "no .la residue found"
  fi
}

# ==================================================
# pkg-config helpers
# ==================================================

print_pkg_version() {
  local pkg="$1"
  local version

  version="$("$PKG_CONFIG_BIN" --modversion "$pkg")"

  step "Check pkg-config version"
  kv "$pkg" "$version"
}

print_pkg_static_libs() {
  local pkg="$1"

  step "Check static link flags"
  "$PKG_CONFIG_BIN" --static --libs "$pkg"
}

# ==================================================
# Build environment logging
# ==================================================

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

# ==================================================
# Final file verification helpers
# ==================================================

begin_final_verify() {
  step "Verify installed files"
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

# ==================================================
# Command runner
# ==================================================

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

# ==================================================
# CMake helpers
# ==================================================

cmake_configure() {
  require_cmd_var CMAKE_BIN

  step "Configure CMake build"

  run_with_heartbeat "configure $NAME" "$LOG_FILE" \
    "$CMAKE_BIN" "$@"

  done_step "configure"
}

cmake_build() {
  require_cmd_var CMAKE_BIN

  step "Build CMake target"

  run_with_heartbeat "build $NAME" "$LOG_FILE" \
    "$CMAKE_BIN" --build "$BUILD_DIR"

  done_step "build"
}

cmake_install() {
  require_cmd_var CMAKE_BIN

  step "Install CMake target"

  run_with_heartbeat "install $NAME" "$LOG_FILE" \
    "$CMAKE_BIN" --install "$BUILD_DIR"

  done_step "install"
}

# ==================================================
# Meson helpers
# ==================================================

meson_configure() {
  require_cmd_var MESON_BIN

  step "Configure Meson build"

  run_with_heartbeat "configure $NAME" "$LOG_FILE" \
    "$MESON_BIN" setup "$BUILD_DIR" "$SRC_DIR" "$@"

  done_step "configure"
}

meson_build() {
  require_cmd_var MESON_BIN

  step "Build Meson target"

  run_with_heartbeat "build $NAME" "$LOG_FILE" \
    "$MESON_BIN" compile -C "$BUILD_DIR"

  done_step "build"
}

meson_install() {
  require_cmd_var MESON_BIN

  step "Install Meson target"

  run_with_heartbeat "install $NAME" "$LOG_FILE" \
    "$MESON_BIN" install -C "$BUILD_DIR"

  done_step "install"
}
