import Foundation
import OSLog

/// Local-only execution statistics tracker.
/// Records cleanup session metrics to UserDefaults for display in the Dashboard.
/// NO data is ever transmitted over the network.
public final class AnalyticsService: Sendable {
    private let storageKey = "MacSweep_LocalStats"

    public init() {}

    /// Records the result of a cleanup operation.
    public func recordCleanup(result: CleanResult) {
        var stats = loadStats()
        stats.totalCleanups += 1
        stats.totalBytesReclaimed += result.totalBytesReclaimed
        stats.totalItemsCleaned += result.successCount
        stats.lastCleanupDate = Date()
        saveStats(stats)
        Logger.app.info("Recorded cleanup stats: \(ByteFormatter.format(result.totalBytesReclaimed)) reclaimed")
    }

    /// Returns cumulative local statistics.
    public func loadStats() -> LocalStats {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let stats = try? JSONDecoder().decode(LocalStats.self, from: data) else {
            return LocalStats()
        }
        return stats
    }

    private func saveStats(_ stats: LocalStats) {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

/// Local-only cumulative statistics. Never transmitted over the network.
public struct LocalStats: Codable, Sendable {
    public var totalCleanups: Int = 0
    public var totalBytesReclaimed: Int64 = 0
    public var totalItemsCleaned: Int = 0
    public var lastCleanupDate: Date?

    public var formattedTotalReclaimed: String {
        ByteFormatter.format(totalBytesReclaimed)
    }
}
