import Foundation
import OSLog

/// Manages security-scoped bookmark persistence for user-selected directories.
/// Reserved for future use if App Store distribution is pursued.
public final class SecurityScopedBookmarkManager {
    private let storageKey = "MacSweep_SecurityScopedBookmarks"

    public init() {}

    /// Saves a security-scoped bookmark for a user-selected URL.
    public func saveBookmark(for url: URL) throws {
        let bookmarkData = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        var bookmarks = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: Data] ?? [:]
        bookmarks[url.path] = bookmarkData
        UserDefaults.standard.set(bookmarks, forKey: storageKey)
        Logger.permissions.info("Saved bookmark for: \(url.path, privacy: .private)")
    }

    /// Resolves a previously saved bookmark and provides scoped access.
    public func resolveBookmark(for path: String) throws -> URL {
        guard let bookmarks = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: Data],
              let data = bookmarks[path] else {
            throw MacSweepError.permissionDenied(path: path)
        }

        var isStale = false
        let url = try URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        if isStale {
            try saveBookmark(for: url)
        }

        return url
    }
}
