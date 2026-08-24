import Foundation

/// Extracts and holds metadata for a single file or directory from the file system.
public struct FileMetadata: Sendable {
    public let url: URL
    public let size: Int64
    public let isDirectory: Bool
    public let isSymbolicLink: Bool
    public let modificationDate: Date
    public let isHidden: Bool

    /// Creates metadata by reading resource values from the file system.
    /// - Parameter url: The file URL to inspect.
    /// - Returns: A populated `FileMetadata`, or nil if the file is unreadable.
    public static func from(_ url: URL) -> FileMetadata? {
        let keys: Set<URLResourceKey> = [
            .fileSizeKey,
            .totalFileAllocatedSizeKey,
            .isDirectoryKey,
            .isSymbolicLinkKey,
            .contentModificationDateKey,
            .isHiddenKey
        ]

        guard let values = try? url.resourceValues(forKeys: keys) else {
            return nil
        }

        let size: Int64 = Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)

        return FileMetadata(
            url: url,
            size: size,
            isDirectory: values.isDirectory ?? false,
            isSymbolicLink: values.isSymbolicLink ?? false,
            modificationDate: values.contentModificationDate ?? Date.distantPast,
            isHidden: values.isHidden ?? false
        )
    }
}
