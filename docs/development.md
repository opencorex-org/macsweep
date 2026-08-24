# MacSweep Development & Setup Guide

**Organization:** OpenCorex  
**Project:** MacSweep (`OpenCorex/macsweep`)  
**Target Platform:** macOS 14.0+  

---

## 1. Prerequisites & Environment Setup

To build, run, and contribute to MacSweep, ensure your development environment satisfies the following prerequisites:

* **Hardware:** Apple Silicon (M1/M2/M3/M4) or Intel Mac running macOS 14.0 (Sonoma) or later.
* **Xcode:** Xcode 15.4 or Xcode 16.0+ installed from the Mac App Store or Apple Developer Portal.
* **Command Line Tools:** Xcode Command Line Tools installed via `xcode-select --install`.
* **Swift Toolchain:** Swift 5.10+ included with Xcode.
* **Linting:** SwiftLint installed via Homebrew (`brew install swiftlint`).
* **Packaging (Optional):** `create-dmg` tool installed via Homebrew (`brew install create-dmg`) for testing local DMG generation.

---

## 2. Cloning & Workspace Structure

Clone the repository directly from GitHub:

```bash
git clone https://github.com/OpenCorex/macsweep.git
cd macsweep
```

### Directory Anatomy
```
macsweep/
├── MacSweep.xcodeproj          # Primary Xcode Workspace Project
├── MacSweep/                   # Application Source Code
│   ├── App/                    # Entrypoint & Environment
│   ├── Core/                   # Scanner, Cleaner, Safety, Storage Logic
│   ├── Models/                 # Swift Value Types & Data Transfer Objects
│   ├── Services/               # Domain Business Logic Services
│   ├── Features/               # SwiftUI Feature Views & ViewModels
│   ├── UI/                     # Design System & Theme Components
│   └── Resources/              # Assets & Strings
├── MacSweepTests/              # Unit & Integration Test Suites
├── MacSweepUITests/            # UI Automation Test Suites
├── scripts/                    # Build, Test, Notarization & Release Automation
└── docs/                       # Project Technical Specifications
```

---

## 3. Building & Running Locally

### 3.1 Using Xcode IDE
1. Open `MacSweep.xcodeproj` in Xcode:
   ```bash
   open MacSweep.xcodeproj
   ```
2. Select the **MacSweep** target and scheme.
3. Select **My Mac** as the run destination.
4. Press `Cmd + R` to compile and launch MacSweep.

### 3.2 Using Command Line Automation
You can build the project from the command line using the provided build scripts:

```bash
# Make build script executable
chmod +x scripts/build.sh

# Run compilation script
./scripts/build.sh
```

Alternatively, invoke `xcodebuild` directly:

```bash
xcodebuild -project MacSweep.xcodeproj \
           -scheme MacSweep \
           -configuration Debug \
           -destination 'platform=macOS' \
           build
```

---

## 4. Running Tests

### 4.1 Running Unit & Integration Tests
Execute all test suites from Xcode using `Cmd + U`, or run the automated test script:

```bash
chmod +x scripts/test.sh
./scripts/test.sh
```

Command line execution via `xcodebuild`:

```bash
xcodebuild test \
           -project MacSweep.xcodeproj \
           -scheme MacSweep \
           -destination 'platform=macOS' \
           -enableCodeCoverage YES
```

---

## 5. Code Style & Linting

MacSweep enforces strict Swift styling rules using **SwiftLint**.

* To view lint errors in Xcode, build the project (SwiftLint automatically runs via a build phase script).
* To run linting manually from the terminal:
  ```bash
  swiftlint lint
  ```
* To automatically fix auto-correctable formatting rules:
  ```bash
  swiftlint --fix
  ```

---

## 6. Architecture & Coding Conventions

### Concurrency Rules
* Always use **Swift Concurrency** (`async/await`, `AsyncSequence`, `Actor`, `TaskGroup`) rather than legacy `DispatchQueue` callbacks.
* Mark ViewModels and UI state bindings with `@MainActor`.
* Keep background scanning engines on non-blocking actors (`actor ScanEngine`).

### Safety Policy
* **Never** call shell executables (`rm -rf`) via `Process`.
* Always validate paths through `SafetyValidator.shared.validate(url:)` before initiating deletions.
* Ensure all user deletions route through `FileManager.default.trashItem(at:resultingItemURL:)`.

---

## 7. Troubleshooting

| Issue | Cause | Solution |
| :--- | :--- | :--- |
| **Permission Denied in Tests** | Test suite scanning protected user paths | Ensure tests use `FileManager.default.temporaryDirectory` mock fixtures. |
| **SwiftLint Command Not Found** | SwiftLint is not installed in `/opt/homebrew/bin` | Run `brew install swiftlint`. |
| **Signing Error on Local Build** | Missing Developer ID signing identity | Set Xcode **Signing & Capabilities > Team** to **None (Sign to Run Locally)** for local testing. |
