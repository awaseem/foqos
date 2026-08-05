#!/bin/bash

set -euo pipefail

export GH_PAGER=cat
export GIT_PAGER=cat
export PAGER=cat

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly PROJECT_RELATIVE_PATH="foqos.xcodeproj/project.pbxproj"
readonly VERSION_UPDATER="$SCRIPT_DIR/update-app-version.rb"
readonly RELEASE_BRANCH="main"

VERSION="${VERSION:-}"

fail() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

step() {
  printf '\n==> %s\n' "$1"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command '$1' was not found."
}

require_clean_release_branch() {
  [[ "$(git branch --show-current)" == "$RELEASE_BRANCH" ]] ||
    fail "App releases must be run from the '$RELEASE_BRANCH' branch."
  [[ -z "$(git status --porcelain)" ]] || fail "Commit or stash all changes before releasing."

  git fetch origin "$RELEASE_BRANCH"
  [[ "$(git rev-parse HEAD)" == "$(git rev-parse "origin/$RELEASE_BRANCH")" ]] ||
    fail "Local '$RELEASE_BRANCH' must exactly match origin/$RELEASE_BRANCH."
}

version_is_greater() {
  ruby -e '
    left, right = ARGV.map { |version| version.split(".").map(&:to_i) }
    width = [left.length, right.length].max
    left += [0] * (width - left.length)
    right += [0] * (width - right.length)
    exit((left <=> right) == 1 ? 0 : 1)
  ' "$1" "$2"
}

validate_source_changes() {
  local unexpected_paths
  unexpected_paths="$({ git status --porcelain | cut -c4- | \
    grep -F -x -v "$PROJECT_RELATIVE_PATH"; } || true)"
  [[ -z "$unexpected_paths" ]] ||
    fail "Unexpected source changes appeared during release:\n$unexpected_paths"
}

[[ "$VERSION" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] ||
  fail "VERSION is required and must use x.y or x.y.z format, for example VERSION=2.2.1."

readonly TAG="v$VERSION"

for command_name in cut gh git grep head ruby; do
  require_command "$command_name"
done
[[ -x "$VERSION_UPDATER" ]] || fail "Version updater is not executable: $VERSION_UPDATER"

cd "$REPO_ROOT"

step "Checking repository and release inputs"
require_clean_release_branch
gh auth status >/dev/null
github_repository="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"

current_version="$($VERSION_UPDATER --current)"
version_is_greater "$VERSION" "$current_version" ||
  fail "VERSION must be greater than the current iOS version ($current_version)."

if git rev-parse --quiet --verify "refs/tags/$TAG" >/dev/null; then
  fail "Local Git tag '$TAG' already exists."
fi
if git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null 2>&1; then
  fail "Git tag '$TAG' already exists on origin."
fi
if gh release view "$TAG" --repo "$github_repository" >/dev/null 2>&1; then
  fail "GitHub release '$TAG' already exists."
fi

previous_ios_tag="$(git tag --list 'v[0-9]*' --sort=-version:refname | head -n 1)"
printf 'Release plan:\n'
printf '  Current version: %s\n' "$current_version"
printf '  New version:     %s\n' "$VERSION"
printf '  Build:           1\n'
printf '  Git tag:         %s\n' "$TAG"
printf '  GitHub release:  Foqos for iOS %s\n' "$VERSION"
printf '  GitHub repo:     %s\n' "$github_repository"
printf '  Trigger:         push to main for Xcode Cloud\n'

if [[ "${RELEASE_CONFIRM:-}" != "YES" ]]; then
  read -r -p "Commit and push this app release? [y/N] " confirmation
  [[ "$confirmation" == "y" || "$confirmation" == "Y" ]] || fail "Release cancelled."
fi

source_changes_committed="NO"
release_tag_pushed="NO"
github_release_created="NO"
release_exit() {
  local status="$?"
  if ((status != 0)) && [[ "$source_changes_committed" == "NO" ]]; then
    git restore --staged --worktree -- "$PROJECT_RELATIVE_PATH"
    printf 'Restored the iOS project version settings.\n' >&2
  elif ((status != 0)) && [[ "$release_tag_pushed" == "YES" ]] &&
    [[ "$github_release_created" == "NO" ]]; then
    printf 'The version and tag were pushed, but the GitHub release was not created.\n' >&2
    printf 'Retry with: gh release create %q --repo %q --verify-tag --title %q --generate-notes' \
      "$TAG" "$github_repository" "Foqos for iOS $VERSION" >&2
    if [[ -n "$previous_ios_tag" ]]; then
      printf ' --notes-start-tag %q' "$previous_ios_tag" >&2
    fi
    printf ' --fail-on-no-commits --latest\n' >&2
  elif ((status != 0)); then
    printf 'The release commit and any local release tag remain for recovery.\n' >&2
  fi
}
trap release_exit EXIT

step "Updating iOS app and extension versions"
"$VERSION_UPDATER" "$VERSION"
"$VERSION_UPDATER" --check "$VERSION"
validate_source_changes
git diff --check
git diff --stat -- "$PROJECT_RELATIVE_PATH"

step "Committing the version"
git add "$PROJECT_RELATIVE_PATH"
git commit -m "Release iOS $VERSION"
source_changes_committed="YES"

step "Pushing main to trigger Xcode Cloud"
git push origin "$RELEASE_BRANCH"

step "Publishing the release tag"
git tag "$TAG"
git push origin "$TAG"
release_tag_pushed="YES"

step "Creating the GitHub release"
release_options=(
  --repo "$github_repository"
  --verify-tag
  --title "Foqos for iOS $VERSION"
  --generate-notes
  --fail-on-no-commits
  --latest
)
if [[ -n "$previous_ios_tag" ]]; then
  release_options+=(--notes-start-tag "$previous_ios_tag")
fi
release_url="$(gh release create "$TAG" "${release_options[@]}")"
github_release_created="YES"

trap - EXIT
printf '\nFoqos for iOS %s was released successfully.\n' "$VERSION"
printf 'Xcode Cloud was triggered by the main branch push.\n'
printf 'GitHub release: %s\n' "$release_url"
