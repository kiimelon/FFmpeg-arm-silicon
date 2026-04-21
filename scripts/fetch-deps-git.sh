#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")"/env.sh

mkdir -p "$SRC"

fetch_git(){
  local url="$1"
  local dir="$2"
  local extra_args="${3:-}"
  
  if [ -d "$SRC/$dir/.git" ]; then
    echo "[skip] $dir already exists"
    return 0
  fi

  echo "[clone] $dir"

  if [ -n "$extra_args" ]; then
    git clone $extra_args "$url" "$SRC/$dir"
  else
    git clone "$url" "$SRC/$dir"
  fi
}

echo "==== fetching dependency sources ===="
echo "SRC=$SRC"
echo

# SDL2
fetch_git "https://github.com/libsdl-org/SDL.git" "SDL" "--branch release-2.32.10 --depth 1"

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

echo
echo "==== done fetching dependency sources ===="
