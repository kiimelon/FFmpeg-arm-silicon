#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"
source "$(dirname "$0")/../build-static-common.sh"

if [ -z "${PKG_CONFIG_BIN:-}" ]; then
  echo "ERROR: pkg-config not found in ORIGINAL_PATH"
  exit 1
fi

NAME="twolame"
SRC_DIR="$SRC/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"
LA_FILE="$PREFIX/lib/libtwolame.la"
PC_FILE="$PREFIX/lib/pkgconfig/twolame.pc"

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
if [ -f "configure" ]; then
  say "configure already present, skipping autogen.sh"
elif [ -f "autogen.sh" ]; then
  say "running autogen.sh"
  PATH="$ORIGINAL_PATH" ./autogen.sh >> "$LOG_FILE" 2>&1
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
    CFLAGS="$CFLAGS -std=gnu89" \
    LDFLAGS="$LDFLAGS" \
    ./configure \
      --prefix="$PREFIX" \
      --enable-static \
      --disable-shared \
      --disable-frontend \
      --disable-maintainer-mode
done_step "configure"

step "running make for library only"
run_with_heartbeat "build $NAME" "$LOG_FILE" \
  make -C libtwolame \
    CC="$CC" \
    CFLAGS="$CFLAGS -std=gnu89" \
    LDFLAGS="$LDFLAGS" \
    libtwolame.la
done_step "build"

step "install static library manually"
mkdir -p "$PREFIX/lib"

if [ -f "libtwolame/.libs/libtwolame.a" ]; then
  cp -f "libtwolame/.libs/libtwolame.a" "$PREFIX/lib/"
elif [ -f "libtwolame/libtwolame.a" ]; then
  cp -f "libtwolame/libtwolame.a" "$PREFIX/lib/"
else
  echo "ERROR: built static library not found: libtwolame/.libs/libtwolame.a or libtwolame/libtwolame.a"
  exit 1
fi
done_step "install static library manually"

step "install headers"
mkdir -p "$PREFIX/include"
if [ -f "libtwolame/twolame.h" ]; then
  cp -f "libtwolame/twolame.h" "$PREFIX/include/"
elif [ -f "twolame.h" ]; then
  cp -f "twolame.h" "$PREFIX/include/"
else
  echo "ERROR: twolame.h not found in source tree"
  exit 1
fi
done_step "install headers"

step "install pkg-config file"
mkdir -p "$PREFIX/lib/pkgconfig"

if [ -f "twolame.pc" ]; then
  cp -f "twolame.pc" "$PC_FILE"
elif [ -f "libtwolame/twolame.pc" ]; then
  cp -f "libtwolame/twolame.pc" "$PC_FILE"
else
  cat > "$PC_FILE" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: twolame
Description: MPEG Audio Layer 2 encoder
Version: 0.4.0
Libs: -L\${libdir} -ltwolame
Cflags: -I\${includedir}
EOF
fi
echo "==> $PC_FILE written"
done_step "install pkg-config file"

remove_one_la "$LA_FILE"

step "verify installed files"
find "$PREFIX/lib" -maxdepth 1 \( -name 'libtwolame*' -o -name 'twolame.pc' \) -print | sort

require_file "$PREFIX/lib/libtwolame.a" "static library not found"
require_file "$PREFIX/include/twolame.h" "header not found"
require_file "$PC_FILE" "pkg-config file not found"
ensure_no_file "$LA_FILE" ".la residue still exists"

print_pkg_version twolame
print_pkg_static_libs twolame

begin_final_verify
print_verified_file "$PREFIX/lib/libtwolame.a"
print_verified_file "$PREFIX/include/twolame.h"
print_verified_file "$PC_FILE"

banner_end
