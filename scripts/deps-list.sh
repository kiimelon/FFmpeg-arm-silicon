#!/usr/bin/env bash

# ==================================================
# Dependency source list
# ==================================================
#
# Format:
#   name|repo_url|ref
#
# This list is the source index used by git-fetch.sh.
# New dependencies can be appended to the end.
#
# Build order is NOT controlled by this list.
# Build order is controlled by DEPS_ORDER below.
# ==================================================

DEPS_LIST=(
  "zlib|https://github.com/madler/zlib.git|v1.3.1"
  "brotli|https://github.com/google/brotli.git|v1.1.0"
  "bzip2|https://gitlab.com/bzip2/bzip2.git|bzip2-1.0.8"
  "dav1d|https://code.videolan.org/videolan/dav1d.git|1.5.2"
  "fribidi|https://github.com/fribidi/fribidi.git|v1.0.16"
  "freetype|https://gitlab.freedesktop.org/freetype/freetype.git|VER-2-13-3"
  "harfbuzz|https://github.com/harfbuzz/harfbuzz.git|11.1.0"
  "lame|https://github.com/zlargon/lame.git|"
  "libass|https://github.com/libass/libass.git|0.17.4"
  "libogg|https://github.com/xiph/ogg.git|v1.3.6"
  "libsoxr|https://github.com/chirlu/soxr.git|0.1.3"
  "libtheora|https://github.com/xiph/theora.git|v1.2.0alpha1"
  "libvorbis|https://github.com/xiph/vorbis.git|v1.3.7"
  "libvpx|https://chromium.googlesource.com/webm/libvpx.git|v1.15.2"
  "libwebp|https://github.com/webmproject/libwebp.git|v1.5.0"
  "libxml2|https://gitlab.gnome.org/GNOME/libxml2.git|v2.14.5"
  "libzmq|https://github.com/zeromq/libzmq.git|v4.3.5"
  "openjpeg|https://github.com/uclouvain/openjpeg.git|v2.5.3"
  "opus|https://github.com/xiph/opus.git|v1.5.2"
  "sdl2|https://github.com/libsdl-org/SDL.git|release-2.32.10"
  "snappy|https://github.com/google/snappy.git|1.2.2"
  "twolame|https://github.com/njh/twolame.git|0.4.0"
  "x264|https://code.videolan.org/videolan/x264.git|stable"
  "x265|https://bitbucket.org/multicoreware/x265_git.git|4.1"
  "zimg|https://github.com/sekrit-twc/zimg.git|release-3.0.6"
)

# ==================================================
# Dependency groups
# ==================================================
#
# DEPS_GROUP_IDS:
#   Internal group IDs used by scripts.
#
# DEPS_GROUP_NAMES:
#   Human-readable group names used in logs.
#
# The index positions of DEPS_GROUP_IDS and DEPS_GROUP_NAMES
# must stay aligned.
# ==================================================

DEPS_GROUP_IDS=(
  SUPPORT
  AUDIO
  VIDEO
  SUBTITLE
  IMAGE_PROCESSING
  UTILITY
  PLAYER
)

DEPS_GROUP_NAMES=(
  "Support libs"
  "Audio chain"
  "Video chain"
  "Subtitle chain"
  "Image / video processing chain"
  "Utility / integration libs"
  "Player / UI"
)

# ==================================================
# Dependency build order by group
# ==================================================
#
# This order is authoritative for build-static-deps.sh.
# Put each dependency after the libraries it depends on.
# Append new dependency names to the proper group.
# ==================================================

# Basic compression / support libs
DEPS_ORDER_SUPPORT=(
  zlib
  bzip2
  brotli
  snappy
)

# Audio chain
#
# libvorbis depends on libogg.
# libtheora also depends on libogg, but it is grouped under video.
DEPS_ORDER_AUDIO=(
  libogg
  opus
  libvorbis
  lame
  twolame
  libsoxr
)

# Video chain
#
# libtheora depends on libogg, so AUDIO must run before VIDEO.
DEPS_ORDER_VIDEO=(
  dav1d
  x264
  x265
  libvpx
  libtheora
)

# Subtitle chain
#
# libass depends on freetype, fribidi, and harfbuzz.
DEPS_ORDER_SUBTITLE=(
  freetype
  fribidi
  harfbuzz
  libass
)

# Image / video processing chain
#
# zimg is a video/image processing library used for scaling,
# colorspace conversion, pixel format handling, and dithering.
DEPS_ORDER_IMAGE_PROCESSING=(
  libwebp
  openjpeg
  zimg
)

# Utility / integration libs
DEPS_ORDER_UTILITY=(
  libxml2
  libzmq
)

# Player / UI dependency for ffplay
DEPS_ORDER_PLAYER=(
  sdl2
)

# ==================================================
# Final flattened build order
# ==================================================
#
# build-static-deps.sh can use this array when it does not need
# group-aware output.
# ==================================================

DEPS_ORDER=(
  "${DEPS_ORDER_SUPPORT[@]}"
  "${DEPS_ORDER_AUDIO[@]}"
  "${DEPS_ORDER_VIDEO[@]}"
  "${DEPS_ORDER_SUBTITLE[@]}"
  "${DEPS_ORDER_IMAGE_PROCESSING[@]}"
  "${DEPS_ORDER_UTILITY[@]}"
  "${DEPS_ORDER_PLAYER[@]}"
)
