import Foundation
import SwiftUI

/// Categories of cleanable artifacts discovered during scanning.
public enum CleanupCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case systemCache
    case userLogs
    case trash
    case developerXcode
    case developerGradle
    case developerNode
    case developerHomebrew
    case developerDocker
    case browserPrivacy
    case largeFiles
    case duplicates
    case applicationLeftovers

    public var id: String { rawValue }

    /// Human-readable display name for UI.
    public var displayName: String {
        switch self {
        case .systemCache: return "System Caches"
        case .userLogs: return "Log Files"
        case .trash: return "Trash"
        case .developerXcode: return "Xcode Caches"
        case .developerGradle: return "Gradle Caches"
        case .developerNode: return "Node.js Caches"
        case .developerHomebrew: return "Homebrew Cache"
        case .developerDocker: return "Docker Data"
        case .browserPrivacy: return "Browser Data"
        case .largeFiles: return "Large Files"
        case .duplicates: return "Duplicates"
        case .applicationLeftovers: return "App Leftovers"
        }
    }

    /// Short description of what this category contains.
    public var subtitle: String {
        switch self {
        case .systemCache: return "Temporary cache files from apps and system"
        case .userLogs: return "Application and system log files"
        case .trash: return "Items in Trash"
        case .developerXcode: return "DerivedData, archives, and simulator caches"
        case .developerGradle: return "Gradle build caches and wrapper downloads"
        case .developerNode: return "npm, pnpm, Yarn, and Bun caches"
        case .developerHomebrew: return "Downloaded bottles and formula caches"
        case .developerDocker: return "Docker desktop build caches"
        case .browserPrivacy: return "Browser caches, cookies, and local storage"
        case .largeFiles: return "Files exceeding the configured size threshold"
        case .duplicates: return "Duplicate file copies"
        case .applicationLeftovers: return "Orphaned files from uninstalled applications"
        }
    }

    /// SF Symbol icon name for this category.
    public var iconName: String {
        switch self {
        case .systemCache: return "internaldrive"
        case .userLogs: return "doc.text"
        case .trash: return "trash"
        case .developerXcode: return "hammer"
        case .developerGradle: return "shippingbox"
        case .developerNode: return "cube.box"
        case .developerHomebrew: return "mug"
        case .developerDocker: return "cube.transparent"
        case .browserPrivacy: return "globe"
        case .largeFiles: return "doc.badge.arrow.up"
        case .duplicates: return "doc.on.doc"
        case .applicationLeftovers: return "app.badge.checkmark"
        }
    }

    /// Icon tint color for this category.
    public var tintColor: Color {
        switch self {
        case .systemCache: return .blue
        case .userLogs: return .gray
        case .trash: return .orange
        case .developerXcode: return .indigo
        case .developerGradle: return .green
        case .developerNode: return .mint
        case .developerHomebrew: return .brown
        case .developerDocker: return .cyan
        case .browserPrivacy: return .purple
        case .largeFiles: return .red
        case .duplicates: return .pink
        case .applicationLeftovers: return .teal
        }
    }

    /// Default risk level associated with this category.
    public var defaultRisk: CleanupRisk {
        switch self {
        case .systemCache, .userLogs, .developerGradle, .developerNode,
             .developerHomebrew, .developerDocker:
            return .safe
        case .trash, .developerXcode, .browserPrivacy, .largeFiles, .duplicates:
            return .caution
        case .applicationLeftovers:
            return .high
        }
    }
}
