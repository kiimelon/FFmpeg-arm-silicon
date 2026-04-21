# FFmpeg-arm-silicon

[Evermeet](https://evermeet.cx/ffmpeg/) is a useful reference for prebuilt FFmpeg binaries, but its main page is currently focused on macOS 64-bit Intel builds. That is part of why I started this project.

I wanted a source-based FFmpeg build, and a cleaner, easier way to build FFmpeg locally on Apple Silicon.

The long-term goal of this project is to provide directly usable FFmpeg binaries for Apple Silicon. It is not there yet, but that is the direction.

For now, this project can already serve as a practical reference for anyone who wants to see how FFmpeg is being built step by step on Apple Silicon.

At the moment, this project targets **macOS 11.0+ on Apple Silicon** and is being tested through repeated clean builds on my own machines.


## Current Progress

- Stage 1: initialization ✅  
  the repository structure is set up, the shared build environment is ready, and dependency sources can be fetched into the project

- Stage 2: dependency build system ✅  
  dependency scripts are in place, libraries can be built into the local prefix, and the current dependency set has been tested successfully on Apple Silicon

## Project Structure

- `scripts/env.sh` — shared build environment
- `scripts/fetch-deps-git.sh` — fetch dependency source repositories
- `scripts/build-deps.sh` — dependency build controller
- `scripts/build-deps/` — per-library build scripts
- `src/` — third-party source trees *
- `build/` — temporary build output *
- `local/` — local install prefix *
- `logs/` — build logs *

* local-only directories, not committed to the repository

## Dependency Groups (currently)

| Group | Libraries * |
|---|---|
| SDL | `sdl2` |
| Subtitle chain | `freetype`, `fribidi`, `harfbuzz`, `libass` |
| Video chain | `x264`, `x265`, `libvpx`, `dav1d` |
| Audio chain | `ogg`, `opus`, `vorbis`, `lame` |
| Image and media extras | `libwebp`, `openjpeg`, `libtheora` |
| Audio and resampling extras | `twolame`, `libsoxr` |
| Utility and support libs | `snappy`, `zimg`, `libxml2`, `libzmq` |

* Third-party libraries fetched by the build scripts keep their own licenses.

## Build Notes

### Fixed

- `libvpx`: `install_name` is fixed after install on macOS
- `lame`: `libmp3lame.pc` is generated manually because upstream install does not provide it
- `opus`: ARM assembly is disabled on Apple Silicon builds
- `libtheora`: ARM assembly is disabled on Apple Silicon builds
- `libsoxr`: CMake policy compatibility is set for newer CMake versions

### Known Issues

- `twolame`: behavior may differ depending on the source tree state
- `zimg`: submodules must be initialized correctly on a clean source tree

### To Verify

- full dependency reproducibility across both Apple Silicon machines
- clean-tree reproducibility for `twolame`
- clean-tree reproducibility for `zimg`
