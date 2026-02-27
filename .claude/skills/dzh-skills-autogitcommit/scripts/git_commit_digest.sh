#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  git_commit_digest.sh [--mode auto|staged|unstaged|all] [--patch-lines N]
                       [--respect-gitignore on|off]

Description:
  Generate a concise digest of repository changes for commit-message drafting.

Defaults:
  --mode auto              Prefer staged changes; fall back to unstaged changes.
  --patch-lines 220        Show at most N patch lines per rendered diff section.
  --respect-gitignore on   Exclude files matched by .gitignore from digest scope.
EOF
}

mode="auto"
patch_lines=220
respect_gitignore="on"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      [[ $# -ge 2 ]] || { echo "Missing value for --mode" >&2; exit 1; }
      mode="$2"
      shift 2
      ;;
    --patch-lines)
      [[ $# -ge 2 ]] || { echo "Missing value for --patch-lines" >&2; exit 1; }
      patch_lines="$2"
      shift 2
      ;;
    --respect-gitignore)
      [[ $# -ge 2 ]] || { echo "Missing value for --respect-gitignore" >&2; exit 1; }
      respect_gitignore="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "$mode" in
  auto|staged|unstaged|all) ;;
  *)
    echo "Invalid --mode: $mode (expected auto|staged|unstaged|all)" >&2
    exit 1
    ;;
esac

case "$respect_gitignore" in
  on|off) ;;
  *)
    echo "Invalid --respect-gitignore: $respect_gitignore (expected on|off)" >&2
    exit 1
    ;;
esac

if ! [[ "$patch_lines" =~ ^[0-9]+$ ]] || [[ "$patch_lines" -le 0 ]]; then
  echo "Invalid --patch-lines value: $patch_lines (must be positive integer)" >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not inside a git repository." >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

list_untracked_paths() {
  if [[ "$respect_gitignore" == "on" ]]; then
    git ls-files --others --exclude-standard
  else
    git ls-files --others
  fi
}

has_untracked() {
  [[ -n "$(list_untracked_paths | head -n 1)" ]]
}

if [[ "$mode" == "auto" ]]; then
  if ! git diff --cached --quiet; then
    mode="staged"
  elif ! git diff --quiet || has_untracked; then
    mode="unstaged"
  else
    mode="staged"
  fi
fi

filter_paths_for_upload() {
  local input="$1"
  local path=""

  while IFS= read -r path; do
    [[ -z "$path" ]] && continue

    if [[ "$respect_gitignore" == "on" ]] && git check-ignore --no-index -q -- "$path"; then
      continue
    fi

    printf '%s\n' "$path"
  done <<< "$input"
}

print_block_or_none() {
  local content="$1"
  if [[ -n "$content" ]]; then
    printf '%s\n' "$content"
  else
    echo "(none)"
  fi
}

run_git_diff_with_paths() {
  local diff_scope="$1"
  local diff_kind="$2"
  local paths_text="$3"
  local output=""
  local old_ifs="$IFS"

  set -f
  IFS=$'\n'
  set -- $paths_text
  IFS="$old_ifs"
  set +f

  if [[ $# -eq 0 ]]; then
    printf ''
    return 0
  fi

  case "$diff_kind" in
    name-status)
      if [[ "$diff_scope" == "staged" ]]; then
        output="$(git diff --cached --name-status --find-renames -- "$@" || true)"
      else
        output="$(git diff --name-status --find-renames -- "$@" || true)"
      fi
      ;;
    stat)
      if [[ "$diff_scope" == "staged" ]]; then
        output="$(git diff --cached --stat --find-renames -- "$@" || true)"
      else
        output="$(git diff --stat --find-renames -- "$@" || true)"
      fi
      ;;
    patch)
      if [[ "$diff_scope" == "staged" ]]; then
        output="$(git diff --cached --unified=1 --find-renames --no-color -- "$@" | sed -n "1,${patch_lines}p")"
      else
        output="$(git diff --unified=1 --find-renames --no-color -- "$@" | sed -n "1,${patch_lines}p")"
      fi
      ;;
    *)
      echo "Internal error: unsupported diff kind '$diff_kind'" >&2
      exit 1
      ;;
  esac

  printf '%s' "$output"
}

render_diff_section() {
  local label="$1"
  local diff_scope="$2"
  local paths_text="$3"

  echo "## ${label}"
  echo

  echo "### Name-status"
  name_status="$(run_git_diff_with_paths "$diff_scope" name-status "$paths_text")"
  print_block_or_none "$name_status"
  echo

  echo "### Diff stat"
  diff_stat="$(run_git_diff_with_paths "$diff_scope" stat "$paths_text")"
  print_block_or_none "$diff_stat"
  echo

  echo "### Patch preview (first ${patch_lines} lines)"
  patch_preview="$(run_git_diff_with_paths "$diff_scope" patch "$paths_text")"
  print_block_or_none "$patch_preview"
  echo
}

staged_paths_raw="$(git diff --cached --name-only --find-renames || true)"
unstaged_paths_raw="$(git diff --name-only --find-renames || true)"
untracked_paths_raw="$(list_untracked_paths || true)"

staged_paths_filtered="$(filter_paths_for_upload "$staged_paths_raw")"
unstaged_paths_filtered="$(filter_paths_for_upload "$unstaged_paths_raw")"
untracked_paths_filtered="$(filter_paths_for_upload "$untracked_paths_raw")"

echo "# Commit Context Digest"
echo "repo: $(basename "$repo_root")"
echo "path: $repo_root"
echo "branch: $(git rev-parse --abbrev-ref HEAD)"
echo "mode: $mode"
echo "respect_gitignore: $respect_gitignore"
echo "generated_at_utc: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo

echo "## Working tree status"
if [[ "$respect_gitignore" == "on" ]]; then
  git status --short --untracked-files=all
else
  git status --short --untracked-files=all --ignored
fi
echo

candidate_label="Upload candidates (.gitignore filtered)"
if [[ "$respect_gitignore" == "off" ]]; then
  candidate_label="Upload candidates (including ignored files)"
fi

echo "## ${candidate_label}"
upload_candidates="$(
  printf '%s\n%s\n%s\n' \
    "$staged_paths_filtered" \
    "$unstaged_paths_filtered" \
    "$untracked_paths_filtered" | awk 'NF && !seen[$0]++'
)"
if [[ -n "$upload_candidates" ]]; then
  printf '%s\n' "$upload_candidates"
else
  echo "(none)"
fi
echo

if [[ "$mode" == "staged" ]]; then
  render_diff_section "Staged changes" staged "$staged_paths_filtered"
elif [[ "$mode" == "unstaged" ]]; then
  render_diff_section "Unstaged changes" unstaged "$unstaged_paths_filtered"

  echo "### Untracked files"
  print_block_or_none "$untracked_paths_filtered"
  echo
else
  render_diff_section "Staged changes" staged "$staged_paths_filtered"
  render_diff_section "Unstaged changes" unstaged "$unstaged_paths_filtered"

  echo "### Untracked files"
  print_block_or_none "$untracked_paths_filtered"
  echo
fi

echo "## Drafting hints"
echo "- Summarize behavior and intent, not every line-level edit."
if [[ "$respect_gitignore" == "on" ]]; then
  echo "- Summarize only upload candidates (respecting .gitignore)."
else
  echo "- Use --respect-gitignore on to exclude ignored files."
fi
echo "- Prefer one commit title under 72 chars."
echo "- Keep commit body lines under 72 chars."
