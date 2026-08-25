# MacSweep Direct Release & Code Signing Specification

**Organization:** OpenCorex  
**Project:** MacSweep (`opencorex-org/macsweep`)  
**Distribution Channel:** Direct Download Only (Developer ID Signed & Apple Notarized)  
**Target Platform:** macOS 14.0+  

---

## 1. Distribution Architecture

MacSweep is distributed exclusively as a **Direct Download** package via OpenCorex GitHub Releases.

```
┌────────────────────────────────────────────────────────────────────────┐
│                   Direct Release Security Standards                    │
├────────────────────────────────────────────────────────────────────────┤
│ • Code Signing: Developer ID Application Certificate                   │
│ • Runtime Security: Hardened Runtime Enabled (`-options runtime`)       │
│ • Packaging: Branded `.dmg` installer with drag-to-Applications layout │
│ • Apple Notarization: Verified via `xcrun notarytool`                  │
│ • Stapling: Embedded ticket via `xcrun stapler staple` for Gatekeeper  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Release Automation Pipeline

```
[ Published Git Tag (v*) ]
            │
            ▼
[ GitHub Actions Triggered: .github/workflows/release.yml ]
            │
            ▼
┌─────────────────────────────────────────┐
│ Step 1: Compile & Xcode Release Archive │
│ xcodebuild archive -scheme MacSweep     │
└────────────────────┬────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────┐
│ Step 2: Export Developer ID Signed Build│
│ xcodebuild -exportArchive               │
└────────────────────┬────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────┐
│ Step 3: Package Custom Disk Image (.dmg)│
│ ./scripts/create-dmg.sh                 │
└────────────────────┬────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────┐
│ Step 4: Submit to Apple Notary Service  │
│ ./scripts/notarize.sh submit            │
└────────────────────┬────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────┐
│ Step 5: Staple Ticket & Verify DMG      │
│ xcrun stapler staple MacSweep.dmg       │
└────────────────────┬────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────┐
│ Step 6: Publish GitHub Release          │
│ Upload MacSweep.dmg & SHA256 Checksums  │
└─────────────────────────────────────────┘
```

---

## 3. Automation Scripts

### 3.1 DMG Packaging (`scripts/create-dmg.sh`)
```bash
#!/usr/bin/env bash
set -euo pipefail

APP_PATH="build/Export/Direct/MacSweep.app"
DMG_PATH="build/Release/MacSweep.dmg"

mkdir -p build/Release

create-dmg \
  --volname "MacSweep Installer" \
  --background "Distribution/DMG/background.png" \
  --window-pos 200 120 \
  --window-size 660 400 \
  --icon-size 100 \
  --icon "MacSweep.app" 180 170 \
  --hide-extension "MacSweep.app" \
  --app-drop-link 480 170 \
  "$DMG_PATH" \
  "$APP_PATH"
```

### 3.2 Apple Notarization (`scripts/notarize.sh`)
```bash
#!/usr/bin/env bash
set -euo pipefail

DMG_PATH="build/Release/MacSweep.dmg"

echo "Submitting $DMG_PATH to Apple Notary Service..."

xcrun notarytool submit "$DMG_PATH" \
  --key-id "$NOTARIZATION_KEY_ID" \
  --issuer "$NOTARIZATION_ISSUER_ID" \
  --key "$NOTARIZATION_KEY_PATH" \
  --wait

echo "Stapling notarization ticket..."
xcrun stapler staple "$DMG_PATH"

echo "Verifying Gatekeeper compliance..."
spctl --assess --type open --context id=gkb-strict "$DMG_PATH"
```

---

## 4. Release Checklist

1. [ ] Update version number in `MacSweep.xcodeproj` (`MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`).
2. [ ] Update `CHANGELOG.md` with release notes and feature highlights.
3. [ ] Run full local unit test suite: `./scripts/test.sh`.
4. [ ] Verify SwiftLint compliance: `swiftlint lint`.
5. [ ] Create signed git tag: `git tag -a v1.0.0 -m "Release v1.0.0"`.
6. [ ] Push git tag to GitHub: `git push origin v1.0.0`.
7. [ ] Verify downloaded `.dmg` mounts properly and passes Gatekeeper (`spctl --assess`).
