import Foundation

/// Provides consistent date formatting across MacSweep for file metadata display.
public struct AppDateFormatter {
    /// Displays relative dates like "2 hours ago", "Yesterday", "3 days ago".
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    /// Standard medium date format (e.g., "Aug 24, 2026").
    private static let mediumFormatter: Foundation.DateFormatter = {
        let formatter = Foundation.DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Full date and time format (e.g., "Aug 24, 2026 at 8:10 AM").
    private static let fullFormatter: Foundation.DateFormatter = {
        let formatter = Foundation.DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    /// Formats a date as a relative string (e.g., "2 hours ago").
    public static func relative(_ date: Date) -> String {
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    /// Formats a date as a medium-style string (e.g., "Aug 24, 2026").
    public static func medium(_ date: Date) -> String {
        return mediumFormatter.string(from: date)
    }

    /// Formats a date with both date and time (e.g., "Aug 24, 2026 at 8:10 AM").
    public static func full(_ date: Date) -> String {
        return fullFormatter.string(from: date)
    }
}
