# MacSweep Architecture & Technical Specification
**Organization:** OpenCorex  
**Project:** MacSweep (`OpenCorex/macsweep`)  
**Platform:** macOS 14.0+  
**Distribution Channel:** Direct Download Only (Developer ID Signed & Apple Notarized)  

---

## Distribution Model

MacSweep is distributed exclusively as a **Direct Download** application (via GitHub Releases and the OpenCorex project portal) packed in a Developer ID signed, Hardened Runtime enabled, and Apple-notarized `.dmg` installer.

```
┌────────────────────────────────────────────────────────────────────────┐
│                   Direct Download Distribution                         │
├────────────────────────────────────────────────────────────────────────┤
│ • Code Signing: Developer ID Application Certificate                   │
│ • Hardened Runtime: Enabled (`-options runtime`)                       │
│ • Gatekeeper Compliance: Apple Notarized & Stapled                     │
│ • Disk Access Scope: Full Disk Access (FDA) Supported                  │
└────────────────────────────────────────────────────────────────────────┘
```

## System Architecture Summary

MacSweep uses a layered data-flow architecture:

```
┌────────────────────────────────────────────────────────────────────────┐
│                          SwiftUI View Layer                            │
│    (DashboardView, SmartScanView, StorageAnalyzerView, SettingsView)   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Binds to State & Triggers Actions
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        Feature ViewModels                              │
│   (@Observable / @StateObject ViewModels handling UI state & flow)     │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Invokes Domain Operations
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                          Service Layer                                 │
│ (ApplicationService, DuplicateDetectionService, LargeFileService)      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Calls Core Engines & Validators
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                         Core Subsystems                                │
│   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌───────────┐  │
│   │   Scanner   │──▶│   Safety    │──▶│   Cleaner   │   │  Storage  │  │
│   └─────────────┘   └─────────────┘   └─────────────┘   └───────────┘  │
│   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐                  │
│   │ FileSystem  │   │ Permissions │   │  Utilities  │                  │
│   └─────────────┘   └─────────────┘   └─────────────┘                  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Low-level system I/O
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                          macOS Native APIs                             │
│   (FileManager, URLResourceValues, OSLog, Security Scopes, SMAppService)│
└────────────────────────────────────────────────────────────────────────┘
```

### Core Separation Principle
1. **Scanner Subsystem:** Read-only path discovery and calculation. Has zero mutation/deletion capabilities.
2. **Safety Subsystem:** Validates target paths against system bounds, protected paths, and symlink escape checks.
3. **Cleaner Subsystem:** Receives user-confirmed, safety-checked items and performs safe Trash relocation or deletion.

### Core Modules Breakdown
- **`App`**: SwiftUI entrypoint, `AppDelegate`, DI container (`AppEnvironment`), global constants.
- **`Core/Scanner`**: Asynchronous file system enumerators & cache scanners (`CacheScanner`, `XcodeScanner`, `GradleScanner`, `NodeScanner`, `DockerScanner`, etc.).
- **`Core/Cleaner`**: Operational execution engine & Trash services (`CleanEngine`, `DeletionService`, `TrashService`).
- **`Core/Safety`**: Rules database & path traversal validation (`SafetyValidator`, `ProtectedPaths`, `SafetyPolicy`).
- **`Core/Storage`**: System disk statistics & tree folder size calculators (`DiskSpaceService`, `DirectorySizeCalculator`).
- **`Core/FileSystem`**: Low-level `FileManager` wrappers, metadata extraction, security-scoped bookmark handles.
- **`Core/Permissions`**: Full Disk Access validators (`PermissionManager`, `FullDiskAccessManager`).
- **`Core/Utilities`**: Formatting, logging (`OSLog`), process execution helpers (`Logger`, `ByteFormatter`).
