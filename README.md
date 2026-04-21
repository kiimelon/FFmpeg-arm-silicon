# FFmpeg-arm-silicon

Apple Silicon (`arm64`) FFmpeg build project for macOS.

## Goal

- Build `ffmpeg`, `ffprobe`, and `ffplay`
- Target Apple Silicon (`arm64`)
- Build and manage local dependencies under this project
- Move toward a fuller feature set comparable to Evermeet's FFmpeg configuration

## Project Structure

- `scripts/env.sh` — shared build environment
- `scripts/build-deps.sh` — dependency build controller
- `scripts/build-deps/` — per-library build scripts
- `src/` — third-party source code
- `build/` — temporary build output
- `local/` — local install prefix
- `logs/` — build logs

## Current Dependencies

- SDL2
- freetype
- fribidi
- harfbuzz
- libass
- x264
- x265
- libvpx
- dav1d
- libogg
- opus
- libvorbis
- lame

## Status

- Stage 1: initialization ✅
- Stage 2: dependency build system in progress

Current progress:
- Source repositories downloaded
- `env.sh` created
- `build-deps.sh` created
- Per-library build scripts added under `scripts/build-deps/`
- Ongoing fixes for Apple Silicon / macOS build issues

## Notes

- `src/`, `build/`, `local/`, and `logs/` stay local and are not committed to the repository.
- This project focuses on reproducible local builds on Apple Silicon macOS
