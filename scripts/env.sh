#!/usr/bin/env bash
set -euo pipefail

# Root
export ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Directories
export SRC="$ROOT/src"
export BUILD="$ROOT/build"
export PREFIX="$ROOT/local"
export LOGS="$ROOT/logs"

# Paths
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
export PATH="$PREFIX/bin:$PATH"

# Apple Silicon
export MACOSX_DEPLOYMENT_TARGET=11.0
export CFLAGS="-arch arm64"
export LDFLAGS="-arch arm64"
