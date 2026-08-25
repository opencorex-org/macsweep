import SwiftUI

public enum Typography {
    public static let largeTitle = Font.system(.largeTitle, design: .default, weight: .bold)
    public static let title = Font.system(.title2, design: .default, weight: .semibold)
    public static let headline = Font.system(.headline, design: .default, weight: .semibold)
    public static let body = Font.system(.body, design: .default)
    public static let caption = Font.system(.caption, design: .default)
    public static let monoDigits = Font.system(.body, design: .monospaced).monospacedDigit()
}
