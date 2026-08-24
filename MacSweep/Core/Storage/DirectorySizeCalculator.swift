import Foundation
import OSLog

/// Calculates directory sizes efficiently for the Storage Analyzer.
public actor DirectorySizeCalculator {
    /// Calculates the size of a directory, yielding child node sizes.
    /// - Parameter url: The root directory URL.
    /// - Returns: A `StorageNode` tree with calculated sizes.
    public func calculateTree(at url: URL, maxDepth: Int = 3) async -> StorageNode {
        let size = await calculateDirectorySize(url)
        var children: [StorageNode] = []

        if maxDepth > 0 {
            let fileManager = FileManager.default
            if let contents = try? fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .totalFileAllocatedSizeKey],
                options: [.skipsHiddenFiles]
            ) {
                for childURL in contents {
                    if Task.isCancelled { break }

                    let values = try? childURL.resourceValues(forKeys: [.isDirectoryKey])
                    let isDir = values?.isDirectory ?? false

                    if isDir {
                        let childNode = await calculateTree(at: childURL, maxDepth: maxDepth - 1)
                        children.append(childNode)
                    } else {
                        let fileSize = Self.fileSize(at: childURL)
                        let node = StorageNode(
                            url: childURL,
                            isDirectory: false,
                            size: fileSize
                        )
                        children.append(node)
                    }
                }
            }
        }

        // Sort children by size descending
        children.sort { $0.size > $1.size }

        // Calculate percentage of parent
        if size > 0 {
            children = children.map { child in
                var mutableChild = child
                mutableChild.percentageOfParent = Double(child.size) / Double(size)
                return mutableChild
            }
        }

        return StorageNode(
            url: url,
            isDirectory: true,
            size: size,
            children: children
        )
    }

    /// Calculates the total size of a directory by enumerating all files.
    private func calculateDirectorySize(_ url: URL) async -> Int64 {
        return await FileEnumerator.directorySize(url)
    }

    /// Returns the allocated size of a single file.
    private static func fileSize(at url: URL) -> Int64 {
        guard let values = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey]) else {
            return 0
        }
        return Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
    }
}
