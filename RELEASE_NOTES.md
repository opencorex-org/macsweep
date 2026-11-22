# MacSweep 1.3.1

MacSweep 1.3.1 improves installation guidance, permission detection, and responsive behavior throughout the application.

## Highlights

- **Customized installation experience**: The DMG now presents a branded drag-to-Applications window with first-launch and macOS security guidance.
- **Reliable permission detection**: Full Disk Access checks now use protected macOS TCC databases instead of an optional preference file.
- **Improved App Uninstaller access flow**: Permission state refreshes when the screen opens, when access is checked again, and immediately before removal.
- **Responsive Storage Insights**: The header, summary metrics, category control, and main navigation sidebar adapt cleanly to available space.
- **Reliable cleanup completion screens**: Progress and result views remain centered at normal sizes and become scrollable when space is constrained.
- **Privacy-first onboarding**: Users can clearly choose limited access or optionally grant Full Disk Access for more complete scans.

> MacSweep is an open-source, ad-hoc-signed build and is not Apple-notarized. On first launch, try to open MacSweep once, then use **System Settings → Privacy & Security → Open Anyway**. Inside onboarding, you can continue with limited access or optionally grant Full Disk Access for more complete scans.

## Requirements

- macOS 14 Sonoma or later.
- Full Disk Access is recommended for complete scan results.
