#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"
source "$(dirname "$0")/../build-static-common.sh"

if [ -z "${PKG_CONFIG_BIN:-}" ]; then
  echo "ERROR: pkg-config not found in ORIGINAL_PATH"
  exit 1
fi

NAME="lame"
SRC_DIR="$SRC/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"
LA_FILE="$PREFIX/lib/libmp3lame.la"
PC_DIR="$PREFIX/lib/pkgconfig"
PC_FILE="$PC_DIR/mp3lame.pc"

banner_start

echo "==> Building $NAME (autotools)"
echo "Source : $SRC_DIR"
echo "Prefix : $PREFIX"
echo "Log    : $LOG_FILE"

require_any_file "source directory not found or invalid" \
  "$SRC_DIR/configure" \
  "$SRC_DIR/config.sub" \
  "$SRC_DIR/config.guess"

mkdir -p "$LOGS" "$PC_DIR"
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
say "keeping bundled configure"
say "refreshing config.sub and config.guess"

CONFIG_SUB_SRC=""
CONFIG_GUESS_SRC=""

for candidate in \
  "/opt/homebrew/share/automake-1.18/config.sub" \
  "/opt/homebrew/share/automake-1.17/config.sub" \
  "/opt/homebrew/share/automake-1.16/config.sub" \
  "/usr/local/share/automake-1.18/config.sub" \
  "/usr/local/share/automake-1.17/config.sub" \
  "/usr/local/share/automake-1.16/config.sub"
do
  if [ -f "$candidate" ]; then
    CONFIG_SUB_SRC="$candidate"
    break
  fi
done

for candidate in \
  "/opt/homebrew/share/automake-1.18/config.guess" \
  "/opt/homebrew/share/automake-1.17/config.guess" \
  "/opt/homebrew/share/automake-1.16/config.guess" \
  "/usr/local/share/automake-1.18/config.guess" \
  "/usr/local/share/automake-1.17/config.guess" \
  "/usr/local/share/automake-1.16/config.guess"
do
  if [ -f "$candidate" ]; then
    CONFIG_GUESS_SRC="$candidate"
    break
  fi
done

if [ -z "$CONFIG_SUB_SRC" ] || [ -z "$CONFIG_GUESS_SRC" ]; then
  echo "ERROR: failed to find modern config.sub/config.guess from automake"
  exit 1
fi

cp "$CONFIG_SUB_SRC" ./config.sub
cp "$CONFIG_GUESS_SRC" ./config.guess
chmod +x ./config.sub ./config.guess

say "config.sub  <- $CONFIG_SUB_SRC"
say "config.guess <- $CONFIG_GUESS_SRC"

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
  make
done_step "build"

step "running make install"
run_with_heartbeat "install $NAME" "$LOG_FILE" \
  make install
done_step "install"

remove_one_la "$LA_FILE"

step "write pkg-config file"
cat > "$PC_FILE" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: mp3lame
Description: LAME MP3 encoder library
Version: 3.100
Libs: -L\${libdir} -lmp3lame
Cflags: -I\${includedir}
EOF
echo "==> $PC_FILE written"
done_step "write pkg-config file"

step "verify installed files"
find "$PREFIX/lib" -maxdepth 1 \( -name 'libmp3lame*' -o -name 'mp3lame.pc' \) -print | sort

require_file "$PREFIX/lib/libmp3lame.a" "static library not found"
require_file "$PREFIX/include/lame/lame.h" "header not found"
require_file "$PC_FILE" "pkg-config file not found"
ensure_no_file "$LA_FILE" ".la residue still exists"

print_pkg_version mp3lame
print_pkg_static_libs mp3lame

begin_final_verify
print_verified_file "$PREFIX/lib/libmp3lame.a"
print_verified_file "$PREFIX/include/lame/lame.h"
print_verified_file "$PC_FILE"

banner_end
