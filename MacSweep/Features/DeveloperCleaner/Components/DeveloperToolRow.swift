import SwiftUI

public struct DeveloperToolRow: View {
    public let item: CleanupItem
    public let onToggle: () -> Void

    public var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { item.isSelected },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .toggleStyle(.checkbox)

            ZStack {
                Circle()
                    .fill(item.category.tintColor.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: item.category.iconName)
                    .font(.system(size: 14))
                    .foregroundColor(item.category.tintColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.msLabel)

                Text(item.url.path)
                    .font(.system(size: 10))
                    .foregroundColor(.msSecondaryLabel)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(item.formattedSize)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.msLabel)

                Text(item.category.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.msSecondaryLabel)
            }
        }
        .padding(.vertical, 4)
    }
}
