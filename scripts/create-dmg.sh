#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="${APP_PATH:-$ROOT_DIR/build/Export/MacSweep.app}"
DMG_PATH="${DMG_PATH:-$ROOT_DIR/build/Release/MacSweep.dmg}"
BACKGROUND_PATH="$ROOT_DIR/Distribution/DMG/background.png"
VOLUME_NAME="MacSweep"

test -d "$APP_PATH"
mkdir -p "$(dirname "$DMG_PATH")"

STAGING_DIR="$(mktemp -d)"
MOUNT_DIR="$(mktemp -d)"
TEMP_DIR="$(mktemp -d)"
READ_WRITE_DMG="$TEMP_DIR/MacSweep-read-write.dmg"
DEVICE=""

cleanup() {
  if [[ -n "$DEVICE" ]]; then
    hdiutil detach "$DEVICE" -quiet 2>/dev/null || true
  fi
  rm -rf "$STAGING_DIR" "$MOUNT_DIR" "$TEMP_DIR" 2>/dev/null || true
}
trap cleanup EXIT

ditto "$APP_PATH" "$STAGING_DIR/MacSweep.app"
ln -s /Applications "$STAGING_DIR/Applications"
mkdir -p "$STAGING_DIR/.background"

swift "$ROOT_DIR/scripts/render-dmg-background.swift" "$BACKGROUND_PATH"
ditto "$BACKGROUND_PATH" "$STAGING_DIR/.background/background.png"

hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -fs HFS+ \
  -format UDRW \
  "$READ_WRITE_DMG"

hdiutil attach "$READ_WRITE_DMG" -readwrite -noverify -noautoopen -mountpoint "$MOUNT_DIR"
DEVICE="$(df "$MOUNT_DIR" | awk 'NR == 2 { print $1 }')"
test -n "$DEVICE"

osascript <<APPLESCRIPT
tell application "Finder"
  tell disk "$VOLUME_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set pathbar visible of container window to false
    set bounds of container window to {100, 100, 860, 620}

    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 104
    set text size of viewOptions to 13
    set background picture of viewOptions to file ".background:background.png"

    set position of item "MacSweep.app" of container window to {210, 180}
    set position of item "Applications" of container window to {550, 180}
    update without registering applications
    delay 2
    close
  end tell
end tell
APPLESCRIPT

sync
hdiutil detach "$DEVICE" -quiet
DEVICE=""

rm -f "$DMG_PATH"
hdiutil convert "$READ_WRITE_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH"

hdiutil verify "$DMG_PATH"
