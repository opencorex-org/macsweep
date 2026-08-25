#!/usr/bin/env bash
set -euo pipefail

echo "Executing release pipeline..."
./scripts/build.sh
./scripts/test.sh
./scripts/archive.sh
./scripts/create-dmg.sh
echo "Release pipeline completed!"
