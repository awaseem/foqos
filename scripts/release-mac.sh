#!/bin/bash

set -euo pipefail

export GH_PAGER=cat
export GIT_PAGER=cat
export PAGER=cat

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly PROJECT="$REPO_ROOT/foqos.xcodeproj"
readonly SCHEME="Foqos Mac"
readonly VERSION_CONFIG="$REPO_ROOT/Config/MacRelease.xcconfig"
readonly EXPORT_OPTIONS="$REPO_ROOT/Config/MacReleaseExportOptions.plist"
readonly APPCAST_FILE="$REPO_ROOT/appcast-macos.xml"
readonly INFO_PLIST="$REPO_ROOT/FoqosMac/Info.plist"
readonly TEAM_ID="YR54789JNV"
readonly DEVELOPER_ID_NAME="Developer ID Application: Ali Waseem ($TEAM_ID)"
readonly RELEASE_BRANCH="main"

VERSION="${VERSION:-}"
BUILD_NUMBER="${BUILD_NUMBER:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-foqos-notary}"
SPARKLE_KEY_ACCOUNT="${SPARKLE_KEY_ACCOUNT:-ambitionsoftware}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-awaseem/foqos}"
RELEASE_NOTES_FILE="${RELEASE_NOTES_FILE:-}"

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

xcconfig_value() {
  local key="$1"
  awk -F ' = ' -v key="$key" '$1 == key { print $2 }' "$VERSION_CONFIG"
}

update_xcconfig_value() {
  local key="$1"
  local value="$2"
  /usr/bin/sed -E -i '' "s/^${key} = .*$/${key} = ${value}/" "$VERSION_CONFIG"
  [[ "$(xcconfig_value "$key")" == "$value" ]] || fail "Unable to update $key."
}

require_clean_release_branch() {
  [[ "$(git branch --show-current)" == "$RELEASE_BRANCH" ]] ||
    fail "Mac releases must be run from the '$RELEASE_BRANCH' branch."
  [[ -z "$(git status --porcelain)" ]] || fail "Commit or stash all changes before releasing."

  git fetch origin "$RELEASE_BRANCH"
  [[ "$(git rev-parse HEAD)" == "$(git rev-parse "origin/$RELEASE_BRANCH")" ]] ||
    fail "Local '$RELEASE_BRANCH' must exactly match origin/$RELEASE_BRANCH."
}

validate_source_changes() {
  local unexpected_paths
  unexpected_paths="$({ git status --porcelain | cut -c4- | \
    grep -v -E '^(Config/MacRelease\.xcconfig|appcast-macos\.xml)$'; } || true)"
  [[ -z "$unexpected_paths" ]] ||
    fail "Unexpected source changes appeared during release:\n$unexpected_paths"
}

[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
  fail "VERSION is required and must use x.y.z format, for example VERSION=0.1.0."
[[ "$BUILD_NUMBER" =~ ^[1-9][0-9]*$ ]] || fail "BUILD_NUMBER must be a positive integer."

readonly TAG="mac-v$VERSION"
readonly DMG_NAME="Foqos-for-Mac-$VERSION.dmg"
readonly FEED_URL="https://raw.githubusercontent.com/$GITHUB_REPOSITORY/main/appcast-macos.xml"
readonly RELEASE_URL="https://github.com/$GITHUB_REPOSITORY/releases/tag/$TAG"
readonly DOWNLOAD_PREFIX="https://github.com/$GITHUB_REPOSITORY/releases/download/$TAG/"
readonly RELEASE_RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"
readonly RELEASE_DIR="$REPO_ROOT/.build/mac-release/$TAG-$BUILD_NUMBER-$RELEASE_RUN_ID"
readonly DERIVED_DATA="$RELEASE_DIR/DerivedData"
readonly ARCHIVE_PATH="$RELEASE_DIR/Foqos-for-Mac.xcarchive"
readonly EXPORT_PATH="$RELEASE_DIR/Export"
readonly APP_PATH="$EXPORT_PATH/Foqos for Mac.app"
readonly APP_ZIP="$RELEASE_DIR/Foqos-for-Mac-$VERSION.zip"
readonly DMG_ROOT="$RELEASE_DIR/DMG"
readonly DMG_PATH="$RELEASE_DIR/$DMG_NAME"
readonly APPCAST_DIR="$RELEASE_DIR/Appcast"

for command_name in awk codesign cut curl date ditto gh git grep hdiutil lipo plutil security \
  sed spctl xcodebuild xmllint xcrun; do
  require_command "$command_name"
done

cd "$REPO_ROOT"

step "Checking repository and release inputs"
require_clean_release_branch

current_build_number="$(xcconfig_value CURRENT_PROJECT_VERSION)"
[[ "$current_build_number" =~ ^[0-9]+$ ]] || fail "Current Mac build number is invalid."
((BUILD_NUMBER > current_build_number)) ||
  fail "BUILD_NUMBER must be greater than the current Mac build number ($current_build_number)."

if git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null 2>&1; then
  fail "Git tag '$TAG' already exists."
fi
if gh release view "$TAG" --repo "$GITHUB_REPOSITORY" >/dev/null 2>&1; then
  fail "GitHub release '$TAG' already exists."
fi

gh auth status >/dev/null
gh repo view "$GITHUB_REPOSITORY" --json nameWithOwner >/dev/null
security find-identity -v -p codesigning | grep -F "$DEVELOPER_ID_NAME" >/dev/null ||
  fail "Developer ID signing identity '$DEVELOPER_ID_NAME' is not installed."

[[ ! -e "$RELEASE_DIR" ]] || fail "Release workspace already exists: $RELEASE_DIR"

printf 'Release plan:\n'
printf '  Version:       %s\n' "$VERSION"
printf '  Build:         %s\n' "$BUILD_NUMBER"
printf '  Git tag:       %s\n' "$TAG"
printf '  GitHub repo:   %s\n' "$GITHUB_REPOSITORY"
printf '  Notary profile:%s\n' " $NOTARY_PROFILE"

if [[ "${RELEASE_CONFIRM:-}" != "YES" ]]; then
  read -r -p "Continue with the Mac release? [y/N] " confirmation
  [[ "$confirmation" == "y" || "$confirmation" == "Y" ]] || fail "Release cancelled."
fi

step "Checking notarization credentials"
if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null; then
  fail "Notary profile '$NOTARY_PROFILE' is unavailable. See the Mac Releases section in README.md."
fi

mkdir -p "$RELEASE_DIR"
readonly ORIGINAL_VERSION_CONFIG="$RELEASE_DIR/MacRelease.xcconfig.original"
readonly ORIGINAL_APPCAST="$RELEASE_DIR/appcast-macos.xml.original"
ditto "$VERSION_CONFIG" "$ORIGINAL_VERSION_CONFIG"
ditto "$APPCAST_FILE" "$ORIGINAL_APPCAST"
source_changes_committed="NO"

release_exit() {
  local status="$?"
  if ((status != 0)) && [[ "$source_changes_committed" == "NO" ]]; then
    ditto "$ORIGINAL_VERSION_CONFIG" "$VERSION_CONFIG"
    ditto "$ORIGINAL_APPCAST" "$APPCAST_FILE"
    printf 'Restored release version and appcast source files.\n' >&2
  fi
  printf 'Release workspace: %s\n' "$RELEASE_DIR"
}
trap release_exit EXIT

step "Resolving Sparkle tools"
xcodebuild -resolvePackageDependencies \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -derivedDataPath "$DERIVED_DATA"

readonly SPARKLE_TOOLS="$DERIVED_DATA/SourcePackages/artifacts/sparkle/Sparkle/bin"
readonly GENERATE_KEYS="$SPARKLE_TOOLS/generate_keys"
readonly GENERATE_APPCAST="$SPARKLE_TOOLS/generate_appcast"
[[ -x "$GENERATE_KEYS" ]] || fail "Sparkle generate_keys tool was not resolved."
[[ -x "$GENERATE_APPCAST" ]] || fail "Sparkle generate_appcast tool was not resolved."

keychain_public_key="$($GENERATE_KEYS --account "$SPARKLE_KEY_ACCOUNT" -p)"
app_public_key="$(plutil -extract SUPublicEDKey raw "$INFO_PLIST")"
[[ "$keychain_public_key" == "$app_public_key" ]] ||
  fail "The Sparkle Keychain key does not match SUPublicEDKey in FoqosMac/Info.plist."
[[ "$(plutil -extract SUFeedURL raw "$INFO_PLIST")" == "$FEED_URL" ]] ||
  fail "SUFeedURL does not match the configured GitHub repository."

step "Updating Mac release version"
update_xcconfig_value MARKETING_VERSION "$VERSION"
update_xcconfig_value CURRENT_PROJECT_VERSION "$BUILD_NUMBER"
git diff --check

step "Archiving the universal Developer ID app"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  -archivePath "$ARCHIVE_PATH" \
  MARKETING_VERSION="$VERSION" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  archive

step "Exporting the signed app"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS"

[[ -d "$APP_PATH" ]] || fail "Exported app was not found at $APP_PATH"
[[ "$(plutil -extract CFBundleShortVersionString raw "$APP_PATH/Contents/Info.plist")" == "$VERSION" ]] ||
  fail "Exported app marketing version does not match $VERSION."
[[ "$(plutil -extract CFBundleVersion raw "$APP_PATH/Contents/Info.plist")" == "$BUILD_NUMBER" ]] ||
  fail "Exported app build number does not match $BUILD_NUMBER."

filter_info="$APP_PATH/Contents/Library/SystemExtensions/dev.ambitionsoftware.foqos.mac.filter.systemextension/Contents/Info.plist"
[[ "$(plutil -extract CFBundleShortVersionString raw "$filter_info")" == "$VERSION" ]] ||
  fail "System extension marketing version does not match $VERSION."
[[ "$(plutil -extract CFBundleVersion raw "$filter_info")" == "$BUILD_NUMBER" ]] ||
  fail "System extension build number does not match $BUILD_NUMBER."

app_architectures="$(lipo -archs "$APP_PATH/Contents/MacOS/Foqos for Mac")"
[[ "$app_architectures" == *arm64* && "$app_architectures" == *x86_64* ]] ||
  fail "Exported app is not universal: $app_architectures"

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
codesign -dv --verbose=4 "$APP_PATH" 2>&1 | grep -F "Authority=$DEVELOPER_ID_NAME" >/dev/null ||
  fail "Exported app is not signed with the expected Developer ID identity."

entitlements_file="$RELEASE_DIR/Foqos-entitlements.plist"
codesign -d --entitlements :- "$APP_PATH" >"$entitlements_file" 2>/dev/null
if [[ "$(plutil -extract com.apple.security.get-task-allow raw "$entitlements_file" 2>/dev/null || true)" == "true" ]]; then
  fail "The exported app allows debugging. Regenerate the Developer ID provisioning profile."
fi

step "Notarizing and stapling the app"
ditto -c -k --keepParent "$APP_PATH" "$APP_ZIP"
xcrun notarytool submit "$APP_ZIP" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait \
  --timeout 30m
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"
spctl --assess --type execute --verbose=4 "$APP_PATH"

step "Creating the DMG"
mkdir -p "$DMG_ROOT"
ditto "$APP_PATH" "$DMG_ROOT/Foqos for Mac.app"
ln -s /Applications "$DMG_ROOT/Applications"
hdiutil create \
  -volname "Foqos for Mac" \
  -srcfolder "$DMG_ROOT" \
  -format UDZO \
  -ov \
  "$DMG_PATH"
codesign --force --sign "$DEVELOPER_ID_NAME" --timestamp "$DMG_PATH"

step "Notarizing and stapling the DMG"
xcrun notarytool submit "$DMG_PATH" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait \
  --timeout 30m
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"
codesign --verify --verbose=2 "$DMG_PATH"
spctl --assess --type open --context context:primary-signature --verbose=4 "$DMG_PATH"

step "Generating the signed Sparkle appcast"
mkdir -p "$APPCAST_DIR"
ditto "$DMG_PATH" "$APPCAST_DIR/$DMG_NAME"
ditto "$APPCAST_FILE" "$APPCAST_DIR/appcast-macos.xml"

if [[ -n "$RELEASE_NOTES_FILE" ]]; then
  if [[ "$RELEASE_NOTES_FILE" != /* ]]; then
    RELEASE_NOTES_FILE="$REPO_ROOT/$RELEASE_NOTES_FILE"
  fi
  [[ -f "$RELEASE_NOTES_FILE" ]] || fail "Release notes file was not found."
  release_notes="$RELEASE_NOTES_FILE"
else
  release_notes="$RELEASE_DIR/release-notes.md"
  printf '# Foqos for Mac %s\n\nSee the GitHub release for details.\n' "$VERSION" >"$release_notes"
fi
ditto "$release_notes" "$APPCAST_DIR/Foqos-for-Mac-$VERSION.md"

(
  cd "$APPCAST_DIR"
  "$GENERATE_APPCAST" \
    --account "$SPARKLE_KEY_ACCOUNT" \
    --download-url-prefix "$DOWNLOAD_PREFIX" \
    --embed-release-notes \
    --link "$RELEASE_URL" \
    --maximum-deltas 0 \
    -o appcast-macos.xml \
    .
)

xmllint --noout "$APPCAST_DIR/appcast-macos.xml"
grep -F "${DOWNLOAD_PREFIX}${DMG_NAME}" "$APPCAST_DIR/appcast-macos.xml" >/dev/null ||
  fail "Generated appcast does not contain the expected DMG URL."
grep -F 'sparkle:edSignature=' "$APPCAST_DIR/appcast-macos.xml" >/dev/null ||
  fail "Generated appcast does not contain a Sparkle signature."
ditto "$APPCAST_DIR/appcast-macos.xml" "$APPCAST_FILE"

validate_source_changes
git diff --check

step "Committing the Mac version"
git add -- "$VERSION_CONFIG"
git diff --cached --quiet && fail "The Mac version file did not change."
git commit -m "Release Foqos for Mac $VERSION"
source_changes_committed="YES"
git push origin "$RELEASE_BRANCH"
release_commit="$(git rev-parse HEAD)"

step "Uploading a draft GitHub release"
gh release create "$TAG" "$DMG_PATH" \
  --repo "$GITHUB_REPOSITORY" \
  --target "$release_commit" \
  --title "Foqos for Mac $VERSION" \
  --notes-file "$release_notes" \
  --draft \
  --latest=false

step "Publishing the Sparkle appcast"
git add -- "$APPCAST_FILE"
git diff --cached --quiet && fail "The Sparkle appcast did not change."
git commit -m "Update Mac appcast for $VERSION"
git push origin "$RELEASE_BRANCH"

step "Publishing the GitHub release"
gh release edit "$TAG" \
  --repo "$GITHUB_REPOSITORY" \
  --draft=false \
  --latest=false

curl --fail --location --head --retry 5 --retry-delay 2 \
  "${DOWNLOAD_PREFIX}${DMG_NAME}" >/dev/null
curl --fail --location --retry 5 --retry-delay 2 \
  "$FEED_URL?build=$BUILD_NUMBER" | xmllint --noout -

printf '\nFoqos for Mac %s (%s) is published.\n' "$VERSION" "$BUILD_NUMBER"
printf 'Release: %s\n' "$RELEASE_URL"
printf 'DMG: %s\n' "$DMG_PATH"
printf 'Appcast: %s\n' "$FEED_URL"
