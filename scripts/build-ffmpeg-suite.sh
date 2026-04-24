#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPT_DIR/env.sh"
source "$SCRIPT_DIR/build-common.sh"

NAME="ffmpeg-suite"

# FFmpeg source
FFMPEG_VERSION="8.1"
FFMPEG_TARBALL="ffmpeg-${FFMPEG_VERSION}.tar.xz"
FFMPEG_URL="https://ffmpeg.org/releases/${FFMPEG_TARBALL}"
FFMPEG_SRC="$SRC/ffmpeg-${FFMPEG_VERSION}"

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

fetch_ffmpeg_source() {
  step "Check FFmpeg source"

  mkdir -p "$SRC"

  kv "Version" "$FFMPEG_VERSION"
  kv "Source" "$FFMPEG_SRC"
  kv "Tarball" "$SRC/$FFMPEG_TARBALL"

  if [[ -d "$FFMPEG_SRC" ]]; then
    say "source already exists"
    done_step "check FFmpeg source"
    return 0
  fi

  say "source not found"
  say "fetching $FFMPEG_URL"

  cd "$SRC"

  if [[ ! -f "$FFMPEG_TARBALL" ]]; then
    curl -fL -o "$FFMPEG_TARBALL" "$FFMPEG_URL"
  else
    say "tarball already exists"
  fi

  say "extracting $FFMPEG_TARBALL"
  tar -xf "$FFMPEG_TARBALL"

  if [[ ! -d "$FFMPEG_SRC" ]]; then
    fail_step "FFmpeg source extraction failed: $FFMPEG_SRC not found"
    exit 1
  fi

  done_step "check FFmpeg source"
}

check_required_tools() {
  step "Check required tools"

  if [ -z "${PKG_CONFIG_BIN:-}" ]; then
    fail_step "pkg-config not found in ORIGINAL_PATH"
    exit 1
  fi

  say "pkg-config: $PKG_CONFIG_BIN"
  done_step "check required tools"
}

check_required_packages() {
  step "Check required pkg-config packages"

  local pair
  local name
  local pkg

  for pair in "${REQUIRED_PKG_PAIRS[@]}"; do
    name="${pair%%:*}"
    pkg="${pair#*:}"

    if ! "$PKG_CONFIG_BIN" --exists "$pkg"; then
      fail_step "missing pkg-config package for $name: $pkg"
      exit 1
    fi

    say "$name -> $pkg"
  done

  done_step "check required pkg-config packages"
}

prepare_logs() {
  step "Prepare FFmpeg logs"

  mkdir -p "$LOGS"

  : > "$CONFIG_LOG"
  : > "$MAKE_LOG"
  : > "$INSTALL_LOG"

  kv "Configure log" "$CONFIG_LOG"
  kv "Make log" "$MAKE_LOG"
  kv "Install log" "$INSTALL_LOG"

  done_step "prepare FFmpeg logs"
}

write_config_log_header() {
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

    local pair
    local name
    local pkg

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
}

configure_ffmpeg() {
  step "Configure FFmpeg"

  if [ ! -d "$FFMPEG_SRC" ]; then
    fail_step "source directory not found: $FFMPEG_SRC"
    exit 1
  fi

  cd "$FFMPEG_SRC"

  make distclean >> "$CONFIG_LOG" 2>&1 || true

  write_config_log_header

  PKG_CONFIG="$PKG_CONFIG_BIN" \
  PKG_CONFIG_PATH="$PKG_CONFIG_PATH" \
  PKG_CONFIG_LIBDIR="$PKG_CONFIG_LIBDIR" \
  run_with_log_tail "configure FFmpeg" "$CONFIG_LOG" \
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
      --enable-libzmq

  done_step "configure FFmpeg"
}

build_ffmpeg() {
  step "Build FFmpeg suite"

  cd "$FFMPEG_SRC"

  run_with_log_tail "build FFmpeg suite" "$MAKE_LOG" \
    make

  done_step "build FFmpeg suite"
}

install_ffmpeg() {
  step "Install FFmpeg suite"

  cd "$FFMPEG_SRC"

  run_with_log_tail "install FFmpeg suite" "$INSTALL_LOG" \
    make install

  done_step "install FFmpeg suite"
}

verify_ffmpeg_suite() {
  step "Verify FFmpeg suite binaries"

  local bin

  for bin in ffmpeg ffprobe ffplay; do
    if [ ! -x "$PREFIX/bin/$bin" ]; then
      fail_step "missing executable: $PREFIX/bin/$bin"
      exit 1
    fi

    ls -l "$PREFIX/bin/$bin"
  done

  done_step "verify FFmpeg suite binaries"
}

print_ffmpeg_summary() {
  stage "FFmpeg suite summary"

  printf "  %-18s %s\n" "ffmpeg" "$PREFIX/bin/ffmpeg"
  printf "  %-18s %s\n" "ffprobe" "$PREFIX/bin/ffprobe"
  printf "  %-18s %s\n" "ffplay" "$PREFIX/bin/ffplay"
  printf "  %-18s %s\n" "configure log" "$CONFIG_LOG"
  printf "  %-18s %s\n" "make log" "$MAKE_LOG"
  printf "  %-18s %s\n" "install log" "$INSTALL_LOG"
}

stage "Stage 3: Building FFmpeg suite"

kv "Version" "$FFMPEG_VERSION"
kv "Source" "$FFMPEG_SRC"
kv "Prefix" "$PREFIX"
kv "Log root" "$LOGS"
kv "pkg-config" "${PKG_CONFIG_BIN:-unset}"

fetch_ffmpeg_source
check_required_tools
prepare_logs
check_required_packages
configure_ffmpeg
build_ffmpeg
install_ffmpeg
verify_ffmpeg_suite
print_ffmpeg_summary

stage "FFmpeg suite completed"
