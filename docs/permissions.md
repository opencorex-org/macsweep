# macOS Permissions Technical Specification

**Project:** MacSweep (`OpenCorex/macsweep`)  
**Organization:** OpenCorex  
**Distribution Channel:** Direct Download Only (Developer ID Signed & Apple Notarized)  
**Target Platform:** macOS 14.0 (Sonoma) and later  
**Document Status:** Production Reference  

---

## 1. Overview

MacSweep is distributed exclusively as a **Direct Download** application (via GitHub Releases and the OpenCorex project portal). It is signed with an Apple **Developer ID Application** certificate, compiled with **Hardened Runtime** enabled, and notarized by Apple's Notary Service.

Because MacSweep performs system cleaning, developer-cache management, storage analysis, and log cleanup across user domain and system-adjacent directories, it relies on **Full Disk Access (FDA)** and explicit user-granted permissions.

MacSweep **never** attempts to bypass macOS security controls, disable System Integrity Protection (SIP), or elevate privileges silently.

---

## 2. Permission Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      MacSweep Direct Download Model                     │
├─────────────────────────────────────────────────────────────────────────┤
│ • Distribution: GitHub Releases / OpenCorex Portal (.dmg installer)     │
│ • Code Signing: Developer ID Application Certificate                    │
│ • Security Enforcement: Hardened Runtime Enabled                        │
│ • Gatekeeper Compliance: Apple Notarized & Stapled                      │
│ • Disk Access Scope: Full Disk Access (FDA) & User Permission Prompts   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Full Disk Access (FDA)

### 3.1 Why Full Disk Access is Required
To scan and clean protected location categories—such as Xcode DerivedData (`~/Library/Developer/Xcode`), system logs (`/private/var/log`), containerized application caches (`~/Library/Containers`), and third-party developer tool stores—macOS requires the user to grant Full Disk Access to MacSweep.

### 3.2 Programmatic FDA Detection
MacSweep detects Full Disk Access status by attempting to inspect a known system-protected path:

```swift
import Foundation
import AppKit

public final class FullDiskAccessManager: Sendable {
    public static let shared = FullDiskAccessManager()

    /// System path used to test Full Disk Access grant
    private let testPath = "/Library/Preferences/com.apple.TimeMachine.plist"

    /// Returns `true` if Full Disk Access is granted by the user
    public var hasFullDiskAccess: Bool {
        return FileManager.default.isReadableFile(atPath: testPath)
    }

    /// Opens macOS System Settings directly to Privacy & Security > Full Disk Access
    public func openSystemSettingsFDA() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
}
```

### 3.3 User Guidance & Onboarding Workflow
1. Upon initial launch, MacSweep checks `FullDiskAccessManager.shared.hasFullDiskAccess`.
2. If FDA is missing, MacSweep displays an intuitive permissions banner explaining why access is necessary.
3. Clicking **Grant Full Disk Access** launches **System Settings > Privacy & Security > Full Disk Access**.
4. MacSweep listens for app focus changes (`NSApplication.didBecomeActiveNotification`) to update permission state dynamically without requiring app restart.

---

## 4. Permission Failure & Graceful Fallback

If Full Disk Access is not granted or a specific path returns permission denied:
* MacSweep **never crashes** or displays uncaught runtime exceptions.
* Diagnostics are logged via `OSLog` (`Logger.permissions`).
* Inaccessible folders are marked with a `Permission Needed` badge and an in-line resolution button.
* Scans proceed safely across all accessible paths while skipping restricted paths cleanly.
