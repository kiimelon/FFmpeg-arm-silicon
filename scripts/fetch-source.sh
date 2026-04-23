#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

mkdir -p "$SRC"

fetch_git() {
  local url="$1"
  local dir="$2"

  if [ -d "$SRC/$dir/.git" ]; then
    echo "[skip] $dir already exists"
    return 0
  fi

  echo "[clone] $dir"

  if [ "$#" -gt 2 ]; then
    shift 2
    git clone "$@" "$url" "$SRC/$dir"
  else
    git clone "$url" "$SRC/$dir"
  fi
}

fetch_tarball() {
  local url="$1"
  local archive_name="$2"
  local extracted_dir="$3"

  if [ -d "$SRC/$extracted_dir" ]; then
    echo "[skip] $extracted_dir already exists"
    return 0
  fi

  echo "[download] $archive_name"
  curl -L -o "$SRC/$archive_name" "$url"

  echo "[extract] $archive_name"
  tar -xf "$SRC/$archive_name" -C "$SRC"
}

echo "==== fetching sources ===="
echo "SRC=$SRC"
echo

# Core compression libs required by freetype
fetch_git "https://github.com/madler/zlib.git" "zlib"
fetch_git "https://github.com/libarchive/bzip2.git" "bzip2"
fetch_git "https://github.com/google/brotli.git" "brotli"

# SDL2
fetch_git "https://github.com/libsdl-org/SDL.git" "sdl2" --branch release-2.32.10 --depth 1

# Subtitle chain
fetch_git "https://gitlab.freedesktop.org/freetype/freetype.git" "freetype"
fetch_git "https://github.com/harfbuzz/harfbuzz.git" "harfbuzz"
fetch_git "https://github.com/fribidi/fribidi.git" "fribidi"
fetch_git "https://github.com/libass/libass.git" "libass"

# Video chain
fetch_git "https://github.com/mirror/x264.git" "x264"
fetch_git "https://bitbucket.org/multicoreware/x265_git" "x265"
fetch_git "https://chromium.googlesource.com/webm/libvpx" "libvpx"
fetch_git "https://github.com/videolan/dav1d.git" "dav1d"

# Audio chain
fetch_git "https://github.com/xiph/opus.git" "opus"
fetch_git "https://github.com/xiph/ogg.git" "libogg"
fetch_git "https://github.com/xiph/vorbis.git" "libvorbis"
fetch_git "https://github.com/lameproject/lame.git" "lame"
fetch_git "https://github.com/njh/twolame.git" "twolame"
fetch_git "https://github.com/chirlu/soxr.git" "libsoxr"

# Image and media extras
fetch_git "https://github.com/webmproject/libwebp.git" "libwebp"
fetch_git "https://github.com/uclouvain/openjpeg.git" "openjpeg"
fetch_git "https://github.com/xiph/theora.git" "libtheora"

# Utility and support libs
fetch_git "https://github.com/google/snappy.git" "snappy"
fetch_git "https://github.com/sekrit-twc/zimg.git" "zimg"
fetch_git "https://gitlab.gnome.org/GNOME/libxml2.git" "libxml2"
fetch_git "https://github.com/zeromq/libzmq.git" "libzmq"

# FFmpeg release source
fetch_tarball \
  "https://ffmpeg.org/releases/ffmpeg-8.1.tar.xz" \
  "ffmpeg-8.1.tar.xz" \
  "ffmpeg-8.1"

echo
echo "==== done fetching sources ===="
