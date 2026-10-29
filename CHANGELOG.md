# Changelog

All notable changes to MacSweep are documented here.

## [1.1.1] - 2026-10-30

### Fixed

- Keep Full Scan, Smart Scan, and Developer Cleaner filesystem work off the UI thread.
- Limit progress updates and enumerate files on demand to reduce UI load and memory buffering.
- Release paused scans on cancellation and retain unprocessed cleanup items for retry.

### Changed

- Remove artificial scan and cleanup delays.
- Add regression checks for enumeration, cancellation, and background cleanup execution.

## [1.1.0] - 2026-09-27

### Added

- App Mover: Relocate applications and associated data to external drives with symlink management.
- Storage Manager: View and manage storage across internal and connected external volumes.
- Real-time cleaning progress overlay with item paths, count, and reclaimed bytes indicator.
- Helper install script (`scripts/install.sh`) to easily copy MacSweep to `/Applications` and strip quarantine flags.

### Changed

- Updated About screen to display the application version cleanly without the build count.
- Release and archive scripts automatically clear quarantine attributes from packaged artifacts.

## [1.0.0] - 2026-09-06

### Added

- Smart Scan, Full Scan, and Developer Cleaner workflows.
- Pause, Resume, and Stop controls for active scans.
- Secure Sparkle-based automatic update support.
- Ad-hoc application signing, DMG packaging, checksums, and GitHub Release automation without a paid Apple account.

### Changed

- Cleanup permanently removes safety-approved items after explicit confirmation.
- Large File cleanup and App Uninstaller continue to use the macOS Trash for recoverability.

### Security

- Update archives require a valid Sparkle EdDSA signature.
- Release publication fails if update signing, application verification, or packaging fails.
