import Foundation

/// Configuration for a scannable category defining target paths and matching rules.
public struct ScanCategoryConfig: Sendable {
    public let category: CleanupCategory
    public let targetPaths: [URL]
    public let recursive: Bool

    public init(category: CleanupCategory, targetPaths: [URL], recursive: Bool = true) {
        self.category = category
        self.targetPaths = targetPaths
        self.recursive = recursive
    }
}
