#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

NAME="lame"
SRC_DIR="$SRC/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

mkdir -p "$LOGS"
cd "$SRC_DIR"

make distclean >/dev/null 2>&1 || true

export LIBTOOL=glibtool
export LIBTOOLIZE=glibtoolize
export ACLOCAL_PATH="$(brew --prefix libtool)/share/aclocal${ACLOCAL_PATH:+:$ACLOCAL_PATH}"

if [ ! -x "./configure" ]; then
  ./autogen.sh 2>&1 | tee "$LOG_FILE"
else
  : > "$LOG_FILE"
fi

./configure \
  --prefix="$PREFIX" \
  --host=arm-apple-darwin \
  2>&1 | tee -a "$LOG_FILE"

make $MAKEFLAGS 2>&1 | tee -a "$LOG_FILE"
make install 2>&1 | tee -a "$LOG_FILE"

mkdir -p "$PREFIX/lib/pkgconfig"

cat > "$PREFIX/lib/pkgconfig/libmp3lame.pc" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: libmp3lame
Description: LAME MP3 encoding library
Version: 3.100
Libs: -L\${libdir} -lmp3lame
Cflags: -I\${includedir}
EOF

echo
echo "==== verify lame ====" | tee -a "$LOG_FILE"

test -f "$PREFIX/include/lame/lame.h" \
  && echo "[ok] lame headers found" | tee -a "$LOG_FILE" \
  || { echo "[fail] lame headers missing" | tee -a "$LOG_FILE"; exit 1; }

ls "$PREFIX/lib"/libmp3lame.* >/dev/null 2>&1 \
  && echo "[ok] libmp3lame found" | tee -a "$LOG_FILE" \
  || { echo "[fail] libmp3lame missing" | tee -a "$LOG_FILE"; exit 1; }

test -f "$PREFIX/lib/pkgconfig/libmp3lame.pc" \
  && echo "[ok] libmp3lame.pc found" | tee -a "$LOG_FILE" \
  || { echo "[fail] libmp3lame.pc missing" | tee -a "$LOG_FILE"; exit 1; }

pkg-config --modversion libmp3lame 2>&1 | tee -a "$LOG_FILE"
pkg-config --libs libmp3lame 2>&1 | tee -a "$LOG_FILE"
