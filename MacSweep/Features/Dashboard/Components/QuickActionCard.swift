import SwiftUI

public struct QuickActionCard: View {
    public let title: String
    public let subtitle: String
    public let iconName: String
    public let iconColor: Color
    public let categoryTag: String
    public let action: () -> Void

    public init(
        title: String,
        subtitle: String,
        iconName: String,
        iconColor: Color,
        categoryTag: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.iconColor = iconColor
        self.categoryTag = categoryTag
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 42, height: 42)

                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.msLabel)

                        Text(categoryTag)
                            .font(.system(size: 9, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(iconColor.opacity(0.12))
                            .foregroundColor(iconColor)
                            .cornerRadius(4)
                    }

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.msSecondaryLabel)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.msSecondaryLabel.opacity(0.6))
            }
            .padding(14)
            .background(Color.msSecondaryBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .hoverEffect(scale: 1.01)
    }
}
