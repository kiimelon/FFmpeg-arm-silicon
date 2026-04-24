#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPT_DIR/build-common.sh"

NAME="build-all-static"

stage "Static FFmpeg suite build started"

stage "Stage 1: Fetching dependency sources"
bash "$SCRIPT_DIR/git-fetch.sh"

stage "Stage 2: Building static dependencies"
bash "$SCRIPT_DIR/build-static-deps.sh"

stage "Stage 3: Building FFmpeg suite"
bash "$SCRIPT_DIR/build-ffmpeg-suite.sh"

stage "Stage 4: Verifying static suite"
bash "$SCRIPT_DIR/verify-static-suite.sh"

stage "Stage 5: Exporting FFmpeg tools"
bash "$SCRIPT_DIR/export-tools.sh"

stage "All static build stages completed successfully"
