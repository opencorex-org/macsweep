import SwiftUI

public struct SecondaryButton: View {
    public let title: String
    public let iconName: String?
    public let action: () -> Void

    public init(
        title: String,
        iconName: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.iconName = iconName
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 13, weight: .medium))
                }
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .frame(minHeight: 30)
            .background(Color.primary.opacity(0.08))
            .foregroundColor(.msLabel)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .hoverEffect(scale: 1.02)
    }
}
