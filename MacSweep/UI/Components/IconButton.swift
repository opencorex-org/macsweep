import SwiftUI

public struct IconButton: View {
    public let iconName: String
    public let tooltip: String?
    public let action: () -> Void

    public init(
        iconName: String,
        tooltip: String? = nil,
        action: @escaping () -> Void
    ) {
        self.iconName = iconName
        self.tooltip = tooltip
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.msSecondaryLabel)
                .frame(width: 28, height: 28)
                .background(Color.primary.opacity(0.05))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .help(tooltip ?? "")
        .hoverEffect(scale: 1.1)
    }
}
