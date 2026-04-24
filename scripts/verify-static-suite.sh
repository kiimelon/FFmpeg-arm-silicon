#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPT_DIR/env.sh"
source "$SCRIPT_DIR/build-common.sh"

NAME="verify-static-suite"

verify_prefix_exists() {
  step "Check static prefix"

  if [ ! -d "$PREFIX" ]; then
    fail_step "prefix not found: $PREFIX"
    exit 1
  fi

  if [ ! -d "$PREFIX/lib" ]; then
    fail_step "prefix lib directory not found: $PREFIX/lib"
    exit 1
  fi

  if [ ! -d "$PREFIX/bin" ]; then
    fail_step "prefix bin directory not found: $PREFIX/bin"
    exit 1
  fi

  say "prefix: $PREFIX"
  done_step "check static prefix"
}

verify_no_dynamic_files_in_prefix() {
  step "Check dynamic files in prefix"

  local dynamic_files=""

  dynamic_files="$(find "$PREFIX" \( -name "*.dylib" -o -name "*.so" \) -print || true)"

  if [ -n "$dynamic_files" ]; then
    fail_step "dynamic files found in prefix"
    echo "$dynamic_files"
    exit 1
  fi

  say "no .dylib or .so files found in $PREFIX"
  done_step "check dynamic files in prefix"
}

verify_static_libraries() {
  step "Count static libraries"

  local static_count=""

  static_count="$(find "$PREFIX" -name "*.a" | wc -l | tr -d ' ')"

  if [ "$static_count" -eq 0 ]; then
    fail_step "no static libraries found in $PREFIX"
    exit 1
  fi

  say "static libraries: $static_count"
  done_step "count static libraries"
}

verify_no_la_residue() {
  step "Check .la residue"

  local la_files=""

  la_files="$(find "$PREFIX" -name "*.la" -print || true)"

  if [ -n "$la_files" ]; then
    fail_step ".la residue found in prefix"
    echo "$la_files"
    exit 1
  fi

  say "no .la residue found in $PREFIX"
  done_step "check .la residue"
}

verify_ffmpeg_binaries_exist() {
  step "Check FFmpeg suite binaries"

  local bin

  for bin in ffmpeg ffprobe ffplay; do
    if [ ! -x "$PREFIX/bin/$bin" ]; then
      fail_step "missing executable: $PREFIX/bin/$bin"
      exit 1
    fi

    say "$bin: $PREFIX/bin/$bin"
  done

  done_step "check FFmpeg suite binaries"
}

verify_ffmpeg_versions() {
  step "Check FFmpeg suite versions"

  "$PREFIX/bin/ffmpeg" -version >/dev/null
  say "ffmpeg version: PASS"

  "$PREFIX/bin/ffprobe" -version >/dev/null
  say "ffprobe version: PASS"

  "$PREFIX/bin/ffplay" -version >/dev/null
  say "ffplay version: PASS"

  done_step "check FFmpeg suite versions"
}

verify_otool_available() {
  step "Check otool"

  if ! command -v otool >/dev/null 2>&1; then
    fail_step "otool not found"
    exit 1
  fi

  say "otool: $(command -v otool)"
  done_step "check otool"
}

verify_no_dynamic_dependency_contamination() {
  step "Check dynamic dependency contamination"

  local bin
  local output

  for bin in ffmpeg ffprobe ffplay; do
    output="$(otool -L "$PREFIX/bin/$bin" | grep -E '/opt/homebrew|/usr/local|Cellar|local-static.*\.dylib' || true)"

    if [ -n "$output" ]; then
      fail_step "non-system dynamic dependency found in $bin"
      echo "$output"
      exit 1
    fi

    say "$bin: PASS"
  done

  done_step "check dynamic dependency contamination"
}

print_verification_summary() {
  stage "Static suite verification summary"

  printf "  %-28s PASS\n" "prefix"
  printf "  %-28s PASS\n" "no dynamic files"
  printf "  %-28s PASS\n" "static libraries"
  printf "  %-28s PASS\n" "no .la residue"
  printf "  %-28s PASS\n" "ffmpeg binaries"
  printf "  %-28s PASS\n" "ffmpeg versions"
  printf "  %-28s PASS\n" "dynamic dependency check"
}

stage "Stage 4: Verifying static suite"

kv "Prefix" "$PREFIX"

verify_prefix_exists
verify_no_dynamic_files_in_prefix
verify_static_libraries
verify_no_la_residue
verify_ffmpeg_binaries_exist
verify_ffmpeg_versions
verify_otool_available
verify_no_dynamic_dependency_contamination
print_verification_summary

stage "Static suite verification passed"
