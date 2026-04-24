#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPT_DIR/env.sh"
source "$SCRIPT_DIR/build-common.sh"

NAME="export-tools"

TOOLS_DIR="$ROOT/Tools"

stage "Stage 5: Exporting FFmpeg tools"

kv "Source bin" "$PREFIX/bin"
kv "Tools dir" "$TOOLS_DIR"

step "Prepare Tools directory"

rm -rf "$TOOLS_DIR"
mkdir -p "$TOOLS_DIR"

done_step "prepare Tools directory"

step "Copy FFmpeg suite binaries"

for bin in ffmpeg ffprobe ffplay; do
  if [ ! -x "$PREFIX/bin/$bin" ]; then
    fail_step "missing executable: $PREFIX/bin/$bin"
    exit 1
  fi

  cp "$PREFIX/bin/$bin" "$TOOLS_DIR/$bin"
  chmod +x "$TOOLS_DIR/$bin"

  print_file_with_size "$TOOLS_DIR/$bin"
done

done_step "copy FFmpeg suite binaries"

step "Verify exported tools"

for bin in ffmpeg ffprobe ffplay; do
  if [ ! -x "$TOOLS_DIR/$bin" ]; then
    fail_step "exported tool is not executable: $TOOLS_DIR/$bin"
    exit 1
  fi

  "$TOOLS_DIR/$bin" -version >/dev/null
  say "$bin: PASS"
done

done_step "verify exported tools"

stage "FFmpeg tools exported"
