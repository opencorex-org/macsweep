import Foundation
import OSLog

/// Coordinates storage analysis operations for the Storage Analyzer feature.
public actor StorageAnalyzer {
    private let calculator = DirectorySizeCalculator()

    /// Analyzes storage usage for a given root directory.
    public func analyze(rootURL: URL, maxDepth: Int = 3) async -> StorageNode {
        Logger.storage.info("Starting storage analysis at: \(rootURL.path, privacy: .private)")
        let tree = await calculator.calculateTree(at: rootURL, maxDepth: maxDepth)
        Logger.storage.info("Storage analysis complete: \(ByteFormatter.format(tree.size))")
        return tree
    }
}
