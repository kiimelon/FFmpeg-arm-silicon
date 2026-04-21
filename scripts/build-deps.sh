#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

SCRIPT_DIR="$(dirname "$0")/build-deps"
LOG_FILE="$LOGS/build-deps.log"

mkdir -p "$LOGS"

deps=(
     sdl2
     freetype fribidi harfbuzz libass
     x264 x265 libvpx dav1d
     ogg opus vorbis lame
     snappy libsoxr libwebp openjpeg
     zimg twolame libtheora libxml2 libzmq
)

: > "$LOG_FILE"

echo "==== build-deps started ====" | tee -a "$LOG_FILE"
echo "ROOT=$ROOT" | tee -a "$LOG_FILE"
echo "SRC=$SRC" | tee -a "$LOG_FILE"
echo "BUILD=$BUILD" | tee -a "$LOG_FILE"
echo "PREFIX=$PREFIX" | tee -a "$LOG_FILE"
echo "LOGS=$LOGS" | tee -a "$LOG_FILE"

for dep in "${deps[@]}"; do
    SCRIPT_PATH="$SCRIPT_DIR/$dep.sh"
    [ -f "$SCRIPT_PATH" ] || { echo "[fail] missing script: $SCRIPT_PATH" | tee -a "$LOG_FILE"; exit 1; }

    echo | tee -a "$LOG_FILE"
    echo "==============================" | tee -a "$LOG_FILE"
    echo "RUNNING: $dep" | tee -a "$LOG_FILE"
    echo "==============================" | tee -a "$LOG_FILE"

    bash "$SCRIPT_PATH" 2>&1 | tee -a "$LOG_FILE"

    echo "[ok] finished: $dep" | tee -a "$LOG_FILE"
done

echo | tee -a "$LOG_FILE"
echo "==== all dependencies built successfully ====" | tee -a "$LOG_FILE"
