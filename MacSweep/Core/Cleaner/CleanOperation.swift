import Foundation

/// Represents a queued cleanup operation for a single item.
public struct CleanOperation: Identifiable, Sendable {
    public let id: UUID
    public let item: CleanupItem
    public let method: CleanMethod

    public init(id: UUID = UUID(), item: CleanupItem, method: CleanMethod = .moveToTrash) {
        self.id = id
        self.item = item
        self.method = method
    }
}

/// Method of file removal.
public enum CleanMethod: String, Sendable {
    case moveToTrash
    case permanentDelete
}
