# MacSweep

<p align="center">
  <img src="MacSweep/Assets.xcassets/AppIcon.appiconset/logo.png" width="128" height="128" alt="MacSweep Logo">
</p>

<p align="center">
  <b>An open-source, transparent, and privacy-first macOS system cleaner, storage analyzer, and developer-cache manager.</b>
</p>

<p align="center">
  <a href="https://github.com/opencorex-org/macsweep/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/opencorex-org/macsweep/ci.yml?branch=main&style=flat-square&label=CI" alt="CI Status"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache%202.0-blue.svg?style=flat-square" alt="License"></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.10%2B-orange.svg?style=flat-square" alt="Swift Version"></a>
  <a href="https://apple.com/macos"><img src="https://img.shields.io/badge/platform-macOS%2014.0%2B-lightgrey.svg?style=flat-square" alt="Platform"></a>
  <a href="https://github.com/opencorex-org/macsweep/releases"><img src="https://img.shields.io/badge/distribution-Direct%20Download-success.svg?style=flat-square" alt="Direct Download"></a>
</p>

---

## Key Features

* **Smart Scan:** Unified discovery of system caches, application logs, temporary files, and Trash items.
* **Developer Cache Cleaner:** Targeted cleaning of Xcode DerivedData, SPM caches, CocoaPods, Gradle, Android build caches, npm, pnpm, Yarn, Bun, Homebrew, and Docker artifacts.
* **Interactive Storage Analyzer:** Visual folder tree and disk usage breakdown.
* **Large File Finder:** Discover large files over configurable thresholds (500 MB to 10 GB+).
* **Safe Duplicate Detection:** Multi-stage content hash engine for discovering duplicate copies safely.
* **App Uninstaller:** Complete leftover file discovery for uninstalled applications.
* **Safety First:** Hardcoded system safeguards, symlink resolution, zero automated background deletions, and explicit Trash relocation.
* **Privacy First:** 100% local scanning, zero telemetry, zero analytics tracking, zero cloud server uploads.

---

## Installation & Distribution

MacSweep is distributed as a **Direct Download** package signed with Apple Developer ID certificates and notarized by Apple.

### Direct Download
Download the latest Developer ID signed and Apple-notarized `.dmg` installer from [GitHub Releases](https://github.com/opencorex-org/macsweep/releases).

1. Download `MacSweep.dmg`.
2. Open the DMG file and drag **MacSweep** into your `Applications` folder.
3. Launch MacSweep and grant Full Disk Access when prompted.

### Building From Source
```bash
git clone https://github.com/opencorex-org/macsweep.git
cd macsweep
open MacSweep.xcodeproj
```
Select the `MacSweep` scheme in Xcode and press `Cmd + R`.

---

## Architecture & Safety

MacSweep decouples file discovery from deletion:

```
[ Scanner Engine ] ──▶ [ Safety Validator ] ──▶ [ User Review ] ──▶ [ Trash Service ]
```

* **Scanner:** Read-only path enumerator. Cannot delete files.
* **Safety Validator:** Validates candidate paths against system boundaries (`/System`, `/usr`, `/Library/Keychains`) and verifies canonical symlinks.
* **Trash Service:** Moves approved files to the macOS Trash using native `FileManager` APIs.

For full technical documentation, see [`docs/architecture.md`](docs/architecture.md) and [`docs/permissions.md`](docs/permissions.md).

---

## Documentation

* [System Architecture Specification](docs/architecture.md)
* [Permissions & FDA Guide](docs/permissions.md)
* [Developer Setup & Contributing Guide](docs/development.md)
* [Direct Release & Code Signing Guide](docs/releases.md)
* [Privacy Policy Statement](docs/privacy.md)
* [Security & Vulnerability Disclosure](SECURITY.md)

---

## License

MacSweep is open-source software licensed under the **Apache License 2.0**. Developed under the **OpenCorex** organization.
