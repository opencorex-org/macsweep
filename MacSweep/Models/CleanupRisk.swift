import Foundation

/// Risk classification assigned to cleanable items by the Safety Validator.
/// Determines UI coloring, confirmation requirements, and default selection state.
public enum CleanupRisk: String, Codable, Sendable, CaseIterable, Comparable {
    /// Harmless temporary files that can be safely removed (e.g., download caches, log files).
    case safe

    /// User-generated artifacts that may have value (e.g., Xcode Archives, old downloads).
    /// Requires user attention but is generally safe to remove.
    case caution

    /// Items requiring strict user verification before removal (e.g., app preferences, shared configs).
    case high

    /// Display name for UI presentation.
    public var displayName: String {
        switch self {
        case .safe: return "Safe"
        case .caution: return "Caution"
        case .high: return "High Risk"
        }
    }

    /// SF Symbol name for the risk level icon.
    public var iconName: String {
        switch self {
        case .safe: return "checkmark.shield.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .high: return "xmark.shield.fill"
        }
    }

    public static func < (lhs: CleanupRisk, rhs: CleanupRisk) -> Bool {
        let order: [CleanupRisk: Int] = [.safe: 0, .caution: 1, .high: 2]
        return order[lhs]! < order[rhs]!
    }
}
