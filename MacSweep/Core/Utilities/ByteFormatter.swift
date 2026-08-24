import Foundation

/// Formats raw byte counts into human-readable storage size strings (e.g., "14.2 GB").
public struct ByteFormatter {
    private static let formatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        return formatter
    }()

    /// Formats a byte count into a localized, human-readable string.
    /// - Parameter bytes: The number of bytes to format.
    /// - Returns: A formatted string such as "14.2 GB" or "512 MB".
    public static func format(_ bytes: Int64) -> String {
        return formatter.string(fromByteCount: bytes)
    }

    /// Formats a byte count with explicit unit control.
    /// - Parameters:
    ///   - bytes: The number of bytes to format.
    ///   - units: The allowed units to display.
    /// - Returns: A formatted string in the specified units.
    public static func format(_ bytes: Int64, units: ByteCountFormatter.Units) -> String {
        let fmt = ByteCountFormatter()
        fmt.countStyle = .file
        fmt.allowedUnits = units
        return fmt.string(fromByteCount: bytes)
    }

    /// Returns a short compact representation (e.g., "14GB").
    public static func compact(_ bytes: Int64) -> String {
        let fmt = ByteCountFormatter()
        fmt.countStyle = .file
        fmt.includesUnit = true
        fmt.isAdaptive = true
        return fmt.string(fromByteCount: bytes)
    }
}
