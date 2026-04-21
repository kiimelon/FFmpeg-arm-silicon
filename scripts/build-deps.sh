#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

SCRIPT_DIR="$(dirname "$0")/build-deps"
LOG_FILE="$LOGS/build-deps.log"

mkdir -p "$LOGS"

deps=(
    sdl2 freetype fribidi harfbuzz libass
    x264 x265 libvpx dav1d
    ogg opus vorbis lame
    snappy libsoxr libwebp openjpeg
    zimg twolame libtheora libxml2 libzmq
)

is_built() {
    local dep="$1"

    case "$dep" in
        sdl2)
            ls "$PREFIX/lib"/libSDL2* >/dev/null 2>&1
            ;;
        freetype)
            test -f "$PREFIX/include/freetype2/freetype/freetype.h"
            ;;
        fribidi)
            test -f "$PREFIX/include/fribidi/fribidi.h"
            ;;
        harfbuzz)
            test -f "$PREFIX/include/harfbuzz/hb.h"
            ;;
        libass)
            test -f "$PREFIX/include/ass/ass.h"
            ;;
        x264)
            test -f "$PREFIX/include/x264.h"
            ;;
        x265)
            ls "$PREFIX/lib"/libx265* >/dev/null 2>&1
            ;;
        libvpx)
            ls "$PREFIX/lib"/libvpx* >/dev/null 2>&1
            ;;
        dav1d)
            ls "$PREFIX/lib"/libdav1d* >/dev/null 2>&1
            ;;
        ogg)
            test -f "$PREFIX/include/ogg/ogg.h"
            ;;
        opus)
            test -f "$PREFIX/include/opus/opus.h"
            ;;
        vorbis)
            test -f "$PREFIX/include/vorbis/vorbisenc.h"
            ;;
        lame)
            test -f "$PREFIX/include/lame/lame.h" && test -f "$PREFIX/lib/pkgconfig/libmp3lame.pc"
            ;;
        snappy)
            test -f "$PREFIX/include/snappy.h"
            ;;
        libsoxr)
            test -f "$PREFIX/include/soxr.h"
            ;;
        libwebp)
            test -f "$PREFIX/include/webp/decode.h"
            ;;
        openjpeg)
            test -f "$PREFIX/include/openjpeg-2.5/openjpeg.h"
            ;;
        zimg)
            test -f "$PREFIX/include/zimg.h"
            ;;
        twolame)
            test -f "$PREFIX/include/twolame.h"
            ;;
        libtheora)
            test -f "$PREFIX/include/theora/theoraenc.h"
            ;;
        libxml2)
            test -f "$PREFIX/include/libxml2/libxml/parser.h"
            ;;
        libzmq)
            test -f "$PREFIX/include/zmq.h"
            ;;
        *)
            return 1
            ;;
    esac
}

: > "$LOG_FILE"

echo "==== build-deps started ====" | tee -a "$LOG_FILE"
echo "ROOT=$ROOT" | tee -a "$LOG_FILE"
echo "SRC=$SRC" | tee -a "$LOG_FILE"
echo "BUILD=$BUILD" | tee -a "$LOG_FILE"
echo "PREFIX=$PREFIX" | tee -a "$LOG_FILE"
echo "LOGS=$LOGS" | tee -a "$LOG_FILE"

for dep in "${deps[@]}"; do
    SCRIPT_PATH="$SCRIPT_DIR/$dep.sh"

    if is_built "$dep"; then
        echo | tee -a "$LOG_FILE"
        echo "*** SKIP: $dep ***" | tee -a "$LOG_FILE"
        echo "already installed under $PREFIX" | tee -a "$LOG_FILE"
        echo | tee -a "$LOG_FILE"
        continue
    fi

    [ -f "$SCRIPT_PATH" ] || {
        echo "[fail] missing script: $SCRIPT_PATH" | tee -a "$LOG_FILE"
        exit 1
    }

    echo | tee -a "$LOG_FILE"
    echo "*** RUNNING: $dep ***" | tee -a "$LOG_FILE"
    echo | tee -a "$LOG_FILE"

    bash "$SCRIPT_PATH" 2>&1 | tee -a "$LOG_FILE"

    echo | tee -a "$LOG_FILE"
    echo "*** PASS: $dep ***" | tee -a "$LOG_FILE"
    echo "log: $LOGS/$dep-build.log" | tee -a "$LOG_FILE"
    echo | tee -a "$LOG_FILE"
    sleep 3
done

echo | tee -a "$LOG_FILE"
echo "==== all dependencies built successfully ====" | tee -a "$LOG_FILE"
