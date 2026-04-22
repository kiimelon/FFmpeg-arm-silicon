#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

FAILED=0

check_bin() {
  local bin="$1"

  echo "==> Checking $bin"

  if [ ! -f "$bin" ]; then
    echo "ERROR: not found: $bin"
    FAILED=1
    return
  fi

  echo "--- otool -L ---"
  otool -L "$bin" || true

  if otool -L "$bin" | grep -q '/opt/homebrew'; then
    echo "ERROR: Homebrew dylib reference found in $bin"
    FAILED=1
  fi

  echo "--- strings scan ---"
  if strings "$bin" | grep -q '/opt/homebrew'; then
    echo "WARNING: /opt/homebrew string found inside $bin"
    FAILED=1
  fi

  echo
}

check_pc_files() {
  echo "==> Checking pkg-config files under $PREFIX"
  if find "$PREFIX" -name '*.pc' -print0 | xargs -0 grep -H '/opt/homebrew' 2>/dev/null; then
    echo "ERROR: /opt/homebrew found in .pc files"
    FAILED=1
  else
    echo "OK: no /opt/homebrew in .pc files"
  fi
  echo
}

check_bin "$PREFIX/bin/ffmpeg"
check_bin "$PREFIX/bin/ffprobe"
check_bin "$PREFIX/bin/ffplay"
check_pc_files

if [ "$FAILED" -ne 0 ]; then
  echo "==> FAILED: Homebrew contamination detected"
  exit 1
fi

echo "==> PASS: no /opt/homebrew contamination detected"
