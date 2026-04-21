# FFmpeg-arm-silicon

A local FFmpeg build project for **macOS Apple Silicon (`arm64`)**.

This project is focused on building FFmpeg and its dependency stack locally on Apple Silicon Macs.

For prebuilt macOS binaries and a much broader upstream-style feature set, see Evermeet’s FFmpeg builds.

## Goal

- Build `ffmpeg`, `ffprobe`, and eventually `ffplay`
- Target **Apple Silicon (`arm64`)**
- Build dependencies locally inside this project
- Move toward a richer dependency set inspired by Evermeet’s FFmpeg configuration

## Project Structure

- `scripts/env.sh` — shared build environment
- `scripts/fetch-deps-git.sh` — fetch dependency source repositories
- `scripts/build-deps.sh` — dependency build controller
- `scripts/build-deps/` — per-library build scripts
- `src/` — third-party source trees *
- `build/` — temporary build output *
- `local/` — local install prefix *
- `logs/` — build logs *

* indicates local-only directories that are not committed to the repository.

## Dependencies

### Core media stack

| Category | Libraries |
|---|---|
| SDL | `sdl2` |
| Subtitle chain | `freetype`, `fribidi`, `harfbuzz`, `libass` |
| Video chain | `x264`, `x265`, `libvpx`, `dav1d` |
| Audio chain | `ogg`, `opus`, `vorbis`, `lame` |

### Extended dependency set

| Category | Libraries |
|---|---|
| Image and media extras | `libwebp`, `openjpeg`, `libtheora` |
| Audio and resampling extras | `twolame`, `libsoxr` |
| Utility and support libs | `snappy`, `zimg`, `libxml2`, `libzmq` |

## Status

- Stage 1: initialization ✅
- Stage 2: dependency build system ✅
- Current state: the current dependency set is building successfully on Apple Silicon

## Current Scope

This repository is for **local source-based builds on macOS Apple Silicon**.
