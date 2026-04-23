#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"
source "$(dirname "$0")/../build-static-common.sh"

if [ -z "${PKG_CONFIG_BIN:-}" ]; then
  echo "ERROR: pkg-config not found in ORIGINAL_PATH"
  exit 1
fi

NAME="libzmq"
SRC_DIR="$SRC/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"
LA_FILE="$PREFIX/lib/libzmq.la"

banner_start

echo "==> Building $NAME (autotools)"
echo "Source : $SRC_DIR"
echo "Prefix : $PREFIX"
echo "Log    : $LOG_FILE"

require_any_file "source directory not found or invalid" \
  "$SRC_DIR/configure" \
  "$SRC_DIR/configure.ac" \
  "$SRC_DIR/configure.in" \
  "$SRC_DIR/autogen.sh"

mkdir -p "$LOGS"
cd "$SRC_DIR"

step "clean previous build state"
say "make distclean (ignore errors if tree is fresh)"
make distclean >/dev/null 2>&1 || true
say "make clean (ignore errors if tree is fresh)"
make clean >/dev/null 2>&1 || true
say "remove stale config.cache"
rm -f config.cache

log_build_env "$LOG_FILE"

step "prepare build system"
if [ -f "autogen.sh" ]; then
  say "running autogen.sh with NOCONFIGURE=1"
  PATH="$ORIGINAL_PATH" NOCONFIGURE=1 ./autogen.sh >> "$LOG_FILE" 2>&1
  say "autogen.sh done"
elif [ -f "configure.ac" ] || [ -f "configure.in" ]; then
  say "running autoreconf -fi"
  PATH="$ORIGINAL_PATH" autoreconf -fi >> "$LOG_FILE" 2>&1
  say "autoreconf done"
else
  say "no autogen.sh/configure.ac found, skipping autoreconf"
fi

require_file "./configure" "configure script not found"

step "configuring static-only build"
run_with_heartbeat "configure $NAME" "$LOG_FILE" \
  env \
    PKG_CONFIG="$PKG_CONFIG_BIN" \
    PKG_CONFIG_PATH="$PKG_CONFIG_PATH" \
    PKG_CONFIG_LIBDIR="$PKG_CONFIG_LIBDIR" \
    CC="$CC" \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS" \
    ./configure \
      --prefix="$PREFIX" \
      --enable-static \
      --disable-shared \
      --disable-perf
done_step "configure"

step "running make"
run_with_heartbeat "build $NAME" "$LOG_FILE" \
  make
done_step "build"

step "running make install"
run_with_heartbeat "install $NAME" "$LOG_FILE" \
  make install
done_step "install"

remove_one_la "$LA_FILE"

step "verify installed files"
find "$PREFIX/lib" -maxdepth 1 -name 'libzmq*' -print | sort

require_file "$PREFIX/lib/libzmq.a" "static library not found"
require_file "$PREFIX/include/zmq.h" "header not found"
require_file "$PREFIX/lib/pkgconfig/libzmq.pc" "pkg-config file not found"
ensure_no_file "$LA_FILE" ".la residue still exists"

print_pkg_version libzmq
print_pkg_static_libs libzmq

print_verified_files \
  "$PREFIX/lib/libzmq.a" \
  "$PREFIX/include/zmq.h" \
  "$PREFIX/lib/pkgconfig/libzmq.pc"

banner_end
