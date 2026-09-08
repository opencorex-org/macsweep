#!/usr/bin/env bash
set -euo pipefail

: "${RELEASE_VERSION:?RELEASE_VERSION is required, for example 1.0.0}"
: "${SPARKLE_PRIVATE_KEY:?SPARKLE_PRIVATE_KEY is required}"

if [[ ! "$RELEASE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "RELEASE_VERSION must use MAJOR.MINOR.PATCH format" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE_DIR="$ROOT_DIR/build/Release"
APP_PATH="$ROOT_DIR/build/Export/MacSweep.app"
TAG="v$RELEASE_VERSION"
UPDATE_ARCHIVE="$RELEASE_DIR/MacSweep-$RELEASE_VERSION.zip"
DMG_PATH="$RELEASE_DIR/MacSweep-$RELEASE_VERSION.dmg"
PACKAGE_PATH="${PACKAGE_PATH:-$ROOT_DIR/build/SourcePackages}"
SPARKLE_BIN="$PACKAGE_PATH/artifacts/sparkle/Sparkle/bin"

cd "$ROOT_DIR"

PROJECT_VERSION="$(xcodebuild -project MacSweep.xcodeproj -scheme MacSweep -configuration Release -showBuildSettings | awk '/MARKETING_VERSION/ { print $3; exit }')"
if [[ "$PROJECT_VERSION" != "$RELEASE_VERSION" ]]; then
  echo "Version mismatch: tag is $RELEASE_VERSION but project is $PROJECT_VERSION" >&2
  exit 1
fi

if [[ "$(git describe --tags --exact-match 2>/dev/null || true)" != "$TAG" ]]; then
  echo "HEAD must be tagged exactly $TAG" >&2
  exit 1
fi

if git show-ref --verify --quiet refs/remotes/origin/main && ! git merge-base --is-ancestor HEAD refs/remotes/origin/main; then
  echo "Release tag must point to a commit contained in origin/main" >&2
  exit 1
fi

./scripts/test.sh
./scripts/archive.sh

mkdir -p "$RELEASE_DIR"

PRE_NOTARY_ZIP="$RELEASE_DIR/MacSweep-notarization.zip"
ditto -c -k --keepParent "$APP_PATH" "$PRE_NOTARY_ZIP"
./scripts/notarize.sh "$APP_PATH" "$PRE_NOTARY_ZIP"
rm -f "$PRE_NOTARY_ZIP"

APP_PATH="$APP_PATH" DMG_PATH="$DMG_PATH" ./scripts/create-dmg.sh
./scripts/notarize.sh "$DMG_PATH"

ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$UPDATE_ARCHIVE"

APPCAST_INPUT="$(mktemp -d)"
trap 'rm -rf "$APPCAST_INPUT"' EXIT
cp "$UPDATE_ARCHIVE" "$APPCAST_INPUT/"
cp RELEASE_NOTES.md "$APPCAST_INPUT/MacSweep-$RELEASE_VERSION.md"

test -x "$SPARKLE_BIN/generate_appcast"
printf '%s' "$SPARKLE_PRIVATE_KEY" | "$SPARKLE_BIN/generate_appcast" \
  --ed-key-file - \
  --download-url-prefix "https://github.com/opencorex-org/macsweep/releases/download/$TAG/" \
  -o "$RELEASE_DIR/appcast.xml" \
  "$APPCAST_INPUT"

shasum -a 256 "$DMG_PATH" "$UPDATE_ARCHIVE" > "$RELEASE_DIR/SHA256SUMS.txt"

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
spctl --assess --type execute --verbose=2 "$APP_PATH"
