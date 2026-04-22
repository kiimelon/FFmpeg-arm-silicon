#!/usr/bin/env bash

# Reconstruct a clean login-shell PATH for tool discovery.
# This avoids reusing a previously sanitized PATH from the current shell.
if [ -z "${ORIGINAL_PATH:-}" ]; then
  export ORIGINAL_PATH="$(zsh -l -c 'printf %s "$PATH"')"
fi

# Resolve project root from the scripts directory.
export ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Standard project directories.
export SRC="$ROOT/src"
export BUILD="$ROOT/build"
export PREFIX="$ROOT/local"
export LOGS="$ROOT/logs"

# Ensure required directories exist.
mkdir -p "$SRC" "$BUILD" "$PREFIX" "$LOGS"

# Apple Silicon baseline.
export MACOSX_DEPLOYMENT_TARGET=11.0
export ARCH="arm64"
export NCPU="$(sysctl -n hw.ncpu)"

# Use the system Clang toolchain on macOS.
export CC="clang"
export CXX="clang++"

# Detect external tools before sanitizing PATH.
# Save absolute paths so later stages do not depend on Homebrew being in PATH.
if PATH="$ORIGINAL_PATH" command -v pkg-config >/dev/null 2>&1; then
  export PKG_CONFIG_BIN="$(PATH="$ORIGINAL_PATH" command -v pkg-config)"
fi

if PATH="$ORIGINAL_PATH" command -v glibtool >/dev/null 2>&1; then
  export LIBTOOL="$(PATH="$ORIGINAL_PATH" command -v glibtool)"
fi

if PATH="$ORIGINAL_PATH" command -v glibtoolize >/dev/null 2>&1; then
  export LIBTOOLIZE="$(PATH="$ORIGINAL_PATH" command -v glibtoolize)"
fi

if PATH="$ORIGINAL_PATH" command -v cmake >/dev/null 2>&1; then
  export CMAKE_BIN="$(PATH="$ORIGINAL_PATH" command -v cmake)"
fi

if PATH="$ORIGINAL_PATH" command -v ninja >/dev/null 2>&1; then
  export NINJA_BIN="$(PATH="$ORIGINAL_PATH" command -v ninja)"
fi

# Keep PATH minimal and deterministic.
# Local tools come first, then system tools.
# Homebrew paths are intentionally excluded here.
export PATH="$PREFIX/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Restrict pkg-config lookup to the local prefix only.
# This helps prevent accidental linkage against external packages.
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig"
export PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig"

# Clear environment variables that commonly leak external include/library
# paths or otherwise affect dependency resolution.
unset CPATH || true
unset C_INCLUDE_PATH || true
unset CPLUS_INCLUDE_PATH || true
unset OBJC_INCLUDE_PATH || true
unset LIBRARY_PATH || true
unset DYLD_LIBRARY_PATH || true
unset DYLD_FALLBACK_LIBRARY_PATH || true
unset SDKROOT || true
unset HOMEBREW_PREFIX || true
unset HOMEBREW_CELLAR || true
unset HOMEBREW_REPOSITORY || true

# Default compiler and linker flags for Apple Silicon.
# These defaults target the whole Apple Silicon family rather than one
# specific chip generation.
export CFLAGS="-arch ${ARCH} -O3"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="-arch ${ARCH}"

# Optional per-machine CPU tuning.
# Example:
#   CPU_TUNE=apple-m4 bash scripts/build-ffmpeg-suite.sh
if [ -n "${CPU_TUNE:-}" ]; then
  export CFLAGS="${CFLAGS} -mcpu=${CPU_TUNE}"
  export CXXFLAGS="${CXXFLAGS} -mcpu=${CPU_TUNE}"
fi

# Shared make flags for parallel builds.
export MAKEFLAGS="-j${NCPU}"

# Optional autotools macro path for stage2 edge cases.
# Disabled by default to avoid pulling external paths into unrelated builds.
if [ -n "${EXTRA_ACLOCAL_PATH:-}" ]; then
  export ACLOCAL_PATH="${EXTRA_ACLOCAL_PATH}${ACLOCAL_PATH:+:$ACLOCAL_PATH}"
fi
