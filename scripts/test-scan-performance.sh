#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/macsweep-scan-tests.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT
xcrun swiftc -parse-as-library -swift-version 5 \
  -default-isolation MainActor \
  -enable-upcoming-feature NonisolatedNonsendingByDefault \
  -module-cache-path "$TEST_DIR/ModuleCache" \
  MacSweep/Core/FileSystem/{FileEnumerator,FileMetadata}.swift \
  MacSweep/Core/Scanner/ScanControl.swift \
  MacSweep/Core/Cleaner/{CleanEngine,CleanResult,CleanProgress,DeletionService}.swift \
  MacSweep/App/MacSweepError.swift \
  MacSweep/Core/Safety/*.swift \
  MacSweep/Core/Utilities/{Logger,ByteFormatter,DateFormatter}.swift \
  MacSweep/Models/{CleanupItem,CleanupCategory,CleanupRisk}.swift \
  MacSweepTests/Core/Scanner/ScanResponsivenessTests.swift \
  -o "$TEST_DIR/scan-tests"
"$TEST_DIR/scan-tests"
