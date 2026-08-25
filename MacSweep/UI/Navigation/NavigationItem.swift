import SwiftUI

public enum NavigationGroup: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case cleanup = "Cleanup"
    case tools = "Tools"
    case preferences = "Preferences"

    public var id: String { rawValue }
}

public enum NavigationItem: String, CaseIterable, Identifiable, Hashable, Sendable {
    case dashboard
    case smartScan
    case storageAnalyzer
    case duplicates
    case largeFiles
    case developerCleaner
    case startupItems
    case uninstaller
    case privacy
    case settings

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .smartScan: return "Smart Scan"
        case .storageAnalyzer: return "Storage Analyzer"
        case .duplicates: return "Duplicates Finder"
        case .largeFiles: return "Large Files"
        case .developerCleaner: return "Developer Cleaner"
        case .startupItems: return "Startup Items"
        case .uninstaller: return "App Uninstaller"
        case .privacy: return "Privacy Cleaner"
        case .settings: return "Settings"
        }
    }

    public var iconName: String {
        switch self {
        case .dashboard: return "gauge.medium"
        case .smartScan: return "sparkles"
        case .storageAnalyzer: return "chart.pie.fill"
        case .duplicates: return "doc.on.doc.fill"
        case .largeFiles: return "doc.badge.arrow.up.fill"
        case .developerCleaner: return "hammer.fill"
        case .startupItems: return "bolt.fill"
        case .uninstaller: return "trash.square.fill"
        case .privacy: return "hand.raised.fill"
        case .settings: return "gearshape.fill"
        }
    }

    public var group: NavigationGroup {
        switch self {
        case .dashboard: return .overview
        case .smartScan, .developerCleaner, .privacy: return .cleanup
        case .storageAnalyzer, .duplicates, .largeFiles, .startupItems, .uninstaller: return .tools
        case .settings: return .preferences
        }
    }
}
