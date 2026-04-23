#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"
source "$(dirname "$0")/../build-static-common.sh"

NAME="bzip2"
SRC_DIR="$SRC/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"
PC_DIR="$PREFIX/lib/pkgconfig"
PC_FILE="$PC_DIR/bzip2.pc"

banner_start

echo "==> Building $NAME (make)"
echo "Source : $SRC_DIR"
echo "Prefix : $PREFIX"
echo "Log    : $LOG_FILE"

require_file "$SRC_DIR/Makefile" "source directory not found or invalid"

mkdir -p "$LOGS" "$PC_DIR"
cd "$SRC_DIR"

step "clean previous build state"
say "make clean (ignore errors if tree is fresh)"
make clean >/dev/null 2>&1 || true

log_build_env "$LOG_FILE"

step "running make"
run_with_heartbeat "build $NAME" "$LOG_FILE" \
  make \
    CC="$CC" \
    CFLAGS="$CFLAGS -fPIC" \
    LDFLAGS="$LDFLAGS"
done_step "build"

step "running make install"
run_with_heartbeat "install $NAME" "$LOG_FILE" \
  make \
    PREFIX="$PREFIX" \
    install
done_step "install"

step "write pkg-config file"
cat > "$PC_FILE" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: bzip2
Description: lossless, block-sorting data compression
Version: 1.0.8
Libs: -L\${libdir} -lbz2
Cflags: -I\${includedir}
EOF
echo "==> $PC_FILE written"
done_step "write pkg-config file"

echo
echo "==> no .la residue expected for $NAME"

step "verify installed files"
find "$PREFIX/lib" -maxdepth 1 \( -name 'libbz2*' -o -name 'bzip2.pc' -o -name 'bz2.pc' \) -print | sort

require_file "$PREFIX/lib/libbz2.a" "static library not found"
require_file "$PREFIX/include/bzlib.h" "header not found"
require_file "$PC_FILE" "pkg-config file not found"

print_pkg_version bzip2
print_pkg_static_libs bzip2

begin_final_verify
print_verified_file "$PREFIX/lib/libbz2.a"
print_verified_file "$PREFIX/include/bzlib.h"
print_verified_file "$PC_FILE"

banner_end
