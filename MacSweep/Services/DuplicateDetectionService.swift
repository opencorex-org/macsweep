import Foundation
import OSLog
import CryptoKit

/// Multi-stage duplicate file detection engine using size grouping and content hashing.
public actor DuplicateDetectionService {
    public init() {}

    /// Discovers duplicate files in the given directories.
    public func findDuplicates(in directories: [URL]) async -> [DuplicateGroup] {
        Logger.scanner.info("Starting duplicate detection")
        var fileBySizeGroup: [Int64: [URL]] = [:]

        // Stage 1 & 2: Enumerate and group by size
        for dir in directories {
            for await metadata in FileEnumerator.enumerate(directory: dir, includeHidden: false) {
                if Task.isCancelled { return [] }
                guard !metadata.isDirectory && metadata.size >= AppConstants.Defaults.duplicateMinimumSize else { continue }
                fileBySizeGroup[metadata.size, default: []].append(metadata.url)
            }
        }

        // Filter to groups with multiple files
        let candidates = fileBySizeGroup.filter { $0.value.count > 1 }
        var groups: [DuplicateGroup] = []

        // Stage 3-5: Hash and group duplicates
        for (fileSize, urls) in candidates {
            if Task.isCancelled { return groups }

            var hashGroups: [String: [URL]] = [:]

            for url in urls {
                if let hash = hashFile(url) {
                    hashGroups[hash, default: []].append(url)
                }
            }

            for (hash, matchedURLs) in hashGroups where matchedURLs.count > 1 {
                let files = matchedURLs.enumerated().map { index, url in
                    let modDate = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                    return DuplicateFile(
                        url: url,
                        modificationDate: modDate,
                        isOriginal: index == 0
                    )
                }

                groups.append(DuplicateGroup(
                    fileHash: hash,
                    fileSize: fileSize,
                    files: files
                ))
            }
        }

        groups.sort { $0.wastedSpace > $1.wastedSpace }
        Logger.scanner.info("Duplicate detection complete: \(groups.count) groups found")
        return groups
    }

    /// Computes SHA256 hash of a file's contents.
    private func hashFile(_ url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }

        var hasher = SHA256()
        while autoreleasepool(invoking: {
            let data = handle.readData(ofLength: 1_048_576) // 1MB chunks
            guard !data.isEmpty else { return false }
            hasher.update(data: data)
            return true
        }) {}

        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
