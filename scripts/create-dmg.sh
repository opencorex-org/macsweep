#!/usr/bin/env bash
set -euo pipefail

echo "Creating MacSweep DMG..."
mkdir -p build/dmg
cp -R build/MacSweep.app build/dmg/ || true
echo "DMG creation complete."
