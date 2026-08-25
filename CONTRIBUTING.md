# Contributing to MacSweep

Thank you for your interest in contributing to **MacSweep** under the **OpenCorex** organization! We welcome pull requests, bug reports, feature requests, and security improvements from developers of all experience levels.

---

## 1. Code of Conduct

All contributors are expected to adhere to our [Code of Conduct](CODE_OF_CONDUCT.md). Please read it before participating in discussions or submitting pull requests.

---

## 2. How to Contribute

### 2.1 Reporting Bugs
* Search existing [GitHub Issues](https://github.com/opencorex-org/macsweep/issues) to verify the bug hasn't been reported.
* Open a new bug report using our `.github/ISSUE_TEMPLATE/bug_report.yml` template.
* Include detailed steps to reproduce, macOS version, and relevant `OSLog` diagnostics (never post personal file paths).

### 2.2 Suggesting Features
* Open a new feature request using `.github/ISSUE_TEMPLATE/feature_request.yml`.
* Describe the feature, why it is useful, and how it aligns with MacSweep's core goals of safety and transparency.

### 2.3 Submitting Pull Requests
1. Fork the repository and create a feature branch (`git checkout -b feature/amazing-scanner`).
2. Follow our [Developer Guide](docs/development.md) for setting up Xcode and dependencies.
3. Ensure all code passes **SwiftLint**: `swiftlint lint`.
4. Ensure all unit and integration tests pass: `./scripts/test.sh`.
5. Write unit tests covering any new scanner logic or safety rules.
6. Submit a clean Pull Request targeting the `develop` branch with a clear summary of changes.

---

## 3. Core Development Principles

* **Safety Above All:** Never bypass path safety checks or attempt silent deletions.
* **No Telemetry:** Never introduce tracking SDKs, analytics pings, or network calls for file metadata.
* **Native Swift & SwiftUI:** Use standard Apple frameworks (Swift Concurrency, Foundation, SwiftUI, OSLog).
* **Test Coverage:** All new features must include unit tests.

---

## 4. Community & Support

Join the conversation on [GitHub Discussions](https://github.com/opencorex-org/macsweep/discussions) or contact the maintainers at **dev@opencorex.org**.
