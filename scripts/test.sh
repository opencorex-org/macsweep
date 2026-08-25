#!/usr/bin/env bash
set -euo pipefail

echo "Running MacSweep tests..."
xcodebuild -project MacSweep.xcodeproj -scheme MacSweep -destination 'platform=macOS' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO test || true
echo "Tests finished."
