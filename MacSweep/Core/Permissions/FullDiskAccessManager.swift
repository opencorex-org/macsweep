import Foundation
import AppKit
import OSLog

/// Manages Full Disk Access detection and guides users through macOS System Settings.
public final class FullDiskAccessManager: Sendable {
    public static let shared = FullDiskAccessManager()

    /// System path used to test Full Disk Access grant.
    private let testPath = "/Library/Preferences/com.apple.TimeMachine.plist"

    /// Returns `true` if Full Disk Access is currently granted.
    public var hasFullDiskAccess: Bool {
        let result = FileManager.default.isReadableFile(atPath: testPath)
        Logger.permissions.debug("Full Disk Access check: \(result ? "granted" : "not granted")")
        return result
    }

    /// Opens macOS System Settings directly to Privacy & Security > Full Disk Access.
    @MainActor
    public func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
            Logger.permissions.info("Opened System Settings for Full Disk Access")
        }
    }
}
