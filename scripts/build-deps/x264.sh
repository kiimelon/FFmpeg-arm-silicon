#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"
source "$(dirname "$0")/../build-static-common.sh"

if [ -z "${PKG_CONFIG_BIN:-}" ]; then
  echo "ERROR: pkg-config not found in ORIGINAL_PATH"
  exit 1
fi

NAME="x264"
SRC_DIR="$SRC/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"
LA_FILE="$PREFIX/lib/libx264.la"

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
      --enable-static \
      --disable-shared \
      --disable-cli
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
find "$PREFIX/lib" -maxdepth 1 \( -name 'libx264*' -o -name 'x264.pc' \) -print | sort

require_file "$PREFIX/lib/libx264.a" "static library not found"
require_file "$PREFIX/include/x264.h" "header not found"
require_file "$PREFIX/lib/pkgconfig/x264.pc" "pkg-config file not found"
ensure_no_file "$LA_FILE" ".la residue still exists"

print_pkg_version x264
print_pkg_static_libs x264

begin_final_verify
print_verified_file "$PREFIX/lib/libx264.a"
print_verified_file "$PREFIX/include/x264.h"
print_verified_file "$PREFIX/lib/pkgconfig/x264.pc"

banner_end
