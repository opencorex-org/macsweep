#!/usr/bin/env bash
set -euo pipefail

: "${DEVELOPMENT_TEAM:?DEVELOPMENT_TEAM is required}"
: "${SPARKLE_PUBLIC_KEY:?SPARKLE_PUBLIC_KEY is required}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCHIVE_PATH="${ARCHIVE_PATH:-$ROOT_DIR/build/MacSweep.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-$ROOT_DIR/build/Export}"
PACKAGE_PATH="${PACKAGE_PATH:-$ROOT_DIR/build/SourcePackages}"
RELEASE_BUILD_NUMBER="${RELEASE_BUILD_NUMBER:-}"

BUILD_NUMBER_ARGS=()
if [[ -n "$RELEASE_BUILD_NUMBER" ]]; then
  if [[ ! "$RELEASE_BUILD_NUMBER" =~ ^[1-9][0-9]*$ ]]; then
    echo "RELEASE_BUILD_NUMBER must be a positive integer" >&2
    exit 1
  fi
  BUILD_NUMBER_ARGS+=(CURRENT_PROJECT_VERSION="$RELEASE_BUILD_NUMBER")
fi

cd "$ROOT_DIR"
xcodebuild \
  -project MacSweep.xcodeproj \
  -scheme MacSweep \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$ARCHIVE_PATH" \
  -clonedSourcePackagesDirPath "$PACKAGE_PATH" \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="Developer ID Application" \
  SPARKLE_PUBLIC_KEY="$SPARKLE_PUBLIC_KEY" \
  "${BUILD_NUMBER_ARGS[@]}" \
  archive

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist Distribution/ExportOptions/DeveloperIDExportOptions.plist

test -d "$EXPORT_PATH/MacSweep.app"
codesign --verify --deep --strict --verbose=2 "$EXPORT_PATH/MacSweep.app"
