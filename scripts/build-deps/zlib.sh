#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"
source "$(dirname "$0")/../build-static-common.sh"

if [ -z "${PKG_CONFIG_BIN:-}" ]; then
  echo "ERROR: pkg-config not found in ORIGINAL_PATH"
  exit 1
fi

NAME="zlib"
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

step "configuring static-only build"
run_with_heartbeat "configure $NAME" "$LOG_FILE" \
  env \
    CHOST="" \
    CC="$CC" \
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS" \
    ./configure \
      --prefix="$PREFIX" \
      --static
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
find "$PREFIX/lib" -maxdepth 1 \( -name 'libz*' -o -name 'zlib.pc' \) -print | sort

require_file "$PREFIX/lib/libz.a" "static library not found"
require_file "$PREFIX/include/zlib.h" "header not found"
require_any_file "pkg-config file not found" \
  "$PREFIX/lib/pkgconfig/zlib.pc" \
  "$PREFIX/share/pkgconfig/zlib.pc"

if [ -f "$PREFIX/lib/pkgconfig/zlib.pc" ]; then
  ZLIB_PC_FILE="$PREFIX/lib/pkgconfig/zlib.pc"
else
  ZLIB_PC_FILE="$PREFIX/share/pkgconfig/zlib.pc"
fi

print_pkg_version zlib
print_pkg_static_libs zlib

begin_final_verify
print_verified_file "$PREFIX/lib/libz.a"
print_verified_file "$PREFIX/include/zlib.h"
print_verified_file "$ZLIB_PC_FILE"

banner_end
