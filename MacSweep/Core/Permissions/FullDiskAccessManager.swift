import Foundation
import AppKit
import OSLog

/// Manages Full Disk Access detection and guides users through macOS System Settings.
public final class FullDiskAccessManager: Sendable {
    public static let shared = FullDiskAccessManager()

    /// TCC databases are present on standard macOS installations and are protected
    /// by Full Disk Access. Unlike optional preference files, opening one gives a
    /// reliable answer even when services such as Time Machine were never configured.
    private var protectedProbeURLs: [URL] {
        let userTCCDatabase = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/com.apple.TCC/TCC.db")
        let systemTCCDatabase = URL(
            fileURLWithPath: "/Library/Application Support/com.apple.TCC/TCC.db"
        )
        return [userTCCDatabase, systemTCCDatabase]
    }

    /// Returns `true` if Full Disk Access is currently granted.
    public var hasFullDiskAccess: Bool {
        let result = protectedProbeURLs.contains { url in
            guard let handle = try? FileHandle(forReadingFrom: url) else { return false }
            try? handle.close()
            return true
        }
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
