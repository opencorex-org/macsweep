import SwiftUI

public struct CardModifier: ViewModifier {
    var backgroundColor: Color = .msSecondaryBackground
    var cornerRadius: CGFloat = AppTheme.cornerRadius
    var padding: CGFloat = AppTheme.contentPadding
    var borderWidth: CGFloat = 0.5
    var borderColor: Color = Color.primary.opacity(0.1)

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

public extension View {
    func cardStyle(
        backgroundColor: Color = .msSecondaryBackground,
        cornerRadius: CGFloat = AppTheme.cornerRadius,
        padding: CGFloat = AppTheme.contentPadding
    ) -> some View {
        modifier(CardModifier(backgroundColor: backgroundColor, cornerRadius: cornerRadius, padding: padding))
    }
}
