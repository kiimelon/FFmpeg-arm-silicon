#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../env.sh"

NAME="libvorbis"
SRC_DIR="$SRC/$NAME"
LOG_FILE="$LOGS/$NAME-build.log"

mkdir -p "$LOGS"
cd "$SRC_DIR"

make distclean >/dev/null 2>&1 || true

cp configure.ac configure.ac.bak
sed -i '' 's/-force_cpusubtype_ALL//g' configure.ac

autoreconf -fiv 2>&1 | tee "$LOG_FILE"

./configure \
  --prefix="$PREFIX" \
  --host=arm-apple-darwin \
  2>&1 | tee -a "$LOG_FILE"

make $MAKEFLAGS 2>&1 | tee -a "$LOG_FILE"
make install 2>&1 | tee -a "$LOG_FILE"

echo "==== verify libvorbis ====" | tee -a "$LOG_FILE"
test -f "$PREFIX/include/vorbis/vorbisenc.h" \
  && echo "[ok] libvorbis headers found" | tee -a "$LOG_FILE" \
  || { echo "[fail] libvorbis headers missing" | tee -a "$LOG_FILE"; exit 1; }

pkg-config --modversion vorbis 2>&1 | tee -a "$LOG_FILE"
pkg-config --libs vorbis 2>&1 | tee -a "$LOG_FILE"
