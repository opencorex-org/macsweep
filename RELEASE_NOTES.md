# MacSweep 1.1.1

MacSweep 1.1.1 improves responsiveness during Full Scan, Smart Scan, and Developer Cleaner operations.

## Highlights

- **Responsive scans and cleanup**: Filesystem operations explicitly run away from the UI thread.
- **Lower progress overhead**: Rate-limited updates and demand-driven file enumeration reduce UI load and memory buffering.
- **Reliable cancellation**: Paused scans stop when cancelled, and unprocessed cleanup items remain available for retry.
- **Faster completion**: Removed artificial scan and cleanup delays.

> MacSweep is an open-source, ad-hoc-signed build and is not Apple-notarized. On first launch, Control-click MacSweep, choose **Open**, then confirm **Open**.

## Requirements

- macOS 14 Sonoma or later.
- Full Disk Access is recommended for complete scan results.
