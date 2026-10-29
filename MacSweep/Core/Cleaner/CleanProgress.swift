import Foundation

/// Live progress update emitted during a cleanup operation.
public nonisolated struct CleanProgress: Sendable {
    public let currentItemName: String
    public let currentItemPath: String
    public let currentCategory: CleanupCategory?
    public let completedItemsCount: Int
    public let totalItemsCount: Int
    public let bytesReclaimed: Int64
    public let totalBytes: Int64

    public var fractionCompleted: Double {
        if totalBytes > 0 {
            return min(Double(bytesReclaimed) / Double(totalBytes), 1)
        }
        guard totalItemsCount > 0 else { return 0 }
        return min(Double(completedItemsCount) / Double(totalItemsCount), 1)
    }

    public var formattedBytesReclaimed: String {
        ByteFormatter.format(bytesReclaimed)
    }

    public var formattedTotalBytes: String {
        ByteFormatter.format(totalBytes)
    }

    public var percentageInt: Int {
        Int(fractionCompleted * 100)
    }

    public init(
        currentItemName: String,
        currentItemPath: String,
        currentCategory: CleanupCategory? = nil,
        completedItemsCount: Int,
        totalItemsCount: Int,
        bytesReclaimed: Int64,
        totalBytes: Int64
    ) {
        self.currentItemName = currentItemName
        self.currentItemPath = currentItemPath
        self.currentCategory = currentCategory
        self.completedItemsCount = completedItemsCount
        self.totalItemsCount = totalItemsCount
        self.bytesReclaimed = bytesReclaimed
        self.totalBytes = totalBytes
    }
}
