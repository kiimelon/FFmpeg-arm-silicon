#!/usr/bin/env bash
set -euo pipefail

# Root
if [ -n "${BASH_SOURCE:-}" ]; then
  _SCRIPT_SOURCE="${BASH_SOURCE[0]}"
else
  _SCRIPT_SOURCE="$0"
fi

export ROOT="$(cd "$(dirname "$_SCRIPT_SOURCE")/.." && pwd)"

# Directories
export SRC="$ROOT/src"
export BUILD="$ROOT/build"
export PREFIX="$ROOT/local"
export LOGS="$ROOT/logs"

# Paths
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig"
export PATH="$PREFIX/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Apple Silicon
export MACOSX_DEPLOYMENT_TARGET=11.0
export CFLAGS="-arch arm64"
export CXXFLAGS="-arch arm64"
export LDFLAGS="-arch arm64"

# Parallel build
export MAKEFLAGS="-j$(sysctl -n hw.ncpu)"

# GNU libtool on macOS
if command -v glibtool >/dev/null 2>&1; then
  export LIBTOOL=glibtool
fi

if command -v glibtoolize >/dev/null 2>&1; then
  export LIBTOOLIZE=glibtoolize
fi

if command -v brew >/dev/null 2>&1 && brew ls --versions libtool >/dev/null 2>&1; then
  export ACLOCAL_PATH="$(brew --prefix libtool)/share/aclocal${ACLOCAL_PATH:+:$ACLOCAL_PATH}"
fi
