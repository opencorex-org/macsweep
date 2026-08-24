import Foundation

/// Specialized size formatting utilities extending ByteFormatter for specific UI contexts.
public struct FileSizeFormatter {
    /// Formats a size with a percentage relative to a total.
    public static func formatWithPercentage(size: Int64, total: Int64) -> String {
        let sizeStr = ByteFormatter.format(size)
        guard total > 0 else { return sizeStr }
        let percentage = Double(size) / Double(total) * 100
        return "\(sizeStr) (\(String(format: "%.1f", percentage))%)"
    }

    /// Returns a short human-readable description of the size (e.g., "Small", "Medium", "Large").
    public static func sizeCategory(_ bytes: Int64) -> String {
        switch bytes {
        case 0..<1_048_576: return "Small"
        case 1_048_576..<104_857_600: return "Medium"
        case 104_857_600..<1_073_741_824: return "Large"
        default: return "Very Large"
        }
    }
}
