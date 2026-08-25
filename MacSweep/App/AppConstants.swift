import Foundation

/// Global constants and default configuration values for MacSweep.
public enum AppConstants {
    /// Application metadata
    public enum App {
        public static let name = "MacSweep"
        public static let organization = "OpenCorex"
        public static let bundleIdentifier = "org.opencorex.macsweep"
        public static let repositoryURL = URL(string: "https://github.com/opencorex-org/macsweep")!
        public static let releasesURL = URL(string: "https://api.github.com/repos/opencorex-org/macsweep/releases/latest")!
    }

    /// Default scan and cleanup settings
    public enum Defaults {
        /// Minimum file age in days before considering for cleanup
        public static let minimumFileAgeDays: Int = 0
        /// Default large file threshold in bytes (1 GB)
        public static let largeFileThreshold: Int64 = 1_073_741_824
        /// Minimum file size for duplicate detection (1 MB)
        public static let duplicateMinimumSize: Int64 = 1_048_576
        /// Partial hash chunk size in bytes (16 KB)
        public static let partialHashChunkSize: Int = 16_384
        /// Maximum concurrent scan operations
        public static let maxConcurrentScans: Int = 4
    }

    /// Large file size threshold presets
    public enum LargeFileThresholds {
        public static let mb500: Int64 = 524_288_000
        public static let gb1: Int64 = 1_073_741_824
        public static let gb5: Int64 = 5_368_709_120
        public static let gb10: Int64 = 10_737_418_240

        public static let all: [(label: String, bytes: Int64)] = [
            ("500 MB", mb500),
            ("1 GB", gb1),
            ("5 GB", gb5),
            ("10 GB", gb10)
        ]
    }

    /// Window and UI dimensions
    public enum Window {
        public static let minWidth: CGFloat = 900
        public static let minHeight: CGFloat = 600
        public static let sidebarWidth: CGFloat = 220
    }
}
