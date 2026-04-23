#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"
source "$(dirname "$0")/build-static-common.sh"
source "$(dirname "$0")/deps-list.sh"

NAME="git-fetch"
LOG_FILE="$LOGS/git-fetch.log"

fetch_banner_start() {
  echo
  echo "***** fetch lib sources start *****"
}

fetch_banner_end() {
  echo
  echo "***** fetch lib sources end *****"
}

git_bin() {
  PATH="$ORIGINAL_PATH" command -v git
}

remote_has_branch() {
  local repo_url="$1"
  local ref="$2"
  "$(git_bin)" ls-remote --exit-code --heads "$repo_url" "$ref" >/dev/null 2>&1
}

remote_has_tag() {
  local repo_url="$1"
  local ref="$2"

  if "$(git_bin)" ls-remote --exit-code --tags "$repo_url" "$ref" >/dev/null 2>&1; then
    return 0
  fi

  "$(git_bin)" ls-remote --exit-code --tags "$repo_url" "${ref}^{}" >/dev/null 2>&1
}

detect_remote_ref_type() {
  local repo_url="$1"
  local ref="$2"

  if remote_has_branch "$repo_url" "$ref"; then
    echo "branch"
    return 0
  fi

  if remote_has_tag "$repo_url" "$ref"; then
    echo "tag"
    return 0
  fi

  return 1
}

current_branch_name() {
  local repo_dir="$1"
  (
    cd "$repo_dir"
    "$(git_bin)" symbolic-ref --quiet --short HEAD 2>/dev/null || true
  )
}

head_matches_tag() {
  local repo_dir="$1"
  local tag_name="$2"
  (
    cd "$repo_dir"

    local head_commit
    local tag_commit

    head_commit="$("$(git_bin)" rev-parse HEAD)"
    tag_commit="$("$(git_bin)" rev-list -n 1 "$tag_name" 2>/dev/null || true)"

    [ -n "$tag_commit" ] && [ "$head_commit" = "$tag_commit" ]
  )
}

local_has_ref() {
  local repo_dir="$1"
  local ref="$2"
  (
    cd "$repo_dir"
    "$(git_bin)" rev-parse --verify "$ref" >/dev/null 2>&1
  )
}

checkout_target_ref() {
  local repo_dir="$1"
  local ref_type="$2"
  local ref="$3"

  (
    cd "$repo_dir"

    case "$ref_type" in
      branch)
        echo "[fetch] fetching branch $ref"
        "$(git_bin)" fetch --depth 1 origin "$ref" 2>&1 | tee -a "$LOG_FILE"

        echo "[fetch] switching to branch $ref"
        "$(git_bin)" checkout -B "$ref" "origin/$ref" 2>&1 | tee -a "$LOG_FILE"
        ;;
      tag)
        echo "[fetch] fetching tag $ref"
        "$(git_bin)" fetch --depth 1 origin "refs/tags/$ref:refs/tags/$ref" 2>&1 | tee -a "$LOG_FILE"

        echo "[fetch] switching to tag $ref"
        "$(git_bin)" checkout --detach "$ref" 2>&1 | tee -a "$LOG_FILE"
        ;;
      *)
        echo "ERROR: unsupported ref type: $ref_type"
        exit 1
        ;;
    esac
  )
}

clone_target_ref() {
  local repo_url="$1"
  local dest_dir="$2"
  local ref="$3"

  if [ -n "$ref" ]; then
    echo "[fetch] cloning with --branch $ref"
    "$(git_bin)" clone "$repo_url" "$dest_dir" --branch "$ref" --depth 1 2>&1 | tee -a "$LOG_FILE"
  else
    echo "[fetch] cloning default branch"
    "$(git_bin)" clone "$repo_url" "$dest_dir" --depth 1 2>&1 | tee -a "$LOG_FILE"
  fi
}

sync_git_dep() {
  local dep_name="$1"
  local repo_url="$2"
  local ref="$3"

  local dest_dir="$SRC/$dep_name"
  local ref_type=""

  step "fetch source: $dep_name"
  echo "[fetch] repo   : $repo_url"
  echo "[fetch] dest   : $dest_dir"
  echo "[fetch] target : ${ref:-default}"

  if [ -n "$ref" ]; then
    echo "[fetch] detecting remote ref type"
    if ! ref_type="$(detect_remote_ref_type "$repo_url" "$ref")"; then
      echo "ERROR: target ref not found for $dep_name: $ref"
      echo "ERROR: repo: $repo_url"
      exit 1
    fi
    echo "[fetch] resolved ref type: $ref_type"
  fi

  if [ ! -e "$dest_dir" ]; then
    clone_target_ref "$repo_url" "$dest_dir" "$ref"
    done_step "fetch source: $dep_name"
    return 0
  fi

  if [ ! -d "$dest_dir/.git" ]; then
    echo "ERROR: destination exists but is not a git repo: $dest_dir"
    exit 1
  fi

  echo "[fetch] existing repo found"

  if [ -z "$ref" ]; then
    echo "[fetch] no target ref configured, keeping existing checkout"
    done_step "fetch source: $dep_name"
    return 0
  fi

  case "$ref_type" in
    branch)
      local current_branch
      current_branch="$(current_branch_name "$dest_dir")"
      echo "[fetch] current branch: ${current_branch:-detached}"

      if [ "$current_branch" = "$ref" ]; then
        echo "[fetch] branch already matches target, no switch needed"
        done_step "fetch source: $dep_name"
        return 0
      fi

      echo "[fetch] branch mismatch, switching to $ref"
      checkout_target_ref "$dest_dir" "$ref_type" "$ref"
      ;;
    tag)
      if local_has_ref "$dest_dir" "$ref" && head_matches_tag "$dest_dir" "$ref"; then
        echo "[fetch] tag already matches target, no switch needed"
        done_step "fetch source: $dep_name"
        return 0
      fi

      echo "[fetch] tag mismatch, switching to $ref"
      checkout_target_ref "$dest_dir" "$ref_type" "$ref"
      ;;
    *)
      echo "ERROR: unresolved ref type for $dep_name"
      exit 1
      ;;
  esac

  done_step "fetch source: $dep_name"
}

fetch_banner_start

echo "==> Fetching library sources (git)"
echo "Source root : $SRC"
echo "Log         : $LOG_FILE"

mkdir -p "$SRC" "$LOGS"
: > "$LOG_FILE"

{
  echo "ROOT=$ROOT"
  echo "SRC=$SRC"
  echo "LOGS=$LOGS"
  echo "ORIGINAL_PATH=$ORIGINAL_PATH"
  echo "PATH=$PATH"
  echo
} >> "$LOG_FILE"

step "check required tool"
if ! PATH="$ORIGINAL_PATH" command -v git >/dev/null 2>&1; then
  echo "ERROR: git not found in ORIGINAL_PATH"
  exit 1
fi
echo "[fetch] git: $(git_bin)"
done_step "check required tool"

for dep in "${DEPS_LIST[@]}"; do
  IFS='|' read -r dep_name repo_url ref <<< "$dep"
  sync_git_dep "$dep_name" "$repo_url" "$ref"
done

step "final verify"
find "$SRC" -maxdepth 1 -mindepth 1 -type d | sort

fetch_banner_end
