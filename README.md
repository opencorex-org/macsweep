<p align="center">
  <img src="Documentation/logo.png" width="128" height="128" alt="MacSweep Logo">
</p>

<h1 align="center">MacSweep</h1>
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
* **Automation & Profiles:** Daily or weekly Quick, Balanced, Developer, Privacy, and Custom maintenance profiles.
* **Cleanup History & Exclusions:** Persistent cleanup records, global folder exclusions, and user-defined age/extension rules.
* **Menu Bar & Notifications:** Quick maintenance, free-space status, external-drive analysis, and native completion notifications.
* **Storage Trends & Health:** Daily free-space history plus live disk and startup-load health indicators.
* **Safety First:** Hardcoded system safeguards, symlink resolution, explicit review, and confirmation before cleanup.
* **Secure Updates:** Automatic updates signed with a dedicated Sparkle EdDSA key.
* **Privacy First:** 100% local scanning, zero telemetry, zero analytics tracking, zero cloud server uploads.

---

## Installation & Distribution

MacSweep is distributed as an open-source **Direct Download** package through GitHub Releases. Current packages use an ad-hoc signature and are not Apple-notarized.

### Direct Download
Download the latest `.dmg` installer from [GitHub Releases](https://github.com/opencorex-org/macsweep/releases).

1. Download `MacSweep.dmg`.
2. Open the DMG file and drag **MacSweep** into your `Applications` folder.
3. The first time you launch it, Control-click MacSweep, choose **Open**, then confirm **Open**.
4. Grant Full Disk Access when prompted.

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
[ Scanner Engine ] ──▶ [ Safety Validator ] ──▶ [ User Review ] ──▶ [ Confirmed Cleanup ]
```

* **Scanner:** Read-only path enumerator. Cannot delete files.
* **Safety Validator:** Validates candidate paths against system boundaries (`/System`, `/usr`, `/Library/Keychains`) and verifies canonical symlinks.
* **Cleanup Engine:** Permanently removes approved cleaner items. Large Files and App Uninstaller remain recoverable through the macOS Trash.

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
