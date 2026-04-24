#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPT_DIR/../env.sh"
source "$SCRIPT_DIR/../build-common.sh"

NAME="twolame"
SRC_DIR="$SRC/$NAME"
BUILD_DIR="$BUILD/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

patch_twolame_asciidoc_check() {
  step "Patch twolame asciidoc maintainer check"

  require_file "./configure" "configure script not found"

  python3 - <<'PY'
from pathlib import Path

p = Path("configure")
text = p.read_text()

old = 'as_fn_error $? "asciidoc is not available and maintainer mode is enabled" "$LINENO" 5'
new = ': # asciidoc maintainer check bypassed for static library build'

count = text.count(old)
print(f"asciidoc hard error matches: {count}")

if count == 0:
    raise SystemExit("ERROR: asciidoc maintainer hard error not found in configure")

text = text.replace(old, new)
p.write_text(text)
print("patched configure asciidoc maintainer check")
PY

  if grep -n 'as_fn_error.*asciidoc is not available and maintainer mode is enabled' ./configure; then
    fail_step "twolame asciidoc hard error still exists after patch"
    exit 1
  fi

  if ! grep -n "bypassed for static library build" ./configure >> "$LOG_FILE"; then
    fail_step "twolame asciidoc bypass marker not found after patch"
    exit 1
  fi

  done_step "patch twolame asciidoc maintainer check"
}

patch_twolame_makefile_docs() {
  step "Patch twolame Makefile documentation targets"

  local doc_makefile="./doc/Makefile"

  require_file "$doc_makefile" "doc Makefile not found after configure"

  python3 - <<'PY'
from pathlib import Path

p = Path("doc/Makefile")
text = p.read_text()
original = text

replacements = {
    "dist_man_MANS = twolame.1": "dist_man_MANS =",
    "man_MANS = twolame.1": "man_MANS =",
}

for old, new in replacements.items():
    text = text.replace(old, new)

if text != original:
    p.write_text(text)
    print("patched doc/Makefile manpage target: twolame.1")
else:
    print("ERROR: twolame.1 manpage target not found in doc/Makefile")
    raise SystemExit(1)
PY

  if grep -nE '^(dist_man_MANS|man_MANS) = .*twolame\.1' "$doc_makefile"; then
    fail_step "twolame.1 manpage target still exists after patch"
    exit 1
  fi

  done_step "patch twolame Makefile documentation targets"
}

banner_start

kv "Build system" "autotools"
kv "Source" "$SRC_DIR"
kv "Build" "$BUILD_DIR"
kv "Prefix" "$PREFIX"
kv "Log" "$LOG_FILE"

if [ ! -d "$SRC_DIR" ]; then
  fail_step "source directory not found: $SRC_DIR"
  exit 1
fi

mkdir -p "$LOGS"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

log_build_env "$LOG_FILE"

cd "$SRC_DIR"

step "Prepare configure script"

if [ -f "configure" ]; then
  say "configure already present, skipping autoreconf"
elif [ -f "configure.ac" ] || [ -f "configure.in" ]; then
  say "running autoreconf"
  run_with_heartbeat "autoreconf $NAME" "$LOG_FILE" \
    autoreconf -fi
elif [ -f "autogen.sh" ]; then
  say "running autogen.sh"
  run_with_heartbeat "autogen $NAME" "$LOG_FILE" \
    ./autogen.sh
else
  say "no autogen.sh/configure.ac found, skipping autoreconf"
fi

done_step "prepare configure script"

require_file "./configure" "configure script not found"

patch_twolame_asciidoc_check

step "Configure static-only build"

{
  echo "===== twolame configure command ====="
  echo "ASCIIDOC=true A2X=true ./configure --prefix=$PREFIX --enable-static --disable-shared --disable-frontend --disable-maintainer-mode"
  echo
} >> "$LOG_FILE"

run_with_heartbeat "configure $NAME" "$LOG_FILE" \
  env \
    ASCIIDOC=true \
    A2X=true \
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

patch_twolame_makefile_docs

step "Build static library"

run_with_heartbeat "build $NAME" "$LOG_FILE" \
  make

done_step "build"

step "Install static library"

run_with_heartbeat "install $NAME" "$LOG_FILE" \
  make install

done_step "install"

step "Remove .la residue"

remove_one_la "$PREFIX/lib/libtwolame.la"

ensure_no_file "$PREFIX/lib/libtwolame.la" ".la residue still exists"

done_step "remove .la residue"

step "Verify installed files"

find "$PREFIX/lib" -maxdepth 1 \( -name 'libtwolame*' -o -name 'twolame.pc' -o -name 'libtwolame.la' \) -print | sort

require_file "$PREFIX/lib/libtwolame.a" "static library not found"
require_file "$PREFIX/include/twolame.h" "header not found"
require_file "$PREFIX/lib/pkgconfig/twolame.pc" "pkg-config file not found"
ensure_no_file "$PREFIX/lib/libtwolame.la" ".la residue still exists"

print_pkg_version twolame
print_pkg_static_libs twolame

begin_final_verify
print_verified_file "$PREFIX/lib/libtwolame.a"
print_verified_file "$PREFIX/include/twolame.h"
print_verified_file "$PREFIX/lib/pkgconfig/twolame.pc"

banner_end