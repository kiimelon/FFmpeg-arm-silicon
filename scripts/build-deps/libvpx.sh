#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"
source "$(dirname "$0")/../build-static-common.sh"

NAME="libvpx"
SRC_DIR="$SRC/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

banner_start

echo "==> Building $NAME (configure)"
echo "Source : $SRC_DIR"
echo "Prefix : $PREFIX"
echo "Log    : $LOG_FILE"

require_file "$SRC_DIR/configure" "source directory not found or invalid"

mkdir -p "$LOGS"
cd "$SRC_DIR"

step "clean previous build state"
say "make distclean (ignore errors if tree is fresh)"
make distclean >/dev/null 2>&1 || true
say "make clean (ignore errors if tree is fresh)"
make clean >/dev/null 2>&1 || true

log_build_env "$LOG_FILE"

require_file "./configure" "configure script not found"

step "configuring static-only build"
run_with_heartbeat "configure $NAME" "$LOG_FILE" \
  env \
    CC="$CC" \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS" \
    ./configure \
      --prefix="$PREFIX" \
      --disable-shared \
      --enable-static \
      --disable-examples \
      --disable-tools \
      --disable-docs \
      --disable-unit-tests \
      --disable-decode-perf-tests \
      --disable-encode-perf-tests \
      --disable-webm-io \
      --enable-vp8 \
      --enable-vp9
done_step "configure"

step "running make"
run_with_heartbeat "build $NAME" "$LOG_FILE" \
  make
done_step "build"

step "running make install"
run_with_heartbeat "install $NAME" "$LOG_FILE" \
  make install
done_step "install"

echo
echo "==> no .la residue expected for $NAME"

step "verify installed files"
find "$PREFIX/lib" -maxdepth 1 \( -name 'libvpx*' -o -name 'vpx.pc' \) -print | sort

require_file "$PREFIX/lib/libvpx.a" "static library not found"
require_file "$PREFIX/include/vpx/vpx_codec.h" "header not found"
require_file "$PREFIX/lib/pkgconfig/vpx.pc" "pkg-config file not found"

print_pkg_version vpx
print_pkg_static_libs vpx

begin_final_verify
print_verified_file "$PREFIX/lib/libvpx.a"
print_verified_file "$PREFIX/include/vpx/vpx_codec.h"
print_verified_file "$PREFIX/lib/pkgconfig/vpx.pc"

banner_end
