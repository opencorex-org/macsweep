# Changelog

All notable changes to **MacSweep** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- Storage Analyzer interactive tree component (`v0.2.0`)
- Large File Finder threshold scanning (`v0.2.0`)
- Duplicate File Detection engine (`v0.3.0`)
- Application Uninstaller leftover finder (`v0.4.0`)

---

## [0.1.0-beta] - 2026-08-24

### Added
- Initial OpenCorex project structure and Xcode workspace layout.
- Decoupled `Scanner`, `Cleaner`, and `Safety` engine architecture.
- Core safety rules database (`ProtectedPaths.swift`) enforcing zero system file deletion.
- Native macOS `FileManager.trashItem` implementation.
- Developer cache scanners for Xcode DerivedData, Gradle, Node/npm, Homebrew, and Docker.
- Unified SwiftUI `DashboardView`, `SmartScanView`, and `SettingsView`.
- Build, test, notarization, and DMG packaging automation scripts (`scripts/`).
- GitHub Actions CI/CD workflows (`ci.yml`, `test.yml`, `release.yml`).
- Comprehensive technical documentation (`docs/architecture.md`, `docs/permissions.md`, `docs/development.md`, `docs/releases.md`, `docs/privacy.md`).
