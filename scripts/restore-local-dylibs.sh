#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

DISABLED_DIR="$PREFIX/lib/_disabled_dylibs"

if [ ! -d "$DISABLED_DIR" ]; then
  echo "nothing to restore"
  exit 0
fi

shopt -s nullglob
for f in "$DISABLED_DIR"/*.dylib; do
  echo "restoring $(basename "$f")"
  mv "$f" "$PREFIX/lib/"
done
shopt -u nullglob

echo "==> restore complete"
