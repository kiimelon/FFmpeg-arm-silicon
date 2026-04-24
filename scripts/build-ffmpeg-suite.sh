#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

# FFmpeg source
FFMPEG_VERSION="8.1"
FFMPEG_TARBALL="ffmpeg-${FFMPEG_VERSION}.tar.xz"
FFMPEG_URL="https://ffmpeg.org/releases/${FFMPEG_TARBALL}"
FFMPEG_SRC="$SRC/ffmpeg-${FFMPEG_VERSION}"

fetch_ffmpeg() {
  mkdir -p "$SRC"

  if [[ -d "$FFMPEG_SRC" ]]; then
    echo "FFmpeg source already exists: $FFMPEG_SRC"
    return 0
  fi

  echo "FFmpeg source not found: $FFMPEG_SRC"
  echo "Fetching $FFMPEG_TARBALL"

  cd "$SRC"

  if [[ ! -f "$FFMPEG_TARBALL" ]]; then
    curl -L -o "$FFMPEG_TARBALL" "$FFMPEG_URL"
  else
    echo "Tarball already exists: $SRC/$FFMPEG_TARBALL"
  fi

  echo "Extracting $FFMPEG_TARBALL"
  tar -xf "$FFMPEG_TARBALL"

  if [[ ! -d "$FFMPEG_SRC" ]]; then
    echo "ERROR: FFmpeg source extraction failed: $FFMPEG_SRC not found"
    exit 1
  fi
}

fetch_ffmpeg

if [ -z "${PKG_CONFIG_BIN:-}" ]; then
  echo "ERROR: pkg-config not found in ORIGINAL_PATH"
  exit 1
fi

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
  "libmp3lame:mp3lame"
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

log_header() {
  local title="$1"
  echo
  echo "=================================================="
  echo "$title"
  echo "=================================================="
}

echo "==> Building FFmpeg suite"
echo "Source : $FFMPEG_SRC"
echo "Prefix : $PREFIX"
echo "Logs   : $LOGS"
echo "pkg-config: $PKG_CONFIG_BIN"

if [ ! -d "$FFMPEG_SRC" ]; then
  echo "ERROR: source directory not found: $FFMPEG_SRC"
  exit 1
fi

mkdir -p "$LOGS"
: > "$CONFIG_LOG"
: > "$MAKE_LOG"
: > "$INSTALL_LOG"

cd "$FFMPEG_SRC"

make distclean >/dev/null 2>&1 || true

log_header "Checking required dependencies"

for pair in "${REQUIRED_PKG_PAIRS[@]}"; do
  name="${pair%%:*}"
  pkg="${pair#*:}"
  echo " - $name -> $pkg"
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

log_header "Running configure"

PKG_CONFIG="$PKG_CONFIG_BIN" \
PKG_CONFIG_PATH="$PKG_CONFIG_PATH" \
PKG_CONFIG_LIBDIR="$PKG_CONFIG_LIBDIR" \
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
  2>&1 | tee -a "$CONFIG_LOG"

log_header "Running make"

make 2>&1 | tee "$MAKE_LOG"

log_header "Running make install"

make install 2>&1 | tee "$INSTALL_LOG"

log_header "Build finished"

ls -l "$PREFIX/bin/ffmpeg" "$PREFIX/bin/ffprobe" "$PREFIX/bin/ffplay"
