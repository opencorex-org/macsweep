# MacSweep Privacy Architecture & Policy

**Organization:** OpenCorex  
**Project:** MacSweep (`OpenCorex/macsweep`)  

---

## 1. Core Privacy Commitments

MacSweep is engineered under a **Strict Zero-Knowledge, Privacy-First Architecture**. We believe system maintenance utilities should respect user privacy and never monitor, track, or collect personal files.

### The 5 Privacy Pillars of MacSweep
1. **100% Local Scanning:** All disk discovery, file size calculations, hash checks, and cache cleanup operations execute exclusively on your local Apple Silicon or Intel Mac CPU.
2. **Zero Network Telemetry:** MacSweep contains **no analytics frameworks**, tracking SDKs, or background pinging services.
3. **No File Transmission:** Your file names, folder structures, file contents, file hashes, and disk metrics **never** leave your machine.
4. **No Cloud Dependencies:** MacSweep does not require an account, registration, login, or cloud connection to function.
5. **Transparent Open Source Code:** Every line of code is open source under the Apache 2.0 license, allowing independent security auditing.

---

## 2. Network Activity Disclosure

MacSweep performs network connections **only** in the following explicit scenarios:

* **Software Update Check (Direct Release Build Only):**
  - **Purpose:** Checks if a newer version of MacSweep is available on GitHub Releases.
  - **Destination:** `https://api.github.com/repos/OpenCorex/macsweep/releases/latest`
  - **Data Transmitted:** Standard HTTP User-Agent requesting JSON release metadata. Zero user identifier, hardware serial, or system information is sent.
  - **User Control:** Updates can be checked manually or toggled off in **Settings > General**.

---

## 3. Apple Privacy Manifest Compliance (`PrivacyInfo.xcprivacy`)

MacSweep ships with a fully declared Apple Privacy Manifest (`PrivacyInfo.xcprivacy`):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>C617.1</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryDiskSpace</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>85F4.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

### Explanations of Accessed APIs
* **File Timestamps (`C617.1`):** Required to display file last-modified dates to the user in Large Files and Duplicates finder workflows.
* **Disk Space (`85F4.1`):** Required to calculate total, used, and available disk capacity displayed on the Dashboard.

---

## 4. Contact & Security Audits

If you have questions regarding MacSweep's privacy architecture or wish to conduct an independent security review, please contact **privacy@opencorex.org**.
