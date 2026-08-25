#!/usr/bin/env bash
set -euo pipefail

echo "Archiving MacSweep..."
xcodebuild -project MacSweep.xcodeproj -scheme MacSweep -archivePath build/MacSweep.xcarchive archive CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
echo "Archive completed."
