import SwiftUI

public enum AppThemePreference: String, CaseIterable, Identifiable {
    case light
    case dark
    case system

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .light: "Light"
        case .dark: "Dark"
        case .system: "System"
        }
    }

    public var icon: String {
        switch self {
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        case .system: "circle.lefthalf.filled"
        }
    }

    public var detail: String {
        switch self {
        case .light: "Always use the light appearance"
        case .dark: "Always use the dark appearance"
        case .system: "Match your Mac's current appearance"
        }
    }

    public var colorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }
}

/// Centralized theme providing consistent styling tokens across MacSweep.
public enum AppTheme {
    /// UserDefaults key shared by the app scene and Settings.
    public static let preferenceKey = "AppThemePreference"
    /// Standard corner radius for card components.
    public static let cornerRadius: CGFloat = 12
    /// Standard padding for content areas.
    public static let contentPadding: CGFloat = 16
    /// Standard spacing between list items.
    public static let itemSpacing: CGFloat = 8
    /// Standard section spacing.
    public static let sectionSpacing: CGFloat = 20
    /// Animation duration for micro-interactions.
    public static let animationDuration: Double = 0.25
}
