#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

for script in scripts/*.sh; do
  bash -n "$script"
done

plutil -lint MacSweep/Info.plist Distribution/ExportOptions/DeveloperIDExportOptions.plist
git diff --check
bash scripts/test-scan-performance.sh
./scripts/build.sh

xcodebuild \
  -project MacSweep.xcodeproj \
  -scheme MacSweep \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath "${DERIVED_DATA_PATH:-$ROOT_DIR/build/DerivedData}" \
  -clonedSourcePackagesDirPath "${PACKAGE_PATH:-$ROOT_DIR/build/SourcePackages}" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  analyze
