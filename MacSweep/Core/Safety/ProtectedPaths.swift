import Foundation

/// Immutable database of protected macOS system paths that must never be modified or deleted.
/// This is the foundation of MacSweep's safety architecture.
public struct ProtectedPaths: Sendable {
    /// Absolute paths that are always protected. Any candidate within these directories is rejected.
    public static let systemRoots: Set<String> = [
        "/System",
        "/usr",
        "/bin",
        "/sbin",
        "/var/db",
        "/private/var/db",
        "/Library/Apple",
        "/Library/CoreServices",
        "/Library/Extensions",
        "/Library/Filesystems",
        "/Library/Frameworks",
        "/private/var/protected"
    ]

    /// User-domain paths that must be protected from deletion.
    public static let userProtected: [String] = [
        "Library/Keychains",
        "Library/Application Support/com.apple.TCC",
        "Library/Application Support/com.apple.sharedfilelist",
        "Library/Preferences/com.apple.loginwindow.plist",
        "Library/Preferences/com.apple.dock.plist",
        "Library/Preferences/com.apple.finder.plist",
        "Library/Preferences/com.apple.systempreferences.plist",
        ".ssh",
        ".gnupg",
        ".CFUserTextEncoding"
    ]

    /// File extensions that should never be cleaned without explicit high-risk confirmation.
    public static let sensitiveExtensions: Set<String> = [
        "keychain",
        "keychain-db",
        "pem",
        "p12",
        "cer",
        "key",
        "ppk"
    ]

    /// Returns true if the given absolute path falls within a protected system root.
    public static func isSystemProtected(_ path: String) -> Bool {
        for root in systemRoots {
            if path == root || path.hasPrefix(root + "/") {
                return true
            }
        }
        return false
    }

    /// Returns true if the given path is a protected user-domain path.
    public static func isUserProtected(_ path: String, homeDirectory: URL) -> Bool {
        let homePath = homeDirectory.path
        for protectedRelative in userProtected {
            let fullProtected = (homePath as NSString).appendingPathComponent(protectedRelative)
            if path == fullProtected || path.hasPrefix(fullProtected + "/") {
                return true
            }
        }
        return false
    }

    /// Returns true if the file extension indicates a sensitive credential file.
    public static func hasSensitiveExtension(_ url: URL) -> Bool {
        return sensitiveExtensions.contains(url.pathExtension.lowercased())
    }
}
