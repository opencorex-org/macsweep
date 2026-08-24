import Foundation
import OSLog

/// Provides real-time disk space metrics for the boot volume.
public final class DiskSpaceService: Sendable {
    public init() {}

    /// Retrieves current disk space information for the boot volume.
    public func getDiskSpace() throws -> DiskSpace {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let values = try homeURL.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey,
            .volumeNameKey
        ])

        guard let totalCapacity = values.volumeTotalCapacity,
              let availableCapacity = values.volumeAvailableCapacityForImportantUsage else {
            throw MacSweepError.diskSpaceUnavailable
        }

        let total = Int64(totalCapacity)
        let available = Int64(availableCapacity)
        let used = total - available

        Logger.storage.debug("Disk space: \(ByteFormatter.format(used)) used of \(ByteFormatter.format(total))")

        return DiskSpace(
            volumeName: values.volumeName ?? "Macintosh HD",
            totalCapacity: total,
            availableCapacity: available,
            usedCapacity: used
        )
    }
}

/// Immutable snapshot of disk space information.
public struct DiskSpace: Sendable {
    public let volumeName: String
    public let totalCapacity: Int64
    public let availableCapacity: Int64
    public let usedCapacity: Int64

    /// Percentage of disk used (0.0 to 1.0).
    public var usedPercentage: Double {
        guard totalCapacity > 0 else { return 0 }
        return Double(usedCapacity) / Double(totalCapacity)
    }

    /// Formatted total capacity string.
    public var formattedTotal: String { ByteFormatter.format(totalCapacity) }
    /// Formatted available capacity string.
    public var formattedAvailable: String { ByteFormatter.format(availableCapacity) }
    /// Formatted used capacity string.
    public var formattedUsed: String { ByteFormatter.format(usedCapacity) }
}
