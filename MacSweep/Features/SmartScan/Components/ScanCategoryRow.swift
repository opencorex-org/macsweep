import SwiftUI

public struct ScanCategoryRow: View {
    public let category: CleanupCategory
    public let items: [CleanupItem]
    public let isSelected: Bool
    public let onToggle: (Bool) -> Void

    public var totalSize: Int64 {
        items.reduce(0) { $0 + $1.size }
    }

    public var selectedCount: Int {
        items.filter(\.isSelected).count
    }

    public var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: { onToggle($0) }
            ))
            .labelsHidden()
            .toggleStyle(.checkbox)

            ZStack {
                Circle()
                    .fill(category.tintColor.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: category.iconName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(category.tintColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(category.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.msLabel)

                Text(category.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.msSecondaryLabel)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(ByteFormatter.format(totalSize))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.msLabel)

                Text("\(selectedCount)/\(items.count) items")
                    .font(.system(size: 11))
                    .foregroundColor(.msSecondaryLabel)
            }
        }
        .padding(.vertical, 6)
    }
}
