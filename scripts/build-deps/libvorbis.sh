#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"
source "$(dirname "$0")/../build-static-common.sh"

if [ -z "${PKG_CONFIG_BIN:-}" ]; then
  echo "ERROR: pkg-config not found in ORIGINAL_PATH"
  exit 1
fi

NAME="libvorbis"
SRC_DIR="$SRC/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

LA_FILES=(
  "$PREFIX/lib/libvorbis.la"
  "$PREFIX/lib/libvorbisenc.la"
  "$PREFIX/lib/libvorbisfile.la"
)

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

log_build_env "$LOG_FILE"

step "prepare build system"
if [ -f "autogen.sh" ]; then
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
    CFLAGS="$CFLAGS" \
    LDFLAGS="$LDFLAGS" \
    ./configure \
      --prefix="$PREFIX" \
      --enable-static \
      --disable-shared
done_step "configure"

step "running make"
run_with_heartbeat "build $NAME" "$LOG_FILE" \
  make -C lib \
    libvorbis.la \
    libvorbisenc.la \
    libvorbisfile.la
done_step "build"

step "install static libraries manually"
mkdir -p "$PREFIX/lib"

require_file "lib/.libs/libvorbis.a" "built static library not found"
cp -f "lib/.libs/libvorbis.a" "$PREFIX/lib/"

if [ -f "lib/.libs/libvorbisenc.a" ]; then
  cp -f "lib/.libs/libvorbisenc.a" "$PREFIX/lib/"
fi

if [ -f "lib/.libs/libvorbisfile.a" ]; then
  cp -f "lib/.libs/libvorbisfile.a" "$PREFIX/lib/"
fi
done_step "install static libraries manually"

step "install headers"
mkdir -p "$PREFIX/include/vorbis"
cp -f include/vorbis/*.h "$PREFIX/include/vorbis/"
done_step "install headers"

step "install pkg-config files"
mkdir -p "$PREFIX/lib/pkgconfig"

if [ -f "vorbis.pc" ]; then
  cp -f "vorbis.pc" "$PREFIX/lib/pkgconfig/"
fi

if [ -f "vorbisenc.pc" ]; then
  cp -f "vorbisenc.pc" "$PREFIX/lib/pkgconfig/"
fi

if [ -f "vorbisfile.pc" ]; then
  cp -f "vorbisfile.pc" "$PREFIX/lib/pkgconfig/"
fi
done_step "install pkg-config files"

remove_many_la "${LA_FILES[@]}"

step "verify installed files"
find "$PREFIX/lib" -maxdepth 1 -name 'libvorbis*' -print | sort

require_file "$PREFIX/lib/libvorbis.a" "static library not found"
require_file "$PREFIX/include/vorbis/codec.h" "header not found"
require_file "$PREFIX/lib/pkgconfig/vorbis.pc" "pkg-config file not found"
ensure_no_many_files "${LA_FILES[@]}"

print_pkg_version vorbis
print_pkg_static_libs vorbis

if [ -f "$PREFIX/lib/pkgconfig/vorbisenc.pc" ]; then
  print_pkg_version vorbisenc
  print_pkg_static_libs vorbisenc
fi

if [ -f "$PREFIX/lib/pkgconfig/vorbisfile.pc" ]; then
  print_pkg_version vorbisfile
  print_pkg_static_libs vorbisfile
fi

begin_final_verify
print_verified_file "$PREFIX/lib/libvorbis.a"
print_verified_file "$PREFIX/include/vorbis/codec.h"
print_verified_file "$PREFIX/lib/pkgconfig/vorbis.pc"

banner_end
