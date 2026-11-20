# Changelog

All notable changes to MacSweep are documented here.

## [1.3.0] - 2026-11-20

### Added

- A Recommendations workspace that presents only safety-approved cleanup opportunities from a comprehensive scan.
- Activity history and storage insights for reviewing scans, cleanups, reclaimed space, and system health.
- Live application localization with an in-app language selector.
- GitHub Sponsors and upstream repository shortcuts in the application UI.

### Changed

- Redesigned Settings with consistently aligned controls, compact menus, and clearer scanning, notification, and maintenance options.
- Privacy-first onboarding now explains local processing and offers limited access before the optional Full Disk Access flow.
- Full Scan now distinguishes recommended items from findings that require review and includes sandboxed application logs.
- Dashboard, uninstaller, privacy, and cleanup workflows provide clearer status, safety, and verification details.
- Storage monitoring and sidebar capacity indicators update as cleanup activity occurs.

### Fixed

- Deduplicate overlapping cache and developer scan results before cleanup.
- Improve safe cache discovery, scan cancellation, and filesystem validation.

## [1.2.0] - 2026-11-01

### Added

- Scheduled and on-demand maintenance profiles, including customizable scan sources and safe auto-cleaning.
- Cleanup history, global scan exclusions, custom cleanup rules, diagnostic report export, and storage trend tracking.
- Menu-bar controls, native notifications, real Launch at Login integration, and automatic external-drive analysis.
- Browser privacy coverage for Edge, Brave, Opera, and Vivaldi with active-browser protection.
- Startup-item publisher, signature, and impact details plus live dashboard health indicators.

### Changed

- Duplicate cleanup now uses the macOS Trash and provides file preview/open actions.
- Large-file, duplicate, uninstall, privacy, Smart Scan, Full Scan, and developer cleanups now record history and notify on completion.

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
