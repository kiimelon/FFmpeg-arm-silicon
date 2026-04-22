#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

if [ -z "${PKG_CONFIG_BIN:-}" ]; then
  echo "ERROR: pkg-config not found in ORIGINAL_PATH"
  exit 1
fi

FFMPEG_VERSION="ffmpeg-8.1"
FFMPEG_SRC="$SRC/$FFMPEG_VERSION"

CONFIG_LOG="$LOGS/ffmpeg-configure.log"
MAKE_LOG="$LOGS/ffmpeg-make.log"
INSTALL_LOG="$LOGS/ffmpeg-install.log"

REQUIRED_PKG_PAIRS=(
  "sdl2:sdl2"
  "freetype:freetype2"
  "fribidi:fribidi"
  "harfbuzz:harfbuzz"
  "libass:libass"
  "x264:x264"
  "libvpx:vpx"
  "dav1d:dav1d"
  "ogg:ogg"
  "opus:opus"
  "vorbis:vorbis"
  "libmp3lame:libmp3lame"
  "libwebp:libwebp"
  "openjpeg:libopenjp2"
  "theora:theora"
  "twolame:twolame"
  "soxr:soxr"
  "snappy:snappy"
  "zimg:zimg"
  "libxml2:libxml-2.0"
  "libzmq:libzmq"
)

echo "==> Building FFmpeg suite"
echo "Source : $FFMPEG_SRC"
echo "Prefix : $PREFIX"
echo "Logs   : $LOGS"
echo "pkg-config: $PKG_CONFIG_BIN"

if [ ! -d "$FFMPEG_SRC" ]; then
  echo "ERROR: source directory not found: $FFMPEG_SRC"
  exit 1
fi

cd "$FFMPEG_SRC"

make distclean >/dev/null 2>&1 || true

echo "==> Checking required dependencies..."

for pair in "${REQUIRED_PKG_PAIRS[@]}"; do
  name="${pair%%:*}"
  pkg="${pair#*:}"
  echo "   - $name -> $pkg"
  if ! "$PKG_CONFIG_BIN" --exists "$pkg"; then
    echo "ERROR: missing pkg-config package for $name: $pkg"
    exit 1
  fi
done

{
  echo "ROOT=$ROOT"
  echo "SRC=$SRC"
  echo "PREFIX=$PREFIX"
  echo "PATH=$PATH"
  echo "ORIGINAL_PATH=$ORIGINAL_PATH"
  echo "PKG_CONFIG_BIN=${PKG_CONFIG_BIN:-unset}"
  echo "PKG_CONFIG_PATH=$PKG_CONFIG_PATH"
  echo "PKG_CONFIG_LIBDIR=$PKG_CONFIG_LIBDIR"
  echo "CC=$CC"
  echo "CXX=$CXX"
  echo "CFLAGS=$CFLAGS"
  echo "CXXFLAGS=$CXXFLAGS"
  echo "LDFLAGS=$LDFLAGS"
  echo "LIBTOOL=${LIBTOOL:-unset}"
  echo "LIBTOOLIZE=${LIBTOOLIZE:-unset}"
  echo
  echo "===== pkg-config versions ====="
  for pair in "${REQUIRED_PKG_PAIRS[@]}"; do
    name="${pair%%:*}"
    pkg="${pair#*:}"
    echo "--- $name -> $pkg ---"
    "$PKG_CONFIG_BIN" --modversion "$pkg"
    "$PKG_CONFIG_BIN" --static --libs "$pkg"
    echo
  done
  echo "===== configure ====="
  echo "ffmpeg configure will use pkg-config: $PKG_CONFIG_BIN"
} > "$CONFIG_LOG"

./configure \
  --prefix="$PREFIX" \
  --cc="$CC" \
  --arch="$ARCH" \
  --pkg-config="$PKG_CONFIG_BIN" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$PREFIX/include" \
  --extra-ldflags="-L$PREFIX/lib" \
  --enable-static \
  --disable-shared \
  --disable-doc \
  --disable-debug \
  --enable-pthreads \
  --enable-version3 \
  --disable-xlib \
  --disable-libxcb \
  --enable-ffmpeg \
  --enable-ffprobe \
  --enable-ffplay \
  --enable-gpl \
  --enable-libdav1d \
  --enable-libx264 \
  --enable-libvpx \
  --enable-libopus \
  --enable-libfreetype \
  --enable-libharfbuzz \
  --enable-libfribidi \
  --enable-libass \
  --enable-libmp3lame \
  --enable-libwebp \
  --enable-libopenjpeg \
  --enable-libtheora \
  --enable-libtwolame \
  --enable-libsoxr \
  --enable-libsnappy \
  --enable-libzimg \
  --enable-libxml2 \
  --enable-libzmq \
  >> "$CONFIG_LOG" 2>&1

make > "$MAKE_LOG" 2>&1
make install > "$INSTALL_LOG" 2>&1

echo "==> Build finished"
ls -l "$PREFIX/bin/ffmpeg" "$PREFIX/bin/ffprobe" "$PREFIX/bin/ffplay"
